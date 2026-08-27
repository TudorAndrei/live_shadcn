defmodule LiveAiElements.Components.Confirmation do
  @moduledoc """
  Confirmation.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Confirmation/class/0" => "flex flex-col gap-2",
    "jsx/ConfirmationAction/class/0" => "h-8 px-3 text-sm",
    "jsx/ConfirmationActions/class/0" => "flex items-center justify-end gap-2 self-end",
    "jsx/ConfirmationTitle/class/0" => "inline"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `confirmation` part."
  attr(:approval, :string, default: nil)
  attr(:state, :string, default: nil)
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def confirmation(assigns) do
    ~H"""
    <LiveShadcn.UI.Alert.alert
      :if={@approval || @state == "input-streaming" || @state == "input-available"}
      variant={@variant}
      class={[upstream_fact("jsx/Confirmation/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Alert.alert>
    """
  end

  @doc "The `confirmation_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def confirmation_title(assigns) do
    ~H"""
    <LiveShadcn.UI.Alert.alert_description class={[upstream_fact("jsx/ConfirmationTitle/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Alert.alert_description>
    """
  end

  @doc "The `confirmation_actions` part."
  attr(:state, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def confirmation_actions(assigns) do
    ~H"""
    <div
      :if={!(@state != "approval-requested")}
      class={[upstream_fact("jsx/ConfirmationActions/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `confirmation_action` part."
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def confirmation_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      type="button"
      size={@size}
      variant={@variant}
      class={upstream_fact("jsx/ConfirmationAction/class/0")}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end
end
