defmodule LiveShadcnTools.BaseUi do
  @moduledoc """
  Reads a Base UI component page into the facts the generator needs.

  Base UI publishes one Markdown page per component with a fixed structure, so
  the page is a machine-readable contract rather than prose:

    * an `## Anatomy` block that shows how the parts nest
    * one `### <Part>` section per part
    * `Renders a <div> element.` — the tag the part becomes
    * a `**<Part> Data Attributes:**` table — the attribute contract
    * a `**<Part> CSS Variables:**` table — the variables a class string may read
    * a `**<Part> Props:**` table — the options the part accepts

  Everything `live_base` emits comes from these tables. A primitive that sets an
  attribute absent from them has invented one, which silently breaks the shadcn
  class strings that read the documented name.
  """

  alias LiveShadcnTools.Tsx

  @doc """
  Returns `%{parts: %{name => part}, anatomy: tree, order: [name]}`.

  A part holds `:element`, `:summary`, `:data`, `:css_vars` and `:props`.
  """
  def parse!(markdown, module \\ nil) do
    # A section is a part if it documents props or says what it renders. That
    # test keeps the parts that render nothing — Base UI says so in as many
    # words — and drops the example and type-alias sections, which share the
    # heading level but describe nothing that reaches the DOM.
    parts =
      markdown
      |> sections()
      |> Enum.map(fn {name, body} -> {name, part(name, body)} end)
      |> Enum.filter(fn {_name, part} -> part.part? end)
      |> Enum.uniq_by(&elem(&1, 0))

    %{
      module: module,
      parts: Map.new(parts),
      order: Enum.map(parts, &elem(&1, 0)),
      anatomy: anatomy!(markdown)
    }
  end

  # Every `### Name` heading whose name is a bare part, so `Root.Props` and
  # `Root.State` — the TypeScript re-exports — do not become parts of their own.
  defp sections(markdown) do
    markdown
    |> String.split(~r/^### /m)
    |> Enum.drop(1)
    |> Enum.flat_map(fn chunk ->
      [heading | rest] = String.split(chunk, "\n", parts: 2)
      heading = String.trim(heading)

      if Regex.match?(~r/^[A-Z][A-Za-z0-9]*$/, heading),
        do: [{heading, Enum.at(rest, 0, "")}],
        else: []
    end)
  end

  defp part(name, body) do
    props = props(body, name)
    element = element(body)

    %{
      element: element,
      # Base UI writes "Doesn't render its own HTML element." for the parts that
      # exist only to hold context — a provider, a submenu root. They are still
      # parts, and the generator has to render their children.
      renders?: element != nil,
      # "Renders a `<span>` element and a hidden `<input>` beside." Base UI says
      # so in as many words, and a control without that input submits nothing.
      hidden_input?: String.contains?(body, "hidden `<input>`"),
      part?: element != nil or props != [] or transparent?(body),
      summary: summary(body),
      data: table_keys(body, "#{name} Data Attributes"),
      css_vars: table_keys(body, "#{name} CSS Variables"),
      props: props
    }
  end

  # Some pages write "Renders a `<span>`." and others "Renders a `<div>`
  # element.", so the word is optional.
  defp element(body) do
    case Regex.run(~r/Renders (?:a|an) `<([a-z0-9]+)>`/, body, capture: :all_but_first) do
      [tag] -> tag
      nil -> nil
    end
  end

  defp transparent?(body), do: String.contains?(body, "render its own HTML element")

  # The first prose line of the section, which Base UI writes as a one-line
  # description of the part. It becomes the `@doc` of the generated function.
  defp summary(body) do
    body
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.find(&(&1 != "" and not String.starts_with?(&1, ["Renders ", "**", "|", "```"])))
  end

  # `**Panel Data Attributes:**` followed by a Markdown table. The first column
  # holds the names; everything else on the page is commentary.
  defp table_keys(body, label) do
    case table(body, label) do
      nil -> []
      rows -> Enum.map(rows, &(&1 |> hd() |> String.trim("`")))
    end
  end

  defp props(body, name) do
    case table(body, "#{name} Props") do
      nil ->
        []

      rows ->
        Enum.map(rows, fn
          [prop, type, default | rest] ->
            %{
              "name" => prop,
              "type" => clean(type),
              "default" => if(default in ["-", ""], do: nil, else: clean(default)),
              "doc" => rest |> Enum.at(0, "") |> clean()
            }

          [prop | _] ->
            %{"name" => prop, "type" => nil, "default" => nil, "doc" => ""}
        end)
    end
  end

  # The rows of the first Markdown table after `label`, header and the `:---`
  # separator removed.
  defp table(body, label) do
    case String.split(body, "**#{label}:**", parts: 2) do
      [_] ->
        nil

      [_, after_label] ->
        after_label
        |> String.split("\n")
        |> Enum.drop_while(&(not row?(&1)))
        |> Enum.take_while(&row?/1)
        |> Enum.map(&cells/1)
        |> Enum.drop(1)
        |> Enum.reject(&separator?/1)
        |> case do
          [] -> nil
          rows -> rows
        end
    end
  end

  defp row?(line), do: String.starts_with?(String.trim(line), "|")

  defp cells(line) do
    line
    |> String.trim()
    |> String.trim("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  defp separator?(cells), do: Enum.all?(cells, &Regex.match?(~r/^:?-+:?$/, &1))

  defp clean(cell) do
    cell
    |> String.replace("&#xA;", " ")
    |> String.replace("\\|", "|")
    |> String.trim("`")
    |> String.split()
    |> Enum.join(" ")
  end

  @doc """
  The part nesting, read from the `## Anatomy` block.

  The block is JSX, so the TSX reader parses it. Returns a list of
  `%{"part" => name, "children" => [...]}`.
  """
  def anatomy!(markdown) do
    case anatomy_source(markdown) do
      nil ->
        []

      source ->
        source
        |> Tsx.parse_jsx!()
        |> anatomy_node()
        |> List.wrap()
    end
  end

  # A page without an anatomy block is a page for a component with one part.
  # The nesting is then not a fact anybody has to state.
  defp anatomy_source(markdown) do
    with [_, after_heading] <- String.split(markdown, "## Anatomy", parts: 2),
         [_, block | _] <- String.split(after_heading, "```") do
      jsx_of(block)
    else
      _ -> nil
    end
  end

  defp jsx_of(block) do
    jsx =
      block
      |> String.split("\n")
      |> Enum.drop_while(&(not String.starts_with?(String.trim(&1), "<")))
      |> Enum.join("\n")
      |> String.trim()
      |> String.trim_trailing(";")

    if jsx == "", do: nil, else: jsx
  end

  defp anatomy_node(%{tag: tag, children: children}) do
    %{
      "part" => tag |> String.split(".") |> List.last(),
      "children" => children |> Enum.filter(&(&1.type == :element)) |> Enum.map(&anatomy_node/1)
    }
  end
end
