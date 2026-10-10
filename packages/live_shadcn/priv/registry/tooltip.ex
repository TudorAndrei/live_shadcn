defmodule LiveShadcn.UI.Tooltip do
  @moduledoc """
  Tooltip. Groups all parts of the tooltip.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/TooltipContent/class/0" => "isolate z-50",
    "jsx/TooltipContent/class/1" =>
      "cn-tooltip-content cn-tooltip-content-logical z-50 w-fit max-w-xs origin-(--transform-origin) bg-foreground text-background",
    "jsx/TooltipContent/class/2" =>
      "cn-tooltip-arrow cn-tooltip-arrow-logical z-50 bg-foreground fill-foreground data-[side=bottom]:top-1 data-[side=left]:top-1/2! data-[side=left]:-right-1 data-[side=left]:-translate-y-1/2 data-[side=right]:top-1/2! data-[side=right]:-left-1 data-[side=right]:-translate-y-1/2 data-[side=top]:-bottom-2.5"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Popover

  @doc """
  Groups all parts of the tooltip.

      <.tooltip id="details">
        <:trigger>Details</:trigger>
        Generated from registry/spec/accordion.json.
      </.tooltip>

  `side` and `align` are what is asked for. Where the popup lands is what
  the browser had room for, and `data-side` reports that.
  """
  attr(:id, :string, required: true, doc: "Every id inside the popover derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether it starts open.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")

  attr(:side, :string,
    default: "top",
    values: ["top", "right", "bottom", "left", "inline-start", "inline-end"],
    doc: "The side asked for. Where it lands is what `data-side` reports."
  )

  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4, doc: "The gap between the trigger and the popup.")

  attr(:autofocus, :boolean,
    default: false,
    doc: "Whether opening moves the focus into the popup. False for a tooltip."
  )

  attr(:class, :any, default: nil, doc: "Appended to the popup's class string.")
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_label, :string, default: nil, doc: "The accessible name for an icon trigger.")
  attr(:trigger_variant, :string, default: "outline")
  attr(:trigger_size, :string, default: "default")

  attr(:trigger_as, :string,
    default: "button",
    values: ["button", "span", "addon-wrapper"]
  )

  attr(:trigger_slot, :string, default: "tooltip-trigger")
  attr(:trigger_data_size, :string, default: nil)
  attr(:trigger_align, :string, default: nil)

  attr(:trigger_click, :any,
    default: nil,
    doc: "An optional client command for a trusted native click."
  )

  attr(:hover_expanded, :boolean,
    default: false,
    doc: "Whether hover uses disclosure semantics on the trigger."
  )

  attr(:trigger_attrs, :map, default: %{}, doc: "Attributes merged onto the trigger.")
  attr(:dir, :string, default: "ltr", values: ["ltr", "rtl"])
  attr(:align_offset, :string, default: "0")
  attr(:side_offset, :string, default: "4")
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:inner_block, required: true, doc: "The popup's body.")

  def tooltip(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      :if={@trigger_as == "button"}
      id={Popover.trigger_id(@id)}
      data-slot={@trigger_slot}
      data-size={@trigger_data_size}
      type="button"
      variant={@trigger_variant}
      size={@trigger_size}
      class={@trigger_class}
      disabled={@disabled}
      aria-label={@trigger_label}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={close_command(@id, @hover_expanded)}
      phx-key="Escape"
      phx-hook="LiveBase.InteractionTrigger"
      data-lb-open-on-hover
      data-lb-hover-command={hover_command(@trigger_click, @disabled, @id, @hover_expanded)}
      data-lb-caller-click={caller_click?(@trigger_click, @disabled)}
      phx-click={click_command(@trigger_click, @disabled, @id, @hover_expanded)}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-trigger-disabled={flag(@disabled)}
      {@trigger_attrs}
    >
      {render_slot(@trigger)}
    </LiveShadcn.UI.Button.button>
    <span
      :if={@trigger_as == "span"}
      id={Popover.trigger_id(@id)}
      data-slot={@trigger_slot}
      class={@trigger_class}
      aria-label={@trigger_label}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={close_command(@id, @hover_expanded)}
      phx-key="Escape"
      phx-hook="LiveBase.InteractionTrigger"
      data-lb-open-on-hover
      data-lb-hover-command={hover_command(@trigger_click, @disabled, @id, @hover_expanded)}
      data-lb-caller-click={caller_click?(@trigger_click, @disabled)}
      phx-click={click_command(@trigger_click, @disabled, @id, @hover_expanded)}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-trigger-disabled={flag(@disabled)}
      {@trigger_attrs}
    >
      {render_slot(@trigger)}
    </span>
    <div
      :if={@trigger_as == "addon-wrapper"}
      id={Popover.trigger_id(@id)}
      data-slot={@trigger_slot}
      role="group"
      data-lb-input-group-addon
      data-align={@trigger_align}
      class={@trigger_class}
      aria-label={@trigger_label}
      aria-controls={Popover.popup_id(@id)}
      phx-window-keydown={close_command(@id, @hover_expanded)}
      phx-key="Escape"
      phx-hook="LiveBase.InteractionTrigger"
      data-lb-open-on-hover
      data-lb-hover-command={hover_command(@trigger_click, @disabled, @id, @hover_expanded)}
      data-lb-caller-click={caller_click?(@trigger_click, @disabled)}
      phx-click={click_command(@trigger_click, @disabled, @id, @hover_expanded)}
      phx-mounted={Popover.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-trigger-disabled={flag(@disabled)}
      {@trigger_attrs}
    >
      {render_slot(@trigger)}
    </div>
    <.portal id={@id <> "-portal"} target="body" class="contents">
      <div
        id={Popover.positioner_id(@id)}
        hidden={not @open}
        phx-click-away={close_command(@id, @hover_expanded)}
        phx-hook={Popover.hook()}
        data-lb-anchor={Popover.trigger_id(@id)}
        data-lb-side={physical_side(@side, @dir)}
        data-lb-semantic-side={@side}
        data-lb-align={@align}
        data-lb-offset={to_string(@offset)}
        data-lb-autofocus={flag(@autofocus)}
        phx-mounted={Popover.owned_attributes(:positioner)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={upstream_fact("jsx/TooltipContent/class/0")}
        dir={@dir}
        {@rest}
      >
        <div
          data-slot="tooltip-content"
          id={Popover.popup_id(@id)}
          tabindex="-1"
          hidden={not @open}
          data-lb-popup
          phx-mounted={Popover.owned_attributes(:popup)}
          data-open={flag(@open)}
          data-closed={flag(not @open)}
          class={LiveShadcn.Cn.merge([upstream_fact("jsx/TooltipContent/class/1"), @class])}
          data-lb-style-target
          data-lb-measure
        >
          {render_slot(@inner_block)}
          <div
            data-lb-arrow
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            class={upstream_fact("jsx/TooltipContent/class/2")}
            data-lb-style-target
          />
        </div>
      </div>
    </.portal>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp caller_click?(trigger_click, false) when not is_nil(trigger_click), do: ""
  defp caller_click?(_trigger_click, _disabled), do: nil

  defp hover_command(trigger_click, false, id, true) when not is_nil(trigger_click),
    do: Popover.toggle(id)

  defp hover_command(trigger_click, false, id, false) when not is_nil(trigger_click),
    do: Popover.tooltip_toggle(id)

  defp hover_command(_trigger_click, _disabled, _id, _hover_expanded), do: nil

  defp close_command(id, true), do: Popover.dismiss(id)
  defp close_command(id, false), do: Popover.tooltip_close(id)

  defp click_command(_trigger_click, true, _id, _hover_expanded), do: nil
  defp click_command(nil, false, id, true), do: Popover.toggle(id)
  defp click_command(nil, false, id, false), do: Popover.tooltip_toggle(id)
  defp click_command(trigger_click, false, _id, _hover_expanded), do: trigger_click

  defp physical_side("inline-start", _dir), do: "left"
  defp physical_side("inline-end", _dir), do: "right"
  defp physical_side(side, _dir), do: side
end
