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
    values: ["top", "right", "bottom", "left", "inline-start", "inline-end"],
    doc: "The side asked for. Where it lands is what `data-side` reports."
  )

  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4, doc: "The gap between the trigger and the popup.")

  attr(:autofocus, :boolean,
    default: false,
    doc: "Whether opening moves the focus into the popup."
  )

  attr(:class, :any, default: nil, doc: "Appended to the popup's class string.")
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_variant, :string, default: "link")
  attr(:trigger_size, :string, default: "default")
  attr(:trigger_as, :string, default: "button", values: ["button", "native-button", "span"])
  attr(:dir, :string, default: "ltr", values: ["ltr", "rtl"])
  attr(:delay, :integer, default: 10)
  attr(:close_delay, :integer, default: 100)
  attr(:align_offset, :integer, default: 4)
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:inner_block, required: true, doc: "The popup's body.")

  def hover_card(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      :if={@trigger_as == "button"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      type="button"
      variant={@trigger_variant}
      size={@trigger_size}
      class={@trigger_class}
      disabled={@disabled}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
    >
      {render_slot(@trigger)}
    </LiveShadcn.UI.Button.button>
    <button
      :if={@trigger_as == "native-button"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      type="button"
      class={@trigger_class}
      disabled={@disabled}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
    >
      {render_slot(@trigger)}
    </button>
    <span
      :if={@trigger_as == "span"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      class={@trigger_class}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
    >
      {render_slot(@trigger)}
    </span>
    <div
      id={Popover.positioner_id(@id)}
      hidden={not @open}
      phx-click-away={Popover.dismiss(@id)}
      phx-hook={Popover.hook()}
      data-lb-anchor={Popover.trigger_id(@id)}
      data-lb-side={physical_side(@side)}
      data-lb-semantic-side={@side}
      data-lb-align={@align}
      data-lb-offset={to_string(@offset)}
      data-lb-align-offset={to_string(@align_offset)}
      data-lb-autofocus={flag(@autofocus)}
      phx-mounted={Popover.owned_attributes(:positioner)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={upstream_fact("jsx/HoverCardContent/class/0")}
    >
      <div
        data-slot="hover-card-content"
        id={Popover.popup_id(@id)}
        tabindex="-1"
        hidden={not @open}
        data-lb-popup
        phx-mounted={Popover.owned_attributes(:popup)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={LiveShadcn.Cn.merge([upstream_fact("jsx/HoverCardContent/class/1"), @class])}
        data-lb-style-target
        data-lb-measure
        dir={@dir}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:variant, :string, default: "link")
  attr(:size, :string, default: "default")
  attr(:as, :string, default: "button", values: ["button", "native-button", "span"])
  attr(:delay, :integer, default: 10)
  attr(:close_delay, :integer, default: 100)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def hover_card_trigger(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      :if={@as == "button"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      type="button"
      variant={@variant}
      size={@size}
      class={@class}
      disabled={@disabled}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    <button
      :if={@as == "native-button"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      type="button"
      class={@class}
      disabled={@disabled}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <span
      :if={@as == "span"}
      id={Popover.trigger_id(@id)}
      data-slot="hover-card-trigger"
      class={@class}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-hook={LiveBase.InteractionTrigger.hook()}
      data-lb-open-on-hover
      data-lb-hover-card
      data-lb-open-delay={to_string(@delay)}
      data-lb-close-delay={to_string(@close_delay)}
      phx-click={if(not @disabled, do: Popover.toggle(@id))}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)

  attr(:side, :string,
    default: "bottom",
    values: ["top", "right", "bottom", "left", "inline-start", "inline-end"]
  )

  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4)
  attr(:autofocus, :boolean, default: false)
  attr(:dir, :string, default: "ltr", values: ["ltr", "rtl"])
  attr(:align_offset, :integer, default: 4)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def hover_card_content(assigns) do
    ~H"""
    <div
      id={Popover.positioner_id(@id)}
      hidden={not @open}
      phx-click-away={Popover.dismiss(@id)}
      phx-hook={Popover.hook()}
      data-lb-anchor={Popover.trigger_id(@id)}
      data-lb-side={physical_side(@side)}
      data-lb-semantic-side={@side}
      data-lb-align={@align}
      data-lb-offset={to_string(@offset)}
      data-lb-align-offset={to_string(@align_offset)}
      data-lb-autofocus={flag(@autofocus)}
      phx-mounted={Popover.owned_attributes(:positioner)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={upstream_fact("jsx/HoverCardContent/class/0")}
    >
      <div
        data-slot="hover-card-content"
        id={Popover.popup_id(@id)}
        tabindex="-1"
        hidden={not @open}
        data-lb-popup
        phx-mounted={Popover.owned_attributes(:popup)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={LiveShadcn.Cn.merge([upstream_fact("jsx/HoverCardContent/class/1"), @class])}
        data-lb-style-target
        data-lb-measure
        dir={@dir}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp physical_side("inline-start"), do: "left"
  defp physical_side("inline-end"), do: "right"
  defp physical_side(side), do: side
end
