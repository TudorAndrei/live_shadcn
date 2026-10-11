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
    "jsx/PopoverHeader/class/0" => "cn-popover-header",
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
    values: ["top", "right", "bottom", "left", "inline-start", "inline-end"],
    doc: "The side asked for. Where it lands is what `data-side` reports."
  )

  attr(:align, :string, default: "center", values: ["start", "center", "end"])
  attr(:side_offset, :integer, default: 4, doc: "The gap between the trigger and the popup.")
  attr(:align_offset, :integer, default: 0)

  attr(:autofocus, :boolean,
    default: true,
    doc: "Whether opening moves the focus into the popup. False for a tooltip."
  )

  attr(:return_focus_to_trigger, :boolean,
    default: false,
    doc: "Whether closing returns focus to the trigger instead of the opener."
  )

  attr(:class, :any, default: nil, doc: "Appended to the popup's class string.")
  attr(:description_class, :any, default: nil)
  attr(:header_class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_label, :string, default: nil, doc: "The accessible name for an icon trigger.")
  attr(:trigger_slot, :string, default: "popover-trigger")
  attr(:trigger_variant, :string, default: "outline")
  attr(:trigger_size, :string, default: "default")
  attr(:trigger_dir, :string, default: nil, values: [nil, "ltr", "rtl"])

  attr(:trigger_component, :string,
    default: "button",
    values: ["button", "input-group-button"],
    doc: "The component that renders the trigger element."
  )

  attr(:trigger_target, :string,
    default: "button",
    values: ["button", "wrapper", "direct"],
    doc:
      "Whether the popover attributes belong to its button, a fixed caller wrapper, or a direct button."
  )

  attr(:trigger_wrapper_class, :any, default: nil)
  attr(:trigger_wrapper_slot, :string, default: nil)
  attr(:trigger_wrapper_align, :string, default: nil)

  attr(:trigger_data_size, :string,
    default: nil,
    doc: "An optional `data-size` value for a composed trigger."
  )

  attr(:trigger_rest, :map, default: %{}, doc: "Additional attributes for the interactive trigger.")

  attr(:dir, :string, default: "ltr", values: ["ltr", "rtl"])
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:title)
  slot(:description)
  slot(:inner_block, required: true, doc: "The popup's body.")

  def popover(assigns) do
    ~H"""
    <div
      :if={@trigger_target != "direct"}
      id={@id}
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
      class="contents"
    >
      <%= if @trigger_target == "wrapper" do %>
        <div
          id={Popover.trigger_id(@id)}
          data-slot={@trigger_wrapper_slot}
          role="group"
          tabindex={if(@disabled, do: "-1", else: "0")}
          aria-disabled={if(@disabled, do: "true")}
          data-lb-input-group-addon
          data-align={@trigger_wrapper_align}
          class={@trigger_wrapper_class}
          aria-label={@trigger_label}
          aria-haspopup="dialog"
          aria-expanded={to_string(@open)}
          aria-controls={Popover.popup_id(@id)}
          phx-click={if(not @disabled, do: Popover.toggle(@id))}
          phx-mounted={Popover.owned_attributes(:trigger)}
          data-popup-open={flag(@open)}
          data-pressed={flag(@open)}
        >
          <LiveShadcn.UI.Button.button
            data-slot={@trigger_slot}
          data-size={@trigger_data_size}
          {@trigger_rest}
          type="button"
          dir={@trigger_dir}
          variant={@trigger_variant}
            size={@trigger_size}
            class={@trigger_class}
            disabled={@disabled}
          >
            {render_slot(@trigger)}
          </LiveShadcn.UI.Button.button>
        </div>
      <% else %>
        <LiveShadcn.UI.Button.button
          data-slot={@trigger_slot}
          data-size={@trigger_data_size}
          {@trigger_rest}
          id={Popover.trigger_id(@id)}
          type="button"
          dir={@trigger_dir}
          variant={@trigger_variant}
          size={@trigger_size}
          class={@trigger_class}
          disabled={@disabled}
          aria-label={@trigger_label}
          aria-haspopup="dialog"
          aria-expanded={to_string(@open)}
          aria-controls={Popover.popup_id(@id)}
          phx-click={if(not @disabled, do: Popover.toggle(@id))}
          phx-mounted={Popover.owned_attributes(:trigger)}
          data-popup-open={flag(@open)}
          data-pressed={flag(@open)}
        >
          {render_slot(@trigger)}
        </LiveShadcn.UI.Button.button>
      <% end %>
    </div>
    <%= if @trigger_target == "direct" and @trigger_component == "input-group-button" do %>
      <LiveShadcn.UI.InputGroup.input_group_button
        data-slot={@trigger_slot}
        id={Popover.trigger_id(@id)}
        type="button"
        dir={@trigger_dir}
        size={@trigger_size}
        variant={@trigger_variant}
        class={@trigger_class}
        disabled={@disabled}
        aria-label={@trigger_label}
        aria-haspopup="dialog"
        aria-expanded={to_string(@open)}
        aria-controls={Popover.popup_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-popup-open={flag(@open)}
        data-pressed={flag(@open)}
        {@trigger_rest}
      >
        {render_slot(@trigger)}
      </LiveShadcn.UI.InputGroup.input_group_button>
    <% else %>
      <LiveShadcn.UI.Button.button
        :if={@trigger_target == "direct"}
        data-slot={@trigger_slot}
        data-size={@trigger_data_size}
        {@trigger_rest}
        id={Popover.trigger_id(@id)}
        type="button"
        dir={@trigger_dir}
        variant={@trigger_variant}
        size={@trigger_size}
        class={@trigger_class}
        disabled={@disabled}
        aria-label={@trigger_label}
        aria-haspopup="dialog"
        aria-expanded={to_string(@open)}
        aria-controls={Popover.popup_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-popup-open={flag(@open)}
        data-pressed={flag(@open)}
      >
        {render_slot(@trigger)}
      </LiveShadcn.UI.Button.button>
    <% end %>
    <.portal id={@id <> "-portal"} target="body" class="contents">
      <div
        id={Popover.positioner_id(@id)}
        hidden={not @open}
        phx-hook={Popover.hook()}
        phx-click-away={if(@trigger_target == "direct", do: Popover.dismiss(@id))}
        phx-window-keydown={if(@trigger_target == "direct", do: Popover.close(@id))}
        phx-key={if(@trigger_target == "direct", do: "Escape")}
        data-lb-anchor={Popover.trigger_id(@id)}
        data-lb-dismiss-owner={if(@trigger_target != "direct", do: @id)}
        data-lb-side={physical_side(@side, @dir)}
        data-lb-semantic-side={@side}
        data-lb-align={@align}
        data-lb-offset={to_string(@side_offset)}
        data-lb-align-offset={to_string(@align_offset)}
        data-lb-autofocus={flag(@autofocus)}
        data-lb-return-focus-to-trigger={flag(@return_focus_to_trigger)}
        data-lb-return-focus-to-wrapper={flag(@trigger_target == "wrapper")}
        phx-mounted={Popover.owned_attributes(:positioner)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={upstream_fact("jsx/PopoverContent/class/0")}
      >
          <div
            data-slot="popover-content"
            id={Popover.popup_id(@id)}
            role="dialog"
            aria-labelledby={if(@title != [], do: @id <> "-title")}
            aria-describedby={if(@description != [], do: @id <> "-description")}
            tabindex="-1"
            hidden={not @open}
            data-lb-popup
            phx-mounted={Popover.owned_attributes(:popup)}
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            class={LiveShadcn.Cn.merge([upstream_fact("jsx/PopoverContent/class/1"), @class])}
            data-lb-style-target
            data-lb-measure
            dir={@dir}
            {@rest}
          >
            <div
              :if={@title != [] or @description != []}
              data-slot="popover-header"
              class={LiveShadcn.Cn.merge([upstream_fact("jsx/PopoverHeader/class/0"), @header_class])}
            >
              <h2
                :if={@title != []}
                data-slot="popover-title"
                id={@id <> "-title"}
                class={LiveShadcn.Cn.merge([upstream_fact("jsx/PopoverTitle/class/0"), @title_class])}
              >
                {render_slot(@title)}
              </h2>
              <p
                :if={@description != []}
                data-slot="popover-description"
                id={@id <> "-description"}
                class={
                  LiveShadcn.Cn.merge([
                    upstream_fact("jsx/PopoverDescription/class/0"),
                    @description_class
                  ])
                }
              >
                {render_slot(@description)}
              </p>
            </div>
            {render_slot(@inner_block)}
          </div>
        </div>
      </.portal>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp physical_side("inline-start", _dir), do: "left"
  defp physical_side("inline-end", _dir), do: "right"
  defp physical_side(side, _dir), do: side
end
