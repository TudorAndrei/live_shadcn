defmodule Mix.Tasks.Ui.Verify do
  @shortdoc "Check a reviewed component against its contract, snapshot, and browser"

  @moduledoc """
  The last stage of the maintainer pipeline, and the only stage that can say a component
  is finished.

      mix ui.verify
      mix ui.verify accordion
      mix ui.verify shadcn/message    # one component, said unambiguously
      mix ui.verify --no-browser      # skip the browser, for a machine without one

  Six checks, each answering a different question:

  | Check | Question |
  |---|---|
  | generated | does the reviewed port on disk still match its contract? |
  | snapshot | has the markup a reader gets changed? |
  | examples | does every official upstream example have HEEx and the exact React reference? |
  | browser | does it behave like Base UI, and does it add no axe-core failures? |
  | parity | does its semantic HTML and computed CSS match upstream React? |
  | pixel | does it paint the same pixels as upstream React? |

  The first two are cheap and run anywhere. The last three start a browser,
  because opening a panel is a client behaviour and so is layout: no amount of
  server-side rendering can tell you whether either works.

  The contract checks cannot catch a spec that read upstream wrongly. A class
  string that the reader dropped is absent from the module, snapshot, and
  expectation. The browser accessibility check compares the port with the
  pinned upstream page and rejects failures added by the port. The last two
  checks also render the pinned upstream source. Parity compares HTML element
  types, visible text, ARIA state, geometry, and computed CSS. Pixel compares
  what the browser paints. Both checks run the initial state and each visible
  open state that the example exposes. Framework-owned ids and LiveView
  transport attributes are not compared because the two renderers cannot share
  these values.

  The result is written to `registry/VERIFY.json`, keyed by `<source>/<name>`,
  which is what makes `mix ui.status` able to mark a component verified. Status
  is never typed by hand, here least of all.
  """
  use Mix.Task

  alias LiveShadcnTools.AiElementsExamples
  alias LiveShadcnTools.BrowserVerification
  alias LiveShadcnTools.PlaywrightReport
  alias LiveShadcnTools.ShadcnExamples
  alias LiveShadcnTools.VerifierLock
  alias LiveShadcnTools.VerificationPolicy

  import LiveShadcnTools

  @browser_example_batch_size 4
  @managed_browser_servers_env "LIVE_SHADCN_MANAGED_SERVERS"
  @browser_server_ready_timeout 120_000
  @browser_server_request_timeout 1_000

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [browser: :boolean])
    browser? = Keyword.get(opts, :browser, true)

    components = if names == [], do: generated(), else: Enum.map(names, &resolve/1)

    if components == [] do
      Mix.raise("nothing to verify: no reviewed component port exists.")
    end

    example_results =
      Map.new(components, fn {source, name} ->
        {ref(source, name),
         example_checks(
           source,
           name,
           example_key(source, name),
           VerificationPolicy.get(source, name)
         )}
      end)

    browser_components =
      Enum.filter(components, fn {source, name} ->
        example_results
        |> Map.fetch!(ref(source, name))
        |> Enum.all?(fn {_check, result} -> result["pass"] end)
      end)

    verify_components = fn shared_checks ->
      Map.new(components, fn {source, name} ->
        reference = ref(source, name)
        checks = Map.fetch!(example_results, reference)

        {reference,
         verify(
           source,
           name,
           browser?,
           examples_complete?(checks),
           official_comparison?(checks),
           checks,
           shared_checks
         )}
      end)
    end

    results =
      if browser? and browser_components != [] do
        try do
          VerifierLock.with_lock(repo_root(), fn token ->
            Process.put(:live_shadcn_source_lease_token, token)

            try do
              ensure_browser_ports_free!()
              prepare_browser!()

              with_managed_browser_servers(fn ->
                shared_checks =
                  if match?([_, _ | _], browser_components) do
                    batch_browser_checks(browser_components)
                  end

                verify_components.(shared_checks)
              end)
            after
              Process.delete(:live_shadcn_source_lease_token)
            end
          end)
        rescue
          error ->
            verification_preparation_failed(
              components,
              example_results,
              Exception.message(error)
            )
        end
      else
        verify_components.(nil)
      end

    write_json!(registry_path("VERIFY.json"), merge(results))
    report(results)
  end

  # A run over one component says nothing about the others, so it replaces its
  # own entries and leaves the rest of the file alone. Writing only what this
  # run proved would demote every component nobody asked about, and demoting a
  # component is what a spec change is for.
  defp merge(results) do
    path = registry_path("VERIFY.json")
    existing = if File.exists?(path), do: read_json!(path), else: %{}

    existing
    |> Map.filter(fn {reference, _result} -> generated?(reference) end)
    |> Map.merge(results)
  end

  # A component that no longer generates has no record to keep. `open-in-chat`
  # is one: every part of it turned out to be a wrapper around
  # `<.dropdown_menu>`, so there is nothing to generate and nothing to verify,
  # and a passing entry left behind would say the opposite.
  defp generated?(reference) do
    {source, name} = parse_ref(reference)

    File.exists?(module_path(source, name))
  end

  # `registry/` knows a component by source and name. `storybook/` knows it by
  # name alone, because an example is hand-written and a person names a file
  # `accordion.spec.mjs`.
  #
  # That works while no two components share a name, and upstream has a
  # `message` in each registry. So the storybook names that one `shadcn-message`
  # and this asks the storybook which key an example is under rather than
  # assuming the name.
  #
  # The source-and-name first, so a component that has its own example is never
  # verified against somebody else's. Then the name, which is what almost every
  # example is called, because a unique name is an identity.
  defp example_key(source, name) do
    previewed = previewed()

    cond do
      "#{source}-#{name}" in previewed -> "#{source}-#{name}"
      name in previewed -> name
      true -> nil
    end
  end

  defp generated do
    registry_path("spec")
    |> Path.join("*/*.json")
    |> Path.wildcard()
    |> Enum.map(&{Path.basename(Path.dirname(&1)), Path.basename(&1, ".json")})
    |> Enum.filter(fn {source, name} -> File.exists?(module_path(source, name)) end)
    |> Enum.sort()
  end

  defp verify(
         source,
         name,
         browser?,
         examples_complete?,
         official_comparison?,
         example_checks,
         shared_checks
       ),
       do:
         verify(
           source,
           name,
           browser?,
           examples_complete?,
           official_comparison?,
           example_checks,
           shared_checks,
           nil
         )

  defp verify(
         source,
         name,
         browser?,
         examples_complete?,
         official_comparison?,
         example_checks,
         shared_checks,
         preparation_failure
       ) do
    reference = ref(source, name)
    key = example_key(source, name)
    policy = VerificationPolicy.get(source, name)

    checks =
      if policy.kind == :no_dom do
        no_dom_checks(policy)
      else
        [
          {"generated", generated_check(reference)},
          {"snapshot", snapshot_check(key)}
        ] ++
          example_checks ++
          browser_checks(
            source,
            name,
            key,
            browser?,
            examples_complete?,
            official_comparison?,
            shared_checks,
            policy,
            preparation_failure
          )
      end

    checks = Map.new(checks)

    %{
      "pass" => verified_checks?(source, policy, checks),
      "spec" => spec_digest(source, name),
      "evidence" => verification_evidence_digest(source, name),
      "checks" => checks
    }
  end

  # A preparation error happens before Playwright can produce a report. It must
  # still replace earlier green evidence for each requested component.
  defp verification_preparation_failed(components, example_results, detail) do
    Map.new(components, fn {source, name} ->
      reference = ref(source, name)
      key = example_key(source, name)
      policy = VerificationPolicy.get(source, name)
      examples = Map.fetch!(example_results, reference)

      {reference,
       verify(
         source,
         name,
         false,
         examples_complete?(examples),
         official_comparison?(examples),
         examples,
         nil,
         "browser preparation failed: #{detail}"
       )}
    end)
  end

  defp browser_checks(
         _source,
         _name,
         _key,
         false,
         _examples_complete?,
         _official_comparison?,
         _shared_checks,
         _policy,
         nil
       ),
       do: browser_not_run_checks()

  defp browser_checks(
         _source,
         _name,
         _key,
         false,
         _examples_complete?,
         _official_comparison?,
         _shared_checks,
         _policy,
         reason
       ),
       do: browser_not_run_checks(reason)

  defp browser_checks(
         _source,
         _name,
         _key,
         true,
         false,
         _official_comparison?,
         _shared_checks,
         _policy,
         _preparation_failure
       ),
       do: browser_not_run_checks("official example coverage is incomplete")

  defp browser_checks(source, name, key, true, true, false, shared_checks, policy, _failure) do
    browser_results(source, name, key, shared_checks, policy) ++
      not_applicable_upstream_checks(policy)
  end

  defp browser_checks(source, name, key, true, true, true, shared_checks, policy, _failure) do
    browser_results(source, name, key, shared_checks, policy) ++
      upstream_results(source, key, shared_checks)
  end

  defp browser_results(source, name, key, nil, policy),
    do: browser_checks_for_component(source, name, key, policy)

  defp browser_results(_source, _name, nil, _shared_checks, _policy) do
    result = no_example()
    [{"browser", result}, {"behavior", result}, {"accessibility", result}]
  end

  defp browser_results(_source, _name, key, shared_checks, _policy) do
    behavior = shared_check(shared_checks, "behavior", key)
    accessibility = shared_check(shared_checks, "accessibility", key)

    [
      {"browser", BrowserVerification.merge_checks([behavior, accessibility])},
      {"behavior", behavior},
      {"accessibility", accessibility}
    ]
  end

  defp upstream_results(_source, key, nil),
    do: [{"parity", parity_check(key)}, {"pixel", pixel_check(key)}]

  defp upstream_results(_source, key, shared_checks) do
    parity =
      if key && ported?(key),
        do: shared_check(shared_checks, "parity", key),
        else: parity_check(key)

    pixel =
      cond do
        is_nil(key) or not ported?(key) -> pixel_check(key)
        skipped_pixels(key) -> pixel_check(key)
        pending_pixels(key) -> pixel_check(key)
        true -> shared_check(shared_checks, "pixel", key)
      end

    [{"parity", parity}, {"pixel", pixel}]
  end

  defp browser_not_run_checks(reason \\ "--no-browser was used") do
    for check <- ["browser", "behavior", "accessibility", "parity", "pixel"] do
      {check,
       %{
         "pass" => false,
         "gated" => false,
         "detail" => "not run because #{reason}"
       }}
    end
  end

  defp not_applicable_upstream_checks(%{kind: :local_only, reason: reason}) do
    for check <- ["parity", "pixel"] do
      {check,
       %{
         "pass" => false,
         "gated" => false,
         "detail" => "not applicable: local-only policy; #{reason}"
       }}
    end
  end

  defp no_dom_checks(%{kind: :no_dom, reason: reason}) do
    for check <- [
          "generated",
          "snapshot",
          "examples",
          "browser",
          "behavior",
          "accessibility",
          "parity",
          "pixel"
        ] do
      {check,
       %{
         "pass" => false,
         "gated" => false,
         "detail" => "not applicable: no-DOM policy; #{reason}"
       }}
    end
  end

  defp examples_complete?(checks),
    do: Enum.all?(checks, fn {_check, result} -> result["pass"] end)

  defp official_comparison?(checks),
    do: get_in(Map.new(checks), ["examples", "official_comparison"]) != false

  defp shared_check(checks, kind, key) do
    get_in(checks, [kind, key]) ||
      %{"pass" => false, "detail" => "#{kind} report has no result for #{key}"}
  end

  # Full verification uses the same four-example batches as a one-component
  # run. Previously it put every preview into one Playwright process, which
  # made a late example time out after an unrelated example had exhausted the
  # browser. Keeping the work in this one Mix task avoids a task per component;
  # each browser command still has one worker by configuration.
  #
  # The behaviour suite remains one file per component. It is a component
  # contract, not an unbounded sweep over every visual state. Accessibility,
  # semantic parity, and pixel parity all enumerate each local official
  # example and use `batched_example_reports/3` below.
  defp batch_browser_checks(components) do
    components
    |> Enum.sort()
    |> Enum.reduce(
      %{"behavior" => %{}, "accessibility" => %{}, "parity" => %{}, "pixel" => %{}},
      fn {source, name}, checks ->
        key = example_key(source, name)
        policy = VerificationPolicy.get(source, name)

        checks =
          checks
          |> put_in(["behavior", key], behavior_check(source, name, key, policy))
          |> put_in(["accessibility", key], accessibility_check(key))

        if policy.kind == :standard do
          checks
          |> put_in(["parity", key], parity_check(key))
          |> put_in(["pixel", key], pixel_check(key))
        else
          checks
        end
      end
    )
  end

  defp batch_browser_check(kind, args, env, parser \\ nil) do
    parser = parser || fn json -> PlaywrightReport.results(json, previewed()) end

    report =
      Path.join(
        System.tmp_dir!(),
        "live-shadcn-#{kind}-#{System.unique_integer([:positive])}.json"
      )

    try do
      {output, status} =
        System.cmd(
          "npx",
          args ++ ["--reporter", "json"],
          cd: browser_dir(),
          stderr_to_stdout: true,
          env:
            env
            |> managed_browser_environment()
            |> Map.put("PARITY_PREPARED", "1")
            |> Map.put("PLAYWRIGHT_JSON_OUTPUT_FILE", report)
        )

      case File.read(report) do
        {:ok, json} ->
          result =
            json
            |> Jason.decode!()
            |> parser.()

          assigned_failure? =
            Enum.any?(result.components, fn {_component, check} -> not check["pass"] end)

          if status != 0 and result.global_failures == [] and not assigned_failure? do
            %{result | global_failures: ["suite exited #{status}\n#{tail(output)}"]}
          else
            result
          end

        {:error, reason} ->
          %{
            components: %{},
            global_failures: [
              "report is not available: #{:file.format_error(reason)}\n#{tail(output)}"
            ]
          }
      end
    rescue
      error ->
        %{
          components: %{},
          global_failures: ["cannot run Playwright: #{Exception.message(error)}"]
        }
    after
      File.rm(report)
    end
  end

  # `mix ui.verify` owns this pair. Each Playwright command receives an
  # explicit lease flag and may reuse only these processes. This keeps the Vite
  # process tied to sources prepared by this run, while every browser batch
  # still starts with a new browser context.
  defp with_managed_browser_servers(fun) when is_function(fun, 0) do
    with_managed_browser_servers(
      fn ->
        start_and_await_browser_servers!()
      end,
      &stop_browser_servers/1,
      fun
    )
  end

  @doc false
  def with_managed_browser_servers(starter, stopper, fun)
      when is_function(starter, 0) and is_function(stopper, 1) and is_function(fun, 0) do
    servers = starter.()
    Process.put(:live_shadcn_managed_browser_servers, true)

    try do
      fun.()
    after
      Process.delete(:live_shadcn_managed_browser_servers)
      stopper.(servers)
    end
  end

  @doc false
  def managed_browser_environment(
        env,
        managed? \\ Process.get(:live_shadcn_managed_browser_servers)
      )
      when is_map(env) do
    if managed? do
      Map.put(env, @managed_browser_servers_env, "1")
    else
      env
    end
  end

  defp start_and_await_browser_servers! do
    servers = start_browser_servers!()
    await_browser_servers!(servers)
    servers
  rescue
    error ->
      stop_browser_servers(Process.get(:live_shadcn_started_browser_servers, []))
      reraise error, __STACKTRACE__
  end

  defp start_browser_servers! do
    [
      start_browser_server!(
        :storybook,
        storybook_dir(),
        "mix",
        ["phx.server"],
        %{"PORT" => Integer.to_string(browser_port!("STORYBOOK_PORT", 4101)), "MIX_ENV" => "dev"},
        "/previews.json",
        ~r/"accordion"/
      ),
      start_browser_server!(
        :parity,
        parity_root(),
        "npm",
        ["run", "dev:prepared"],
        %{"PARITY_PORT" => Integer.to_string(browser_port!("PARITY_PORT", 4102))},
        "/preview/badge/variants",
        ~r/<div id="root"/
      )
    ]
  end

  defp start_browser_server!(name, cwd, command, args, env, path, expected) do
    executable =
      System.find_executable(command) ||
        Mix.raise("cannot start #{name} browser server: `#{command}` is not available")

    process =
      Port.open(
        {:spawn_executable, executable},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          args: Enum.map(args, &String.to_charlist/1),
          cd: String.to_charlist(cwd),
          env:
            Enum.map(env, fn {key, value} ->
              {String.to_charlist(key), String.to_charlist(value)}
            end)
        ]
      )

    server = %{
      name: name,
      process: process,
      port: browser_port!(port_env(name), default_port(name)),
      path: path,
      expected: expected
    }

    Process.put(:live_shadcn_started_browser_servers, [
      server | Process.get(:live_shadcn_started_browser_servers, [])
    ])

    server
  end

  defp await_browser_servers!(servers) do
    Application.ensure_all_started(:inets)
    deadline = System.monotonic_time(:millisecond) + @browser_server_ready_timeout
    Enum.each(servers, &await_browser_server!(&1, deadline))
    Process.delete(:live_shadcn_started_browser_servers)
    servers
  end

  defp await_browser_server!(server, deadline) do
    case browser_server_reply(server) do
      {:ok, body} when is_binary(body) ->
        if Regex.match?(server.expected, body) do
          :ok
        else
          wait_for_browser_server!(server, deadline)
        end

      :not_ready ->
        wait_for_browser_server!(server, deadline)
    end
  end

  defp wait_for_browser_server!(server, deadline) do
    now = System.monotonic_time(:millisecond)

    cond do
      Port.info(server.process) == nil ->
        Mix.raise("#{server.name} browser server stopped before it became ready")

      now >= deadline ->
        Mix.raise("#{server.name} browser server did not become ready before the timeout")

      true ->
        process = server.process

        receive do
          {^process, {:data, _output}} -> :ok
          {^process, {:exit_status, _status}} -> :ok
        after
          min(@browser_server_request_timeout, deadline - now) -> :ok
        end

        await_browser_server!(server, deadline)
    end
  end

  defp browser_server_reply(server) do
    url =
      ~c"http://127.0.0.1:" ++ Integer.to_charlist(server.port) ++ String.to_charlist(server.path)

    case :httpc.request(:get, {url, []}, [timeout: @browser_server_request_timeout],
           body_format: :binary
         ) do
      {:ok, {{_version, 200, _reason}, _headers, body}} -> {:ok, body}
      _ -> :not_ready
    end
  end

  defp stop_browser_servers(servers) do
    Enum.each(Enum.reverse(servers), &stop_browser_server/1)
    Process.delete(:live_shadcn_started_browser_servers)
  end

  defp stop_browser_server(%{process: process}) do
    if Port.info(process) != nil do
      Port.close(process)
    end
  end

  defp port_env(:storybook), do: "STORYBOOK_PORT"
  defp port_env(:parity), do: "PARITY_PORT"
  defp default_port(:storybook), do: 4101
  defp default_port(:parity), do: 4102

  # Prepare the pinned React sources once before Playwright starts any small
  # batch. The prepared server command only starts Vite, so repeated batches do
  # not race while replacing parity/.upstream.
  #
  # The browser must also use the JavaScript and CSS from the current source
  # tree. A previous build can make a corrected hook look broken, or make a
  # broken hook look correct. Build once before the browser suites start when
  # any asset input is newer than either output.
  def prepare_browser!, do: prepare_browser!(&run_in/4)

  @doc false
  def ensure_browser_ports_free!(ports \\ browser_ports()) do
    Enum.each(ports, fn {name, port} ->
      case :gen_tcp.listen(port, [:binary, active: false]) do
        {:ok, socket} ->
          :ok = :gen_tcp.close(socket)

        {:error, :eaddrinuse} ->
          Mix.raise(
            "cannot prepare browser sources: #{name} port #{port} is already occupied; " <>
              "stop that server before verification"
          )

        {:error, reason} ->
          Mix.raise(
            "cannot reserve #{name} port #{port} before browser preparation: " <>
              "#{:inet.format_error(reason)}"
          )
      end
    end)

    :ok
  end

  @doc false
  def prepare_browser!(runner) when is_function(runner, 4) do
    prepare_parity_sources!(runner)
    prepare_browser_assets!(runner)
    :ok
  end

  defp prepare_parity_sources!(runner) do
    env =
      case Process.get(:live_shadcn_source_lease_token) do
        nil -> %{}
        token -> %{"PARITY_SOURCE_LEASE_TOKEN" => token}
      end

    case runner.(parity_root(), "npm", ["run", "upstream"], env) do
      %{"pass" => true} -> :ok
      %{"detail" => detail} -> Mix.raise("cannot prepare pinned parity sources:\n#{detail}")
    end
  end

  defp prepare_browser_assets!(runner) do
    unless browser_assets_current?() do
      case runner.(storybook_dir(), "mix", ["assets.build"], %{}) do
        %{"pass" => true} -> :ok
        %{"detail" => detail} -> Mix.raise("cannot prepare browser assets:\n#{detail}")
      end
    end
  end

  defp browser_ports do
    [
      storybook: browser_port!("STORYBOOK_PORT", 4101),
      parity: browser_port!("PARITY_PORT", 4102)
    ]
  end

  defp browser_port!(name, default) do
    case System.get_env(name) do
      nil -> default
      value -> String.to_integer(value)
    end
  rescue
    ArgumentError -> Mix.raise("#{name} must be an integer port")
  end

  defp browser_assets_current? do
    outputs =
      for name <- ["app.css", "app.js"] do
        Path.join([storybook_dir(), "priv", "static", "assets", name])
      end

    if Enum.all?(outputs, &File.exists?/1) do
      oldest_output = outputs |> Enum.map(&modified_at!/1) |> Enum.min()
      Enum.all?(browser_asset_inputs(), &(modified_at!(&1) <= oldest_output))
    else
      false
    end
  end

  defp browser_asset_inputs do
    [
      Path.join([storybook_dir(), "assets", "**", "*.{css,js,mjs,json}"]),
      Path.join([storybook_dir(), "lib", "**", "*.ex"]),
      Path.join([repo_root(), "packages", "*", "assets", "**", "*.js"]),
      Path.join([repo_root(), "packages", "*", "priv", "registry", "*.ex"]),
      Path.join([repo_root(), "registry", "upstream", "shadcn", "styles", "*.css"])
    ]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.reject(&String.contains?(&1, "/node_modules/"))
  end

  defp modified_at!(path) do
    path
    |> File.stat!()
    |> Map.fetch!(:mtime)
    |> :calendar.datetime_to_gregorian_seconds()
  end

  # The spec digest is recorded with the result, so a passing entry cannot
  # outlive the spec it was true of.
  defp spec_digest(source, name) do
    path = spec_path(source, name)
    if File.exists?(path), do: digest(File.read!(path))
  end

  defp generated_check(reference) do
    {source, name} = parse_ref(reference)
    contract = read_json!(spec_path(source, name))

    if reviewed_contract?(contract) do
      run_in(tools_dir(), "mix", ["ui.spec", "--check", "--offline", reference])
    else
      %{
        "pass" => false,
        "detail" => "unresolved official facts: #{Enum.join(unresolved_facts(contract), ", ")}"
      }
    end
  end

  defp example_checks(_source, _name, key, %{kind: :local_only, reason: reason}),
    do: [{"examples", local_only_examples_check(key, reason)}]

  defp example_checks(_source, _name, _key, %{kind: :no_dom, reason: reason}),
    do: [{"examples", no_dom_examples_check(reason)}]

  defp example_checks("shadcn", name, key, _policy), do: [{"examples", examples_check(name, key)}]

  defp example_checks("ai_elements", name, key, _policy),
    do: [{"examples", ai_examples_check(name, key)}]

  defp example_checks(_source, _name, _key, _policy), do: []

  defp local_only_examples_check(key, reason) do
    case BrowserVerification.examples(previews(), key || "") do
      [] ->
        %{
          "pass" => false,
          "official_comparison" => false,
          "detail" => "local-only policy has no HEEx preview: #{reason}"
        }

      examples ->
        %{
          "pass" => true,
          "official_comparison" => false,
          "detail" =>
            "not applicable: #{length(examples)} local-only HEEx preview#{if length(examples) == 1, do: "", else: "s"}; #{reason}"
        }
    end
  end

  defp no_dom_examples_check(reason) do
    %{
      "pass" => false,
      "official_comparison" => false,
      "gated" => false,
      "detail" => "not applicable: no-DOM policy; #{reason}"
    }
  end

  defp examples_check(name, key) do
    expected =
      registry_path("UPSTREAM.json")
      |> read_json!()
      |> get_in(["examples", "shadcn", name])
      |> case do
        nil -> []
        sources -> ShadcnExamples.from_sources(name, sources)
      end

    local_examples =
      registry_path(["snapshot", "index.json"])
      |> read_json!()
      |> Map.get(key, [])

    ShadcnExamples.coverage(expected, local_examples)
  end

  defp ai_examples_check(name, key) do
    manifest = registry_path("UPSTREAM.json") |> read_json!()
    expected = AiElementsExamples.from_manifest(manifest, name)

    local_only =
      browser_dir()
      |> Path.join("ai-component-audit.json")
      |> read_json!()
      |> Map.get(key || "", %{})
      |> Map.get("local_only_examples", [])

    local_examples =
      registry_path(["snapshot", "index.json"])
      |> read_json!()
      |> Map.get(key, [])

    case AiElementsExamples.problems(manifest) do
      [] ->
        AiElementsExamples.coverage(expected, local_examples, local_only)

      problems ->
        %{
          "pass" => false,
          "official_comparison" => false,
          "detail" => "AI example discovery is ambiguous: #{Enum.join(problems, "; ")}"
        }
    end
  end

  defp snapshot_check(nil), do: no_example()

  defp snapshot_check(key),
    do: run_in(storybook_dir(), "mix", ["snapshot", "--check", key])

  # Accessibility proves accessibility. It cannot stand in for an interaction
  # suite, because a static page can have a clean accessibility tree.
  defp browser_checks_for_component(source, name, key, policy) do
    behavior = behavior_check(source, name, key, policy)
    accessibility = accessibility_check(key)

    [
      {"browser", BrowserVerification.merge_checks([behavior, accessibility])},
      {"behavior", behavior},
      {"accessibility", accessibility}
    ]
  end

  defp behavior_check(_source, _name, nil, _policy), do: no_example()

  defp behavior_check(source, name, key, policy) do
    case behavior_suite(source, name, key, policy) do
      {:suite, suite} ->
        run_in(browser_dir(), "npx", ["playwright", "test", suite], %{
          "PREVIEW_COMPONENT" => key
        })
        |> BrowserVerification.label("behavior #{key}")

      {:not_applicable, reason} ->
        %{
          "pass" => false,
          "gated" => false,
          "detail" => "behavior is not applicable: #{reason}"
        }

      :missing ->
        %{
          "pass" => false,
          "detail" => "no mapped behavior suite for #{ref(source, name)}"
        }
    end
  end

  defp behavior_suite("ai_elements", _name, key, _policy) do
    contract =
      browser_dir()
      |> Path.join("ai-component-audit.json")
      |> read_json!()
      |> Map.get(key, %{})

    case contract do
      %{"contract" => "interactive", "spec" => suite}
      when is_binary(suite) and byte_size(suite) > 0 ->
        if File.exists?(Path.join(browser_dir(), suite)), do: {:suite, suite}, else: :missing

      %{"contract" => reason} when is_binary(reason) ->
        {:not_applicable, reason}

      _ ->
        :missing
    end
  end

  defp behavior_suite(source, name, _key, policy) do
    case VerificationPolicy.behavior(source, name) do
      {:not_applicable, reason} ->
        {:not_applicable, reason}

      :required ->
        suite = "#{name}.spec.mjs"

        if policy.kind == :standard and File.exists?(Path.join(browser_dir(), suite)) do
          {:suite, suite}
        else
          :missing
        end
    end
  end

  defp accessibility_check(nil), do: no_example()

  defp accessibility_check(key) do
    batched_example_check(key, "accessibility", [
      "playwright",
      "test",
      "accessibility.spec.mjs"
    ])
  end

  # The component beside its upstream React source.
  #
  # The three checks above all ask whether the pipeline was consistent with
  # itself: the module matches the spec, the markup matches the snapshot, the
  # behaviour matches Base UI's contract. None of them can catch a spec that
  # read upstream wrongly, because every one of them reads that same spec. This
  # one reads upstream instead.
  defp parity_check(nil), do: no_example()

  defp parity_check(key) do
    if ported?(key) do
      batched_example_check(key, "parity", [
        "playwright",
        "test",
        "parity.spec.mjs",
        "--grep",
        "draws what React draws"
      ])
    else
      %{
        "pass" => false,
        "detail" => "no React reference yet: add one to parity/src/examples/#{key}.<example>.tsx"
      }
    end
  end

  # The fifth check, and the only one that looks at what was painted.
  #
  # `parity` compares numbers and strings — box geometry and 37 computed
  # properties, per `data-slot`. It cannot see a shadow, an `::after`, a
  # z-order, an SVG glyph, or anything on an element without a `data-slot`.
  # This one photographs both sides and diffs the pixels.
  #
  # Not a replacement for the fourth. `parity` names the fix in the vocabulary a
  # recipe is written in — `padding-left: React 0.5rem, Phoenix 8px`. `pixel`
  # catches what that cannot see, and names only a region. Each is the other's
  # triage tool.
  defp pixel_check(nil), do: no_example()

  defp pixel_check(key) do
    if ported?(key) do
      batched_pixel_check(key)
    else
      previews()
      |> BrowserVerification.examples(key)
      |> Enum.map(fn example ->
        %{
          "pass" => false,
          "detail" =>
            "no React reference yet: add one to parity/src/examples/#{key}.<example>.tsx"
        }
        |> BrowserVerification.label("pixel #{key}.#{example}")
      end)
      |> BrowserVerification.merge_checks()
    end
  end

  defp batched_example_check(key, kind, args) do
    {report, expected} = batched_example_reports(key, kind, args)

    report_example_checks(report, expected, kind)
  end

  defp batched_pixel_check(key) do
    batched_pixel_result(key).components[key]
  end

  defp batched_pixel_result(key) do
    {report, _expected} =
      batched_example_reports(key, "pixel", ["playwright", "test", "--project", "pixel"])

    %{
      components: %{
        key => report_example_checks(report, expected_examples(key), "pixel", &pixel_result/2)
      },
      global_failures: report.global_failures
    }
  end

  defp batched_example_reports(key, kind, args) do
    expected = expected_examples(key)

    reports =
      key
      |> example_batches()
      |> Enum.map(fn batch ->
        names = Enum.map(batch, &"#{key}.#{&1}")

        batch_browser_check(
          kind,
          args,
          %{
            "PREVIEW_COMPONENT" => key,
            "PREVIEW_EXAMPLES" => Enum.join(batch, ",")
          },
          fn json -> PlaywrightReport.example_results(json, names) end
        )
      end)

    {BrowserVerification.merge_reports(reports), expected}
  end

  defp example_batches(key) do
    previews()
    |> BrowserVerification.examples(key)
    |> BrowserVerification.batches(@browser_example_batch_size)
  end

  defp expected_examples(key) do
    previews()
    |> BrowserVerification.examples(key)
    |> Enum.map(&{&1, "#{key}.#{&1}"})
  end

  defp report_example_checks(report, expected, kind, transform \\ fn result, _name -> result end) do
    checks =
      Enum.map(expected, fn {_example, name} ->
        result =
          Map.get(report.components, name, %{
            "pass" => false,
            "detail" => "#{kind} report has no result for #{name}"
          })

        result
        |> transform.(name)
        |> BrowserVerification.label("#{kind} #{name}")
      end)

    global =
      Enum.map(report.global_failures, fn failure ->
        %{"pass" => false, "detail" => "#{kind}: #{failure}"}
      end)

    BrowserVerification.merge_checks(checks ++ global)
  end

  defp pixel_result(result, name) do
    mode =
      cond do
        why = skipped_pixel(name) -> {:skipped, why}
        pending_pixel?(name) -> :pending
        pixels = pixel_budget(name) -> {:budgeted, pixels}
        true -> :compared
      end

    BrowserVerification.finalize_pixel(result, name, mode)
  end

  # The example of this component that will not be compared, and why.
  defp skipped_pixels(key) do
    with %{"skips" => skips} <- budget(),
         {example, why} <- Enum.find(skips, &String.starts_with?(elem(&1, 0), "#{key}.")) do
      {example, why}
    else
      _none -> nil
    end
  end

  defp skipped_pixel(name) do
    with %{"skips" => skips} <- budget() do
      Map.get(skips, name)
    end
  end

  # The examples of this component that are still in `pending`, if any.
  defp pending_pixels(key) do
    with %{"pending" => pending} <- budget(),
         [_ | _] = mine <- Enum.filter(pending, &String.starts_with?(&1, "#{key}.")) do
      Enum.join(mine, ", ")
    else
      _none -> nil
    end
  end

  defp pending_pixel?(name) do
    with %{"pending" => pending} <- budget() do
      name in pending
    else
      _none -> false
    end
  end

  defp pixel_budget(name) do
    with %{"budgets" => budgets} <- budget(),
         pixels when is_integer(pixels) and pixels > 0 <- Map.get(budgets, name) do
      pixels
    end
  end

  defp budget do
    path = Path.join([browser_dir(), "pixel-budget.json"])
    if File.exists?(path), do: read_json!(path)
  end

  defp ported?(key) do
    official_shadcn?(key) or
      parity_dir()
      |> Path.join("#{key}.*.tsx")
      |> Path.wildcard()
      |> Kernel.!=([])
  end

  defp official_shadcn?("ai_elements-" <> _name), do: false

  defp official_shadcn?(key) do
    name = String.replace_prefix(key, "shadcn-", "")

    registry_path("UPSTREAM.json")
    |> read_json!()
    |> get_in(["examples", "shadcn", name])
    |> is_list()
  end

  defp parity_root, do: Path.join(repo_root(), "parity")
  defp parity_dir, do: Path.join([parity_root(), "src", "examples"])

  defp no_example do
    %{
      "pass" => false,
      "detail" => "no example yet: add one to storybook/lib/storybook_web/examples.ex"
    }
  end

  defp previews do
    path = registry_path(["snapshot", "index.json"])
    if File.exists?(path), do: read_json!(path), else: %{}
  end

  defp previewed, do: previews() |> Map.keys()

  defp run_in(dir, command, args, env \\ %{}) do
    env =
      if command == "npx" and "playwright" in args do
        env
        |> managed_browser_environment()
        |> Map.put_new("PARITY_PREPARED", "1")
      else
        env
      end

    case System.cmd(command, args, cd: dir, stderr_to_stdout: true, env: env) do
      {_output, 0} -> %{"pass" => true}
      {output, status} -> %{"pass" => false, "detail" => tail(output), "exit" => status}
    end
  rescue
    error in ErlangError ->
      %{"pass" => false, "detail" => "cannot run `#{command}`: #{Exception.message(error)}"}
  end

  # Enough of the failure to act on, not so much that VERIFY.json stops being
  # reviewable in a diff.
  defp tail(output) do
    output
    |> String.split("\n")
    |> Enum.reject(&(String.trim(&1) == ""))
    |> Enum.take(-12)
    |> Enum.join("\n")
  end

  defp report(results) do
    for {name, result} <- results do
      failed = for {check, %{"pass" => false}} <- result["checks"], do: check

      if result["pass"] do
        Mix.shell().info("  ✓ #{name}")
      else
        Mix.shell().error("  ✗ #{name}: #{Enum.join(failed, ", ")}")

        for check <- failed,
            detail = get_in(result, ["checks", check, "detail"]),
            do: Mix.shell().error(indent(detail))
      end
    end

    failures = for {name, %{"pass" => false}} <- results, do: name

    if failures == [] do
      Mix.shell().info("verified #{map_size(results)} component(s)")
    else
      Mix.raise("not verified: #{Enum.join(failures, ", ")}")
    end
  end

  defp indent(text),
    do: text |> String.split("\n") |> Enum.map_join("\n", &("      " <> &1))

  defp tools_dir, do: Path.join(repo_root(), "tools")
  defp storybook_dir, do: Path.join(repo_root(), "storybook")
  defp browser_dir, do: Path.join([repo_root(), "storybook", "test", "browser"])
end
