defmodule LiveShadcn.UI.Message do
  @moduledoc """
  Message.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Message/class/0" =>
      "cn-message group/message relative flex w-full min-w-0 data-[align=end]:flex-row-reverse",
    "jsx/MessageAvatar/class/0" =>
      "cn-message-avatar flex w-fit shrink-0 items-center justify-center self-end overflow-hidden rounded-full bg-muted",
    "jsx/MessageContent/class/0" =>
      "cn-message-content flex w-full min-w-0 flex-col wrap-break-word",
    "jsx/MessageFooter/class/0" =>
      "cn-message-footer flex max-w-full min-w-0 items-center group-data-[align=end]/message:justify-end",
    "jsx/MessageGroup/class/0" => "cn-message-group flex min-w-0 flex-col",
    "jsx/MessageHeader/class/0" => "cn-message-header flex max-w-full min-w-0 items-center"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `message-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-group"}
      class={[upstream_fact("jsx/MessageGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message` part."
  attr(:align, :string, default: "start", values: ["start", "end"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message"}
      data-align={@align}
      class={[
        upstream_fact("jsx/Message/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-avatar` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_avatar(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-avatar"}
      class={[
        upstream_fact("jsx/MessageAvatar/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-content"}
      class={[upstream_fact("jsx/MessageContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-footer` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_footer(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-footer"}
      class={[
        upstream_fact("jsx/MessageFooter/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message-header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_header(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "message-header"}
      class={[upstream_fact("jsx/MessageHeader/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end