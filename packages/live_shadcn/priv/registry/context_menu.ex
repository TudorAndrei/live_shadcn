defmodule LiveShadcn.UI.ContextMenu do
  @moduledoc """
  Context menu. A menu that opens at a right-click or long-press position.

  The component uses the shared dropdown-menu renderer. Context Menu supplies
  its own trigger gesture, slots, and upstream classes.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ContextMenuCheckboxItem/class/0" =>
      "cn-context-menu-checkbox-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/ContextMenuCheckboxItem/class/1" => "cn-context-menu-item-indicator pointer-events-none",
    "jsx/ContextMenuContent/class/0" => "isolate z-50 outline-none",
    "jsx/ContextMenuContent/class/1" =>
      "cn-context-menu-content cn-context-menu-content-logical cn-menu-target cn-menu-translucent z-50 max-h-(--available-height) origin-(--transform-origin) overflow-x-hidden overflow-y-auto outline-none",
    "jsx/ContextMenuItem/class/0" =>
      "cn-context-menu-item group/context-menu-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/ContextMenuLabel/class/0" => "cn-context-menu-label",
    "jsx/ContextMenuRadioItem/class/0" =>
      "cn-context-menu-radio-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/ContextMenuRadioItem/class/1" => "cn-context-menu-item-indicator pointer-events-none",
    "jsx/ContextMenuSeparator/class/0" => "cn-context-menu-separator",
    "jsx/ContextMenuShortcut/class/0" => "cn-context-menu-shortcut",
    "jsx/ContextMenuSubContent/class/0" =>
      "cn-context-menu-subcontent cn-menu-target cn-menu-translucent",
    "jsx/ContextMenuSubTrigger/class/0" =>
      "cn-context-menu-sub-trigger flex cursor-default items-center outline-hidden select-none [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/ContextMenuSubTrigger/class/1" => "cn-rtl-flip ml-auto",
    "jsx/ContextMenuTrigger/class/0" => "cn-context-menu-trigger select-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveShadcn.UI.DropdownMenu

  @menu_parts %{
    group_slot: "context-menu-group",
    content_class: @upstream_facts["jsx/ContextMenuContent/class/1"],
    item_slot: "context-menu-item",
    item_class: @upstream_facts["jsx/ContextMenuItem/class/0"],
    checkbox_item_slot: "context-menu-checkbox-item",
    checkbox_item_class: @upstream_facts["jsx/ContextMenuCheckboxItem/class/0"],
    checkbox_indicator_slot: nil,
    checkbox_indicator_class: @upstream_facts["jsx/ContextMenuCheckboxItem/class/1"],
    checkbox_indicator_selector: ".cn-context-menu-item-indicator",
    radio_group_slot: "context-menu-radio-group",
    radio_item_slot: "context-menu-radio-item",
    radio_item_class: @upstream_facts["jsx/ContextMenuRadioItem/class/0"],
    radio_indicator_slot: nil,
    radio_indicator_class: @upstream_facts["jsx/ContextMenuRadioItem/class/1"],
    radio_indicator_selector: ".cn-context-menu-item-indicator",
    label_slot: "context-menu-label",
    label_class: @upstream_facts["jsx/ContextMenuLabel/class/0"],
    separator_slot: "context-menu-separator",
    separator_class: @upstream_facts["jsx/ContextMenuSeparator/class/0"],
    shortcut_slot: "context-menu-shortcut",
    shortcut_class: @upstream_facts["jsx/ContextMenuShortcut/class/0"],
    sub_trigger_slot: "context-menu-sub-trigger",
    sub_trigger_base_class: @upstream_facts["jsx/ContextMenuSubTrigger/class/0"],
    sub_content_slot: "context-menu-sub-content",
    sub_content_base_class: @upstream_facts["jsx/ContextMenuSubContent/class/0"]
  }

  @doc """
  A menu that opens at the pointer position after a context gesture.

      <.context_menu id="actions">
        <:trigger>Right click here</:trigger>
        <:entry kind="item" value="copy">Copy</:entry>
        <:entry kind="item" value="delete" variant="destructive">Delete</:entry>
      </.context_menu>
  """
  attr(:id, :string, required: true, doc: "Every id inside the menu derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether the menu starts open.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")
  attr(:side, :string, default: "right", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:align_offset, :string, default: "4")
  attr(:side_offset, :string, default: "0")
  attr(:class, :any, default: nil, doc: "Appended to the menu content class.")
  attr(:trigger_class, :any, default: nil, doc: "Appended to the trigger class.")
  attr(:item_class, :any, default: nil)
  attr(:inset, :boolean, default: false)
  attr(:variant, :string, default: "default", values: ["default", "destructive"])
  attr(:grouped, :boolean, default: true)
  attr(:trigger_attrs, :map, default: %{})
  attr(:content_attrs, :map, default: %{})
  attr(:rest, :global)

  slot(:trigger, required: true)

  slot :item do
    attr(:value, :string, required: true)
    attr(:disabled, :boolean)
    attr(:href, :string)
    attr(:target, :string)
    attr(:rel, :string)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:"phx-click", :any)
    attr(:"phx-value-value", :any)
  end

  slot :entry do
    attr(:kind, :string,
      required: true,
      values: ["checkbox", "label", "item", "radio-group", "separator", "submenu"]
    )

    attr(:value, :string)
    attr(:checked, :boolean)

    attr(:controlled, :boolean,
      doc: "The caller owns checked or value. Run its click command without a client state change."
    )

    attr(:group, :string)
    attr(:label, :string)
    attr(:section, :string)
    attr(:grouped, :boolean)
    attr(:disabled, :boolean)
    attr(:inset, :boolean)
    attr(:variant, :string, values: ["default", "destructive"])
    attr(:class, :any)
    attr(:shortcut, :string)
    attr(:items, :list)
    attr(:content_attrs, :map)
    attr(:href, :string)
    attr(:target, :string)
    attr(:rel, :string)
    attr(:"phx-click", :any)
    attr(:navigate, :string)
    attr(:patch, :string)
  end

  slot(:inner_block)

  def context_menu(assigns) do
    assigns = assign(assigns, :menu_parts, @menu_parts)

    ~H"""
    <DropdownMenu.dropdown_menu
      id={@id}
      open={@open}
      disabled={@disabled}
      context
      side={@side}
      align={@align}
      align_offset={@align_offset}
      side_offset={@side_offset}
      grouped={@grouped}
      trigger_slot="context-menu-trigger"
      popup_slot="context-menu-content"
      item_slot="context-menu-item"
      trigger_class={[
        upstream_fact("jsx/ContextMenuTrigger/class/0"),
        @trigger_class
      ]}
      class={@class}
      item_class={@item_class}
      inset={@inset}
      variant={@variant}
      trigger_attrs={@trigger_attrs}
      content_attrs={@content_attrs}
      parts={@menu_parts}
      {@rest}
    >
      <:trigger>{render_slot(@trigger)}</:trigger>
      <:item
        :for={item <- @item}
        value={item[:value]}
        disabled={item[:disabled]}
        href={item[:href]}
        target={item[:target]}
        rel={item[:rel]}
        navigate={item[:navigate]}
        patch={item[:patch]}
        phx-click={item[:"phx-click"]}
        phx-value-value={item[:"phx-value-value"]}
      >
        {render_slot(item)}
      </:item>
      <:entry
        :for={entry <- @entry}
        kind={entry[:kind]}
        value={entry[:value]}
        checked={entry[:checked]}
        controlled={entry[:controlled]}
        group={entry[:group]}
        label={entry[:label]}
        section={entry[:section]}
        grouped={entry[:grouped]}
        disabled={entry[:disabled]}
        inset={entry[:inset]}
        variant={entry[:variant]}
        class={entry[:class]}
        shortcut={entry[:shortcut]}
        items={entry[:items]}
        content_attrs={entry[:content_attrs]}
        href={entry[:href]}
        target={entry[:target]}
        rel={entry[:rel]}
        phx-click={entry[:"phx-click"]}
        navigate={entry[:navigate]}
        patch={entry[:patch]}
      >
        {render_slot(entry)}
      </:entry>
      {render_slot(@inner_block)}
    </DropdownMenu.dropdown_menu>
    """
  end
end
