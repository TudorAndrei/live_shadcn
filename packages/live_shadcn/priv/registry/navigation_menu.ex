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
    "jsx/NavigationMenuItem/class/0" => "cn-navigation-menu-item relative",
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

  slot(:trigger, required: true, doc: "What opens the navigation content.")
  slot(:inner_block, required: true, doc: "The navigation content.")

  def navigation_menu(assigns) do
    ~H"""
    <div
      id={@id}
      class="contents"
      phx-window-keydown={Popover.close(@id)}
      phx-key="Escape"
      phx-click-away={Popover.dismiss(@id)}
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
            data-slot="navigation-menu-item"
            class={[upstream_fact("jsx/NavigationMenuItem/class/0"), (@item_class || "")]}
          >
            <button
              data-slot="navigation-menu-trigger"
              id={Popover.trigger_id(@id)}
              type="button"
              aria-disabled={to_string(@disabled)}
              aria-expanded={to_string(@open)}
              aria-controls={Popover.popup_id(@id)}
              phx-click={if(not @disabled, do: Popover.toggle(@id))}
              phx-mounted={Popover.owned_attributes(:trigger)}
              class={[
                upstream_fact("port/class/0"),
                (@trigger_class || "")
              ]}
              data-lb-style-target
            >
              {render_slot(@trigger)}
              <LiveShadcn.Icon.icon name="chevron-down" class={upstream_fact("jsx/NavigationMenuTrigger/class/1")} />
            </button>
          </li>
        </ul>
        <div class={["contents", (@positioner_class || "")]}>
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
            class={[
              upstream_fact("jsx/NavigationMenuPositioner/class/0"),
              (@positioner_class || "")
            ]}
            data-lb-measure
          >
            <nav
              id={Popover.popup_id(@id)}
              hidden={not @open}
              data-lb-popup
              phx-mounted={Popover.owned_attributes(:popup)}
              class={upstream_fact("jsx/NavigationMenuPositioner/class/1")}
              data-lb-style-target
              data-lb-measure
            >
              <div class={upstream_fact("jsx/NavigationMenuPositioner/class/2")}>
                <div
                  data-slot="navigation-menu-content"
                  class={[
                    upstream_fact("jsx/NavigationMenuContent/class/0"),
                    (@content_class || "")
                  ]}
                  data-lb-style-target
                >
                  {render_slot(@inner_block)}
                </div>
              </div>
            </nav>
          </div>
        </div>
      </nav>
    </div>
    """
  end
end
