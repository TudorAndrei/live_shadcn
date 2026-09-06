defmodule LiveShadcnTools do
  @moduledoc """
  Shared helpers for the maintainer synchronization pipeline.

  The pipeline is `ui.fetch -> ui.spec -> ui.verify`. Every stage is
  deterministic and reads only from `registry/`, so a rerun on the same pinned
  upstream commit must produce a byte-identical result.
  """

  @doc "Absolute path of the monorepo root, found by walking up from the cwd."
  def repo_root do
    File.cwd!()
    |> Path.expand()
    |> walk_up()
    |> case do
      nil ->
        Mix.raise("cannot find repo root: no parent directory holds both registry/ and packages/")

      root ->
        root
    end
  end

  defp walk_up("/"), do: nil

  defp walk_up(dir) do
    if File.dir?(Path.join(dir, "registry")) and File.dir?(Path.join(dir, "packages")) do
      dir
    else
      walk_up(Path.dirname(dir))
    end
  end

  def registry_path(parts), do: Path.join([repo_root(), "registry" | List.wrap(parts)])

  @sources ~w(shadcn ai_elements)
  @docs_only_required_checks ~w(snapshot examples browser behavior accessibility parity pixel)

  alias LiveShadcnTools.VerificationPolicy

  @doc """
  The two upstream registries a component can come from.
  """
  def sources, do: @sources

  @doc "Official shadcn documentation families with examples but no registry primitive."
  def docs_only_shadcn_families(root \\ repo_root()) do
    manifest = root |> registry_path("UPSTREAM.json") |> read_json!()

    primitives =
      manifest
      |> Map.get("files", %{})
      |> Map.keys()
      |> Enum.filter(&(String.starts_with?(&1, "shadcn/ui/") and String.ends_with?(&1, ".tsx")))
      |> MapSet.new(fn path -> path |> Path.basename(".tsx") end)

    manifest
    |> get_in(["examples", "shadcn"])
    |> Kernel.||(%{})
    |> Enum.filter(fn {name, examples} ->
      is_list(examples) and examples != [] and name not in primitives
    end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @doc "Returns the effective verification policy for a primitive or docs-only family."
  def verification_policy(source, name), do: verification_policy(source, name, repo_root())

  def verification_policy("shadcn", name, root) do
    policy = VerificationPolicy.get("shadcn", name)

    if name in docs_only_shadcn_families(root) do
      %{policy | kind: :docs_only, required_checks: @docs_only_required_checks}
    else
      policy
    end
  end

  def verification_policy(source, name, _root), do: VerificationPolicy.get(source, name)

  @doc """
  A component's identity is its source and its name, never its name alone.

  Upstream has two components called `message`, one in the shadcn registry and
  one in AI Elements. They have different anatomies. Keying a file on the name
  alone collapses them: the one written second takes the file, and every later
  stage reports its status for both.

  The reference is what a stage writes into a path or a JSON key:

      iex> LiveShadcnTools.ref("shadcn", "message")
      "shadcn/message"

  """
  def ref(source, name) when source in @sources, do: source <> "/" <> name

  # A recipe that writes one function for the whole component, because its parts
  # have to agree about one id and an id repeated is an id to mistype.
  @folding ~w(dialog disclosure listbox menu popover tabs)

  @doc "The recipes that fold every part of a component into one function."
  def folding_recipes, do: @folding

  # Which recipe carries which other recipe's behaviour. A component whose own
  # recipe is here folds that component's markup *and* the recipe writes the
  # ids, the commands and the attributes over it: `task` is a collapsible, and
  # `mic-selector` is a listbox drawn inside a popover.
  @carries %{
    "dialog" => ~w(dialog),
    "disclosure" => ~w(disclosure),
    "listbox" => ~w(listbox popover),
    "menu" => ~w(menu popover),
    "navigation-menu" => ~w(navigation-menu popover menu),
    "popover" => ~w(popover),
    "tabs" => ~w(tabs)
  }

  @doc """
  Whether a component built by `recipe` can carry a component built by `folded`.

  A component that renders a behaving one has to *be* it: the fold copies the
  markup, and only the recipe writes the behaviour over that markup. So a
  presentational component that renders a popover has nobody to write the
  trigger's id, and folding the markup in would give it a popup that never
  opens. It is the caller who composes the real one — the same answer `menubar`
  already gives for a wrapper around a menu.
  """
  def carries?(recipe, folded),
    do: folded not in @folding or folded in Map.get(@carries, recipe, [])

  # What a call needs at each end. The component called writes one function per
  # part and carries no behaviour of its own; the component calling writes one
  # function per part too, because a recipe that folds a component into one
  # function builds its own tree and has no call site to put this at.
  #
  # `form-control` and `switch` are the near misses: both write one function per
  # part, and both attach behaviour to it. Called, shadcn's switch brings its
  # hidden checkbox and its own `phx-click` — over the one
  # `environment-variables` writes to toggle a secret — and shadcn's input
  # brings the validity attributes a field owns. Their markup folds in and the
  # AI Element keeps the behaviour it wrote.
  @callable ~w(presentational separator progress)
  @calling ~w(presentational clipboard form-control file-tree shimmer)

  @doc """
  Whether a component calls another rather than folding its markup in.

  `live_ai_elements` depends on `live_shadcn`, so an AI Element that renders
  shadcn's `<Button>` calls `LiveShadcn.UI.Button.button/1`. A `live_shadcn`
  component folds instead: `mix ui.add` copies it into an application's own
  namespace, where a call would name a module that is not there.
  """
  def callable?("ai_elements", own, called), do: own in @calling and called in @callable
  def callable?(_source, _own, _called), do: false

  @namespaces %{"shadcn" => LiveShadcn.UI, "ai_elements" => LiveAiElements.Components}

  @doc """
  The module namespace for a source's component ports.

  The migration tool uses it to name a module it writes and to name a module it
  calls. Both uses must agree, so there is one mapping.

      iex> LiveShadcnTools.namespace("shadcn")
      LiveShadcn.UI

  """
  def namespace(source) when source in @sources, do: Map.fetch!(@namespaces, source)

  @doc "Splits a reference back into its source and its name."
  def parse_ref(reference) do
    case String.split(reference, "/", parts: 2) do
      [source, name] when source in @sources and name != "" ->
        {source, name}

      _ ->
        Mix.raise("""
        `#{reference}` is not a component reference.

        A reference is `<source>/<name>`, and source is one of: #{Enum.join(@sources, ", ")}.
        """)
    end
  end

  @doc "Where `mix ui.spec` writes a component, and every later stage reads it."
  def spec_path(source, name) when source in @sources,
    do: registry_path(["spec", source, "#{name}.json"])

  @doc """
  Where a reviewed component module is stored.

  The two packages ship differently, and the paths say so. `live_shadcn` is
  copied into the host application by `mix ui.add`, so its modules are source
  under `priv/`. `live_ai_elements` is an ordinary dependency, so its modules
  are compiled under `lib/`.
  """
  def module_path("shadcn", name),
    do: Path.join([repo_root(), "packages", "live_shadcn", "priv", "registry", module_file(name)])

  def module_path("ai_elements", name),
    do:
      Path.join([
        repo_root(),
        "packages",
        "live_ai_elements",
        "lib",
        "live_ai_elements",
        "components",
        module_file(name)
      ])

  defp module_file(name), do: String.replace(name, "-", "_") <> ".ex"

  @doc "Every component a person has triaged, as `{source, name}` pairs."
  def inventory do
    registry_path("INVENTORY.json")
    |> read_json!()
    |> Map.fetch!("components")
    |> Enum.map(&{&1["source"], &1["name"]})
  end

  @doc """
  Turns a name typed on the command line into a `{source, name}` pair.

  A bare name is accepted while it names exactly one component. `message` names
  two, so it is refused rather than guessed at, and the message says what to
  type instead.
  """
  def resolve(argument) do
    if String.contains?(argument, "/") do
      parse_ref(argument)
    else
      case Enum.filter(inventory(), fn {_source, name} -> name == argument end) do
        [pair] ->
          pair

        [] ->
          if argument in docs_only_shadcn_families() do
            {"shadcn", argument}
          else
            Mix.raise(
              "no component is called `#{argument}`. It is not in registry/INVENTORY.json."
            )
          end

        many ->
          Mix.raise("""
          `#{argument}` names #{length(many)} components, one per upstream registry.

          Say which: #{Enum.map_join(many, ", ", fn {source, name} -> ref(source, name) end)}
          """)
      end
    end
  end

  @doc """
  The assign a prop is read by, from the name upstream gave it.

  A leading underscore comes off. `slider` resolves its list of values from
  three places and calls the result `_values`, because the mark is how
  JavaScript says "this name is mine". It says nothing about the value, and a
  caller asked for `_values` would reasonably wonder what it had done wrong.
  """
  def assign(name), do: name |> Macro.underscore() |> String.trim_leading("_")

  @unresolved_reason "the generated port does not contain this source literal"

  @doc "Official source facts that the reviewed port still does not implement."
  def unresolved_facts(contract) when is_map(contract) do
    contract
    |> Map.get("ignored", %{})
    |> Enum.filter(fn {_fact, reason} -> reason == @unresolved_reason end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @doc "Whether a contract accounts for all official source facts."
  def reviewed_contract?(contract), do: unresolved_facts(contract) == []

  @doc "The checks a current verification record must contain for this policy."
  def required_verification_checks(_source, %{required_checks: checks}) when is_list(checks),
    do: checks

  def required_verification_checks(_source, %{kind: :standard}),
    do: ~w(generated snapshot examples browser behavior accessibility parity pixel)

  def required_verification_checks(_source, _policy), do: []

  @doc "Whether all checks required by a policy are current and successful."
  def policy_checks_complete?(source, policy, checks) when is_map(checks) do
    Enum.all?(required_verification_checks(source, policy), fn name ->
      case Map.get(checks, name) do
        %{"pass" => true, "gated" => false} when policy.kind in [:standard, :docs_only] -> false
        %{"pass" => true} -> true
        _ -> false
      end
    end)
  end

  def policy_checks_complete?(_source, _policy, _checks), do: false

  @doc "Whether a verification record has an explicit current failure."
  def verification_failed?(%{"pass" => false}, _current?), do: true

  def verification_failed?(%{"checks" => checks}, true) when is_map(checks) do
    Enum.any?(checks, fn
      {_name, %{"pass" => false}} -> true
      _check -> false
    end)
  end

  def verification_failed?(_result, _current?), do: false

  @doc "Whether the current check schema proves a standard component verified."
  def verified_checks?(source, policy, checks) when is_map(checks) do
    policy.kind in [:standard, :docs_only] and policy_checks_complete?(source, policy, checks)
  end

  def verified_checks?(_source, _policy, _checks), do: false

  @doc "Digest of the pinned upstream source, rendered output, and verification rules."
  def verification_evidence_digest(source, name),
    do: verification_evidence_digest(source, name, repo_root())

  @doc false
  def verification_evidence_digest(source, name, root) do
    snapshot_index = root |> registry_path(["snapshot", "index.json"]) |> read_json!()
    previews = Map.keys(snapshot_index)

    key =
      cond do
        "#{source}-#{name}" in previews -> "#{source}-#{name}"
        name in previews -> name
        true -> name
      end

    local_examples = Map.get(snapshot_index, key, [])

    snapshots =
      local_examples
      |> Enum.map(fn example ->
        path = Path.join([root, "registry", "snapshot", "#{key}-#{example}.html"])

        {Path.relative_to(path, root),
         if(File.regular?(path), do: File.read!(path), else: :missing)}
      end)
      |> Enum.sort_by(&elem(&1, 0))

    fixtures =
      root
      |> Path.join("parity/src/examples/#{key}.*.tsx")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(&{Path.basename(&1), File.read!(&1)})

    manifest = root |> registry_path("UPSTREAM.json") |> read_json!()
    documented = get_in(manifest, ["examples", source, name]) || []
    upstream_ref = get_in(manifest, ["sources", source, "ref"])

    evidence_inputs =
      case source do
        "ai_elements" ->
          {local_examples, manifest, pinned_ai_sources(root)}

        _other ->
          official_path = Path.join(root, "parity/official-examples.json")

          official =
            if File.exists?(official_path) do
              official_path
              |> read_json!()
              |> Enum.filter(fn {example, _path} -> String.starts_with?(example, key <> ".") end)
              |> Enum.sort()
            else
              []
            end

          official
      end

    storybook_renderers =
      evidence_files(root, [
        "storybook/lib/storybook_web/examples.ex",
        "storybook/lib/mix/tasks/snapshot.ex",
        "storybook/lib/storybook_web/live/preview_live.ex"
      ])

    verification_rules =
      [
        "tools/lib/mix/tasks/ui.verify.ex",
        "tools/lib/live_shadcn_tools.ex",
        "tools/lib/live_shadcn_tools/browser_verification.ex",
        "tools/lib/live_shadcn_tools/incremental_verification.ex",
        "tools/lib/live_shadcn_tools/playwright_report.ex",
        "tools/lib/live_shadcn_tools/ai_elements_examples.ex",
        "tools/lib/live_shadcn_tools/shadcn_examples.ex",
        "tools/lib/live_shadcn_tools/verification_policy.ex",
        "registry/VERIFICATION_POLICY.json",
        "storybook/test/browser/*.mjs",
        "storybook/test/browser/ai-component-audit.json",
        "storybook/test/browser/parity-divergence.json",
        "storybook/test/browser/pixel-budget.json",
        "storybook/test/browser/package-lock.json",
        "parity/package-lock.json",
        "parity/src/main.tsx",
        "parity/src/official-ai-elements.mjs",
        "parity/src/official-shadcn.mjs",
        "parity/source-lease.mjs",
        "parity/upstream.mjs",
        "parity/vite.config.mjs"
      ]
      |> Enum.flat_map(fn pattern -> Path.wildcard(Path.join(root, pattern)) end)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})

    digest(
      :erlang.term_to_binary({
        upstream_ref,
        documented,
        fixtures,
        snapshots,
        evidence_inputs,
        storybook_renderers,
        verification_rules
      })
    )
  end

  defp registry_path(root, parts), do: Path.join([root, "registry" | List.wrap(parts)])

  defp evidence_files(root, paths) do
    paths
    |> Enum.map(&Path.join(root, &1))
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  defp pinned_ai_sources(root) do
    ["registry/upstream/ai_elements/*.tsx", "registry/upstream/ai_examples/*.tsx"]
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, root), File.read!(&1)})
  end

  @doc "SHA-256 of a binary, hex encoded. Used to detect upstream drift."
  def digest(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  def write!(path, content) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end

  def read_json!(path), do: path |> File.read!() |> Jason.decode!()

  def write_json!(path, term) do
    write!(
      path,
      Jason.encode_to_iodata!(term, pretty: true) |> IO.iodata_to_binary() |> Kernel.<>("\n")
    )
  end

  @doc "Writes JSON by an atomic same-directory rename."
  def write_json_atomic!(path, term) do
    File.mkdir_p!(Path.dirname(path))

    temporary =
      Path.join(
        Path.dirname(path),
        ".#{Path.basename(path)}.#{System.unique_integer([:positive])}.tmp"
      )

    content =
      Jason.encode_to_iodata!(term, pretty: true) |> IO.iodata_to_binary() |> Kernel.<>("\n")

    try do
      File.write!(temporary, content)
      File.rename!(temporary, path)
    after
      File.rm(temporary)
    end

    path
  end
end
