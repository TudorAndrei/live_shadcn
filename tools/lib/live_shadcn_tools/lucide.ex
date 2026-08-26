defmodule LiveShadcnTools.Lucide do
  @moduledoc """
  What each `lucide-react` export actually draws.

  A React source names an icon by its export: `<CheckCircleIcon />`. Kebab-cased
  that reads `check-circle`, and an icon set asked for `check-circle` has
  nothing to give — lucide renamed it to `circle-check-big` and kept the old
  name as an alias. Seven of the forty-four icons this registry uses are such
  aliases, `Loader2Icon` and `MoreHorizontalIcon` among them, so the wrong glyph
  was drawn wherever one appeared.

  lucide publishes the whole table on one line of its type declaration:

      export { CircleCheckBig, CircleCheckBig as CheckCircle,
               CircleCheckBig as CheckCircleIcon, … }

  `mix ui.fetch` downloads that file and this reads it, which is the same rule
  every other fact in this pipeline follows: fetched, not typed.
  """

  @doc """
  `%{export_name => the name it really draws}`, from lucide's `.d.ts`.

  An export that is its own canonical name is in the table too, mapped to
  itself: a caller then never has to ask whether a name was found.
  """
  def aliases(declaration) when is_binary(declaration) do
    declaration
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, "export {"))
    |> exports()
  end

  defp exports(nil), do: %{}

  defp exports(line) do
    line
    |> String.replace_prefix("export {", "")
    |> String.replace_suffix("};", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(&pair/1)
    |> Map.new()
  end

  # `CircleCheckBig as CheckCircleIcon` — the name lucide draws, and a name that
  # reaches it. A bare `CircleCheckBig` is both.
  defp pair(entry) do
    case String.split(entry, " as ") do
      [canonical, alias_name] -> [{alias_name, canonical}]
      [name] -> if name =~ ~r/^[A-Z]\w*$/, do: [{name, name}], else: []
    end
  end
end
