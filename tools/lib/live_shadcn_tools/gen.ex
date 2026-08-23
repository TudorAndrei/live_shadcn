defmodule LiveShadcnTools.Gen do
  @moduledoc """
  Stage 3 of the pipeline: a spec becomes a HEEx module.

  The generator is deterministic. It reads `registry/spec/<name>.json`, picks
  the recipe the spec names, and writes the module. Running it twice on an
  unchanged spec produces identical bytes, which is what makes `--check` a
  usable CI gate and what makes a diff in generated output mean something.

  No model is involved. A recipe is written once by a person, reviewed, and
  then frozen.
  """

  alias LiveShadcnTools.Gen.Dialog
  alias LiveShadcnTools.Gen.Disclosure
  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Listbox
  alias LiveShadcnTools.Gen.Menu
  alias LiveShadcnTools.Gen.Popover
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tabs

  @recipes %{
    "dialog" => Dialog,
    "disclosure" => Disclosure,
    "form-control" => FormControl,
    "listbox" => Listbox,
    "menu" => Menu,
    "popover" => Popover,
    "presentational" => Presentational,
    "tabs" => Tabs
  }

  @doc "The recipes that have been written."
  def recipes, do: Map.keys(@recipes)

  @doc """
  The formatted module source for a spec.

  `:module` is the module name to generate under.
  """
  def module(spec, opts) do
    recipe = spec["recipe"]
    reachable!(spec)

    case Map.fetch(@recipes, recipe) do
      {:ok, implementation} -> spec |> implementation.module(opts) |> format()
      :error -> {:error, recipe}
    end
  end

  @doc """
  Refuses a component that names a module the host application will not have.

  A component may call another component this pipeline generates, and inside
  one package that works. Across packages it cannot, and the reason is how the
  two packages ship:

    * `live_shadcn` is copied into the application by `mix ui.add`, which
      rewrites `LiveShadcn.UI.Button` to `MyAppWeb.Components.UI.Button`
    * `live_ai_elements` is an ordinary dependency, compiled once, with its
      module names fixed before the application is built

  So a compiled `LiveAiElements.Components.Reasoning` that calls
  `LiveShadcn.UI.Collapsible` names a module that does not exist: `mix ui.add`
  renamed it on the way in, and had no way to reach into a dependency and
  rename the call.

  The reference is real and upstream writes it, so the fix is not to drop it.
  It is to fold the referenced component's markup into this one, the way the
  spec already folds a Base UI part. Until the reader does that, a component
  that needs it is named here rather than generated wrong.
  """
  def reachable!(spec) do
    case Enum.uniq(foreign_refs(spec["parts"], spec["source"])) do
      [] ->
        :ok

      components ->
        raise """
        #{spec["name"]} renders #{Enum.join(components, ", ")}, which #{other(spec["source"])} \
        generates into another package. A dependency cannot name a module that \
        `mix ui.add` renames on the way into an application, so the markup has \
        to be folded in rather than called.
        """
    end
  end

  defp foreign_refs(node, source) when is_list(node),
    do: Enum.flat_map(node, &foreign_refs(&1, source))

  defp foreign_refs(
         %{"type" => "component_ref", "source" => other, "component" => component},
         source
       )
       when other != source,
       do: ["#{other}/#{component}"]

  defp foreign_refs(node, source) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&foreign_refs(&1, source))

  defp foreign_refs(_node, _source), do: []

  defp other("ai_elements"), do: "the shadcn registry"
  defp other(_source), do: "AI Elements"

  @doc "The module name a component is generated under."
  def module_name(namespace, name),
    do: Module.concat(namespace, name |> String.replace("-", "_") |> Macro.camelize())

  # Formatting is part of being deterministic. Two specs that differ only in
  # whitespace have to produce the same module, and a generated file that the
  # project formatter would rewrite is a file somebody will rewrite by hand.
  defp format(source) do
    formatted =
      source
      |> Code.format_string!(
        sigils: [H: &Phoenix.LiveView.HTMLFormatter.format/2],
        # The HEEx formatter reports parse errors against a file name.
        file: "generated.ex",
        line_length: 98
      )
      |> IO.iodata_to_binary()

    {:ok, formatted <> "\n"}
  end
end
