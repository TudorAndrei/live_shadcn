defmodule LiveShadcnTools.Gen.Presentational do
  @moduledoc """
  The `presentational` recipe: markup and class strings, and no behavior.

  More than half the registry is this. A card is a `<div>` with a class string;
  a badge is a `<span>` with a class string that depends on a variant. Neither
  has state, neither needs `LiveBase`, and neither needs the parts folded into
  one function — the caller composes them freely, so each exported part becomes
  a function of its own.

  ## What it still has to get right

  **Variants.** shadcn writes them as a `cva` table: which variants exist, what
  each is called, which is the default, and the class string each carries. The
  spec records all four, so the generated component declares
  `attr :variant, :string, values: ~w(default outline …)` from data rather than
  from somebody reading the table and retyping it.

  **The attributes that are not the class string.** `data-size={size}` on a card
  is markup too. A component that dropped it would render a different card, so
  every attribute upstream writes is emitted.
  """

  alias LiveShadcnTools.Gen.Heex

  @doc "The module source for one component."
  def module(spec, opts) do
    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

    #{Enum.map_join(spec["parts"], "\n", &function(&1, spec))}#{variant_table(spec)}
    end
    """
  end

  @doc """
  One function for one part.

  The form-control recipe borrows this for the parts of its own components that
  hold no value: a `<label>` is markup whichever recipe it appears under.
  """
  def function(part, spec) do
    name = part["name"]
    attrs = attributes(part, spec)

    """
    #{part_doc(part, spec)}
    #{Enum.map_join(attrs, "\n", &declaration/1)}
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global, include: #{inspect(Heex.globals(Heex.tag_of(part["tree"], by_name(spec))))}
    #{slot(part)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(part, spec)}
        \"\"\"
      end
    """
  end

  defp by_name(spec), do: Map.new(spec["parts"], &{&1["name"], &1})

  # A prop upstream destructures is a prop the caller can set. `className` is
  # handled on its own, and the rest arrive through `:global`.
  @doc "The attributes a part exposes, with their defaults and allowed values."
  def attributes(part, spec) do
    variants = variant_table_of(part, spec)
    paths = path_roots(part)

    part
    |> Map.get("params", %{})
    |> Map.drop(["className", "children", "render"])
    |> Enum.sort()
    |> Enum.map(fn {name, default} ->
      # The `cva` table's `defaultVariants` is as much upstream's decision as
      # the destructuring default is, and it is the one that decides which
      # class string is applied.
      default = default || get_in(variants, ["defaults", name])

      %{
        name: Macro.underscore(name),
        default: default,
        values: variants |> Map.get("variants", %{}) |> Map.get(name) |> values(),
        type: type(name, default, paths)
      }
    end)
  end

  defp values(nil), do: nil
  defp values(group), do: group |> Map.keys() |> Enum.sort()

  # What a prop holds, from the two things upstream says about it: the default
  # it wrote down, and what the markup does with it. `disabled = false` is a
  # yes-or-no and `data.filename` is a value with fields, and declaring either
  # one a string makes the component lie about what it takes — a `:string`
  # holding `"false"` is true to every `:if` that reads it.
  defp type(_name, default, _paths) when default in ["true", "false"], do: ":boolean"
  defp type(name, _default, paths), do: if(name in paths, do: ":any", else: ":string")

  # The props the markup reads a field off, rather than rendering whole.
  defp path_roots(part) do
    for code <- Heex.codes(part["tree"]),
        [root] <- Regex.scan(~r/\b([a-z_][A-Za-z0-9_]*)\.[a-z_]/, code, capture: :all_but_first),
        uniq: true,
        do: root
  end

  # Every attribute gets a default, even if it is `nil`. A declared attribute
  # with no default is simply absent from the assigns, and the component would
  # raise the first time nobody passed it.
  @doc "One `attr` line."
  def declaration(%{name: name, default: default, values: values} = attribute) do
    type = Map.get(attribute, :type, ":string")

    options =
      ["default: #{inspect(literal(type, default))}", values && "values: #{inspect(values)}"]
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join("", &", #{&1}")

    "  attr :#{name}, #{type}#{options}"
  end

  defp literal(":boolean", "true"), do: true
  defp literal(":boolean", "false"), do: false
  defp literal(_type, default), do: default

  defp slot(part) do
    if Heex.marker?(tree(part)), do: "  slot :inner_block\n", else: ""
  end

  defp tree(part), do: Heex.with_children(part["tree"])

  defp markup(part, spec) do
    Heex.render(tree(part), %{
      attrs: %{},
      children: "{render_slot(@inner_block)}",
      class: "@class",
      variants: variant_table_of(part, spec),
      params: Map.get(part, "params", %{}),
      contexts: Map.get(part, "contexts", []),
      client_attributes: [],
      hook_part: nil,
      rest: true
    })
  end

  @doc "The `cva` table this part's class string is built from, if any."
  def variant_table_of(part, spec) do
    case variant_binding(part["tree"]) do
      nil -> %{}
      name -> get_in(spec, ["variants", name]) || %{}
    end
  end

  defp variant_binding(%{"variant_class" => name}) when is_binary(name), do: name

  defp variant_binding(node),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&variant_binding/1)

  @doc """
  The variant table as a module attribute, written once per component and read
  by every part that has variants. It is data, so it stays data.
  """
  def variant_table(spec) do
    # Only the tables a part reads. A component that folded in another one's
    # markup inherits its `cva` tables too, and writing one nothing reads is a
    # private function nobody calls — which is a compiler warning, and this
    # project compiles generated code with warnings as errors.
    used =
      spec["parts"]
      |> List.wrap()
      |> Enum.flat_map(&Map.keys(variant_table_of(&1, spec)["variants"] || %{}))
      |> MapSet.new()

    tables =
      for {_binding, table} <- spec["variants"] || %{},
          {group, values} <- table["variants"] || %{},
          MapSet.member?(used, group),
          into: %{},
          do: {group, values}

    if tables == %{} do
      ""
    else
      """

        # The variant table, from the `cva` call upstream writes it in.
        @variants #{inspect(tables, pretty: true, limit: :infinity)}

        defp variant_class(group, value), do: get_in(@variants, [group, value])
      """
    end
  end

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string and every `data-slot` below came from upstream. Change the
      spec or the recipe, not this file.
      \"\"\"\
    """
  end

  defp part_doc(part, spec) do
    summary =
      get_in(spec, ["primitives", "#{spec["name"]}.#{part["primitive"]}", "summary"]) ||
        "The `#{part["tree"]["slot"] || part["name"]}` part."

    "  @doc #{inspect(summary)}"
  end
end
