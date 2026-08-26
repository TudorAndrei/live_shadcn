defmodule LiveShadcnTools.Gen.Shimmer do
  @moduledoc """
  The `shimmer` recipe: one element, and a gradient that travels across it.

  ## What the recipe does, and why there is one at all

  `shimmer` is a paragraph with a class string, which is the presentational
  recipe's whole job. What it also has is three props that belong to `motion`
  rather than to HTML — `initial`, `animate` and `transition` — and a `<p>` has
  no such attributes. Written out they would be three invented attributes; left
  out, the component would not shimmer.

  So the recipe reads them, and hands what they say to `LiveBase.Shimmer`, which
  runs the same two keyframes through the same Web Animations API that `motion`
  runs them through.

  ## Why the animation is not a class string

  It could be a `@keyframes` rule and a Tailwind `animate-[…]` utility. It is
  not, because a `@keyframes` rule is a style rule, and no style rule in this
  project is typed by a person: every class string here was fetched. The two
  positions are upstream's and they are in the markup, which is the same
  arrangement every other client-owned fact in this pipeline has.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational

  # motion's own props, and the only three. Each is read and then dropped: an
  # `<p initial="…">` is an attribute nothing defines.
  @motion ~w(initial animate transition)

  @doc "The module source for one component."
  def module(spec, opts) do
    part = shimmering!(spec)
    keyframes = keyframes(part)

    spec
    |> Map.update!("parts", fn parts ->
      Enum.map(parts, fn one ->
        if one["name"] == part["name"],
          do: animated(one, attributes(keyframes)),
          else: one
      end)
    end)
    |> Presentational.module(Keyword.put(opts, :declare, %{part["name"] => declarations()}))
  end

  # On the node itself, because a `<p>` is documented by no Base UI page and so
  # is keyed by nothing: `:attrs` in the context reaches a primitive, and this
  # element is not one. `Heex.with_attrs/2` is the seam for exactly that, and
  # shadcn's sidebar reaches for it for the same reason.
  defp animated(part, attributes) do
    Map.update!(part, "tree", fn tree ->
      tree |> without_motion() |> Heex.with_attrs(attributes)
    end)
  end

  defp shimmering!(spec) do
    case Enum.filter(spec["parts"], &motion?(&1["tree"])) do
      [part] ->
        part

      parts ->
        raise """
        #{spec["name"]} has #{length(parts)} parts that animate, and the shimmer \
        recipe writes one element. Either the component is not this shape, or the \
        recipe has to say which of them the hook belongs on.
        """
    end
  end

  defp motion?(%{"attrs" => attrs}) when is_list(attrs),
    do: Enum.any?(attrs, &(&1["name"] in @motion))

  defp motion?(_tree), do: false

  # `initial={{ backgroundPosition: "100% center" }}` and its partner. Read as
  # text, because what they hold is two strings the browser is handed unchanged
  # — a position is CSS on both sides, and neither language has an opinion
  # about it.
  defp keyframes(part) do
    Map.new(["initial", "animate"], fn name ->
      {name, position(Enum.find(part["tree"]["attrs"], &(&1["name"] == name)))}
    end)
  end

  defp position(nil), do: nil

  defp position(%{"value" => value}) when is_binary(value) do
    case Regex.run(~r/backgroundPosition:\s*"([^"]*)"/, value, capture: :all_but_first) do
      [position] -> position
      nil -> nil
    end
  end

  defp position(_attr), do: nil

  defp without_motion(tree) do
    Map.update!(tree, "attrs", fn attrs -> Enum.reject(attrs, &(&1["name"] in @motion)) end)
  end

  defp attributes(%{"initial" => from, "animate" => to}) when is_binary(from) and is_binary(to) do
    [
      {"id", :code, "@id"},
      {"phx-hook", :code, "LiveBase.Shimmer.hook()"},
      {"data-lb-shimmer", :text, "#{from},#{to}"},
      # Upstream's `duration` is seconds, which is what a `transition` takes.
      # The Web Animations API takes milliseconds.
      {"data-lb-duration", :code, "trunc(@duration * 1000)"}
    ]
  end

  defp attributes(_keyframes),
    do: raise("shimmer has no `initial` and `animate` to animate between")

  defp declarations do
    [
      ~s|attr :id, :string, required: true, doc: "The hook needs one to be found by."|
    ]
  end
end
