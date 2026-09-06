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
  alias LiveShadcnTools.IncrementalVerification
  alias LiveShadcnTools.PlaywrightReport
  alias LiveShadcnTools.ShadcnExamples
  alias LiveShadcnTools.VerificationPolicy
  alias LiveShadcnTools.VerifierLock
  alias LiveShadcnVerification

  import LiveShadcnTools

  @browser_example_batch_size 2
  @message_scroller_behavior_batch_size 1
  @single_example_browser_kinds ~w(parity pixel)
  @browser_server_stop_timeout 5_000
  @browser_server_stop_poll 50
  @generic_shadcn_behavior_suite "interaction-parity.spec.mjs"
  @suffix_colliding_suites ~w(dialog.spec.mjs input.spec.mjs parity.spec.mjs)
  @message_scroller_behavior_titles [
    "the default transcript uses the pinned composer and completes an assistant reply",
    "anchoring uses the selected role, exact position, reset, and re-add flow",
    "group chat keeps its marker anchor through Rocky's reply and reset",
    "previous context uses the exact margin and peek through its busy, reply, and reset flow",
    "streaming follows the end only until the reader scrolls away",
    "opening position applies the initial last anchor and each exact tab position",
    "loading history preserves the exact visible row position and supports reset",
    "all animation presets run a real user entry and keep assistant rows static",
    "commands render the pinned transcript and jump to each anchored user message",
    "visibility renders the pinned transcript and updates its outline target state",
    "scrollable matches the pinned transcript and reports native scroll state"
  ]
  @managed_browser_servers_env "LIVE_SHADCN_MANAGED_SERVERS"
  @browser_server_ready_timeout 120_000
  @browser_server_request_timeout 1_000

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, names, invalid} =
      OptionParser.parse(argv,
        strict: [browser: :boolean, examples: :string, source: :string, record: :keep]
      )

    valid_options!(invalid)
    records = Keyword.get_values(opts, :record)

    if records != [] do
      record_incremental!(names, opts, records)
    else
      verify_run(names, opts)
    end
  end

  defp valid_options!([]), do: :ok

  defp valid_options!(invalid) do
    options = Enum.map_join(invalid, ", ", fn {option, _value} -> option end)
    Mix.raise("invalid option(s): #{options}")
  end

  defp verify_run(names, opts) do
    browser? = Keyword.get(opts, :browser, true)
    source = source!(Keyword.get(opts, :source))
    components = components_for_verify(names, source)

    if components == [] do
      Mix.raise("nothing to verify: no reviewed component port exists.")
    end

    shadcn_identities =
      Map.new(components, fn
        {"shadcn", name} ->
          {ref("shadcn", name),
           LiveShadcnVerification.evidence_digest("shadcn", name, repo_root())}

        {source, name} ->
          {ref(source, name), verification_evidence_digest(source, name)}
      end)

    example_results =
      Map.new(components, fn {source, name} ->
        {ref(source, name),
         example_checks(
           source,
           name,
           example_key(source, name),
           verification_policy(source, name)
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
              LiveShadcnVerification.verify_pinned_upstream_files!(repo_root())
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

    Enum.each(components, fn {source, name} ->
      reference = ref(source, name)

      LiveShadcnVerification.assert_identity_unchanged!(
        repo_root(),
        source,
        name,
        Map.fetch!(shadcn_identities, reference)
      )
    end)

    write_json!(registry_path("VERIFY.json"), merge(results))
    report(results)
  end

  # Small browser batches are run outside this task to keep their scope and
  # resource use explicit. This import path records one completed JSON report
  # without starting a browser. The record is still gated by the same static
  # checks and evidence digest as a full verification run.
  defp record_incremental!(names, opts, records) do
    source_filter = source!(Keyword.get(opts, :source))

    {source, name} =
      case components_for_verify(names, source_filter) do
        [component] -> component
        [] -> Mix.raise("incremental evidence needs exactly one component name")
        _ -> Mix.raise("incremental evidence records one component at a time")
      end

    {layer, report_path} = parse_record!(records)
    key = example_key(source, name)
    examples = parse_record_examples!(opts, key)
    policy = verification_policy(source, name)

    if policy.kind not in [:standard, :docs_only] do
      Mix.raise("incremental browser evidence is not available for #{ref(source, name)}")
    end

    identity_digest = verification_evidence_digest(source, name)
    identity = incremental_identity(source, name, key)
    results = import_report!(report_path, source, name, layer, key, examples)

    VerifierLock.with_lock(repo_root(), fn _token ->
      path = registry_path("VERIFY.json")
      current = if File.exists?(path), do: read_json!(path), else: %{}
      reference = ref(source, name)
      prior = Map.get(current, reference, %{})

      incremental =
        IncrementalVerification.merge(
          Map.get(prior, "incremental", %{}),
          identity,
          layer,
          results
        )

      browser = IncrementalVerification.aggregate(incremental, identity)

      checks =
        source
        |> incremental_static_checks(name, key, policy)
        |> Map.merge(browser["checks"])

      checks =
        Map.put(checks, "policy", %{
          "pass" => policy_checks_complete?(source, policy, checks),
          "detail" => "required checks for #{policy.kind} policy"
        })

      record = %{
        "pass" => verified_checks?(source, policy, checks),
        "spec" => spec_digest(source, name),
        "evidence" => identity["evidence"],
        "checks" => checks,
        "incremental" => incremental
      }

      LiveShadcnVerification.assert_identity_unchanged!(
        repo_root(),
        source,
        name,
        identity_digest
      )

      current
      |> Map.filter(fn {existing, _record} -> verification_target?(existing) end)
      |> Map.put(reference, record)
      |> then(&write_json_atomic!(path, &1))

      report(%{reference => record})
    end)
  end

  defp parse_record!([record]) do
    case String.split(record, "=", parts: 2) do
      [layer, path] ->
        if layer in IncrementalVerification.layers() and byte_size(path) > 0 do
          {layer, path}
        else
          invalid_record!()
        end

      _ ->
        invalid_record!()
    end
  end

  defp parse_record!(_records),
    do: Mix.raise("import one completed Playwright report at a time")

  defp invalid_record! do
    Mix.raise(
      "--record must be LAYER=PLAYWRIGHT_JSON, where LAYER is #{Enum.join(IncrementalVerification.layers(), ", ")}"
    )
  end

  defp parse_record_examples!(opts, key) when is_binary(key) do
    examples =
      opts
      |> Keyword.get(:examples, "")
      |> String.split(",", trim: true)
      |> Enum.uniq()
      |> Enum.sort()

    current = BrowserVerification.examples(previews(), key) |> Enum.sort()
    unknown = examples -- current

    cond do
      examples == [] ->
        Mix.raise("--examples must name the preview examples in this completed batch")

      unknown != [] ->
        Mix.raise("--examples contains unknown current examples: #{Enum.join(unknown, ", ")}")

      true ->
        examples
    end
  end

  defp parse_record_examples!(_opts, _key),
    do: Mix.raise("incremental evidence needs a Storybook preview")

  defp incremental_identity(source, name, key) do
    %{
      "evidence" => verification_evidence_digest(source, name),
      "examples" => BrowserVerification.examples(previews(), key) |> Enum.sort(),
      "spec" => spec_digest(source, name)
    }
  end

  defp import_report!(report_path, source, name, layer, key, examples) do
    report = report_path |> File.read!() |> Jason.decode!()

    expected = %{
      source: source,
      name: name,
      layer: layer,
      preview_key: key,
      examples: examples,
      identity: verification_evidence_digest(source, name)
    }

    LiveShadcnVerification.Report.validate!(report, expected)
    names = Enum.map(examples, &"#{key}.#{&1}")

    result = PlaywrightReport.incremental_example_results(report, layer, names)
    PlaywrightReport.require_example_coverage!(result, names)

    Enum.into(examples, %{}, fn example ->
      name = "#{key}.#{example}"

      check =
        Map.get(result.components, name, %{
          "pass" => false,
          "detail" => "#{layer} report has no result for #{name}"
        })

      check =
        result.global_failures
        |> Enum.map(&%{"pass" => false, "detail" => "#{layer}: #{&1}"})
        |> then(&BrowserVerification.merge_checks([check | &1]))
        |> maybe_finalize_pixel(layer, name)

      {example, BrowserVerification.label(check, "#{layer} #{name}")}
    end)
  rescue
    error in File.Error ->
      Mix.raise("cannot import #{report_path}: #{Exception.message(error)}")

    error in Jason.DecodeError ->
      Mix.raise("cannot decode #{report_path}: #{Exception.message(error)}")
  end

  defp maybe_finalize_pixel(check, "pixel", name), do: pixel_result(check, name)
  defp maybe_finalize_pixel(check, _layer, _name), do: check

  defp incremental_static_checks(source, name, key, policy) do
    (generated_checks(policy, ref(source, name)) ++
       [{"snapshot", snapshot_check(key)}] ++
       example_checks(source, name, key, policy))
    |> Map.new()
  end

  # A run over one component says nothing about the others, so it replaces its
  # own entries and leaves the rest of the file alone. Writing only what this
  # run proved would demote every component nobody asked about, and demoting a
  # component is what a spec change is for.
  defp merge(results) do
    path = registry_path("VERIFY.json")
    existing = if File.exists?(path), do: read_json!(path), else: %{}

    existing
    |> Map.filter(fn {reference, _result} -> verification_target?(reference) end)
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

  defp verification_target?(reference) do
    generated?(reference) or
      case parse_ref(reference) do
        {"shadcn", name} -> name in docs_only_shadcn_families()
        _ -> false
      end
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
    LiveShadcnTools.verification_targets()
  end

  defp components_for_verify(names, source) do
    components =
      if names == [], do: generated(), else: Enum.map(names, &resolve/1)

    components
    |> Enum.uniq()
    |> Enum.map(fn {component_source, name} = component ->
      if source != nil and source != component_source do
        Mix.raise("#{ref(component_source, name)} does not belong to source #{source}.")
      end

      component
    end)
    |> only_source(source)
  end

  defp only_source(components, nil), do: components
  defp only_source(components, source), do: Enum.filter(components, fn {s, _} -> s == source end)

  defp source!(nil), do: nil

  defp source!(source) when source in ["shadcn", "ai_elements"], do: source

  defp source!(source),
    do: Mix.raise("invalid source #{source}; expected shadcn or ai_elements")

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
    policy = verification_policy(source, name)

    checks =
      if policy.kind == :no_dom do
        no_dom_checks(policy)
      else
        generated_checks(policy, reference) ++
          [{"snapshot", snapshot_check(key)}] ++
          example_checks ++
          browser_checks(%{
            source: source,
            name: name,
            key: key,
            browser?: browser?,
            examples_complete?: examples_complete?,
            official_comparison?: official_comparison?,
            shared_checks: shared_checks,
            policy: policy,
            preparation_failure: preparation_failure
          })
      end

    checks =
      Map.new(checks, fn {name, check} ->
        {name, LiveShadcnVerification.with_check_outcome(check)}
      end)

    checks =
      Map.put(checks, "policy", %{
        "pass" => policy_checks_complete?(source, policy, checks),
        "detail" => "required checks for #{policy.kind} policy",
        "outcome" =>
          if(policy_checks_complete?(source, policy, checks), do: "passed", else: "incomplete")
      })

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

  defp browser_checks(%{browser?: false, preparation_failure: nil}),
    do: browser_not_run_checks()

  defp browser_checks(%{browser?: false, preparation_failure: reason}),
    do: browser_not_run_checks(reason)

  defp browser_checks(%{browser?: true, examples_complete?: false}),
    do: browser_not_run_checks("official example coverage is incomplete")

  defp browser_checks(%{
         source: source,
         name: name,
         key: key,
         browser?: true,
         examples_complete?: true,
         official_comparison?: official_comparison?,
         shared_checks: shared_checks,
         policy: policy
       }) do
    browser_results(source, name, key, shared_checks, policy) ++
      upstream_checks(official_comparison?, source, name, key, shared_checks, policy)
  end

  defp upstream_checks(true, source, name, key, shared_checks, _policy),
    do: upstream_results(source, name, key, shared_checks)

  defp upstream_checks(false, _source, _name, _key, _shared_checks, policy),
    do: not_applicable_upstream_checks(policy)

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

  defp upstream_results(source, name, key, nil),
    do: [{"parity", parity_check(source, name, key)}, {"pixel", pixel_check(source, name, key)}]

  defp upstream_results(source, name, key, shared_checks) do
    parity =
      if key && ported?(key),
        do: shared_check(shared_checks, "parity", key),
        else: parity_check(source, name, key)

    pixel =
      cond do
        is_nil(key) or not ported?(key) -> pixel_check(source, name, key)
        skipped_pixels(key) -> pixel_check(source, name, key)
        pending_pixels(key) -> pixel_check(source, name, key)
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

  # Full verification uses the same two-example batches as a one-component
  # run. Previously it put every preview into one Playwright process, which
  # made a late example time out after an unrelated example had exhausted the
  # browser. Keeping the work in this one Mix task avoids a task per component;
  # each browser command still has one worker by configuration.
  #
  # Each shadcn component runs the common semantic suite and, when present, its
  # component suite. Message Scroller has many independent behaviour contracts,
  # so it runs selected titles in small sequential batches. Accessibility,
  # semantic parity, and pixel parity all enumerate each local official
  # example and use `batched_example_reports/3` below.
  defp batch_browser_checks(components) do
    components
    |> Enum.sort()
    |> Enum.reduce(
      %{"behavior" => %{}, "accessibility" => %{}, "parity" => %{}, "pixel" => %{}},
      fn {source, name}, checks ->
        key = example_key(source, name)
        policy = verification_policy(source, name)

        checks =
          checks
          |> put_in(["behavior", key], behavior_check(source, name, key, policy))
          |> put_in(["accessibility", key], accessibility_check(source, name, key))

        if upstream_comparison_policy?(policy) do
          checks
          |> put_in(["parity", key], parity_check(source, name, key))
          |> put_in(["pixel", key], pixel_check(source, name, key))
        else
          checks
        end
      end
    )
  end

  defp batch_browser_check(source, name, key, kind, args, env, parser, examples) do
    report =
      Path.join(
        System.tmp_dir!(),
        "live-shadcn-#{kind}-#{System.unique_integer([:positive])}.json"
      )

    envelope = browser_report_envelope(source, name, kind, key, examples) |> Jason.encode!()

    playwright_arguments =
      case args do
        ["playwright", "test" | rest] -> rest
        rest -> rest
      end

    verify_script = Path.join(browser_dir(), "verify.mjs")

    try do
      {output, status} =
        System.cmd(
          "node",
          [verify_script | playwright_arguments],
          cd: browser_dir(),
          stderr_to_stdout: true,
          env:
            env
            |> managed_browser_environment()
            |> Map.put("PARITY_PREPARED", "1")
            |> Map.put("PLAYWRIGHT_JSON_OUTPUT_FILE", report)
            |> Map.put("LIVE_SHADCN_VERIFY_ENVELOPE", envelope)
        )

      case File.read(report) do
        {:ok, json} ->
          decoded = Jason.decode!(json)

          LiveShadcnVerification.Report.validate!(decoded, %{
            source: source,
            name: name,
            layer: kind,
            preview_key: key,
            examples: examples,
            identity: verification_evidence_digest(source, name),
            states: []
          })

          result = parser.(decoded)
          names = Enum.map(examples, &"#{key}.#{&1}")
          PlaywrightReport.require_example_coverage!(result, names)

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

  @doc false
  def browser_report_envelope(source, name, layer, preview_key, examples, opts \\ []) do
    LiveShadcnVerification.Report.envelope(
      source,
      name,
      layer,
      preview_key,
      examples,
      verification_evidence_digest(source, name),
      opts
    )
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
        vite_executable!(),
        [vite_entrypoint!()],
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

    os_pid =
      case Port.info(process, :os_pid) do
        {:os_pid, pid} when is_integer(pid) and pid > 0 ->
          pid

        _ ->
          Port.close(process)
          Mix.raise("cannot start #{name} browser server: no operating-system process id")
      end

    server = %{
      name: name,
      process: process,
      os_pid: os_pid,
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

    servers = Enum.map(servers, &attach_browser_server_drain/1)
    Process.delete(:live_shadcn_started_browser_servers)
    servers
  end

  # A Port stops its child when its controlling process stops reading output.
  # Storybook writes normal request logs after readiness, so ownership moves to
  # a small process that discards those logs for the whole verification run.
  defp attach_browser_server_drain(%{process: process} = server) do
    Map.put(server, :drain, drain_browser_port(process))
  end

  @doc false
  def drain_browser_port(port, observer \\ nil) when is_port(port) do
    drain = spawn(fn -> drain_browser_port_output(port, observer) end)
    true = Port.connect(port, drain)
    drain
  end

  defp drain_browser_port_output(port, observer) do
    receive do
      {^port, {:data, output}} ->
        if is_pid(observer), do: send(observer, {:browser_port_output, port, output})
        drain_browser_port_output(port, observer)

      {^port, {:exit_status, status}} ->
        if is_pid(observer), do: send(observer, {:browser_port_exit, port, status})

      {:stop_browser_port_drain, caller} ->
        if Port.info(port) != nil, do: Port.close(port)
        send(caller, {:browser_port_drain_stopped, self()})
    end
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

  @doc false
  def stop_browser_servers(servers) when is_list(servers) do
    Enum.each(Enum.reverse(servers), &stop_browser_server/1)
    Process.delete(:live_shadcn_started_browser_servers)
    :ok
  end

  defp stop_browser_server(%{process: process, os_pid: os_pid} = server) do
    processes = browser_server_process_tree(process, os_pid)
    term_sent? = signal_browser_server_processes(processes, "-TERM")

    if term_sent? and
         not wait_for_browser_server_stop(server, @browser_server_stop_timeout) do
      processes
      |> Kernel.++(browser_server_process_tree(process, os_pid))
      |> Enum.uniq_by(&{&1.pid, &1.identity})
      |> signal_browser_server_processes("-KILL")
    end

    close_browser_server_port(server)
    await_browser_server_stopped!(server)
  end

  defp close_browser_server_port(%{drain: drain, process: process}) when is_pid(drain) do
    stop_browser_port_drain(drain)
    close_browser_server_port(process)
  end

  defp close_browser_server_port(%{process: process}), do: close_browser_server_port(process)

  defp close_browser_server_port(process) when is_port(process) do
    if Port.info(process) != nil do
      Port.close(process)
    end
  end

  # `mix phx.server` starts through `erl_child_setup`. The Port owns that
  # wrapper, but the wrapper owns the Phoenix BEAM process that keeps the
  # listener alive. Capture only the current Port process tree, then stop
  # descendants before their wrapper. This cannot signal another verifier.
  defp browser_server_process_tree(process, os_pid)
       when is_port(process) and is_integer(os_pid) and os_pid > 0 do
    if Port.info(process, :os_pid) == {:os_pid, os_pid} do
      [os_pid | descendant_process_ids(os_pid)]
      |> Enum.flat_map(&capture_process/1)
    else
      []
    end
  end

  defp descendant_process_ids(pid) when is_integer(pid) and pid > 0 do
    pid
    |> child_process_ids()
    |> Enum.flat_map(fn child -> [child | descendant_process_ids(child)] end)
  end

  defp child_process_ids(pid) do
    case System.find_executable("pgrep") do
      nil ->
        []

      executable ->
        case System.cmd(executable, ["-P", Integer.to_string(pid)], stderr_to_stdout: true) do
          {output, 0} ->
            parse_process_ids(output)

          _ ->
            []
        end
    end
  end

  defp parse_process_ids(output) do
    output
    |> String.split()
    |> Enum.flat_map(&parse_process_id/1)
  end

  defp parse_process_id(value) do
    case Integer.parse(value) do
      {pid, ""} when pid > 0 -> [pid]
      _ -> []
    end
  end

  # The KILL retry happens after the graceful timeout. A PID can be reused in
  # that interval, so signal only a process whose start time and command still
  # equal the identity captured from the Port process tree.
  defp capture_process(pid) when is_integer(pid) and pid > 0 do
    case System.find_executable("ps") do
      nil ->
        []

      executable ->
        case System.cmd(
               executable,
               ["-p", Integer.to_string(pid), "-o", "lstart=", "-o", "command="],
               stderr_to_stdout: true
             ) do
          {identity, 0} when identity != "" -> [%{pid: pid, identity: identity}]
          _ -> []
        end
    end
  end

  defp signal_browser_server_processes(processes, signal)
       when is_list(processes) and signal in ["-TERM", "-KILL"] do
    matching_processes =
      processes
      |> Enum.reverse()
      |> Enum.filter(&same_process?/1)

    Enum.each(matching_processes, &signal_process(&1.pid, signal))
    matching_processes != []
  end

  defp same_process?(%{pid: pid, identity: identity}) do
    os_process_alive?(pid) and capture_process(pid) == [%{pid: pid, identity: identity}]
  end

  defp await_browser_server_stopped!(%{name: name, os_pid: os_pid, port: port} = server) do
    if browser_server_stopped?(server) do
      :ok
    else
      Mix.raise("#{name} browser server did not stop (pid #{os_pid}, port #{port})")
    end
  end

  defp wait_for_browser_server_stop(server, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout

    Stream.repeatedly(fn -> browser_server_stopped?(server) end)
    |> Enum.reduce_while(false, fn stopped?, _ ->
      cond do
        stopped? ->
          {:halt, true}

        System.monotonic_time(:millisecond) >= deadline ->
          {:halt, false}

        true ->
          Process.sleep(@browser_server_stop_poll)
          {:cont, false}
      end
    end)
  end

  # `kill -0` is not a safe final lifecycle check. A terminated child can be a
  # zombie briefly, and its former PID can later identify an unrelated process.
  # The Port is the managed child identity. Once it is closed and the service
  # port is free, this verification run no longer owns a running server.
  defp browser_server_stopped?(%{process: process, port: port}) do
    Port.info(process) == nil and browser_server_port_free?(port)
  end

  defp os_process_alive?(pid) when is_integer(pid) and pid > 0 do
    case :os.type() do
      {:unix, _} ->
        case System.cmd("kill", ["-0", Integer.to_string(pid)], stderr_to_stdout: true) do
          {_output, 0} -> true
          _ -> false
        end

      _ ->
        true
    end
  end

  defp signal_process(pid, signal) when is_integer(pid) and pid > 0 do
    if match?({:unix, _}, :os.type()) do
      _ = System.cmd("kill", [signal, Integer.to_string(pid)], stderr_to_stdout: true)
    end

    :ok
  end

  defp browser_server_port_free?(port) when is_integer(port) and port in 1..65_535 do
    browser_port_probe(port) == :free
  end

  defp browser_port_probe(port) when is_integer(port) and port in 1..65_535 do
    case :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 100) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        :occupied

      {:error, :econnrefused} ->
        reserve_browser_port(port)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reserve_browser_port(port) do
    case :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true, ip: {127, 0, 0, 1}]) do
      {:ok, socket} ->
        :ok = :gen_tcp.close(socket)
        :free

      {:error, :eaddrinuse} ->
        :occupied

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def stop_browser_port_drain(drain) when is_pid(drain) do
    monitor = Process.monitor(drain)
    send(drain, {:stop_browser_port_drain, self()})

    receive do
      {:browser_port_drain_stopped, ^drain} ->
        Process.demonitor(monitor, [:flush])

      {:DOWN, ^monitor, :process, ^drain, _reason} ->
        :ok
    after
      1_000 ->
        Process.exit(drain, :kill)

        receive do
          {:DOWN, ^monitor, :process, ^drain, _reason} -> :ok
        after
          1_000 -> :ok
        end
    end

    :ok
  end

  defp port_env(:storybook), do: "STORYBOOK_PORT"
  defp port_env(:parity), do: "PARITY_PORT"
  defp default_port(:storybook), do: 4101
  defp default_port(:parity), do: 4102

  defp vite_executable! do
    System.find_executable("node") ||
      Mix.raise("cannot start parity browser server: `node` is not available")
  end

  defp vite_entrypoint! do
    path = Path.join([parity_root(), "node_modules", "vite", "bin", "vite.js"])

    if File.regular?(path) do
      path
    else
      Mix.raise("cannot start parity browser server: Vite is not installed at #{path}")
    end
  end

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
      case browser_port_probe(port) do
        :free ->
          :ok

        :occupied ->
          Mix.raise(
            "cannot prepare browser sources: #{name} port #{port} is already occupied; " <>
              "stop that server before verification"
          )

        {:error, reason} ->
          Mix.raise(
            "cannot check #{name} port #{port} before browser preparation: " <>
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

  defp generated_checks(%{kind: :docs_only}, _reference), do: []
  defp generated_checks(_policy, reference), do: [{"generated", generated_check(reference)}]

  defp upstream_comparison_policy?(%{kind: kind}) when kind in [:standard, :docs_only], do: true
  defp upstream_comparison_policy?(_policy), do: false

  defp example_checks(source, name, key, policy) do
    case policy do
      %{kind: :local_only} ->
        [{"examples", local_only_examples_check(key, policy)}]

      %{kind: :no_dom, reason: reason} ->
        [{"examples", no_dom_examples_check(reason)}]

      _ ->
        source_example_checks(source, name, key)
    end
  end

  defp source_example_checks("shadcn", name, key), do: [{"examples", examples_check(name, key)}]

  defp source_example_checks("ai_elements", name, key),
    do: [{"examples", ai_examples_check(name, key)}]

  defp source_example_checks(_source, _name, _key), do: []

  defp local_only_examples_check(key, %{local_fixture: fixture, reason: reason}) do
    case BrowserVerification.examples(previews(), key || "") do
      [] ->
        %{
          "pass" => false,
          "official_comparison" => false,
          "detail" => "local-only policy has no HEEx preview: #{reason}"
        }

      examples ->
        if fixture in examples do
          %{
            "pass" => true,
            "official_comparison" => false,
            "detail" => "not applicable: approved local fixture #{key}.#{fixture}; #{reason}"
          }
        else
          %{
            "pass" => false,
            "official_comparison" => false,
            "detail" => "local-only policy fixture #{key}.#{fixture} is not a HEEx preview"
          }
        end
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
    accessibility = accessibility_check(source, name, key)

    [
      {"browser", BrowserVerification.merge_checks([behavior, accessibility])},
      {"behavior", behavior},
      {"accessibility", accessibility}
    ]
  end

  defp behavior_check(_source, _name, nil, _policy), do: no_example()

  defp behavior_check(source, name, key, policy) do
    case behavior_commands(source, name, key, policy) do
      {:commands, commands} ->
        commands
        |> Enum.map(fn arguments ->
          run_in(browser_dir(), "npx", arguments, %{
            "PREVIEW_COMPONENT" => key
          })
          |> BrowserVerification.label("behavior #{key}")
        end)
        |> BrowserVerification.merge_checks()

      {:not_applicable, reason} ->
        %{
          "pass" => true,
          "not_applicable" => true,
          "detail" => "behavior is not applicable: #{reason}"
        }

      :missing ->
        %{
          "pass" => false,
          "detail" => "no mapped behavior suite for #{ref(source, name)}"
        }
    end
  end

  @doc false
  def behavior_commands(source, name, key, policy) do
    case behavior_suites(source, name, key, policy) do
      {:suites, suites} ->
        {:commands, Enum.flat_map(suites, &behavior_batch_arguments(source, name, key, &1))}

      result ->
        result
    end
  end

  @doc false
  def behavior_suites("shadcn", name, _key, policy) do
    case VerificationPolicy.behavior("shadcn", name) do
      {:not_applicable, reason} ->
        {:not_applicable, reason}

      :required ->
        named_suite = "#{name}.spec.mjs"

        cond do
          not upstream_comparison_policy?(policy) ->
            :missing

          not File.exists?(Path.join(browser_dir(), @generic_shadcn_behavior_suite)) ->
            :missing

          File.exists?(Path.join(browser_dir(), named_suite)) ->
            {:suites, [@generic_shadcn_behavior_suite, named_suite]}

          true ->
            {:suites, [@generic_shadcn_behavior_suite]}
        end
    end
  end

  def behavior_suites(source, name, key, policy) do
    case behavior_suite(source, name, key, policy) do
      {:suite, suite} -> {:suites, [suite]}
      result -> result
    end
  end

  @doc false
  def behavior_suite("ai_elements", _name, key, _policy) do
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

  def behavior_suite(source, name, _key, policy) do
    case VerificationPolicy.behavior(source, name) do
      {:not_applicable, reason} ->
        {:not_applicable, reason}

      :required ->
        suite = "#{name}.spec.mjs"

        cond do
          not upstream_comparison_policy?(policy) ->
            :missing

          File.exists?(Path.join(browser_dir(), suite)) ->
            {:suite, suite}

          true ->
            :missing
        end
    end
  end

  @doc false
  def behavior_batch_arguments("shadcn", _name, key, @generic_shadcn_behavior_suite) do
    key
    |> official_example_names()
    |> Enum.map(&"#{key} / #{&1} keeps inferred interaction semantics")
    |> BrowserVerification.batches(@browser_example_batch_size)
    |> Enum.map(fn titles ->
      [
        "playwright",
        "test",
        @generic_shadcn_behavior_suite,
        "--workers",
        "1",
        "--grep",
        behavior_title_pattern(titles)
      ]
    end)
  end

  def behavior_batch_arguments("shadcn", "message-scroller", _key, suite)
      when is_binary(suite) do
    @message_scroller_behavior_titles
    |> BrowserVerification.batches(@message_scroller_behavior_batch_size)
    |> Enum.map(fn titles ->
      [
        "playwright",
        "test",
        exact_spec_path_filter(suite),
        "--workers",
        "1",
        "--grep",
        behavior_title_pattern(titles)
      ]
    end)
  end

  def behavior_batch_arguments(_source, _name, _key, suite) when is_binary(suite),
    do: [["playwright", "test", exact_spec_path_filter(suite), "--workers", "1"]]

  @doc false
  def behavior_batch_arguments(source, name, suite),
    do: behavior_batch_arguments(source, name, name, suite)

  defp behavior_title_pattern(titles) do
    titles
    |> Enum.map_join("|", &Regex.escape/1)
    # Playwright matches against the complete title path, which includes the
    # project and spec-file titles before the test title. Keep the end anchor
    # to select the exact examples, but do not require the test title to start
    # the complete path.
    |> then(&"(?:#{&1})$")
  end

  defp exact_spec_path_filter(suite) when suite in @suffix_colliding_suites,
    do: "(?:^|/)#{Regex.escape(suite)}$"

  defp exact_spec_path_filter(suite), do: suite

  defp official_example_names(key) do
    prefix = key <> "."

    parity_root()
    |> Path.join("official-examples.json")
    |> read_json!()
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, prefix))
    |> Enum.map(&String.replace_prefix(&1, prefix, ""))
    |> Enum.sort()
  end

  defp accessibility_check(_source, _name, nil), do: no_example()

  defp accessibility_check(source, name, key) do
    batched_example_check(source, name, key, "accessibility", [
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
  defp parity_check(_source, _name, nil), do: no_example()

  defp parity_check(source, name, key) do
    if ported?(key) do
      batched_example_check(source, name, key, "parity", parity_batch_arguments())
    else
      %{
        "pass" => false,
        "detail" => "no React reference yet: add one to parity/src/examples/#{key}.<example>.tsx"
      }
    end
  end

  @doc false
  def parity_batch_arguments do
    [
      "playwright",
      "test",
      exact_spec_path_filter("parity.spec.mjs"),
      "--grep",
      "draws what React draws"
    ]
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
  defp pixel_check(_source, _name, nil), do: no_example()

  defp pixel_check(source, name, key) do
    if ported?(key) do
      batched_pixel_check(source, name, key)
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

  defp batched_example_check(source, name, key, kind, args) do
    {report, expected} = batched_example_reports(source, name, key, kind, args)

    report_example_checks(report, expected, kind)
  end

  defp batched_pixel_check(source, name, key) do
    batched_pixel_result(source, name, key).components[key]
  end

  defp batched_pixel_result(source, name, key) do
    {report, _expected} =
      batched_example_reports(source, name, key, "pixel", [
        "playwright",
        "test",
        "--project",
        "pixel"
      ])

    %{
      components: %{
        key => report_example_checks(report, expected_examples(key), "pixel", &pixel_result/2)
      },
      global_failures: report.global_failures
    }
  end

  defp batched_example_reports(source, name, key, kind, args) do
    expected = expected_examples(key)

    reports =
      key
      |> example_batches(kind)
      |> Enum.map(fn batch ->
        names = Enum.map(batch, &"#{key}.#{&1}")

        batch_browser_check(
          source,
          name,
          key,
          kind,
          args,
          %{
            "PREVIEW_COMPONENT" => key,
            "PREVIEW_EXAMPLES" => Enum.join(batch, ",")
          },
          fn json -> PlaywrightReport.example_results(json, names) end,
          batch
        )
      end)

    {BrowserVerification.merge_reports(reports), expected}
  end

  defp example_batches(key, kind) do
    example_batches(key, kind, BrowserVerification.examples(previews(), key))
  end

  @doc false
  def example_batches(key, kind, examples)
      when is_binary(key) and is_binary(kind) and is_list(examples) do
    examples
    |> BrowserVerification.batches(browser_example_batch_size(key, kind))
  end

  defp browser_example_batch_size(_key, kind) when kind in @single_example_browser_kinds, do: 1
  defp browser_example_batch_size(_key, _kind), do: @browser_example_batch_size

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
    case budget() do
      %{"pending" => pending} -> name in pending
      _ -> false
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
