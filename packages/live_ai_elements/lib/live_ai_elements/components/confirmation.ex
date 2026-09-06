defmodule LiveAiElements.Components.Confirmation do
  @moduledoc """
  Confirmation.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  @states ~w(
    input-streaming
    input-available
    approval-requested
    approval-responded
    output-available
    output-denied
    output-error
  )
  @response_states ~w(approval-responded output-denied output-available)
  @alert_description_class "text-muted-foreground col-start-2 grid justify-items-start gap-1 text-sm [&_p]:leading-relaxed"

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
  attr(:approval, :map,
    default: nil,
    doc: "The approval map, with an `id` and an optional boolean `approved` value."
  )

  attr(:state, :string, required: true, values: @states)

  attr(:variant, :string, default: "default", values: ~w(default destructive))
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def confirmation(assigns) do
    ~H"""
    <div
      :if={show_confirmation?(@approval, @state)}
      data-slot={@rest[:"data-slot"] || "alert"}
      role="alert"
      class={[
        Shadcn.alert_class(@variant),
        upstream_fact("jsx/Confirmation/class/0"),
        "!flex !gap-2",
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `confirmation_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def confirmation_title(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "alert-description"}
      class={
        LiveShadcn.Cn.merge([
          alert_description_class(),
          upstream_fact("jsx/ConfirmationTitle/class/0"),
          @class
        ])
      }
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `confirmation_request` part."
  attr(:state, :string, required: true, values: @states)
  slot(:inner_block)

  def confirmation_request(assigns) do
    ~H"""
    <%= if @state == "approval-requested" do %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  @doc "The `confirmation_accepted` part."
  attr(:approval, :map,
    default: nil,
    doc: "The approval map, with an `id` and an optional boolean `approved` value."
  )

  attr(:state, :string, required: true, values: @states)
  slot(:inner_block)

  def confirmation_accepted(assigns) do
    ~H"""
    <%= if approved?(@approval) and response_state?(@state) do %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  @doc "The `confirmation_rejected` part."
  attr(:approval, :map,
    default: nil,
    doc: "The approval map, with an `id` and an optional boolean `approved` value."
  )

  attr(:state, :string, required: true, values: @states)
  slot(:inner_block)

  def confirmation_rejected(assigns) do
    ~H"""
    <%= if rejected?(@approval) and response_state?(@state) do %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  @doc "The `confirmation_actions` part."
  attr(:state, :string, required: true, values: @states)
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
  attr(:size, :string, default: "default", values: ~w(default sm lg icon icon-sm icon-lg))

  attr(:variant, :string,
    default: "default",
    values: ~w(default destructive outline secondary ghost link)
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def confirmation_action(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      type="button"
      class={
        LiveShadcn.Cn.merge([
          Shadcn.button_class(@size, @variant),
          @class || upstream_fact("jsx/ConfirmationAction/class/0")
        ])
      }
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp approved?(%{approved: true}), do: true
  defp approved?(%{"approved" => true}), do: true
  defp approved?(_approval), do: false

  defp rejected?(%{approved: false}), do: true
  defp rejected?(%{"approved" => false}), do: true
  defp rejected?(_approval), do: false

  defp show_confirmation?(approval, state),
    do: not is_nil(approval) and state not in ["input-streaming", "input-available"]

  defp response_state?(state), do: state in @response_states
  defp alert_description_class, do: @alert_description_class
end
