defmodule LiveShadcn.UI.HoverCard do
  @moduledoc """
  Hover card.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/HoverCardContent/class/0" => "isolate z-50",
    "jsx/HoverCardContent/class/1" =>
      "cn-hover-card-content cn-hover-card-content-logical z-50 origin-(--transform-origin) outline-hidden"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Popover

  @doc """


      <.hover_card id="details">
        <:trigger>Details</:trigger>
        Generated from registry/spec/accordion.json.
      </.hover_card>

  `side` and `align` are what is asked for. Where the popup lands is what
  the browser had room for, and `data-side` reports that.
  """
  attr(:id, :string, required: true, doc: "Every id inside the popover derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether it starts open.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")

  attr(:side, :string,
    default: "bottom",
    values: ["top", "right", "bottom", "left"],
    doc: "The side asked for. Where it lands is what `data-side` reports."
  )

  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4, doc: "The gap between the trigger and the popup.")

  attr(:autofocus, :boolean,
    default: true,
    doc: "Whether opening moves the focus into the popup. False for a tooltip."
  )

  attr(:class, :any, default: nil, doc: "Appended to the popup's class string.")
  attr(:trigger_class, :any, default: nil)
  attr(:align_offset, :string, default: "4")
  attr(:side_offset, :string, default: "4")
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:inner_block, required: true, doc: "The popup's body.")

  def hover_card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      class="contents"
      {@rest}
    >
      <a
        data-slot="hover-card-trigger"
        id={Popover.trigger_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-popup-open={flag(@open)}
      >
        {render_slot(@trigger)}
      </a>
      <div data-slot="hover-card-portal" class="contents">
        <div
          id={Popover.positioner_id(@id)}
          hidden={not @open}
          phx-hook={Popover.hook()}
          data-lb-anchor={Popover.trigger_id(@id)}
          data-lb-side={@side}
          data-lb-align={@align}
          data-lb-offset={to_string(@offset)}
          data-lb-autofocus={flag(@autofocus)}
          phx-mounted={Popover.owned_attributes(:positioner)}
          data-open={flag(@open)}
          data-closed={flag(not @open)}
          class={upstream_fact("jsx/HoverCardContent/class/0")}
        >
          <div
            data-slot="hover-card-content"
            id={Popover.popup_id(@id)}
            role="dialog"
            tabindex="-1"
            hidden={not @open}
            data-lb-popup
            phx-mounted={Popover.owned_attributes(:popup)}
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            class={[
              upstream_fact("jsx/HoverCardContent/class/1"),
              (@class || "")
            ]}
            data-lb-style-target
            data-lb-measure
          >
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end