defmodule LiveAiElements.Components.Node do
  @moduledoc """
  Node.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Node/class/0" => "node-container relative size-full h-auto w-sm gap-0 rounded-md p-0",
    "jsx/NodeContent/class/0" => "p-3",
    "jsx/NodeFooter/class/0" => "rounded-b-md border-t bg-secondary p-3!",
    "jsx/NodeHeader/class/0" => "gap-0.5 rounded-t-md border-b bg-secondary p-3!"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `node` part."
  attr(:handles, :any, default: nil)
  attr(:size, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card"}
      class={[
        Shadcn.card_class(:card),
        upstream_fact("jsx/Node/class/0"),
        "!gap-0 !rounded-md !p-0",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div :if={@handles.target} />
      <div :if={@handles.source} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_header(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-header"}
      class={[
        Shadcn.card_class(:header),
        upstream_fact("jsx/NodeHeader/class/0"),
        "!gap-0.5",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_title(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-title"}
      class={Shadcn.card_class(:title)}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_description(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-description"}
      class={Shadcn.card_class(:description)}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_action` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_action(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-action"}
      class={Shadcn.card_class(:action)}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-content"}
      class={[Shadcn.card_class(:content), upstream_fact("jsx/NodeContent/class/0"), "!p-3", @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `node_footer` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_footer(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "card-footer"}
      class={[
        Shadcn.card_class(:footer),
        upstream_fact("jsx/NodeFooter/class/0"),
        "!p-3",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
