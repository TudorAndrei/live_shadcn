defmodule LiveShadcn.Cn do
  @moduledoc """
  Merges Tailwind class strings in the order used by shadcn's `cn` helper.

  A later class removes an earlier class when both set the same CSS property.
  Unknown classes stay in the result. This safe default lets the browser parity
  check report a missing group without deleting a class on a guess.
  """

  @exact %{
    "display" => ~w(block inline-block inline flex inline-flex table inline-table
                    table-cell table-row grid inline-grid contents list-item
                    flow-root hidden),
    "position" => ~w(static fixed absolute relative sticky),
    "user-select" => ~w(select-none select-text select-all select-auto),
    "flex" => ~w(flex-1 flex-auto flex-initial flex-none),
    "flex-direction" => ~w(flex-row flex-row-reverse flex-col flex-col-reverse),
    "flex-wrap" => ~w(flex-wrap flex-wrap-reverse flex-nowrap),
    "white-space" => ~w(whitespace-normal whitespace-nowrap whitespace-pre
                         whitespace-pre-line whitespace-pre-wrap whitespace-break-spaces),
    "text-align" => ~w(text-left text-center text-right text-justify text-start text-end),
    "text-transform" => ~w(uppercase lowercase capitalize normal-case),
    "font-style" => ~w(italic not-italic),
    "box-sizing" => ~w(box-border box-content),
    "isolation" => ~w(isolate isolation-auto),
    "table-layout" => ~w(table-auto table-fixed),
    "border-collapse" => ~w(border-collapse border-separate),
    "object-fit" => ~w(object-contain object-cover object-fill object-none object-scale-down),
    "pointer-events" => ~w(pointer-events-none pointer-events-auto),
    "visibility" => ~w(visible invisible collapse),
    "overflow" =>
      ~w(overflow-auto overflow-hidden overflow-clip overflow-visible overflow-scroll),
    "font-weight" => ~w(font-thin font-extralight font-light font-normal font-medium font-semibold
                         font-bold font-extrabold font-black),
    "outline-style" => ~w(outline-none outline-hidden),
    "flex-grow" => ~w(grow grow-0),
    "flex-shrink" => ~w(shrink shrink-0)
  }

  @prefixes ~w(
    w- h- size- min-w- min-h- max-w- max-h-
    p- px- py- pt- pr- pb- pl- ps- pe-
    m- mx- my- mt- mr- mb- ml- ms- me-
    gap- gap-x- gap-y- space-x- space-y-
    top- right- bottom- left- inset- inset-x- inset-y- start- end-
    basis- grow- shrink- order- z-
    grid-cols- grid-rows- col-span- row-span-
    justify- justify-items- justify-self- items- self-
    place-items- place-content- place-self-
    opacity- leading- tracking- align- aspect- blur-
    bg-
    duration- delay- ease- animate- cursor- resize- appearance-
    overflow-x- overflow-y- float- clear-
  )

  @padding_groups ~w(p- px- py- pt- pr- pb- pl- ps- pe-)

  @doc "Merges a list of class strings."
  def merge(strings) when is_list(strings) do
    strings
    |> Enum.flat_map(&classes/1)
    |> Enum.reduce([], fn class, kept ->
      group = group(class)

      kept
      |> Enum.reject(fn earlier -> group(earlier) in conflicts(group) end)
      |> Kernel.++([class])
    end)
    |> Enum.join(" ")
  end

  def merge(string) when is_binary(string), do: merge([string])

  defp classes(value) when is_binary(value), do: String.split(value)
  defp classes(value) when is_list(value), do: Enum.flat_map(value, &classes/1)
  defp classes(_value), do: []

  defp group(class) do
    {variants, utility} = split_variants(class)
    {variants, utility_group(utility, variants)}
  end

  # Tailwind's composite utilities only remove the dimensions they set. A later
  # `size-*` sets both dimensions, while a later `h-*` keeps an earlier
  # `size-*` for width. Padding follows the same directional rule.
  defp conflicts({variants, "size-"}), do: Enum.map(["size-", "w-", "h-"], &{variants, &1})
  defp conflicts({variants, "p-"}), do: Enum.map(@padding_groups, &{variants, &1})

  # `line-clamp-*` sets overflow as well as display. A later `flex` replaces
  # only its display value, so it must not remove the clamp utility. A later
  # clamp does replace an earlier display utility.
  defp conflicts({variants, "line-clamp"}), do: [{variants, "line-clamp"}, {variants, "display"}]

  defp conflicts({variants, group}), do: [{variants, group}]

  defp utility_group("!" <> utility, variants), do: utility_group(utility, variants)
  defp utility_group("-" <> utility, variants), do: utility_group(utility, variants)
  defp utility_group("line-clamp-" <> _value, _variants), do: "line-clamp"

  defp utility_group(utility, _variants) do
    cond do
      named = Enum.find_value(@exact, fn {name, members} -> utility in members && name end) ->
        named

      utility == "rounded" or String.starts_with?(utility, "rounded-") ->
        "rounded"

      utility == "transition" or String.starts_with?(utility, "transition-") ->
        "transition"

      prefix = longest_prefix(utility) ->
        prefix

      true ->
        utility
    end
  end

  defp longest_prefix(utility) do
    @prefixes
    |> Enum.filter(&String.starts_with?(utility, &1))
    |> Enum.max_by(&String.length/1, fn -> nil end)
  end

  defp split_variants(class) do
    case split_at_last_colon(class, 0, 0, nil) do
      nil -> {"", class}
      at -> {binary_part(class, 0, at), binary_part(class, at + 1, byte_size(class) - at - 1)}
    end
  end

  defp split_at_last_colon(class, at, _depth, last) when at == byte_size(class), do: last

  defp split_at_last_colon(class, at, depth, last) do
    case binary_part(class, at, 1) do
      "[" -> split_at_last_colon(class, at + 1, depth + 1, last)
      "(" -> split_at_last_colon(class, at + 1, depth + 1, last)
      "]" -> split_at_last_colon(class, at + 1, depth - 1, last)
      ")" -> split_at_last_colon(class, at + 1, depth - 1, last)
      ":" when depth == 0 -> split_at_last_colon(class, at + 1, depth, at)
      _other -> split_at_last_colon(class, at + 1, depth, last)
    end
  end
end
