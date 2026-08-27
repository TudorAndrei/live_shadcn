defmodule LiveShadcn.UI.Table do
  @moduledoc """
  Table.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Table/class/0" => "cn-table-container",
    "jsx/Table/class/1" => "cn-table",
    "jsx/TableBody/class/0" => "cn-table-body",
    "jsx/TableCaption/class/0" => "cn-table-caption",
    "jsx/TableCell/class/0" => "cn-table-cell",
    "jsx/TableFooter/class/0" => "cn-table-footer",
    "jsx/TableHead/class/0" => "cn-table-head",
    "jsx/TableHeader/class/0" => "cn-table-header",
    "jsx/TableRow/class/0" => "cn-table-row has-aria-expanded:bg-muted/50"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `table-container` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table(assigns) do
    ~H"""
    <div data-slot="table-container" class={upstream_fact("jsx/Table/class/0")}>
      <table
        data-slot={@rest[:"data-slot"] || "table"}
        class={[upstream_fact("jsx/Table/class/1"), (@class || "")]}
        {Map.drop(@rest, [:"data-slot"])}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  @doc "The `table-header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table_header(assigns) do
    ~H"""
    <thead
      data-slot={@rest[:"data-slot"] || "table-header"}
      class={[upstream_fact("jsx/TableHeader/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </thead>
    """
  end

  @doc "The `table-body` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table_body(assigns) do
    ~H"""
    <tbody
      data-slot={@rest[:"data-slot"] || "table-body"}
      class={[upstream_fact("jsx/TableBody/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  @doc "The `table-footer` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table_footer(assigns) do
    ~H"""
    <tfoot
      data-slot={@rest[:"data-slot"] || "table-footer"}
      class={[upstream_fact("jsx/TableFooter/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  @doc "The `table-head` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "colspan", "rowspan", "headers", "scope", "abbr"])
  slot(:inner_block)

  def table_head(assigns) do
    ~H"""
    <th
      data-slot={@rest[:"data-slot"] || "table-head"}
      class={[upstream_fact("jsx/TableHead/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  @doc "The `table-row` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table_row(assigns) do
    ~H"""
    <tr
      data-slot={@rest[:"data-slot"] || "table-row"}
      class={[upstream_fact("jsx/TableRow/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </tr>
    """
  end

  @doc "The `table-cell` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "colspan", "rowspan", "headers"])
  slot(:inner_block)

  def table_cell(assigns) do
    ~H"""
    <td
      data-slot={@rest[:"data-slot"] || "table-cell"}
      class={[upstream_fact("jsx/TableCell/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </td>
    """
  end

  @doc "The `table-caption` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def table_caption(assigns) do
    ~H"""
    <caption
      data-slot={@rest[:"data-slot"] || "table-caption"}
      class={[upstream_fact("jsx/TableCaption/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </caption>
    """
  end
end