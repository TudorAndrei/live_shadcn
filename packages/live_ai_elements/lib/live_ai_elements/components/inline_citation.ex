defmodule LiveAiElements.Components.InlineCitation do
  @moduledoc """
  Inline citation. Built on `shadcn/carousel`.

  Upstream exports 3 more parts, each a thin
  wrapper around a part of `<.hover_card>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Carousel/class/0" => "relative",
    "jsx/CarouselContent/class/0" => "overflow-hidden",
    "jsx/CarouselContent/class/1" => "flex",
    "jsx/CarouselContent/class/2" => "-ml-4",
    "jsx/CarouselContent/class/3" => "-mt-4 flex-col",
    "jsx/CarouselItem/class/1" => "pl-4",
    "jsx/CarouselItem/class/2" => "pt-4",
    "jsx/InlineCitation/class/0" => "group inline items-center gap-1",
    "jsx/InlineCitationCarouselHeader/class/0" =>
      "flex items-center justify-between gap-2 rounded-t-md bg-secondary p-2",
    "jsx/InlineCitationCarouselIndex/class/0" =>
      "flex flex-1 items-center justify-end px-3 py-1 text-muted-foreground text-xs",
    "jsx/InlineCitationCarouselNext/class/0" => "shrink-0",
    "jsx/InlineCitationCarouselNext/class/1" => "size-4 text-muted-foreground",
    "jsx/InlineCitationQuote/class/0" =>
      "border-muted border-l-2 pl-3 text-muted-foreground text-sm italic",
    "jsx/InlineCitationSource/class/0" => "space-y-1",
    "jsx/InlineCitationSource/class/1" => "truncate font-medium text-sm leading-tight",
    "jsx/InlineCitationSource/class/2" => "truncate break-all text-muted-foreground text-xs",
    "jsx/InlineCitationSource/class/3" =>
      "line-clamp-3 text-muted-foreground text-sm leading-relaxed",
    "jsx/InlineCitationText/class/0" => "transition-colors group-hover:bg-accent",
    "port/class/0" => "min-w-0 shrink-0 grow-0 basis-full w-full space-y-2 p-4 pl-8"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `inline_citation` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/InlineCitation/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `inline_citation_text` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_text(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/InlineCitationText/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `inline_citation_carousel` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_carousel(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "carousel"}
      role="region"
      aria-roledescription="carousel"
      class={[upstream_fact("jsx/Carousel/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `carousel-content` part."
  attr(:orientation, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_carousel_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "carousel-content"}
      class={[upstream_fact("jsx/CarouselContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div
        class={[upstream_fact("jsx/CarouselContent/class/1"), if(@orientation == "horizontal", do: upstream_fact("jsx/CarouselContent/class/2"), else: upstream_fact("jsx/CarouselContent/class/3")), (@class || "")]}
        {@rest}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `carousel-item` part."
  attr(:orientation, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_carousel_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "carousel-item"}
      role="group"
      aria-roledescription="slide"
      class={[
        upstream_fact("port/class/0"),
        if(@orientation == "horizontal", do: upstream_fact("jsx/CarouselItem/class/1"), else: upstream_fact("jsx/CarouselItem/class/2")),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `inline_citation_carousel_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_carousel_header(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/InlineCitationCarouselHeader/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `inline_citation_carousel_index` part."
  attr(:count, :string, default: "0")
  attr(:current, :string, default: "0")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_carousel_index(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/InlineCitationCarouselIndex/class/0"), (@class || "")]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {"#{@current}/#{@count}"}
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `inline_citation_carousel_prev` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def inline_citation_carousel_prev(assigns) do
    ~H"""
    <button aria-label="Previous" type="button" class={[upstream_fact("jsx/InlineCitationCarouselNext/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="arrow-left" class={upstream_fact("jsx/InlineCitationCarouselNext/class/1")} />{render_slot(
        @inner_block
      )}
    </button>
    """
  end

  @doc "The `inline_citation_carousel_next` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def inline_citation_carousel_next(assigns) do
    ~H"""
    <button aria-label="Next" type="button" class={[upstream_fact("jsx/InlineCitationCarouselNext/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="arrow-right" class={upstream_fact("jsx/InlineCitationCarouselNext/class/1")} />{render_slot(
        @inner_block
      )}
    </button>
    """
  end

  @doc "The `inline_citation_source` part."
  attr(:description, :string, default: nil)
  attr(:title, :string, default: nil)
  attr(:url, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_source(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/InlineCitationSource/class/0"), (@class || "")]} {@rest}>
      <h4 :if={@title} class={upstream_fact("jsx/InlineCitationSource/class/1")}>
        {@title}
      </h4>
      <p :if={@url} class={upstream_fact("jsx/InlineCitationSource/class/2")}>
        {@url}
      </p>
      <p :if={@description} class={upstream_fact("jsx/InlineCitationSource/class/3")}>
        {@description}
      </p>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `inline_citation_quote` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def inline_citation_quote(assigns) do
    ~H"""
    <blockquote
      class={[upstream_fact("jsx/InlineCitationQuote/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </blockquote>
    """
  end
end
