defmodule LiveShadcnTools do
  @moduledoc """
  Shared helpers for the maintainer codegen pipeline.

  The pipeline is `ui.fetch -> ui.spec -> ui.gen -> ui.verify`. Every stage is
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

  @doc """
  The two upstream registries a component can come from.
  """
  def sources, do: @sources

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

  @namespaces %{"shadcn" => LiveShadcn.UI, "ai_elements" => LiveAiElements.Components}

  @doc """
  The module namespace a source's components are generated under.

  `mix ui.gen` uses it to name the module it writes, and the generator uses it
  to name a module it calls. Both have to agree, so there is one mapping.

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
  Where `mix ui.gen` writes a component's module.

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
          Mix.raise("no component is called `#{argument}`. It is not in registry/INVENTORY.json.")

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
end
