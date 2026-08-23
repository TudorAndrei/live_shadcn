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

    case Map.fetch(@recipes, recipe) do
      {:ok, implementation} -> spec |> implementation.module(opts) |> format()
      :error -> {:error, recipe}
    end
  end

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
