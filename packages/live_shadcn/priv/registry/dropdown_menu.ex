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

  attr(:context, :boolean,
    default: false,
    doc: "Whether a context gesture, instead of a normal button click, opens the menu."
  )

  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 4)
  attr(:class, :any, default: nil, doc: "Appended to the menu's class string.")

  attr(:grouped, :boolean,
    default: false,
    doc: "Whether each section between separators is an upstream menu group."
  )

  attr(:inset, :boolean, default: false, doc: "Line the text up with items that have an icon.")
  attr(:trigger_slot, :string, default: "dropdown-menu-trigger")

  attr(:direct_trigger, :boolean,
    default: false,
    doc: "Whether the built-in trigger is emitted without the menu root wrapper."
  )

  attr(:transient_controls, :boolean,
    default: false,
    doc: "Whether aria-controls is present only while the menu is open."
  )

  attr(:return_focus, :boolean,
    default: true,
    doc: "Whether closing returns focus to the opener."
  )

  attr(:popup_slot, :string, default: "dropdown-menu-content")
  attr(:item_slot, :string, default: "dropdown-menu-item")
  attr(:parts, :map, default: %{}, doc: "Part slots and classes changed by a composed menu.")

  attr(:item_class, :any, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:portal_class, :any, default: nil)
  attr(:separator_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_attrs, :map, default: %{}, doc: "Attributes merged onto the trigger button.")

  attr(:content_attrs, :map,
    default: %{},
    doc: "Attributes merged onto the portalled menu content."
  )

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
    attr(:label, :string, doc: "An optional label rendered inside a radio group.")
    attr(:section, :string, doc: "Entries with the same section share one menu group.")
    attr(:grouped, :boolean, doc: "Whether this submenu groups entries between separators.")
    attr(:disabled, :boolean)
    attr(:inset, :boolean)
    attr(:variant, :string, values: ["default", "destructive"])
    attr(:class, :any)
    attr(:shortcut, :string)
    attr(:items, :list, doc: "The ordered item maps inside a submenu.")
    attr(:content_attrs, :map, doc: "Attributes merged onto submenu content.")
    attr(:href, :string)
    attr(:target, :string)
    attr(:rel, :string)
    attr(:clipboard, :string, doc: "Text copied by the client when the item is selected.")
    attr(:"phx-click", :any)
    attr(:navigate, :string)
    attr(:patch, :string)
  end

  slot(:inner_block, doc: "Anything the items do not cover.")

  def dropdown_menu(assigns) do
    ~H"""
    <div
      :if={not @direct_trigger}
      id={@id}
      data-slot={part(@parts, :root_slot, nil)}
      class="contents"
      phx-window-keydown={close_menu(@id, @entry, @transient_controls)}
      phx-key="Escape"
      {@rest}
    >
      <%= if @context do %>
        <div
          id={Popover.trigger_id(@id)}
          aria-controls={controls(@id, @open, @transient_controls)}
          aria-disabled={if(@disabled, do: "true")}
          phx-hook="LiveBase.InteractionTrigger"
          data-lb-open-on-context
          data-lb-positioner={Popover.positioner_id(@id)}
          phx-click={if(not @disabled, do: toggle_menu(@id, @transient_controls))}
          phx-mounted={Popover.owned_attributes(:trigger)}
          data-slot={@trigger_slot}
          data-popup-open={flag(@open)}
          data-pressed={flag(@open)}
          data-disabled={flag(@disabled)}
          class={[@trigger_class]}
          {@trigger_attrs}
        >
          {render_slot(@trigger)}
        </div>
      <% else %>
        <button
          id={Popover.trigger_id(@id)}
          type="button"
          disabled={@disabled}
          role={if(@trigger_slot == "menubar-trigger", do: "menuitem")}
          aria-disabled={if(@trigger_slot == "menubar-trigger", do: to_string(@disabled))}
          aria-haspopup="menu"
          aria-expanded={to_string(@open)}
          aria-controls={controls(@id, @open, @transient_controls)}
          phx-click={if(not @disabled, do: toggle_menu(@id, @transient_controls))}
          phx-mounted={Popover.owned_attributes(:trigger)}
          data-slot={@trigger_slot}
          data-popup-open={flag(@open)}
          class={
            LiveShadcn.Cn.merge([
              trigger_classes(@trigger_variant, @trigger_size),
              @trigger_class
            ])
          }
          {@trigger_attrs}
        >
          {render_slot(@trigger)}
        </button>
      <% end %>
    </div>
    <%= if @direct_trigger do %>
      <button
        id={Popover.trigger_id(@id)}
        type="button"
        disabled={@disabled}
        role={if(@trigger_slot == "menubar-trigger", do: "menuitem")}
        aria-disabled={if(@trigger_slot == "menubar-trigger", do: to_string(@disabled))}
        aria-haspopup="menu"
        aria-expanded={to_string(@open)}
        aria-controls={controls(@id, @open, @transient_controls)}
        phx-click={if(not @disabled, do: toggle_menu(@id, @transient_controls))}
        phx-mounted={Popover.owned_attributes(:trigger)}
        data-slot={@trigger_slot}
        data-popup-open={flag(@open)}
        class={
          LiveShadcn.Cn.merge([
            trigger_classes(@trigger_variant, @trigger_size),
            @trigger_class
          ])
        }
        {@trigger_attrs}
      >
        {render_slot(@trigger)}
      </button>
    <% end %>
    <.portal id={"#{@id}-portal"} target="body" class={["contents", @portal_class]}>
      <div
        id={Popover.positioner_id(@id)}
        hidden={not @open}
        phx-hook={Popover.hook()}
        phx-click-away={close_menu(@id, @entry, @transient_controls)}
        phx-window-keydown={if(@direct_trigger, do: close_menu(@id, @entry, @transient_controls))}
        phx-key={if(@direct_trigger, do: "Escape")}
        data-lb-anchor={Popover.trigger_id(@id)}
        data-lb-side={@side}
        data-lb-align={@align}
        data-lb-offset={@side_offset}
        data-lb-align-offset={@align_offset}
        data-lb-autofocus
        data-lb-no-return-focus={flag(not @return_focus)}
        phx-mounted={Popover.owned_attributes(:positioner)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={upstream_fact("jsx/DropdownMenuContent/class/0")}
      >
          <div
            id={Popover.popup_id(@id)}
            role="menu"
            aria-orientation="vertical"
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
            class={
              LiveShadcn.Cn.merge([
                part(
                  @parts,
                  :content_class,
                  upstream_fact("jsx/DropdownMenuContent/class/1")
                ),
                @class
              ])
            }
            data-lb-style-target
            data-lb-measure
            {@content_attrs}
          >
            <%= for {{grouped, entries}, group_index} <- Enum.with_index(entry_groups(@entry, @grouped)) do %>
              <% label_index = Enum.find_index(entries, &(&1[:kind] == "label")) %>
              <% label_id = menu_group_label_id(@id, grouped, label_index, group_index) %>
              <.entry_group grouped={grouped} labelled_by={label_id} parts={@parts}>
                <%= for {entry, entry_index} <- Enum.with_index(entries) do %>
                  <div
                    :if={entry[:kind] == "label"}
                    id={if(entry_index == label_index, do: label_id)}
                    role="presentation"
                    data-slot={part(@parts, :label_slot, "dropdown-menu-label")}
                    data-inset={flag(entry[:inset] == true)}
                    class={[
                      part(
                        @parts,
                        :label_class,
                        upstream_fact("jsx/DropdownMenuLabel/class/0")
                      ),
                      entry[:class]
                    ]}
                  >
                    {render_slot(entry)}
                  </div>
                  <div
                    :if={entry[:kind] == "separator"}
                    role="separator"
                    aria-orientation="horizontal"
                    data-slot={part(@parts, :separator_slot, "dropdown-menu-separator")}
                    class={[
                      part(
                        @parts,
                        :separator_class,
                        upstream_fact("jsx/DropdownMenuSeparator/class/0")
                      ),
                      entry[:class]
                    ]}
                  >
                  </div>
                  <div :if={entry[:kind] == "submenu"}>
                    <div
                      id={Popover.trigger_id(submenu_id(@id, entry[:value]))}
                      role="menuitem"
                      tabindex="-1"
                      aria-haspopup="menu"
                      aria-expanded="false"
                      aria-controls={Popover.popup_id(submenu_id(@id, entry[:value]))}
                      phx-click={Popover.toggle(submenu_id(@id, entry[:value]))}
                      phx-mounted={Popover.owned_attributes(:trigger)}
                      data-slot={part(@parts, :sub_trigger_slot, "dropdown-menu-sub-trigger")}
                      data-popup-open={flag(false)}
                      data-pressed={flag(false)}
                      data-inset={flag(entry[:inset] == true)}
                      class={[
                        part(
                          @parts,
                          :sub_trigger_base_class,
                          upstream_fact("jsx/DropdownMenuSubTrigger/class/0")
                        ),
                        part(@parts, :sub_trigger_class, nil),
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
                    <.portal
                      id={"#{submenu_id(@id, entry[:value])}-portal"}
                      target="body"
                      class="contents"
                    >
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
                          aria-orientation="vertical"
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
                          data-slot={part(@parts, :sub_content_slot, "dropdown-menu-sub-content")}
                          data-closed=""
                          class={[
                            part(
                              @parts,
                              :content_class,
                              upstream_fact("jsx/DropdownMenuContent/class/1")
                            ),
                            part(
                              @parts,
                              :sub_content_base_class,
                              upstream_fact("jsx/DropdownMenuSubContent/class/0")
                            ),
                            part(@parts, :sub_content_class, nil)
                          ]}
                          data-lb-style-target
                          data-lb-measure
                          {entry[:content_attrs] || %{}}
                        >
                          <.submenu_entries
                            menu={submenu_id(@id, entry[:value])}
                            root_menu={@id}
                            root_entries={@entry}
                            entries={entry[:items] || []}
                            grouped={entry[:grouped] == true}
                            parts={@parts}
                          />
                        </div>
                      </div>
                    </.portal>
                  </div>
                  <div
                    :if={entry[:kind] == "checkbox"}
                    id={Menu.item_id(@id, entry[:value])}
                    role="menuitemcheckbox"
                    tabindex="-1"
                    aria-checked={to_string(entry[:checked] == true)}
                    aria-disabled={if(entry[:disabled] == true, do: "true")}
                    phx-click={
                      if(entry[:disabled] != true,
                        do:
                          toggle_checkbox(
                            Menu.item_id(@id, entry[:value]),
                            @parts,
                            entry[:"phx-click"]
                          )
                      )
                    }
                    phx-mounted={Menu.owned_attributes(:item)}
                    data-slot={part(@parts, :checkbox_item_slot, "dropdown-menu-checkbox-item")}
                    data-checked={flag(entry[:checked] == true)}
                    data-unchecked={flag(entry[:checked] != true)}
                    data-disabled={flag(entry[:disabled] == true)}
                    data-inset={flag(entry[:inset] == true)}
                    class={[
                      part(
                        @parts,
                        :checkbox_item_class,
                        upstream_fact("jsx/DropdownMenuCheckboxItem/class/0")
                      ),
                      entry[:class]
                    ]}
                  >
                    <span
                      data-slot={
                        part(
                          @parts,
                          :checkbox_indicator_slot,
                          "dropdown-menu-checkbox-item-indicator"
                        )
                      }
                      data-checked={flag(entry[:checked] == true)}
                      data-unchecked={flag(entry[:checked] != true)}
                      class={
                        part(
                          @parts,
                          :checkbox_indicator_class,
                          upstream_fact("jsx/DropdownMenuCheckboxItem/class/1")
                        )
                      }
                    >
                      <LiveShadcn.Icon.icon name="check" hidden={entry[:checked] != true} />
                    </span>
                    {render_slot(entry)}
                    <span
                      :if={entry[:shortcut]}
                      data-slot={part(@parts, :shortcut_slot, "dropdown-menu-shortcut")}
                      class={
                        part(
                          @parts,
                          :shortcut_class,
                          upstream_fact("jsx/DropdownMenuShortcut/class/0")
                        )
                      }
                    >
                      {entry[:shortcut]}
                    </span>
                  </div>
                  <div
                    :if={entry[:kind] == "radio-group"}
                    id={radio_group_id(@id, entry[:group])}
                    role="group"
                    data-slot={part(@parts, :radio_group_slot, "dropdown-menu-radio-group")}
                  >
                    <div
                      :if={entry[:label]}
                      role="presentation"
                      data-slot={part(@parts, :label_slot, "dropdown-menu-label")}
                      class={part(
                        @parts,
                        :label_class,
                        upstream_fact("jsx/DropdownMenuLabel/class/0")
                      )}
                    >
                      {entry[:label]}
                    </div>
                    <div
                      :for={radio <- entry[:items] || []}
                      id={Menu.item_id(@id, radio[:value])}
                      role="menuitemradio"
                      tabindex="-1"
                      aria-checked={to_string(entry[:value] == radio[:value])}
                      aria-disabled={if(radio[:disabled] == true, do: "true")}
                      phx-click={
                        if(radio[:disabled] != true,
                          do:
                            select_radio(
                              radio_group_id(@id, entry[:group]),
                              Menu.item_id(@id, radio[:value]),
                              @parts,
                              radio[:"phx-click"] || entry[:"phx-click"]
                            )
                        )
                      }
                      phx-mounted={Menu.owned_attributes(:item)}
                      data-slot={part(@parts, :radio_item_slot, "dropdown-menu-radio-item")}
                      data-checked={flag(entry[:value] == radio[:value])}
                      data-unchecked={flag(entry[:value] != radio[:value])}
                      data-disabled={flag(radio[:disabled] == true)}
                      data-inset={flag(radio[:inset] == true)}
                      class={[
                        part(
                          @parts,
                          :radio_item_class,
                          upstream_fact("jsx/DropdownMenuRadioItem/class/0")
                        ),
                        radio[:class]
                      ]}
                    >
                      <span
                        data-slot={
                          part(
                            @parts,
                            :radio_indicator_slot,
                            "dropdown-menu-radio-item-indicator"
                          )
                        }
                        data-checked={flag(entry[:value] == radio[:value])}
                        data-unchecked={flag(entry[:value] != radio[:value])}
                        class={
                          part(
                            @parts,
                            :radio_indicator_class,
                            upstream_fact("jsx/DropdownMenuRadioItem/class/1")
                          )
                        }
                      >
                        <LiveShadcn.Icon.icon
                          name="check"
                          hidden={entry[:value] != radio[:value]}
                        />
                      </span>
                      <LiveShadcn.Icon.icon :if={radio[:icon]} name={radio[:icon]} />
                      {radio[:label]}
                      <span
                        :if={radio[:shortcut]}
                        data-slot={part(@parts, :shortcut_slot, "dropdown-menu-shortcut")}
                        class={
                          part(
                            @parts,
                            :shortcut_class,
                            upstream_fact("jsx/DropdownMenuShortcut/class/0")
                          )
                        }
                      >
                        {radio[:shortcut]}
                      </span>
                    </div>
                  </div>
                  <a
                    :if={entry[:kind] == "item" and entry[:href]}
                    id={Menu.item_id(@id, entry[:value])}
                    role="menuitem"
                    aria-disabled={if(entry[:disabled] == true, do: "true")}
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
                    data-slot={part(@parts, :item_slot, "dropdown-menu-item")}
                    data-disabled={flag(entry[:disabled] == true)}
                    data-variant={entry[:variant] || "default"}
                    data-inset={flag(entry[:inset] == true)}
                    class={[
                      part(
                        @parts,
                        :item_class,
                        upstream_fact("jsx/DropdownMenuItem/class/0")
                      ),
                      entry[:class]
                    ]}
                  >
                    {render_slot(entry)}
                    <span
                      :if={entry[:shortcut]}
                      data-slot={part(@parts, :shortcut_slot, "dropdown-menu-shortcut")}
                      class={
                        part(
                          @parts,
                          :shortcut_class,
                          upstream_fact("jsx/DropdownMenuShortcut/class/0")
                        )
                      }
                    >
                      {entry[:shortcut]}
                    </span>
                  </a>
                  <div
                    :if={entry[:kind] == "item" and !entry[:href]}
                    id={Menu.item_id(@id, entry[:value])}
                    role="menuitem"
                    aria-disabled={if(entry[:disabled] == true, do: "true")}
                    tabindex="-1"
                    phx-click={
                      if(entry[:disabled] != true,
                        do: choose(@id, @entry, entry[:"phx-click"])
                      )
                    }
                    phx-hook={if(entry[:clipboard], do: LiveBase.Clipboard.hook())}
                    phx-mounted={entry_owned_attributes(entry)}
                    {Map.take(entry, [:navigate, :patch])}
                    data-slot={part(@parts, :item_slot, "dropdown-menu-item")}
                    data-lb-clipboard={entry[:clipboard]}
                    data-disabled={flag(entry[:disabled] == true)}
                    data-variant={entry[:variant] || "default"}
                    data-inset={flag(entry[:inset] == true)}
                    class={[
                      part(
                        @parts,
                        :item_class,
                        upstream_fact("jsx/DropdownMenuItem/class/0")
                      ),
                      entry[:class]
                    ]}
                  >
                    {render_slot(entry)}
                    <span
                      :if={entry[:shortcut]}
                      data-slot={part(@parts, :shortcut_slot, "dropdown-menu-shortcut")}
                      class={
                        part(
                          @parts,
                          :shortcut_class,
                          upstream_fact("jsx/DropdownMenuShortcut/class/0")
                        )
                      }
                    >
                      {entry[:shortcut]}
                    </span>
                  </div>
                <% end %>
              </.entry_group>
            <% end %>
            <a
              :for={item <- @item}
              :if={item[:href]}
              id={Menu.item_id(@id, item[:value])}
              role="menuitem"
              aria-disabled={if(item[:disabled] == true, do: "true")}
              tabindex="-1"
              href={item[:href]}
              target={item[:target]}
              rel={item[:rel]}
              phx-click={if(item[:disabled] != true, do: choose(@id, @entry, item[:"phx-click"]))}
              phx-mounted={Menu.owned_attributes(:item)}
              data-slot={@item_slot}
              data-disabled={flag(item[:disabled] == true)}
              data-variant={@variant}
              data-inset={flag(@inset)}
              class={[
                part(@parts, :item_class, upstream_fact("jsx/DropdownMenuItem/class/0")),
                @item_class || ""
              ]}
            >
              {render_slot(item)}
            </a>
            <div
              :for={item <- @item}
              :if={!item[:href]}
              id={Menu.item_id(@id, item[:value])}
              role="menuitem"
              aria-disabled={if(item[:disabled] == true, do: "true")}
              tabindex="-1"
              phx-click={if(item[:disabled] != true, do: choose(@id, @entry, item[:"phx-click"]))}
              phx-mounted={Menu.owned_attributes(:item)}
              {Map.take(item, [:"phx-value-value", :navigate, :patch])}
              data-slot={@item_slot}
              data-disabled={flag(item[:disabled] == true)}
              data-variant={@variant}
              data-inset={flag(@inset)}
              class={[
                part(@parts, :item_class, upstream_fact("jsx/DropdownMenuItem/class/0")),
                @item_class || ""
              ]}
            >
              {render_slot(item)}
            </div>
            {render_slot(@inner_block)}
          </div>
        </div>
      </.portal>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp entry_owned_attributes(entry) do
    js = Menu.owned_attributes(:item)

    if is_binary(entry[:clipboard]),
      do: JS.concat(js, LiveBase.Clipboard.owned_attributes()),
      else: js
  end

  defp entry_groups(entries, false) do
    if Enum.any?(entries, & &1[:section]) do
      entries
      |> Enum.chunk_by(& &1[:section])
      |> Enum.map(fn entries -> {not is_nil(hd(entries)[:section]), entries} end)
    else
      [{false, entries}]
    end
  end

  defp entry_groups(entries, true) do
    entries
    |> Enum.chunk_by(&(&1[:kind] == "separator"))
    |> Enum.map(fn entries ->
      {hd(entries)[:kind] != "separator", entries}
    end)
  end

  attr(:grouped, :boolean, required: true)
  attr(:labelled_by, :string, default: nil)
  attr(:parts, :map, required: true)
  slot(:inner_block, required: true)

  defp entry_group(assigns) do
    ~H"""
    <%= if @grouped do %>
      <div
        data-slot={part(@parts, :group_slot, "dropdown-menu-group")}
        role="group"
        aria-labelledby={@labelled_by}
      >
        {render_slot(@inner_block)}
      </div>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  attr(:menu, :string, required: true)
  attr(:root_menu, :string, required: true)
  attr(:root_entries, :list, required: true)
  attr(:entries, :list, required: true)
  attr(:grouped, :boolean, required: true)
  attr(:parts, :map, required: true)

  defp submenu_entries(assigns) do
    ~H"""
    <%= for {{grouped, entries}, group_index} <- Enum.with_index(entry_groups(@entries, @grouped)) do %>
      <% label_index = Enum.find_index(entries, &(entry_kind(&1) == "label")) %>
      <% label_id = menu_group_label_id(@menu, grouped, label_index, group_index) %>
      <.entry_group grouped={grouped} labelled_by={label_id} parts={@parts}>
        <%= for {entry, entry_index} <- Enum.with_index(entries) do %>
          <div
            :if={entry_kind(entry) == "label"}
            id={if(entry_index == label_index, do: label_id)}
            role="presentation"
            data-slot={part(@parts, :label_slot, "dropdown-menu-label")}
            data-inset={flag(entry[:inset] == true)}
            class={[
              part(@parts, :label_class, upstream_fact("jsx/DropdownMenuLabel/class/0")),
              entry[:class]
            ]}
          >
            <.map_entry_content entry={entry} />
          </div>
          <div
            :if={entry_kind(entry) == "separator"}
            role="separator"
            aria-orientation="horizontal"
            data-slot={part(@parts, :separator_slot, "dropdown-menu-separator")}
            class={[
              part(
                @parts,
                :separator_class,
                upstream_fact("jsx/DropdownMenuSeparator/class/0")
              ),
              entry[:class]
            ]}
          >
          </div>
          <div :if={entry_kind(entry) == "submenu"}>
            <div
              id={Popover.trigger_id(submenu_id(@menu, entry[:value]))}
              role="menuitem"
              tabindex="-1"
              aria-haspopup="menu"
              aria-expanded="false"
              aria-controls={Popover.popup_id(submenu_id(@menu, entry[:value]))}
              phx-click={Popover.toggle(submenu_id(@menu, entry[:value]))}
              phx-mounted={Popover.owned_attributes(:trigger)}
              data-slot={part(@parts, :sub_trigger_slot, "dropdown-menu-sub-trigger")}
              data-popup-open={flag(false)}
              data-pressed={flag(false)}
              data-inset={flag(entry[:inset] == true)}
              class={[
                part(
                  @parts,
                  :sub_trigger_base_class,
                  upstream_fact("jsx/DropdownMenuSubTrigger/class/0")
                ),
                part(@parts, :sub_trigger_class, nil),
                entry[:class]
              ]}
            >
              <.map_entry_content entry={entry} />
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
            <.portal
              id={"#{submenu_id(@menu, entry[:value])}-portal"}
              target="body"
              class="contents"
            >
              <div
                id={Popover.positioner_id(submenu_id(@menu, entry[:value]))}
                hidden
                phx-hook={Popover.hook()}
                data-lb-anchor={Popover.trigger_id(submenu_id(@menu, entry[:value]))}
                data-lb-side="right"
                data-lb-align="start"
                data-lb-offset="0"
                data-lb-align-offset="-3"
                phx-mounted={Popover.owned_attributes(:positioner)}
                data-closed=""
                class={upstream_fact("jsx/DropdownMenuContent/class/0")}
              >
                <div
                  id={Popover.popup_id(submenu_id(@menu, entry[:value]))}
                  role="menu"
                  aria-orientation="vertical"
                  tabindex="-1"
                  hidden
                  data-lb-popup
                  data-lb-submenu
                  data-lb-parent-trigger={Popover.trigger_id(submenu_id(@menu, entry[:value]))}
                  phx-hook={Menu.hook()}
                  data-lb-roving="menuitem"
                  data-lb-orientation="vertical"
                  data-lb-loop
                  data-lb-highlight="data-highlighted"
                  phx-mounted={Popover.owned_attributes(:popup)}
                  data-slot={part(@parts, :sub_content_slot, "dropdown-menu-sub-content")}
                  data-closed=""
                  class={[
                    part(
                      @parts,
                      :content_class,
                      upstream_fact("jsx/DropdownMenuContent/class/1")
                    ),
                    part(
                      @parts,
                      :sub_content_base_class,
                      upstream_fact("jsx/DropdownMenuSubContent/class/0")
                    ),
                    part(@parts, :sub_content_class, nil)
                  ]}
                  data-lb-style-target
                  data-lb-measure
                  {entry[:content_attrs] || %{}}
                >
                  <.submenu_entries
                    menu={submenu_id(@menu, entry[:value])}
                    root_menu={@root_menu}
                    root_entries={@root_entries}
                    entries={entry[:items] || []}
                    grouped={entry[:grouped] == true}
                    parts={@parts}
                  />
                </div>
              </div>
            </.portal>
          </div>
          <div
            :if={entry_kind(entry) == "checkbox"}
            id={Menu.item_id(@menu, entry[:value])}
            role="menuitemcheckbox"
            tabindex="-1"
            aria-checked={to_string(entry[:checked] == true)}
            aria-disabled={if(entry[:disabled] == true, do: "true")}
            phx-click={
              if(entry[:disabled] != true,
                do:
                  toggle_checkbox(
                    Menu.item_id(@menu, entry[:value]),
                    @parts,
                    entry[:"phx-click"]
                  )
              )
            }
            phx-mounted={Menu.owned_attributes(:item)}
            data-slot={part(@parts, :checkbox_item_slot, "dropdown-menu-checkbox-item")}
            data-checked={flag(entry[:checked] == true)}
            data-unchecked={flag(entry[:checked] != true)}
            data-disabled={flag(entry[:disabled] == true)}
            data-inset={flag(entry[:inset] == true)}
            class={[
              part(
                @parts,
                :checkbox_item_class,
                upstream_fact("jsx/DropdownMenuCheckboxItem/class/0")
              ),
              entry[:class]
            ]}
          >
            <span
              data-slot={
                part(
                  @parts,
                  :checkbox_indicator_slot,
                  "dropdown-menu-checkbox-item-indicator"
                )
              }
              data-checked={flag(entry[:checked] == true)}
              data-unchecked={flag(entry[:checked] != true)}
              class={
                part(
                  @parts,
                  :checkbox_indicator_class,
                  upstream_fact("jsx/DropdownMenuCheckboxItem/class/1")
                )
              }
            >
              <LiveShadcn.Icon.icon name="check" hidden={entry[:checked] != true} />
            </span>
            <.map_entry_content entry={entry} />
          </div>
          <div
            :if={entry_kind(entry) == "radio-group"}
            id={radio_group_id(@menu, entry[:group])}
            role="group"
            data-slot={part(@parts, :radio_group_slot, "dropdown-menu-radio-group")}
          >
            <div
              :if={entry[:label]}
              role="presentation"
              data-slot={part(@parts, :label_slot, "dropdown-menu-label")}
              class={part(
                @parts,
                :label_class,
                upstream_fact("jsx/DropdownMenuLabel/class/0")
              )}
            >
              {entry[:label]}
            </div>
            <div
              :for={radio <- entry[:items] || []}
              id={Menu.item_id(@menu, radio[:value])}
              role="menuitemradio"
              tabindex="-1"
              aria-checked={to_string(entry[:value] == radio[:value])}
              aria-disabled={if(radio[:disabled] == true, do: "true")}
              phx-click={
                if(radio[:disabled] != true,
                  do:
                    select_radio(
                      radio_group_id(@menu, entry[:group]),
                      Menu.item_id(@menu, radio[:value]),
                      @parts,
                      radio[:"phx-click"] || entry[:"phx-click"]
                    )
                )
              }
              phx-mounted={Menu.owned_attributes(:item)}
              data-slot={part(@parts, :radio_item_slot, "dropdown-menu-radio-item")}
              data-checked={flag(entry[:value] == radio[:value])}
              data-unchecked={flag(entry[:value] != radio[:value])}
              data-disabled={flag(radio[:disabled] == true)}
              data-inset={flag(radio[:inset] == true)}
              class={[
                part(
                  @parts,
                  :radio_item_class,
                  upstream_fact("jsx/DropdownMenuRadioItem/class/0")
                ),
                radio[:class]
              ]}
            >
              <span
                data-slot={
                  part(
                    @parts,
                    :radio_indicator_slot,
                    "dropdown-menu-radio-item-indicator"
                  )
                }
                data-checked={flag(entry[:value] == radio[:value])}
                data-unchecked={flag(entry[:value] != radio[:value])}
                class={
                  part(
                    @parts,
                    :radio_indicator_class,
                    upstream_fact("jsx/DropdownMenuRadioItem/class/1")
                  )
                }
              >
                <LiveShadcn.Icon.icon name="check" hidden={entry[:value] != radio[:value]} />
              </span>
              <LiveShadcn.Icon.icon :if={radio[:icon]} name={radio[:icon]} />
              {radio[:label]}
            </div>
          </div>
          <div
            :if={entry_kind(entry) == "item"}
            id={Menu.item_id(@menu, entry[:value])}
            role="menuitem"
            aria-disabled={if(entry[:disabled] == true, do: "true")}
            tabindex="-1"
            phx-click={
              if(entry[:disabled] != true,
                do: choose(@root_menu, @root_entries, entry[:"phx-click"])
              )
            }
            phx-mounted={Menu.owned_attributes(:item)}
            data-slot={part(@parts, :item_slot, "dropdown-menu-item")}
            data-disabled={flag(entry[:disabled] == true)}
            data-variant={entry[:variant] || "default"}
            data-inset={flag(entry[:inset] == true)}
            class={[
              part(@parts, :item_class, upstream_fact("jsx/DropdownMenuItem/class/0")),
              entry[:class]
            ]}
          >
            <.map_entry_content entry={entry} />
            <span
              :if={entry[:shortcut]}
              data-slot={part(@parts, :shortcut_slot, "dropdown-menu-shortcut")}
              class={
                part(
                  @parts,
                  :shortcut_class,
                  upstream_fact("jsx/DropdownMenuShortcut/class/0")
                )
              }
            >
              {entry[:shortcut]}
            </span>
          </div>
        <% end %>
      </.entry_group>
    <% end %>
    """
  end

  attr(:entry, :map, required: true)

  defp map_entry_content(assigns) do
    ~H"""
    <LiveShadcn.Icon.icon :if={@entry[:icon]} name={@entry[:icon]} />
    {@entry[:label]}
    """
  end

  defp entry_kind(entry), do: entry[:kind] || "item"

  defp menu_group_label_id(_menu, false, _label_index, _group_index), do: nil
  defp menu_group_label_id(_menu, _grouped, nil, _group_index), do: nil

  defp menu_group_label_id(menu, true, _label_index, group_index) do
    "#{menu}-group-#{group_index}-label"
  end

  defp submenu_id(menu, value), do: "#{menu}-#{value}"
  defp radio_group_id(menu, group), do: "#{menu}-#{group || "radio"}-group"

  defp toggle_checkbox(item, parts, command) do
    control = "##{item}"

    indicator_slot =
      part(parts, :checkbox_indicator_slot, "dropdown-menu-checkbox-item-indicator")

    indicator_selector =
      part(
        parts,
        :checkbox_indicator_selector,
        part_selector(indicator_slot, :checkbox_indicator)
      )

    indicator = "#{control} #{indicator_selector}"
    icon = "#{indicator} > svg"

    %JS{}
    |> JS.toggle_attribute({"aria-checked", "true", "false"}, to: control)
    |> JS.toggle_attribute({"data-checked", ""}, to: control)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: control)
    |> JS.toggle_attribute({"hidden", ""}, to: icon)
    |> JS.toggle_attribute({"data-checked", ""}, to: indicator)
    |> JS.toggle_attribute({"data-unchecked", ""}, to: indicator)
    |> append_command(command)
  end

  defp select_radio(group, item, parts, command) do
    control = "##{item}"
    others = "##{group} [role='menuitemradio']:not(#{control})"
    indicator_slot = part(parts, :radio_indicator_slot, "dropdown-menu-radio-item-indicator")

    indicator_selector =
      part(parts, :radio_indicator_selector, part_selector(indicator_slot, :radio_indicator))

    control_indicator = "#{control} #{indicator_selector}"
    other_indicators = "#{others} #{indicator_selector}"
    control_icon = "#{control_indicator} > svg"
    other_icons = "#{other_indicators} > svg"

    %JS{}
    |> JS.set_attribute({"aria-checked", "false"}, to: others)
    |> JS.remove_attribute("data-checked", to: others)
    |> JS.set_attribute({"data-unchecked", ""}, to: others)
    |> JS.set_attribute({"hidden", ""}, to: other_icons)
    |> JS.remove_attribute("data-checked", to: other_indicators)
    |> JS.set_attribute({"data-unchecked", ""}, to: other_indicators)
    |> JS.set_attribute({"aria-checked", "true"}, to: control)
    |> JS.set_attribute({"data-checked", ""}, to: control)
    |> JS.remove_attribute("data-unchecked", to: control)
    |> JS.remove_attribute("hidden", to: control_icon)
    |> JS.set_attribute({"data-checked", ""}, to: control_indicator)
    |> JS.remove_attribute("data-unchecked", to: control_indicator)
    |> append_command(command)
  end

  defp append_command(js, nil), do: js
  defp append_command(js, name) when is_binary(name), do: JS.push(js, name)
  defp append_command(%JS{ops: ours}, %JS{ops: theirs}), do: %JS{ops: ours ++ theirs}

  defp controls(_id, false, true), do: nil
  defp controls(id, _open, _transient_controls), do: Popover.popup_id(id)

  defp toggle_menu(menu, false), do: Popover.toggle(menu)

  defp toggle_menu(menu, true) do
    Popover.toggle(menu)
    |> JS.toggle_attribute({"aria-controls", Popover.popup_id(menu)},
      to: "##{Popover.trigger_id(menu)}"
    )
  end

  defp close_menu(menu, entries, transient_controls) do
    Popover.close(menu)
    |> maybe_remove_controls(menu, transient_controls)
    |> close_submenus(menu, entries)
  end

  defp maybe_remove_controls(js, _menu, false), do: js

  defp maybe_remove_controls(js, menu, true) do
    JS.remove_attribute(js, "aria-controls", to: "##{Popover.trigger_id(menu)}")
  end

  defp choose(menu, entries, command) do
    close_submenus(Menu.choose(menu, command), menu, entries)
  end

  defp close_submenus(js, menu, entries) do
    entries
    |> Enum.filter(&(&1[:kind] == "submenu"))
    |> Enum.reduce(js, fn entry, commands ->
      submenu = submenu_id(menu, entry[:value])

      commands
      |> Popover.close(submenu)
      |> close_submenus(submenu, entry[:items] || [])
    end)
  end

  defp trigger_classes(nil, _size), do: ""

  defp trigger_classes(variant, size) do
    Button.button_class(variant: variant, size: size)
  end

  @doc false
  def item_class, do: upstream_fact("jsx/DropdownMenuItem/class/0")

  defp part(parts, key, default) do
    case Map.fetch(parts, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  defp part_selector(nil, :checkbox_indicator),
    do: ".cn-menubar-checkbox-item-indicator"

  defp part_selector(nil, :radio_indicator),
    do: ".cn-menubar-radio-item-indicator"

  defp part_selector(slot, _kind), do: "[data-slot='#{slot}']"
end
