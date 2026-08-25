defmodule LiveShadcnTools.Gen.Decorate do
  @moduledoc """
  What a folded component's own recipe writes, written over the fold.

  A fold copies markup. A recipe adds what markup alone cannot say — an
  attribute a class string reads, an id a hook is found by, a command that runs
  on the client — and none of that travels with the copy. So a component built
  out of a behaving one loses exactly the part that made it behave.

  There are three answers in this pipeline, and this module is the smallest of
  them:

    * a recipe that folds a whole component into one function cannot be applied
      to a piece of somebody else's tree, so the part is dropped and the caller
      composes the real component — `LiveShadcnTools.carries?/2` decides that
    * a recipe whose whole contribution is **attributes on a named slot** is
      applied here, over the folded markup
    * anything else is a gap, and the component that folds it says so rather
      than generating a copy that looks right and does nothing

  ## Why this is a list of one

  `separator` renames one attribute: Base UI writes `data-orientation`, a
  `<div orientation="horizontal">` is styled by nothing, and that is how
  `checkpoint` came to draw a separator zero pixels wide. Nothing in that
  depends on who folded it.

  `switch` is the nearest thing to a second entry and is deliberately not here.
  What it writes reads an assign — `flag(@checked)` — and a host has no such
  assign: `environment-variables` calls it `show_values`, the server owns it,
  and flipping it pushes an event because the value it reveals is a secret. A
  recipe that names an assign, an id, a hook or an event needs the host to say
  what those are, and that is the host recipe's decision to write down rather
  than a transformation to apply blind.

  So the rule for adding one: a decoration is what is true of the component
  **wherever it is drawn**. If it needs to know anything about where, it is not
  one.
  """

  alias LiveShadcnTools.Gen.Separator

  @decorating %{"separator" => Separator}

  @doc "The recipes whose contribution a fold can carry."
  def recipes, do: Map.keys(@decorating)

  @doc """
  Applies the recipe of every component this spec folded.

  `resolve` is `fn source, name -> spec | nil end`, the same one the generator
  reads a folded component's anatomy with. A fold that resolves to nothing is
  left alone: `mix ui.gen` reports it rather than guessing.
  """
  def folded(spec, resolve) do
    for reference <- spec["folds"] || [], reduce: spec do
      spec -> decorate(spec, recipe_of(reference, resolve))
    end
  end

  defp decorate(spec, recipe) do
    case Map.get(@decorating, recipe) do
      nil -> spec
      module -> module.decorate(spec)
    end
  end

  defp recipe_of(reference, resolve) when is_function(resolve, 2) do
    [source, name] = String.split(reference, "/", parts: 2)

    case resolve.(source, name) do
      %{"recipe" => recipe} -> recipe
      _unresolved -> nil
    end
  end

  defp recipe_of(_reference, _resolve), do: nil
end
