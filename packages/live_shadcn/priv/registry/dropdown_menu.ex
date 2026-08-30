defmodule LiveShadcn.UI.DropdownMenu do
  @moduledoc """
  Dropdown menu. Groups all parts of the menu.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/DropdownMenuCheckboxItem/class/0" =>
      "cn-dropdown-menu-checkbox-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/DropdownMenuCheckboxItem/class/1" =>
      "cn-dropdown-menu-item-indicator pointer-events-none",
    "jsx/DropdownMenuContent/class/0" => "isolate z-50 outline-none",
    "jsx/DropdownMenuContent/class/1" =>
      "cn-dropdown-menu-content cn-dropdown-menu-content-logical cn-menu-target cn-menu-translucent z-50 max-h-(--available-height) w-(--anchor-width) origin-(--transform-origin) overflow-x-hidden overflow-y-auto outline-none data-closed:overflow-hidden",
    "jsx/DropdownMenuItem/class/0" =>
      "cn-dropdown-menu-item group/dropdown-menu-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/DropdownMenuLabel/class/0" => "cn-dropdown-menu-label",
    "jsx/DropdownMenuRadioItem/class/0" =>
      "cn-dropdown-menu-radio-item relative flex cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/DropdownMenuRadioItem/class/1" => "cn-dropdown-menu-item-indicator pointer-events-none",
    "jsx/DropdownMenuSeparator/class/0" => "cn-dropdown-menu-separator",
    "jsx/DropdownMenuShortcut/class/0" => "cn-dropdown-menu-shortcut",
    "jsx/DropdownMenuSubContent/class/0" =>
      "cn-dropdown-menu-sub-content cn-menu-target cn-menu-translucent w-auto",
    "jsx/DropdownMenuSubTrigger/class/0" =>
      "cn-dropdown-menu-sub-trigger flex cursor-default items-center outline-hidden select-none data-popup-open:bg-accent data-popup-open:text-accent-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "jsx/DropdownMenuSubTrigger/class/1" => "cn-rtl-flip ml-auto"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Menu
  alias LiveBase.Popover
  alias LiveShadcn.UI.Button
  alias Phoenix.LiveView.JS

  @doc """
  Groups all parts of the menu.

      <.dropdown_menu id="actions">
        <:trigger>Actions</:trigger>
        <:item value="regenerate" phx-click="regenerate">Regenerate</:item>
        <:item value="verify" phx-click="verify">Verify</:item>
      </.dropdown_menu>

  The arrow keys walk the items and mark the one they arrive at. Choosing is
  a separate gesture, and only choosing closes the menu.
  """
  attr(:id, :string, required: true, doc: "Every id inside the menu derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether it starts open.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")
  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4)
  attr(:class, :any, default: nil, doc: "Appended to the menu's class string.")
  attr(:inset, :boolean, default: false, doc: "Line the text up with items that have an icon.")
  attr(:trigger_slot, :string, default: "dropdown-menu-trigger")
  attr(:popup_slot, :string, default: "dropdown-menu-content")
  attr(:item_slot, :string, default: "dropdown-menu-item")

  attr(:item_class, :any, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:portal_class, :any, default: nil)
  attr(:separator_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)

  attr(:trigger_variant, :string,
    default: nil,
    values: [nil, "default", "destructive", "outline", "secondary", "ghost", "link"]
  )

  attr(:trigger_size, :string,
    default: "default",
    values: ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"]
  )

  attr(:align_offset, :string, default: "0")
  attr(:side_offset, :string, default: "4")
  attr(:variant, :string, default: "default", values: ["default", "destructive"])
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")

  slot :item, doc: "One thing to choose. Choosing it closes the menu." do
    attr(:value, :string, required: true, doc: "Unique. The item's id derives from it.")
    attr(:disabled, :boolean, doc: "Whether it refuses to be chosen.")
    attr(:"phx-click", :any, doc: "What choosing it does, beside closing the menu.")
    attr(:"phx-value-value", :any)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:href, :string)
    attr(:target, :string)
    attr(:rel, :string)
  end

  slot :entry, doc: "A label, item, separator, or submenu, in source order." do
    attr(:kind, :string,
      required: true,
      values: ["checkbox", "label", "item", "radio-group", "separator", "submenu"]
    )

    attr(:value, :string)
    attr(:checked, :boolean)
    attr(:group, :string)
    attr(:disabled, :boolean)
    attr(:inset, :boolean)
    attr(:variant, :string, values: ["default", "destructive"])
    attr(:class, :any)
    attr(:shortcut, :string)
    attr(:items, :list, doc: "The ordered item maps inside a submenu.")
    attr(:href, :string)
    attr(:target, :string)
    attr(:rel, :string)
    attr(:"phx-click", :any)
    attr(:navigate, :string)
    attr(:patch, :string)
  end

  slot(:inner_block, doc: "Anything the items do not cover.")

  def dropdown_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class="contents"
      phx-window-keydown={close_menu(@id, @entry)}
      phx-key="Escape"
      phx-click-away={close_menu(@id, @entry)}
      {@rest}
    >
      <button
        id={Popover.trigger_id(@id)}
        type="button"
        aria-haspopup="menu"
        aria-expanded={to_string(@open)}
        aria-controls={Popover.popup_id(@id)}
        phx-click={if(not @disabled, do: Popover.toggle(@id))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-slot={@trigger_slot}
        data-popup-open={flag(@open)}
        data-pressed={flag(@open)}
        class={[trigger_classes(@trigger_variant, @trigger_size), @trigger_class]}
      >
        {render_slot(@trigger)}
      </button>
      <div class={["contents", (@class || "")]}>
        <div
          id={Popover.positioner_id(@id)}
          hidden={not @open}
          phx-hook={Popover.hook()}
          data-lb-anchor={Popover.trigger_id(@id)}
          data-lb-side={@side}
          data-lb-align={@align}
          data-lb-offset={to_string(@offset)}
          data-lb-autofocus
          phx-mounted={Popover.owned_attributes(:positioner)}
          data-open={flag(@open)}
          data-closed={flag(not @open)}
          class={upstream_fact("jsx/DropdownMenuContent/class/0")}
        >
          <div
            id={Popover.popup_id(@id)}
            role="menu"
            tabindex="-1"
            hidden={not @open}
            data-lb-popup
            phx-hook={Menu.hook()}
            data-lb-roving="menuitem"
            data-lb-orientation="vertical"
            data-lb-loop
            data-lb-highlight="data-highlighted"
            phx-mounted={Popover.owned_attributes(:popup)}
            data-slot={@popup_slot}
            data-open={flag(@open)}
            data-closed={flag(not @open)}
            data-variant={@variant}
            class={[
              upstream_fact("jsx/DropdownMenuContent/class/1"),
              (@class || "")
            ]}
            data-lb-style-target
            data-lb-measure
          >
            <%= for entry <- @entry do %>
              <div
                :if={entry[:kind] == "label"}
                data-slot="dropdown-menu-label"
                data-inset={flag(entry[:inset] == true)}
                class={[
                  upstream_fact("jsx/DropdownMenuLabel/class/0"),
                  entry[:class]
                ]}
              >
                {render_slot(entry)}
              </div>
              <div
                :if={entry[:kind] == "separator"}
                role="separator"
                data-slot="dropdown-menu-separator"
                class={[
                  upstream_fact("jsx/DropdownMenuSeparator/class/0"),
                  entry[:class]
                ]}
              >
              </div>
              <div :if={entry[:kind] == "submenu"} data-slot="dropdown-menu-sub">
                <div
                  id={Popover.trigger_id(submenu_id(@id, entry[:value]))}
                  role="menuitem"
                  tabindex="-1"
                  aria-haspopup="menu"
                  aria-expanded="false"
                  aria-controls={Popover.popup_id(submenu_id(@id, entry[:value]))}
                  phx-click={Popover.toggle(submenu_id(@id, entry[:value]))}
                  phx-mounted={Popover.owned_attributes(:trigger)}
                  data-slot="dropdown-menu-sub-trigger"
                  data-popup-open={flag(false)}
                  data-pressed={flag(false)}
                  data-inset={flag(entry[:inset] == true)}
                  class={[
                    upstream_fact("jsx/DropdownMenuSubTrigger/class/0"),
                    entry[:class]
                  ]}
                >
                  {render_slot(entry)}
                  <svg
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    aria-hidden="true"
                    class={upstream_fact("jsx/DropdownMenuSubTrigger/class/1")}
                  >
                    <path d="m9 18 6-6-6-6" />
                  </svg>
                </div>
                <div
                  id={Popover.positioner_id(submenu_id(@id, entry[:value]))}
                  hidden
                  phx-hook={Popover.hook()}
                  data-lb-anchor={Popover.trigger_id(submenu_id(@id, entry[:value]))}
                  data-lb-side="right"
                  data-lb-align="start"
                  data-lb-offset="0"
                  data-lb-align-offset="-3"
                  phx-mounted={Popover.owned_attributes(:positioner)}
                  data-closed=""
                  class={upstream_fact("jsx/DropdownMenuContent/class/0")}
                >
                  <div
                    id={Popover.popup_id(submenu_id(@id, entry[:value]))}
                    role="menu"
                    tabindex="-1"
                    hidden
                    data-lb-popup
                    data-lb-submenu
                    data-lb-parent-trigger={Popover.trigger_id(submenu_id(@id, entry[:value]))}
                    phx-hook={Menu.hook()}
                    data-lb-roving="menuitem"
                    data-lb-orientation="vertical"
                    data-lb-loop
                    data-lb-highlight="data-highlighted"
                    phx-mounted={Popover.owned_attributes(:popup)}
                    data-slot="dropdown-menu-sub-content"
                    data-closed=""
                    class={upstream_fact("jsx/DropdownMenuSubContent/class/0")}
                    data-lb-style-target
                    data-lb-measure
                  >
                    <%= for subentry <- entry[:items] || [] do %>
                      <div
                        :if={subentry[:kind] == "separator"}
                        role="separator"
                        data-slot="dropdown-menu-separator"
                        class={upstream_fact("jsx/DropdownMenuSeparator/class/0")}
                      >
                      </div>
                      <div
                        :if={subentry[:kind] != "separator"}
                        id={Menu.item_id(submenu_id(@id, entry[:value]), subentry[:value])}
                        role="menuitem"
                        tabindex="-1"
                        phx-click={
                          if(subentry[:disabled] != true,
                            do: choose(@id, @entry, subentry[:"phx-click"])
                          )
                        }
                        phx-mounted={Menu.owned_attributes(:item)}
                        data-slot="dropdown-menu-item"
                        data-disabled={flag(subentry[:disabled] == true)}
                        data-variant={subentry[:variant] || "default"}
                        class={upstream_fact("jsx/DropdownMenuItem/class/0")}
                      >
                        {subentry[:label]}
                        <span
                          :if={subentry[:shortcut]}
                          data-slot="dropdown-menu-shortcut"
                          class={upstream_fact("jsx/DropdownMenuShortcut/class/0")}
                        >
                          {subentry[:shortcut]}
                        </span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              <div
                :if={entry[:kind] == "checkbox"}
                id={Menu.item_id(@id, entry[:value])}
                role="menuitemcheckbox"
                tabindex="-1"
                aria-checked={to_string(entry[:checked] == true)}
                aria-disabled={to_string(entry[:disabled] == true)}
                phx-click={
                  if(entry[:disabled] != true,
                    do:
                      toggle_checkbox(
                        Menu.item_id(@id, entry[:value]),
                        entry[:"phx-click"]
                      )
                  )
                }
                phx-mounted={Menu.owned_attributes(:item)}
                data-slot="dropdown-menu-checkbox-item"
                data-checked={flag(entry[:checked] == true)}
                data-unchecked={flag(entry[:checked] != true)}
                data-disabled={flag(entry[:disabled] == true)}
                data-inset={flag(entry[:inset] == true)}
                class={[
                  upstream_fact("jsx/DropdownMenuCheckboxItem/class/0"),
                  entry[:class]
                ]}
              >
                <span
                  hidden={entry[:checked] != true}
                  data-slot="dropdown-menu-checkbox-item-indicator"
                  data-checked={flag(entry[:checked] == true)}
                  data-unchecked={flag(entry[:checked] != true)}
                  class={upstream_fact("jsx/DropdownMenuCheckboxItem/class/1")}
                >
                  <LiveShadcn.Icon.icon name="check" />
                </span>
                {render_slot(entry)}
                <span
                  :if={entry[:shortcut]}
                  data-slot="dropdown-menu-shortcut"
                  class={upstream_fact("jsx/DropdownMenuShortcut/class/0")}
                >
                  {entry[:shortcut]}
                </span>
              </div>
              <div
                :if={entry[:kind] == "radio-group"}
                id={radio_group_id(@id, entry[:group])}
                role="group"
                data-slot="dropdown-menu-radio-group"
              >
                <div
                  :for={radio <- entry[:items] || []}
                  id={Menu.item_id(@id, radio[:value])}
                  role="menuitemradio"
                  tabindex="-1"
                  aria-checked={to_string(entry[:value] == radio[:value])}
                  aria-disabled={to_string(radio[:disabled] == true)}
                  phx-click={
                    if(radio[:disabled] != true,
                      do:
                        select_radio(
                          radio_group_id(@id, entry[:group]),
                          Menu.item_id(@id, radio[:value]),
                          radio[:"phx-click"] || entry[:"phx-click"]
                        )
                    )
                  }
                  phx-mounted={Menu.owned_attributes(:item)}
                  data-slot="dropdown-menu-radio-item"
                  data-checked={flag(entry[:value] == radio[:value])}
                  data-unchecked={flag(entry[:value] != radio[:value])}
                  data-disabled={flag(radio[:disabled] == true)}
                  data-inset={flag(radio[:inset] == true)}
                  class={[
                    upstream_fact("jsx/DropdownMenuRadioItem/class/0"),
                    radio[:class]
                  ]}
                >
                  <span
                    hidden={entry[:value] != radio[:value]}
                    data-slot="dropdown-menu-radio-item-indicator"
                    data-checked={flag(entry[:value] == radio[:value])}
                    data-unchecked={flag(entry[:value] != radio[:value])}
                    class={upstream_fact("jsx/DropdownMenuRadioItem/class/1")}
                  >
                    <LiveShadcn.Icon.icon name="check" />
                  </span>
                  {radio[:label]}
                  <span
                    :if={radio[:shortcut]}
                    data-slot="dropdown-menu-shortcut"
                    class={upstream_fact("jsx/DropdownMenuShortcut/class/0")}
                  >
                    {radio[:shortcut]}
                  </span>
                </div>
              </div>
              <a
                :if={entry[:kind] == "item" and entry[:href]}
                id={Menu.item_id(@id, entry[:value])}
                role="menuitem"
                tabindex="-1"
                href={entry[:href]}
                target={entry[:target]}
                rel={entry[:rel]}
                phx-click={
                  if(entry[:disabled] != true,
                    do: choose(@id, @entry, entry[:"phx-click"])
                  )
                }
                phx-mounted={Menu.owned_attributes(:item)}
                data-slot="dropdown-menu-item"
                data-disabled={flag(entry[:disabled] == true)}
                data-variant={entry[:variant] || "default"}
                data-inset={flag(entry[:inset] == true)}
                class={[
                  upstream_fact("jsx/DropdownMenuItem/class/0"),
                  entry[:class]
                ]}
              >
                {render_slot(entry)}
                <span
                  :if={entry[:shortcut]}
                  data-slot="dropdown-menu-shortcut"
                  class={upstream_fact("jsx/DropdownMenuShortcut/class/0")}
                >
                  {entry[:shortcut]}
                </span>
              </a>
              <div
                :if={entry[:kind] == "item" and !entry[:href]}
                id={Menu.item_id(@id, entry[:value])}
                role="menuitem"
                tabindex="-1"
                phx-click={
                  if(entry[:disabled] != true,
                    do: choose(@id, @entry, entry[:"phx-click"])
                  )
                }
                phx-mounted={Menu.owned_attributes(:item)}
                {Map.take(entry, [:navigate, :patch])}
                data-slot="dropdown-menu-item"
                data-disabled={flag(entry[:disabled] == true)}
                data-variant={entry[:variant] || "default"}
                data-inset={flag(entry[:inset] == true)}
                class={[
                  upstream_fact("jsx/DropdownMenuItem/class/0"),
                  entry[:class]
                ]}
              >
                {render_slot(entry)}
                <span
                  :if={entry[:shortcut]}
                  data-slot="dropdown-menu-shortcut"
                  class={upstream_fact("jsx/DropdownMenuShortcut/class/0")}
                >
                  {entry[:shortcut]}
                </span>
              </div>
            <% end %>
            <a
              :for={item <- @item}
              :if={item[:href]}
              id={Menu.item_id(@id, item[:value])}
              role="menuitem"
              tabindex="-1"
              href={item[:href]}
              target={item[:target]}
              rel={item[:rel]}
              phx-click={
                if(item[:disabled] != true, do: choose(@id, @entry, item[:"phx-click"]))
              }
              phx-mounted={Menu.owned_attributes(:item)}
              data-slot={@item_slot}
              data-disabled={flag(item[:disabled] == true)}
              data-variant={@variant}
              data-inset={flag(@inset)}
              class={[
                upstream_fact("jsx/DropdownMenuItem/class/0"),
                (@item_class || "")
              ]}
            >
              {render_slot(item)}
            </a>
            <div
              :for={item <- @item}
              :if={!item[:href]}
              id={Menu.item_id(@id, item[:value])}
              role="menuitem"
              tabindex="-1"
              phx-click={
                if(item[:disabled] != true, do: choose(@id, @entry, item[:"phx-click"]))
              }
              phx-mounted={Menu.owned_attributes(:item)}
              {Map.take(item, [:"phx-value-value", :navigate, :patch])}
              data-slot={@item_slot}
              data-disabled={flag(item[:disabled] == true)}
              data-variant={@variant}
              data-inset={flag(@inset)}
              class={[
                upstream_fact("jsx/DropdownMenuItem/class/0"),
                (@item_class || "")
              ]}
            >
              {render_slot(item)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp submenu_id(menu, value), do: "#{menu}-#{value}"
  defp radio_group_id(menu, group), do: "#{menu}-#{group || "radio"}-group"

  defp toggle_checkbox(item, command) do
    control = "##{item}"
    indicator = "#{control} [data-slot='dropdown-menu-checkbox-item-indicator']"

    %JS{}
    |> JS.toggle_attribute({"aria-checked", "true", "false"}, to: control)
    |> JS.toggle_attribute({"data-checked", ""}, to: control)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: control)
    |> JS.toggle_attribute({"hidden", ""}, to: indicator)
    |> JS.toggle_attribute({"data-checked", ""}, to: indicator)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: indicator)
    |> append_command(command)
  end

  defp select_radio(group, item, command) do
    control = "##{item}"
    others = "##{group} [role='menuitemradio']:not(#{control})"
    control_indicator = "#{control} [data-slot='dropdown-menu-radio-item-indicator']"
    other_indicators = "#{others} [data-slot='dropdown-menu-radio-item-indicator']"

    %JS{}
    |> JS.set_attribute({"aria-checked", "false"}, to: others)
    |> JS.remove_attribute("data-checked", to: others)
    |> JS.set_attribute({"data-unchecked", ""}, to: others)
    |> JS.set_attribute({"hidden", ""}, to: other_indicators)
    |> JS.remove_attribute("data-checked", to: other_indicators)
    |> JS.set_attribute({"data-unchecked", ""}, to: other_indicators)
    |> JS.set_attribute({"aria-checked", "true"}, to: control)
    |> JS.set_attribute({"data-checked", ""}, to: control)
    |> JS.remove_attribute("data-unchecked", to: control)
    |> JS.remove_attribute("hidden", to: control_indicator)
    |> JS.set_attribute({"data-checked", ""}, to: control_indicator)
    |> JS.remove_attribute("data-unchecked", to: control_indicator)
    |> append_command(command)
  end

  defp append_command(js, nil), do: js
  defp append_command(js, name) when is_binary(name), do: JS.push(js, name)
  defp append_command(%JS{ops: ours}, %JS{ops: theirs}), do: %JS{ops: ours ++ theirs}

  defp close_menu(menu, entries) do
    close_submenus(Popover.close(menu), menu, entries)
  end

  defp choose(menu, entries, command) do
    close_submenus(Menu.choose(menu, command), menu, entries)
  end

  defp close_submenus(js, menu, entries) do
    entries
    |> Enum.filter(&(&1[:kind] == "submenu"))
    |> Enum.reduce(js, fn entry, commands ->
      Popover.close(commands, submenu_id(menu, entry[:value]))
    end)
  end

  defp trigger_classes(nil, _size), do: []

  defp trigger_classes(variant, size) do
    [
      Button.variant_class("buttonVariants", "size", size),
      Button.variant_class("buttonVariants", "variant", variant),
      Button.part_class("button")
    ]
  end
end
