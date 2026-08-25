defmodule LiveShadcnTools.TwMerge do
  @moduledoc """
  Joins class strings the way `cn()` does.

  `cn` is `twMerge(clsx(…))`, and `twMerge` is not a join. Where two of its
  arguments set the same thing, the later one wins and the earlier one is
  *removed*:

      cn(buttonVariants({ variant: "ghost", size: "icon" }), "… flex …")

  The button's base carries `inline-flex`; the calendar's day button asks for
  `flex`. React renders one of them. Joining both renders whichever Tailwind
  emitted later in the sheet — `inline-flex`, as it happens — so a reader that
  joins produces a class string that draws a different box from the one
  upstream draws, and says nothing.

  ## What it knows, and what it does with what it does not

  A class belongs to a **group**, and a group is a thing an element can only
  have one of. `flex`, `inline-flex` and `hidden` are all `display`. Two classes
  in one group conflict, and the last one stated wins.

  A class this module does not recognise is its own group, so it conflicts only
  with an exact copy of itself. That is deliberate, and it is the safe
  direction: the pipeline joined everything before this module existed, so
  keeping an unrecognised class is what already happened. What must never occur
  is dropping a class on a guess — `text-sm` and `text-muted-foreground` are one
  prefix and two groups, and a table that guessed at `text-` would silently
  delete a colour.

  A missed merge is not silent for long. `parity.spec.mjs` compares the computed
  styles of both renderings and `pixel.spec.mjs` gates the picture at zero
  differing pixels, so a class that should have been dropped and was not arrives
  as a failure that names the element.

  ## Variants

  `disabled:opacity-50` and `opacity-50` do not conflict: one applies in a state
  the other does not. So the variant prefixes are part of the group.
  """

  # Groups whose members are a fixed, unambiguous list. Every one of these is a
  # property an element has exactly one of.
  @exact %{
    "display" => ~w(block inline-block inline flex inline-flex table inline-table
                    table-cell table-row grid inline-grid contents list-item
                    flow-root hidden),
    "position" => ~w(static fixed absolute relative sticky),
    "user-select" => ~w(select-none select-text select-all select-auto),
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

  # Groups written as a prefix and a value. Each is listed because *every* class
  # with that prefix belongs to the one group.
  #
  # `text-`, `border-`, `font-`, `shadow-` and `ring-` are deliberately absent.
  # Each is one prefix over two groups — `text-sm` is a size and
  # `text-muted-foreground` is a colour — and a table that guessed would delete
  # one of them. They fall through to "its own group", which keeps both, which
  # is what this pipeline did before this module existed.
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
    duration- delay- ease- animate- cursor- resize- appearance-
    overflow-x- overflow-y- float- clear-
  )

  @doc """
  Joins class strings as `cn()` would.

  Takes the strings in the order upstream passes them and returns one class
  string, with every class an assignment later in the list overrides removed.
  """
  def merge(strings) when is_list(strings) do
    strings
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.flat_map(&String.split/1)
    |> Enum.reverse()
    # Last one stated wins, so walking backwards keeps the first one seen.
    |> Enum.reduce({[], MapSet.new()}, fn class, {kept, groups} ->
      group = group(class)

      if MapSet.member?(groups, group),
        do: {kept, groups},
        else: {[class | kept], MapSet.put(groups, group)}
    end)
    |> elem(0)
    |> Enum.join(" ")
  end

  def merge(string) when is_binary(string), do: merge([string])

  @doc """
  The group a class belongs to: two classes in one group cannot both apply.

  A class the table does not recognise is its own group, so it conflicts with
  nothing but an exact copy of itself.
  """
  def group(class) do
    {variants, utility} = split_variants(class)

    {variants, utility_group(utility)}
  end

  # `!` is `!important` and does not change what a utility sets. `-mt-2` is the
  # same group as `mt-2`.
  defp utility_group("!" <> utility), do: utility_group(utility)
  defp utility_group("-" <> utility), do: utility_group(utility)

  defp utility_group(utility) do
    cond do
      named = Enum.find_value(@exact, fn {name, members} -> utility in members && name end) ->
        named

      prefix = longest_prefix(utility) ->
        prefix

      true ->
        utility
    end
  end

  # The longest match, because `min-w-4` is `min-w-` and not `w-` inside it.
  defp longest_prefix(utility) do
    @prefixes
    |> Enum.filter(&String.starts_with?(utility, &1))
    |> Enum.max_by(&String.length/1, fn -> nil end)
  end

  # Everything before the last unbracketed colon. `[&_svg]:shrink-0` and
  # `shrink-0` are different questions, and an arbitrary variant can hold a
  # colon of its own inside its brackets.
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
