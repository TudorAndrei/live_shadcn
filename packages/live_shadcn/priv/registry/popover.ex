defmodule LiveShadcn.UI.Popover do
  @moduledoc """
  Popover. Groups all parts of the popover.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/PopoverContent/class/0" => "isolate z-50",
    "jsx/PopoverContent/class/1" =>
      "cn-popover-content cn-popover-content-logical z-50 w-72 origin-(--transform-origin) outline-hidden",
    "jsx/PopoverDescription/class/0" => "cn-popover-description",
    "jsx/PopoverTitle/class/0" => "cn-popover-title"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Popover

  @doc """
  Groups all parts of the popover.

      <.popover id="details">
        <:trigger>Details</:trigger>
        Generated from registry/spec/accordion.json.
      </.popover>

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
  attr(:description_class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:align_offset, :string, default: "0")
  attr(:side_offset, :string, default: "4")
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:title)
  slot(:description)
  slot(:inner_block, required: true, doc: "The popup's body.")

  def popover(assigns) do
    ~H"""
    <div
      id={@id}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      class="contents"
      {@rest}
    >
      <button
        data-slot="popover-trigger"
        id={Popover.trigger_id(@id)}
        type="button"
        aria-haspopup="dialog"
        aria-expanded={to_string(@open)}
        aria-controls={Popover.popup_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-popup-open={flag(@open)}
        data-pressed={flag(@open)}
      >
        {render_slot(@trigger)}
      </button>
      <div class="contents">
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
          class={upstream_fact("jsx/PopoverContent/class/0")}
        >
          <div
            data-slot="popover-content"
            id={Popover.popup_id(@id)}
            role="dialog"
            tabindex="-1"
            hidden={not @open}
            data-lb-popup
            phx-mounted={Popover.owned_attributes(:popup)}
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            class={[
              upstream_fact("jsx/PopoverContent/class/1"),
              (@class || "")
            ]}
            data-lb-style-target
            data-lb-measure
          >
            <h2
              data-slot="popover-title"
              id={@id <> "-title"}
              class={[upstream_fact("jsx/PopoverTitle/class/0"), (@title_class || "")]}
            >
              {render_slot(@title)}
            </h2>
            <p
              data-slot="popover-description"
              id={@id <> "-description"}
              class={[upstream_fact("jsx/PopoverDescription/class/0"), (@description_class || "")]}
            >
              {render_slot(@description)}
            </p>
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