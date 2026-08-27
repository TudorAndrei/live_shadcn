defmodule LiveAiElements.Components.Node do
  @moduledoc """
  Node.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

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
    <LiveShadcn.UI.Card.card
      size={@size}
      class={[upstream_fact("jsx/Node/class/0"), @class]}
      {@rest}
    >
      <div :if={@handles.target} />
      <div :if={@handles.source} />
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card>
    """
  end

  @doc "The `node_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_header(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_header
      class={[upstream_fact("jsx/NodeHeader/class/0"), @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_header>
    """
  end

  @doc "The `node_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_title(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_title {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_title>
    """
  end

  @doc "The `node_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_description(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_description {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_description>
    """
  end

  @doc "The `node_action` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_action {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_action>
    """
  end

  @doc "The `node_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_content(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_content class={[upstream_fact("jsx/NodeContent/class/0"), @class]} {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_content>
    """
  end

  @doc "The `node_footer` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def node_footer(assigns) do
    ~H"""
    <LiveShadcn.UI.Card.card_footer
      class={[upstream_fact("jsx/NodeFooter/class/0"), @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Card.card_footer>
    """
  end
end
