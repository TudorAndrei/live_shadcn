defmodule LiveShadcn.UI.Menubar do
  @moduledoc """
  Menubar. The container for menus.

  Upstream exports 13 more parts, each a thin
  wrapper around a part of `<.dropdown_menu>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Menubar/class/0" => "cn-menubar flex items-center",
    "jsx/MenubarCheckboxItem/class/0" =>
      "cn-menubar-checkbox-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/MenubarCheckboxItem/class/1" =>
      "cn-menubar-checkbox-item-indicator pointer-events-none absolute flex items-center justify-center",
    "jsx/MenubarContent/class/0" =>
      "cn-menubar-content cn-menubar-content-logical cn-menu-target cn-menu-translucent",
    "jsx/MenubarItem/class/0" => "cn-menubar-item group/menubar-item",
    "jsx/MenubarLabel/class/0" => "cn-menubar-label",
    "jsx/MenubarRadioItem/class/0" =>
      "cn-menubar-radio-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/MenubarRadioItem/class/1" =>
      "cn-menubar-radio-item-indicator pointer-events-none absolute flex items-center justify-center",
    "jsx/MenubarSeparator/class/0" => "cn-menubar-separator -mx-1 my-1 h-px",
    "jsx/MenubarShortcut/class/0" => "cn-menubar-shortcut ml-auto",
    "jsx/MenubarSubContent/class/0" =>
      "cn-menubar-sub-content cn-menu-target cn-menu-translucent",
    "jsx/MenubarSubTrigger/class/0" => "cn-menubar-sub-trigger",
    "jsx/MenubarTrigger/class/0" =>
      "cn-menubar-trigger flex items-center outline-hidden select-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Menubar
  alias LiveShadcn.UI.DropdownMenu

  @menu_parts %{
    group_slot: "menubar-group",
    item_slot: "menubar-item",
    item_class:
      "cn-dropdown-menu-item group/dropdown-menu-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 " <> @upstream_facts["jsx/MenubarItem/class/0"],
    checkbox_item_slot: "menubar-checkbox-item",
    checkbox_item_class: @upstream_facts["jsx/MenubarCheckboxItem/class/0"],
    checkbox_indicator_slot: nil,
    checkbox_indicator_class: @upstream_facts["jsx/MenubarCheckboxItem/class/1"],
    radio_group_slot: "menubar-radio-group",
    radio_item_slot: "menubar-radio-item",
    radio_item_class: @upstream_facts["jsx/MenubarRadioItem/class/0"],
    radio_indicator_slot: nil,
    radio_indicator_class: @upstream_facts["jsx/MenubarRadioItem/class/1"],
    label_slot: "menubar-label",
    label_class: "cn-dropdown-menu-label " <> @upstream_facts["jsx/MenubarLabel/class/0"],
    separator_slot: "menubar-separator",
    separator_class: "cn-dropdown-menu-separator " <> @upstream_facts["jsx/MenubarSeparator/class/0"],
    shortcut_slot: "menubar-shortcut",
    shortcut_class: "cn-dropdown-menu-shortcut " <> @upstream_facts["jsx/MenubarShortcut/class/0"],
    sub_trigger_slot: "menubar-sub-trigger",
    sub_trigger_class: @upstream_facts["jsx/MenubarSubTrigger/class/0"],
    sub_content_slot: "menubar-sub-content",
    sub_content_class: @upstream_facts["jsx/MenubarSubContent/class/0"]
  }

  @doc "The `menubar` part."

  attr(:id, :string, default: nil, doc: "Required when keyboard navigation is active.")
  attr(:dir, :string, default: nil, values: [nil, "ltr", "rtl"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def menubar(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot={@rest[:"data-slot"] || "menubar"}
      role="menubar"
      aria-orientation="horizontal"
      dir={@dir}
      phx-hook={if(@id, do: Menubar.hook())}
      class={[upstream_fact("jsx/Menubar/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "One menu in the menubar, rendered through the shared dropdown-menu behavior."
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:class, :any, default: nil)
  attr(:grouped, :boolean, default: false)
  attr(:tabindex, :integer, default: nil)
  attr(:content_attrs, :map, default: %{})

  slot(:trigger, required: true)

  slot :entry do
    attr(:kind, :string,
      required: true,
      values: ["checkbox", "label", "item", "radio-group", "separator", "submenu"]
    )

    attr(:value, :string)
    attr(:checked, :boolean)
    attr(:group, :string)
    attr(:section, :string)
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

  def menubar_menu(assigns) do
    assigns =
      assigns
      |> assign(
        :trigger_attrs,
        if(assigns.tabindex, do: %{tabindex: assigns.tabindex}, else: %{})
      )
      |> assign(:menu_parts, @menu_parts)

    ~H"""
    <DropdownMenu.dropdown_menu
      id={@id}
      open={@open}
      disabled={@disabled}
      align={@align}
      align_offset="-4"
      side_offset="8"
      grouped={@grouped}
      trigger_slot="menubar-trigger"
      popup_slot="menubar-content"
      item_slot="menubar-item"
      trigger_class={upstream_fact("jsx/MenubarTrigger/class/0")}
      class={[
        upstream_fact("jsx/MenubarContent/class/0"),
        @class
      ]}
      item_class={upstream_fact("jsx/MenubarItem/class/0")}
      trigger_attrs={@trigger_attrs}
      content_attrs={@content_attrs}
      parts={@menu_parts}
    >
      <:trigger>{render_slot(@trigger)}</:trigger>
      <:entry
        :for={entry <- @entry}
        kind={entry[:kind]}
        value={entry[:value]}
        checked={entry[:checked]}
        group={entry[:group]}
        section={entry[:section]}
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
    </DropdownMenu.dropdown_menu>
    """
  end

  @doc "The `menubar-checkbox-item` part."
  attr(:checked, :string, default: nil)
  attr(:inset, :boolean, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def menubar_checkbox_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "menubar-checkbox-item"}
      data-inset={@inset}
      checked={@checked}
      class={[
        upstream_fact("jsx/MenubarCheckboxItem/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <span class={upstream_fact("jsx/MenubarCheckboxItem/class/1")}>
        <span>
          <LiveShadcn.Icon.icon name="check" />
        </span>
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `menubar-radio-item` part."
  attr(:inset, :boolean, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def menubar_radio_item(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "menubar-radio-item"}
      data-inset={@inset}
      class={[
        upstream_fact("jsx/MenubarRadioItem/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <span class={upstream_fact("jsx/MenubarRadioItem/class/1")}>
        <span>
          <LiveShadcn.Icon.icon name="check" />
        </span>
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
