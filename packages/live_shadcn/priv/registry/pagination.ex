defmodule LiveShadcn.UI.Pagination do
  @moduledoc """
  Pagination.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Pagination/class/0" => "cn-pagination mx-auto flex w-full justify-center",
    "jsx/PaginationContent/class/0" => "cn-pagination-content flex items-center",
    "jsx/PaginationEllipsis/class/0" => "cn-pagination-ellipsis flex items-center justify-center",
    "jsx/PaginationEllipsis/class/1" => "sr-only",
    "jsx/PaginationLink/class/0" => "cn-pagination-link",
    "jsx/PaginationNext/class/0" => "cn-pagination-next",
    "jsx/PaginationNext/class/1" => "cn-pagination-next-text hidden sm:block",
    "jsx/PaginationNext/class/2" => "cn-rtl-flip",
    "jsx/PaginationPrevious/class/0" => "cn-pagination-previous",
    "jsx/PaginationPrevious/class/2" => "cn-pagination-previous-text hidden sm:block"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `pagination` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def pagination(assigns) do
    ~H"""
    <nav
      data-slot={@rest[:"data-slot"] || "pagination"}
      role="navigation"
      aria-label="pagination"
      class={[upstream_fact("jsx/Pagination/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  @doc "The `pagination-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def pagination_content(assigns) do
    ~H"""
    <ul
      data-slot={@rest[:"data-slot"] || "pagination-content"}
      class={[upstream_fact("jsx/PaginationContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc "The `pagination-ellipsis` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def pagination_ellipsis(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "pagination-ellipsis"}
      aria-hidden
      class={[upstream_fact("jsx/PaginationEllipsis/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.Icon.icon name="ellipsis" /><span class={upstream_fact("jsx/PaginationEllipsis/class/1")}>More pages</span>{render_slot(
        @inner_block
      )}
    </span>
    """
  end

  @doc "The `pagination-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def pagination_item(assigns) do
    ~H"""
    <li data-slot={@rest[:"data-slot"] || "pagination-item"} {Map.drop(@rest, [:"data-slot"])}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `pagination_link` part."
  attr(:is_active, :boolean, default: nil)
  attr(:size, :string, default: "icon")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"])
  slot(:inner_block)

  def pagination_link(assigns) do
    ~H"""
    <a
      data-slot={@rest[:"data-slot"] || "pagination-link"}
      role="button"
      aria-current={if(@is_active, do: "page", else: nil)}
      data-active={@is_active}
      class={[
        LiveShadcn.UI.Button.part_class("button"),
        LiveShadcn.UI.Button.variant_class("buttonVariants", "size", @size),
        LiveShadcn.UI.Button.variant_class(
          "buttonVariants",
          "variant",
          if(@is_active, do: "outline", else: "ghost")
        ),
        upstream_fact("jsx/PaginationLink/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  @doc "The `pagination_next` part."
  attr(:text, :string, default: "Next")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"])
  slot(:inner_block)

  def pagination_next(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to next page"
      size="default"
      class={[upstream_fact("jsx/PaginationNext/class/0"), @class]}
      {@rest}
    >
      <span class={upstream_fact("jsx/PaginationNext/class/1")}>{@text}</span><LiveShadcn.Icon.icon
        name="chevron-right"
        class={upstream_fact("jsx/PaginationNext/class/2")}
      />{render_slot(@inner_block)}
    </.pagination_link>
    """
  end

  @doc "The `pagination_previous` part."
  attr(:text, :string, default: "Previous")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"])
  slot(:inner_block)

  def pagination_previous(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to previous page"
      size="default"
      class={[upstream_fact("jsx/PaginationPrevious/class/0"), @class]}
      {@rest}
    >
      <LiveShadcn.Icon.icon name="chevron-left" class={upstream_fact("jsx/PaginationNext/class/2")} /><span class={upstream_fact("jsx/PaginationPrevious/class/2")}>{@text}</span>{render_slot(
        @inner_block
      )}
    </.pagination_link>
    """
  end
end
