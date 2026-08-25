defmodule Mix.Tasks.Ui.Verify do
  @shortdoc "Check a generated component against its spec, its snapshot, and a browser"

  @moduledoc """
  Stage 4 of the codegen pipeline, and the only stage that can say a component
  is finished.

      mix ui.verify
      mix ui.verify accordion
      mix ui.verify shadcn/message    # one component, said unambiguously
      mix ui.verify --browser false   # skip the browser, for a machine without one

  Five checks, each answering a different question:

  | Check | Question |
  |---|---|
  | generated | does the module on disk still match its spec? |
  | snapshot | has the markup a reader gets changed? |
  | browser | does it behave like Base UI, and is it clean under axe-core? |
  | parity | does it draw what the React it was generated from draws? |
  | pixel | does it *paint* what that React paints? |

  The first two are cheap and run anywhere. The last three start a browser,
  because opening a panel is a client behaviour and so is layout: no amount of
  server-side rendering can tell you whether either works.

  The first three all read the same spec, so none of them can catch a spec that
  read upstream wrongly — a class string the reader dropped is missing from the
  module, from the snapshot, and from the expectation. The last two read upstream
  instead, by rendering it: the fourth compares numbers, and the fifth compares
  what was painted. A textarea showing its placeholder and one showing nothing
  are the same box with the same computed styles, and only the fifth can tell
  them apart.

  The result is written to `registry/VERIFY.json`, keyed by `<source>/<name>`,
  which is what makes `mix ui.status` able to mark a component verified. Status
  is never typed by hand, here least of all.
  """
  use Mix.Task

  import LiveShadcnTools

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    {opts, names, _} = OptionParser.parse(argv, strict: [browser: :boolean])
    browser? = Keyword.get(opts, :browser, true)

    components = if names == [], do: generated(), else: Enum.map(names, &resolve/1)

    if components == [] do
      Mix.raise("nothing to verify: no component has been generated yet. Run `mix ui.gen`.")
    end

    results =
      Map.new(components, fn {source, name} ->
        {ref(source, name), verify(source, name, browser?)}
      end)

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

  defp verify(source, name, browser?) do
    reference = ref(source, name)
    key = example_key(source, name)

    checks =
      [
        {"generated", generated_check(reference)},
        {"snapshot", snapshot_check(key)}
      ] ++
        if browser?,
          do: [
            {"browser", browser_check(name, key)},
            {"parity", parity_check(key)},
            {"pixel", pixel_check(key)}
          ],
          else: []

    %{
      "pass" => Enum.all?(checks, fn {_name, check} -> check["pass"] end),
      "spec" => spec_digest(source, name),
      "checks" => Map.new(checks)
    }
  end

  # The spec digest is recorded with the result, so a passing entry cannot
  # outlive the spec it was true of.
  defp spec_digest(source, name) do
    path = spec_path(source, name)
    if File.exists?(path), do: digest(File.read!(path))
  end

  defp generated_check(reference),
    do: run_in(tools_dir(), "mix", ["ui.gen", "--check", reference])

  defp snapshot_check(nil), do: no_example()

  defp snapshot_check(key),
    do: run_in(storybook_dir(), "mix", ["snapshot", "--check", key])

  # A component with behaviour has a suite of its own. One without still has an
  # accessibility contract, and the generic axe run over its preview pages is
  # what checks it. A component with neither has no example yet, which is a
  # real reason not to call it verified.
  defp browser_check(_name, nil), do: no_example()

  defp browser_check(name, key) do
    if File.exists?(Path.join(browser_dir(), "#{name}.spec.mjs")) do
      run_in(browser_dir(), "npx", ["playwright", "test", "#{name}.spec.mjs"])
    else
      run_in(browser_dir(), "npx", ["playwright", "test", "accessibility.spec.mjs"], %{
        "PREVIEW_COMPONENT" => key
      })
    end
  end

  # The component beside the React it was generated from.
  #
  # The three checks above all ask whether the pipeline was consistent with
  # itself: the module matches the spec, the markup matches the snapshot, the
  # behaviour matches Base UI's contract. None of them can catch a spec that
  # read upstream wrongly, because every one of them reads that same spec. This
  # one reads upstream instead.
  defp parity_check(nil), do: no_example()

  defp parity_check(key) do
    if ported?(key) do
      run_in(browser_dir(), "npx", ["playwright", "test", "parity.spec.mjs"], %{
        "PREVIEW_COMPONENT" => key
      })
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
    cond do
      not ported?(key) ->
        %{
          "pass" => false,
          "detail" =>
            "no React reference yet: add one to parity/src/examples/#{key}.<example>.tsx"
        }

      # A skip is a decision, and the record should say so rather than say
      # "pass". `chart` is the one: its example cannot be compared at all,
      # because upstream puts the caller's children inside recharts'
      # `ResponsiveContainer` and that sizes anything which is not a recharts
      # element to nothing. The reason lives beside the skip, and
      # `pixel.spec.mjs` fails if the example would now pass at zero — so a
      # skip that outlives its reason is caught rather than kept.
      skipped = skipped_pixels(key) ->
        {example, why} = skipped
        %{"pass" => true, "detail" => "#{example} is not compared: #{why}"}

      pending = pending_pixels(key) ->
        # A pending example *passes* the spec — that is what lets the check land
        # without a red build on day one. It must not pass verification.
        #
        # Pending means measured and not yet decided, and a component recorded
        # as verified while one of its examples differs by a known number of
        # pixels is the inventory claiming something nobody established. The
        # suite stays green; the record tells the truth.
        %{
          "pass" => false,
          "detail" => "measured, not yet gated: #{pending}"
        }

      true ->
        run_in(browser_dir(), "npx", ["playwright", "test", "--project", "pixel"], %{
          "PREVIEW_COMPONENT" => key
        })
    end
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

  # The examples of this component that are still in `pending`, if any.
  defp pending_pixels(key) do
    with %{"pending" => pending} <- budget(),
         [_ | _] = mine <- Enum.filter(pending, &String.starts_with?(&1, "#{key}.")) do
      Enum.join(mine, ", ")
    else
      _none -> nil
    end
  end

  defp budget do
    path = Path.join([browser_dir(), "pixel-budget.json"])
    if File.exists?(path), do: read_json!(path)
  end

  defp ported?(key) do
    parity_dir()
    |> Path.join("#{key}.*.tsx")
    |> Path.wildcard()
    |> Kernel.!=([])
  end

  defp parity_dir, do: Path.join([repo_root(), "parity", "src", "examples"])

  defp no_example do
    %{
      "pass" => false,
      "detail" => "no example yet: add one to storybook/lib/storybook_web/examples.ex"
    }
  end

  defp previewed do
    path = registry_path(["snapshot", "index.json"])
    if File.exists?(path), do: Map.keys(read_json!(path)), else: []
  end

  defp run_in(dir, command, args, env \\ %{}) do
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
