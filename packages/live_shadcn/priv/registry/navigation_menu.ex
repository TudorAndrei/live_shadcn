defmodule LiveShadcn.UI.NavigationMenu do
  @moduledoc """
  Navigation menu. Groups all parts of the navigation menu.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/NavigationMenu/class/0" =>
      "cn-navigation-menu group/navigation-menu relative flex max-w-max flex-1 items-center justify-center",
    "jsx/NavigationMenuContent/class/0" =>
      "cn-navigation-menu-content data-ending-style:data-activation-direction=left:translate-x-[50%] data-ending-style:data-activation-direction=right:translate-x-[-50%] data-starting-style:data-activation-direction=left:translate-x-[-50%] data-starting-style:data-activation-direction=right:translate-x-[50%] h-full w-auto transition-[opacity,transform,translate] duration-[0.35s] data-ending-style:opacity-0 data-starting-style:opacity-0 **:data-[slot=navigation-menu-link]:focus:ring-0 **:data-[slot=navigation-menu-link]:focus:outline-none",
    "jsx/NavigationMenuIndicator/class/0" =>
      "cn-navigation-menu-indicator top-full z-1 flex h-1.5 items-end justify-center overflow-hidden",
    "jsx/NavigationMenuIndicator/class/1" =>
      "cn-navigation-menu-indicator-arrow relative top-[60%] h-2 w-2 rotate-45",
    "jsx/NavigationMenuItem/class/0" => "cn-navigation-menu-item relative",
    "jsx/NavigationMenuLink/class/0" => "cn-navigation-menu-link",
    "jsx/NavigationMenuList/class/0" =>
      "cn-navigation-menu-list group flex flex-1 list-none items-center justify-center",
    "jsx/NavigationMenuPositioner/class/0" =>
      "cn-navigation-menu-positioner isolate z-50 h-(--positioner-height) w-(--positioner-width) max-w-(--available-width) transition-[top,left,right,bottom] duration-[0.35s] data-instant:transition-none",
    "jsx/NavigationMenuPositioner/class/1" =>
      "cn-navigation-menu-popup data-[ending-style]:easing-[ease] xs:w-(--popup-width) relative h-(--popup-height) w-(--popup-width) origin-(--transform-origin) transition-[opacity,transform,width,height,scale,translate] duration-[0.35s] ease-[cubic-bezier(0.22,1,0.36,1)]",
    "jsx/NavigationMenuPositioner/class/2" => "relative size-full overflow-hidden",
    "jsx/NavigationMenuTrigger/class/1" => "cn-navigation-menu-trigger-icon",
    "port/class/0" =>
      "cn-navigation-menu-trigger group/navigation-menu-trigger inline-flex h-9 w-max items-center justify-center outline-none disabled:pointer-events-none group"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Popover

  @doc """
  Navigation links, and the panel one of them opens.

      <.navigation_menu id="docs">
        <:trigger>Documentation</:trigger>
        <p>The roadmap, the inventory, and the architecture.</p>
      </.navigation_menu>

  Opening and closing run on the client. The panel is presented through a
  viewport, which is what upstream animates between one item and the next.
  """

  attr(:id, :string, required: true, doc: "Every id inside the menu derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether the content starts open.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")
  attr(:orientation, :string, default: "horizontal", values: ["horizontal", "vertical"])
  attr(:side, :string, default: "bottom", values: ["top", "right", "bottom", "left"])
  attr(:align, :string, default: "start", values: ["start", "center", "end"])
  attr(:offset, :integer, default: 8)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:list_class, :any, default: nil)
  attr(:item_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:positioner_class, :any, default: nil)
  attr(:popup_class, :any, default: nil)
  attr(:viewport_class, :any, default: nil)
  attr(:content_class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger, doc: "What opens the navigation content in the one-item form.")
  slot(:inner_block, doc: "The navigation content in the one-item form.")

  slot :item, doc: "One trigger and its navigation content." do
    attr(:id, :string, required: true)
    attr(:trigger, :string, required: true)
    attr(:open, :boolean)
    attr(:disabled, :boolean)
    attr(:class, :any)
    attr(:trigger_class, :any)
    attr(:content_class, :any)
    attr(:content_attrs, :map)
  end

  slot :link, doc: "One navigation link that does not open content." do
    attr(:href, :string, required: true)
    attr(:class, :any)
    attr(:attrs, :map)
  end

  def navigation_menu(assigns) do
    assigns = assign(assigns, :entries, navigation_entries(assigns))

    ~H"""
    <div
      id={@id}
      class="contents"
      phx-window-keydown={close_all(@entries)}
      phx-key="Escape"
      {@rest}
    >
      <nav
        data-slot="navigation-menu"
        class={[
          upstream_fact("jsx/NavigationMenu/class/0"),
          (@class || "")
        ]}
      >
        <ul
          data-slot="navigation-menu-list"
          class={[
            upstream_fact("jsx/NavigationMenuList/class/0"),
            (@list_class || "")
          ]}
        >
          <li
            :for={entry <- @entries}
            data-slot="navigation-menu-item"
            class={[
              upstream_fact("jsx/NavigationMenuItem/class/0"),
              (@item_class || ""),
              (entry[:class] || "")
            ]}
          >
            <button
              data-slot="navigation-menu-trigger"
              id={Popover.trigger_id(entry.id)}
              type="button"
              aria-disabled={to_string(entry.disabled)}
              aria-expanded={to_string(entry.open)}
              aria-controls={Popover.popup_id(entry.id)}
              phx-click={if(not entry.disabled, do: toggle_entry(@entries, entry.id))}
              phx-mounted={Popover.owned_attributes(:trigger)}
              class={[
                upstream_fact("port/class/0"),
                (@trigger_class || ""),
                (entry[:trigger_class] || "")
              ]}
              data-lb-style-target
            >
              <%= if entry.legacy do %>
                {render_slot(@trigger)}
              <% else %>
                {entry.trigger}
              <% end %>
              <LiveShadcn.Icon.icon name="chevron-down" class={upstream_fact("jsx/NavigationMenuTrigger/class/1")} />
            </button>
          </li>
          <li
            :for={link <- @link}
            data-slot="navigation-menu-item"
            class={[upstream_fact("jsx/NavigationMenuItem/class/0"), (@item_class || "")]}
          >
            <.navigation_menu_link
              href={link.href}
              class={[
                upstream_fact("port/class/0"),
                (link[:class] || "")
              ]}
              {link[:attrs] || %{}}
            >
              {render_slot(link)}
            </.navigation_menu_link>
          </li>
        </ul>
        <div :for={entry <- @entries} class="contents">
          <div
            id={Popover.positioner_id(entry.id)}
            dir="ltr"
            hidden={not entry.open}
            phx-hook={Popover.hook()}
            data-lb-anchor={Popover.trigger_id(entry.id)}
            data-lb-side={@side}
            data-lb-align={@align}
            data-lb-offset={to_string(@offset)}
            data-lb-fractional
            data-lb-autofocus
            phx-click-away={Popover.dismiss(entry.id)}
            phx-mounted={Popover.owned_attributes(:positioner)}
            class={[
              upstream_fact("jsx/NavigationMenuPositioner/class/0"),
              (@positioner_class || "")
            ]}
            data-lb-measure
          >
            <nav
              id={Popover.popup_id(entry.id)}
              hidden={not entry.open}
              data-lb-popup
              phx-mounted={Popover.owned_attributes(:popup)}
              class={[upstream_fact("jsx/NavigationMenuPositioner/class/1"), (@popup_class || "")]}
              data-lb-style-target
              data-lb-measure
            >
              <div class={[upstream_fact("jsx/NavigationMenuPositioner/class/2"), (@viewport_class || "")]}>
                <div
                  data-slot="navigation-menu-content"
                  class={[
                    upstream_fact("jsx/NavigationMenuContent/class/0"),
                    (@content_class || ""),
                    (entry[:content_class] || "")
                  ]}
                  data-lb-style-target
                  {entry[:content_attrs] || %{}}
                >
                  <%= if entry.legacy do %>
                    {render_slot(@inner_block)}
                  <% else %>
                    {render_slot(entry)}
                  <% end %>
                </div>
              </div>
            </nav>
          </div>
        </div>
      </nav>
    </div>
    """
  end

  attr(:href, :string, required: true)
  attr(:active, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @doc "A link in navigation menu content."
  def navigation_menu_link(assigns) do
    ~H"""
    <a
      data-slot="navigation-menu-link"
      href={@href}
      data-active={if(@active, do: "true")}
      class={[upstream_fact("jsx/NavigationMenuLink/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  @doc "An arrow under the active navigation item."
  attr(:state, :string, default: "visible", values: ["visible", "hidden"])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def navigation_menu_indicator(assigns) do
    ~H"""
    <div
      data-slot="navigation-menu-indicator"
      data-state={@state}
      class={[upstream_fact("jsx/NavigationMenuIndicator/class/0"), @class || ""]}
      {@rest}
    >
      <div class={upstream_fact("jsx/NavigationMenuIndicator/class/1")} />
    </div>
    """
  end

  defp navigation_entries(%{item: [_ | _] = items}) do
    Enum.map(items, fn item ->
      item
      |> Map.put(:open, item[:open] || false)
      |> Map.put(:disabled, item[:disabled] || false)
      |> Map.put(:trigger, item.trigger)
      |> Map.put(:legacy, false)
    end)
  end

  defp navigation_entries(assigns) do
    [
      %{
        id: assigns.id,
        open: assigns.open,
        disabled: assigns.disabled,
        legacy: true
      }
    ]
  end

  defp close_all(entries) do
    Enum.reduce(entries, %Phoenix.LiveView.JS{}, fn entry, js ->
      Popover.close(js, entry.id)
    end)
  end

  defp toggle_entry(entries, id) do
    entries
    |> Enum.reject(&(&1.id == id))
    |> Enum.reduce(%Phoenix.LiveView.JS{}, fn entry, js -> Popover.close(js, entry.id) end)
    |> Popover.toggle(id)
  end
end
