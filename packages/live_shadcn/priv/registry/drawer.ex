defmodule LiveShadcn.UI.Drawer do
  @moduledoc """
  Drawer. Groups all parts of the drawer.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/DrawerContent/class/0" =>
      "pointer-events-none fixed inset-0 z-50 select-none data-[modal=true]:pointer-events-auto",
    "jsx/DrawerContent/class/13" =>
      "cn-drawer-content-base flex min-h-0 flex-1 flex-col overflow-hidden overscroll-contain rounded-[inherit] transition-opacity duration-300 ease-[cubic-bezier(0.45,1.005,0,1.005)] select-text group-data-nested-drawer-open/drawer-popup:opacity-0 group-data-nested-drawer-swiping/drawer-popup:opacity-100 group-data-swiping/drawer-popup:select-none",
    "jsx/DrawerDescription/class/0" => "cn-drawer-description text-balance",
    "jsx/DrawerFooter/class/0" => "cn-drawer-footer-base mt-auto flex shrink-0 flex-col",
    "jsx/DrawerHeader/class/0" =>
      "cn-drawer-header-base flex shrink-0 flex-col group-data-[swipe-axis=y]/drawer-popup:text-center",
    "jsx/DrawerOverlay/class/0" =>
      "cn-drawer-overlay fixed inset-0 z-50 min-h-dvh opacity-[max(var(--drawer-overlay-min-opacity,0),calc(1-var(--drawer-swipe-progress)))] transition-opacity duration-450 ease-[cubic-bezier(0.32,0.72,0,1)] select-none data-ending-style:pointer-events-none data-ending-style:opacity-0 data-ending-style:duration-[calc(var(--drawer-swipe-strength)*400ms)] data-snap-points:[--drawer-overlay-min-opacity:0.5] data-starting-style:opacity-0 data-swiping:duration-0 supports-[-webkit-touch-callout:none]:absolute",
    "jsx/DrawerSwipeHandle/class/0" =>
      "cn-drawer-swipe-handle relative z-10 flex shrink-0 cursor-grab transition-opacity duration-200 group-data-nested-drawer-open/drawer-popup:opacity-0 group-data-nested-drawer-swiping/drawer-popup:opacity-100 group-data-[swipe-direction=left]/drawer-popup:order-last group-data-[swipe-direction=up]/drawer-popup:order-last active:cursor-grabbing",
    "jsx/DrawerTitle/class/0" => "cn-drawer-title cn-font-heading",
    "port/class/0" =>
      "cn-drawer-popup group/drawer-popup pointer-events-auto fixed z-50 m-(--drawer-inset,0px) flex h-(--drawer-content-height) max-h-(--drawer-content-max-height,none) min-h-0 w-(--drawer-content-width,auto) transform-[translate3d(var(--translate-x,0px),var(--translate-y,0px),0)_scale(var(--stack-scale))] flex-col transition-[transform,height,opacity,filter] duration-450 ease-[cubic-bezier(0.22,1,0.36,1)] will-change-transform outline-none select-none [interpolate-size:allow-keywords] data-nested-drawer-open:overflow-hidden data-nested-drawer-open:brightness-95 after:pointer-events-none after:absolute after:bg-(--drawer-bleed-background,var(--color-popover)) data-[swipe-axis=x]:after:inset-y-0 data-[swipe-axis=x]:after:w-(--bleed) data-[swipe-axis=y]:after:inset-x-0 data-[swipe-axis=y]:after:h-(--bleed) data-[swipe-direction=down]:after:top-full data-[swipe-direction=left]:after:right-full data-[swipe-direction=right]:after:left-full data-[swipe-direction=up]:after:bottom-full [--drawer-content-height:var(--drawer-height,auto)] data-[swipe-axis=x]:[--drawer-content-width:75%] data-[swipe-axis=y]:[--drawer-content-max-height:calc(100dvh-6rem)] data-[swipe-axis=y]:data-snap-points:[--drawer-content-height:100dvh] data-[swipe-axis=x]:sm:[--drawer-content-width:24rem] [--bleed:3rem] [--peek:1rem] [--stack-height:var(--drawer-frontmost-height,var(--drawer-height,0px))] [--stack-peek-offset:max(0px,calc((var(--nested-drawers)-var(--stack-progress))*var(--peek)))] [--stack-progress:clamp(0,var(--drawer-swipe-progress),1)] [--stack-scale-base:max(0,calc(1-(var(--nested-drawers)*var(--stack-step))))] [--stack-scale:clamp(0,calc(var(--stack-scale-base)+(var(--stack-step)*var(--stack-progress))),1)] [--stack-shrink:calc(1-var(--stack-scale))] [--stack-step:0.05] data-ending-style:transform-(--closed-transform) data-ending-style:opacity-[0.9999] data-ending-style:duration-[calc(var(--drawer-swipe-strength)*400ms)] data-nested-drawer-swiping:duration-0 data-ending-style:data-nested-drawer-swiping:duration-[calc(var(--drawer-swipe-strength)*400ms)] data-starting-style:transform-(--closed-transform) data-swiping:duration-0 data-ending-style:data-swiping:duration-[calc(var(--drawer-swipe-strength)*400ms)] data-[swipe-axis=y]:inset-x-0 data-[swipe-axis=y]:data-nested-drawer-open:h-(--stack-height) data-[swipe-axis=x]:inset-y-0 data-[swipe-axis=x]:flex-row data-[swipe-direction=down]:bottom-0 data-[swipe-direction=down]:origin-bottom data-[swipe-direction=down]:[--closed-transform:translate3d(0,calc(100%+var(--drawer-inset,0px)+2px),0)] data-[swipe-direction=down]:[--translate-y:calc(var(--drawer-snap-point-offset,0px)+var(--drawer-swipe-movement-y)-var(--stack-peek-offset)-(var(--stack-shrink)*var(--stack-height)))] data-[swipe-direction=up]:top-0 data-[swipe-direction=up]:origin-top data-[swipe-direction=up]:[--closed-transform:translate3d(0,calc(-100%-var(--drawer-inset,0px)-2px),0)] data-[swipe-direction=up]:[--translate-y:calc(var(--drawer-snap-point-offset,0px)+var(--drawer-swipe-movement-y)+var(--stack-peek-offset)+(var(--stack-shrink)*var(--stack-height)))] data-[swipe-direction=left]:left-0 data-[swipe-direction=left]:origin-left data-[swipe-direction=left]:[--closed-transform:translate3d(calc(-100%-var(--drawer-inset,0px)-2px),0,0)] data-[swipe-direction=left]:[--translate-x:calc(var(--drawer-swipe-movement-x)+var(--stack-peek-offset)+(var(--stack-shrink)*100%))] data-[swipe-direction=right]:right-0 data-[swipe-direction=right]:origin-right data-[swipe-direction=right]:[--closed-transform:translate3d(calc(100%+var(--drawer-inset,0px)+2px),0,0)] data-[swipe-direction=right]:[--translate-x:calc(var(--drawer-swipe-movement-x)-var(--stack-peek-offset)-(var(--stack-shrink)*100%))]"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Dialog

  @doc """
  Groups all parts of the drawer.

      <.drawer id="confirm">
        <:trigger>Delete</:trigger>
        <:title>Are you sure?</:title>
        <:description>This cannot be undone.</:description>
        Deleting removes the component and its spec.
      </.drawer>

  Opening and closing runs entirely on the client. The focus moves in when it
  opens and returns to the trigger when it closes, because a keyboard reader
  who loses their place on the page has lost the page.
  """
  attr(:id, :string, required: true, doc: "Every id inside the dialog derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether it starts open.")
  attr(:alert, :boolean, default: false, doc: "An alert dialog interrupts; a dialog does not.")
  attr(:dismissable, :boolean, default: true, doc: "Whether Escape and the backdrop close it.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")
  attr(:modal, :boolean, default: true, doc: "Whether the drawer makes the page behind it inert.")
  attr(:nested, :boolean, default: false, doc: "Whether this drawer is inside another drawer.")
  attr(:parent, :string, default: nil, doc: "The id of the parent drawer.")

  attr(:disable_pointer_dismissal, :boolean,
    default: false,
    doc: "Whether a pointer outside a non-modal drawer can dismiss it."
  )

  attr(:show_close_button, :boolean,
    default: true,
    doc: "Whether the popup draws its own close button."
  )

  attr(:snap_points, :list, default: [], doc: "The heights a drawer settles at.")
  attr(:class, :any, default: nil, doc: "Appended to the dialog's own class string.")
  attr(:content_class, :any, default: nil)
  attr(:footer_class, :any, default: nil)
  attr(:header_class, :any, default: nil)
  attr(:overlay_class, :any, default: nil)
  attr(:close_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:portal_class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:viewport_class, :any, default: nil)
  attr(:show_swipe_handle, :boolean, default: false)

  attr(:swipe_direction, :string,
    default: "down",
    values: ["down", "left", "right", "up"]
  )

  attr(:trigger_variant, :string,
    default: "secondary",
    values: ["default", "destructive", "outline", "secondary", "ghost", "link"]
  )

  attr(:trigger_size, :string,
    default: "default",
    values: ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"]
  )

  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:title, doc: "What names it. Required for a dialog to be announced.")
  slot(:description, doc: "What describes it, beyond the title.")
  slot(:footer, doc: "Actions, along the bottom.")

  slot :close, doc: "A button that closes the drawer." do
    attr(:variant, :string)
    attr(:size, :string)
    attr(:class, :any)
    attr(:disabled, :boolean)
  end

  slot(:inner_block, required: true, doc: "The dialog's body.")

  def drawer(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      data-slot="drawer-trigger"
      id={Dialog.trigger_id(@id)}
      type="button"
      disabled={@disabled}
      aria-haspopup="dialog"
      aria-expanded={to_string(@open)}
      aria-controls={Dialog.popup_id(@id)}
      phx-click={if(not @disabled, do: open(@id))}
      phx-mounted={Dialog.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-disabled={flag(@disabled)}
      variant={@trigger_variant}
      size={@trigger_size}
      class={@trigger_class}
    >
      {render_slot(@trigger)}
    </LiveShadcn.UI.Button.button>
    <.portal id={"#{@id}-portal"} target="body" class={["contents", @portal_class]}>
    <div
      :if={@modal and not @nested}
      data-slot="drawer-overlay"
      id={Dialog.backdrop_id(@id)}
      role="presentation"
      aria-hidden="true"
      hidden={not @open}
      phx-click={if(@dismissable, do: close(@id))}
      phx-mounted={Dialog.owned_attributes(:backdrop)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      data-snap-points={flag(@snap_points != [])}
      class={[
        upstream_fact("jsx/DrawerOverlay/class/0"),
        (@overlay_class || "")
      ]}
      data-lb-style-target
      data-lb-measure
    />
    <div
      data-slot="drawer-viewport"
      id={viewport_id(@id)}
      data-modal={to_string(@modal)}
      hidden={not @open}
      phx-mounted={JS.ignore_attributes(["hidden"], [])}
      class={[
        upstream_fact("jsx/DrawerContent/class/0"),
        @viewport_class
      ]}
    >
      <div
        data-slot="drawer-popup"
        id={Dialog.popup_id(@id)}
        role={if(@alert, do: "alertdialog", else: "dialog")}
        aria-labelledby={if(@title != [], do: Dialog.title_id(@id))}
        aria-describedby={if(@description != [], do: Dialog.description_id(@id))}
        tabindex="-1"
        hidden={not @open}
        phx-hook="LiveBase.Drawer"
        data-lb-backdrop={if(@modal and not @nested, do: Dialog.backdrop_id(@id))}
        data-lb-dismissible={flag(@dismissable)}
        data-lb-modal={flag(@modal)}
        data-lb-parent={if(@parent, do: Dialog.popup_id(@parent))}
        data-lb-disable-pointer-dismissal={flag(@disable_pointer_dismissal)}
        data-lb-snap-points={if(@snap_points != [], do: Jason.encode!(@snap_points))}
        data-lb-trigger={Dialog.trigger_id(@id)}
        data-lb-viewport={viewport_id(@id)}
        phx-mounted={Dialog.owned_attributes(:popup)}
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        data-swipe-axis={if(@swipe_direction in ["down", "up"], do: "y", else: "x")}
        data-swipe-direction={@swipe_direction}
        data-snap-points={flag(@snap_points != [])}
        class={[
          upstream_fact("port/class/0"),
          (@class || "")
        ]}
        data-lb-measure
        {@rest}
      >
        <div
          :if={@show_swipe_handle}
          data-slot="drawer-swipe-handle"
          aria-hidden="true"
          class={upstream_fact("jsx/DrawerSwipeHandle/class/0")}
        />
        <div
          data-slot="drawer-content"
          class={[upstream_fact("jsx/DrawerContent/class/13"), @content_class]}
        >
          <div
            :if={@title != [] or @description != []}
            data-slot="drawer-header"
            class={[upstream_fact("jsx/DrawerHeader/class/0"), @header_class]}
          >
            <h2
              :if={@title != []}
              data-slot="drawer-title"
              id={Dialog.title_id(@id)}
              class={[upstream_fact("jsx/DrawerTitle/class/0"), (@title_class || "")]}
            >
              {render_slot(@title)}
            </h2>
            <p
              :if={@description != []}
              data-slot="drawer-description"
              id={Dialog.description_id(@id)}
              class={[upstream_fact("jsx/DrawerDescription/class/0"), (@description_class || "")]}
            >
              {render_slot(@description)}
            </p>
          </div>
          {render_slot(@inner_block)}
          <div
            :if={@footer != [] or @close != []}
            data-slot="drawer-footer"
            class={[upstream_fact("jsx/DrawerFooter/class/0"), @footer_class]}
          >
            {render_slot(@footer)}
            <LiveShadcn.UI.Button.button
              :for={close <- @close}
              data-slot="drawer-close"
              type="button"
              phx-click={close(@id)}
              disabled={close[:disabled] || false}
              variant={close[:variant] || "default"}
              size={close[:size] || "default"}
              class={[close[:class], @close_class]}
            >
              {render_slot(close)}
            </LiveShadcn.UI.Button.button>
          </div>
        </div>
      </div>
    </div>
    </.portal>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp viewport_id(id), do: "#{id}-viewport"

  defp open(id) do
    %JS{}
    |> JS.remove_attribute("hidden", to: "##{viewport_id(id)}")
    |> Dialog.open(id, :popup)
  end

  defp close(id), do: Dialog.close(id)
end
