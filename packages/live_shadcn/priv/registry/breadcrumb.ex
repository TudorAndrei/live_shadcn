defmodule LiveShadcn.UI.Breadcrumb do
  @moduledoc """
  Breadcrumb.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Breadcrumb/class/0" => "cn-breadcrumb",
    "jsx/BreadcrumbEllipsis/class/0" => "cn-breadcrumb-ellipsis flex items-center justify-center",
    "jsx/BreadcrumbEllipsis/class/1" => "sr-only",
    "jsx/BreadcrumbItem/class/0" => "cn-breadcrumb-item inline-flex items-center",
    "jsx/BreadcrumbLink/class/0" => "cn-breadcrumb-link",
    "jsx/BreadcrumbList/class/0" => "cn-breadcrumb-list flex flex-wrap items-center wrap-break-word",
    "jsx/BreadcrumbPage/class/0" => "cn-breadcrumb-page",
    "jsx/BreadcrumbSeparator/class/0" => "cn-breadcrumb-separator",
    "jsx/BreadcrumbSeparator/class/1" => "cn-rtl-flip"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `breadcrumb` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def breadcrumb(assigns) do
    ~H"""
    <nav
      data-slot={@rest[:"data-slot"] || "breadcrumb"}
      aria-label="breadcrumb"
      class={[upstream_fact("jsx/Breadcrumb/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  @doc "The `breadcrumb-list` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "start", "reversed"])
  slot(:inner_block)

  def breadcrumb_list(assigns) do
    ~H"""
    <ol
      data-slot={@rest[:"data-slot"] || "breadcrumb-list"}
      class={[upstream_fact("jsx/BreadcrumbList/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </ol>
    """
  end

  @doc "The `breadcrumb-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def breadcrumb_item(assigns) do
    ~H"""
    <li
      data-slot={@rest[:"data-slot"] || "breadcrumb-item"}
      class={[upstream_fact("jsx/BreadcrumbItem/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `breadcrumb-link` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"])
  slot(:inner_block)

  def breadcrumb_link(assigns) do
    ~H"""
    <a
      data-slot={@rest[:"data-slot"] || "breadcrumb-link"}
      class={[upstream_fact("jsx/BreadcrumbLink/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  @doc "The `breadcrumb-page` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def breadcrumb_page(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "breadcrumb-page"}
      role="link"
      aria-disabled="true"
      aria-current="page"
      class={[upstream_fact("jsx/BreadcrumbPage/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `breadcrumb-separator` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def breadcrumb_separator(assigns) do
    ~H"""
    <li
      data-slot={@rest[:"data-slot"] || "breadcrumb-separator"}
      role="presentation"
      aria-hidden="true"
      class={[upstream_fact("jsx/BreadcrumbSeparator/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="chevron-right" class={upstream_fact("jsx/BreadcrumbSeparator/class/1")} />
      <% end %>
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `breadcrumb-ellipsis` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def breadcrumb_ellipsis(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "breadcrumb-ellipsis"}
      role="presentation"
      aria-hidden="true"
      class={[upstream_fact("jsx/BreadcrumbEllipsis/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.Icon.icon name="ellipsis" /><span class={upstream_fact("jsx/BreadcrumbEllipsis/class/1")}>More</span>{render_slot(
        @inner_block
      )}
    </span>
    """
  end
end