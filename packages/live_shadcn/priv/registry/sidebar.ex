defmodule LiveShadcn.UI.Sidebar do
  @moduledoc """
  Sidebar.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/sidebarMenuButtonVariants/base" => "cn-sidebar-menu-button peer/menu-button group/menu-button flex w-full items-center overflow-hidden outline-hidden disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 [&_svg]:size-4 [&_svg]:shrink-0 [&>span:last-child]:truncate",
    "cva/sidebarMenuButtonVariants/default/size" => "default",
    "cva/sidebarMenuButtonVariants/default/variant" => "default",
    "cva/sidebarMenuButtonVariants/variant/size/default" => "cn-sidebar-menu-button-size-default",
    "cva/sidebarMenuButtonVariants/variant/size/lg" => "cn-sidebar-menu-button-size-lg",
    "cva/sidebarMenuButtonVariants/variant/size/sm" => "cn-sidebar-menu-button-size-sm",
    "cva/sidebarMenuButtonVariants/variant/variant/default" => "cn-sidebar-menu-button-variant-default",
    "cva/sidebarMenuButtonVariants/variant/variant/outline" => "cn-sidebar-menu-button-variant-outline",
    "jsx/Sidebar/class/10" => "fixed inset-y-0 z-10 hidden h-svh w-(--sidebar-width) transition-[left,right,width] duration-200 ease-linear data-[side=left]:left-0 data-[side=left]:group-data-[collapsible=offcanvas]:left-[calc(var(--sidebar-width)*-1)] data-[side=right]:right-0 data-[side=right]:group-data-[collapsible=offcanvas]:right-[calc(var(--sidebar-width)*-1)] md:flex",
    "jsx/Sidebar/class/11" => "p-2 group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4))+2px)]",
    "jsx/Sidebar/class/12" => "group-data-[collapsible=icon]:w-(--sidebar-width-icon) group-data-[side=left]:border-r group-data-[side=right]:border-l",
    "jsx/Sidebar/class/13" => "cn-sidebar-inner flex size-full flex-col",
    "jsx/Sidebar/class/2" => "sr-only",
    "jsx/Sidebar/class/4" => "group peer hidden text-sidebar-foreground md:block",
    "jsx/Sidebar/class/8" => "group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4)))]",
    "jsx/Sidebar/class/9" => "group-data-[collapsible=icon]:w-(--sidebar-width-icon)",
    "jsx/SidebarContent/class/0" => "cn-sidebar-content flex min-h-0 flex-1 flex-col overflow-auto group-data-[collapsible=icon]:overflow-hidden",
    "jsx/SidebarFooter/class/0" => "cn-sidebar-footer flex flex-col",
    "jsx/SidebarGroup/class/0" => "cn-sidebar-group relative flex w-full min-w-0 flex-col",
    "jsx/SidebarGroupAction/class/0" => "cn-sidebar-group-action flex aspect-square items-center justify-center outline-hidden transition-transform group-data-[collapsible=icon]:hidden after:absolute after:-inset-2 md:after:hidden [&>svg]:shrink-0",
    "jsx/SidebarGroupContent/class/0" => "cn-sidebar-group-content w-full",
    "jsx/SidebarGroupLabel/class/0" => "cn-sidebar-group-label flex shrink-0 items-center outline-hidden [&>svg]:shrink-0",
    "jsx/SidebarHeader/class/0" => "cn-sidebar-header flex flex-col",
    "jsx/SidebarInput/class/0" => "cn-sidebar-input",
    "jsx/SidebarInset/class/0" => "cn-sidebar-inset relative flex w-full flex-1 flex-col",
    "jsx/SidebarMenu/class/0" => "cn-sidebar-menu flex w-full min-w-0 flex-col",
    "jsx/SidebarMenuAction/class/0" => "cn-sidebar-menu-action flex items-center justify-center outline-hidden transition-transform group-data-[collapsible=icon]:hidden after:absolute after:-inset-2 md:after:hidden [&>svg]:shrink-0",
    "jsx/SidebarMenuAction/class/1" => "group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 peer-data-active/menu-button:text-sidebar-accent-foreground aria-expanded:opacity-100 md:opacity-0",
    "jsx/SidebarMenuBadge/class/0" => "cn-sidebar-menu-badge flex items-center justify-center tabular-nums select-none group-data-[collapsible=icon]:hidden",
    "jsx/SidebarMenuItem/class/0" => "group/menu-item relative",
    "jsx/SidebarMenuSkeleton/class/0" => "cn-sidebar-menu-skeleton flex items-center",
    "jsx/SidebarMenuSkeleton/class/1" => "cn-sidebar-menu-skeleton-icon",
    "jsx/SidebarMenuSkeleton/class/2" => "cn-sidebar-menu-skeleton-text max-w-(--skeleton-width) flex-1",
    "jsx/SidebarMenuSub/class/0" => "cn-sidebar-menu-sub flex min-w-0 flex-col",
    "jsx/SidebarMenuSubButton/class/0" => "cn-sidebar-menu-sub-button flex min-w-0 -translate-x-px items-center overflow-hidden outline-hidden group-data-[collapsible=icon]:hidden disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 [&>span:last-child]:truncate [&>svg]:shrink-0",
    "jsx/SidebarMenuSubItem/class/0" => "group/menu-sub-item relative",
    "jsx/SidebarSeparator/class/0" => "cn-sidebar-separator w-auto",
    "jsx/SidebarTrigger/class/0" => "cn-sidebar-trigger",
    "jsx/SidebarTrigger/class/1" => "cn-rtl-flip",
    "port/class/0" => "cn-sidebar-gap relative w-(--sidebar-width) bg-transparent group-data-[collapsible=offcanvas]:w-0 group-data-[side=right]:rotate-180",
    "port/class/1" => "cn-sidebar-rail absolute inset-y-0 z-20 hidden w-4 transition-all ease-linear group-data-[side=left]:-right-4 group-data-[side=right]:left-0 after:absolute after:inset-y-0 after:start-1/2 after:w-[2px] sm:flex ltr:-translate-x-1/2 rtl:-translate-x-1/2 in-data-[side=left]:cursor-w-resize in-data-[side=right]:cursor-e-resize [[data-side=left][data-state=collapsed]_&]:cursor-e-resize [[data-side=right][data-state=collapsed]_&]:cursor-w-resize group-data-[collapsible=offcanvas]:translate-x-0 group-data-[collapsible=offcanvas]:after:left-full hover:group-data-[collapsible=offcanvas]:bg-sidebar [[data-side=left][data-collapsible=offcanvas]_&]:-right-2 [[data-side=right][data-collapsible=offcanvas]_&]:-left-2"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                       [table, "variant", group, choice] <- [String.split(path, "/")],
                       reduce: %{} do
    variants ->
      put_in(
        variants,
        [
          Access.key(table, %{}),
          Access.key(group, %{}),
          Access.key(choice, nil)
        ],
        value
      )
  end)

  alias LiveBase.Sidebar

  @doc """
  A navigation panel that collapses.

      <.sidebar id="nav" collapsible="icon">
        <.sidebar_content>…</.sidebar_content>
      </.sidebar>

  Collapsing and expanding runs entirely on the client. The server is not
  told, and does not need to be: whether a reader has the navigation open
  is a fact about their window rather than about the application's data.
  """

  attr(:id, :string, required: true, doc: "What a trigger names to open it.")
  attr(:open, :boolean, default: true, doc: "Whether it starts expanded.")
  attr(:side, :string, default: "left", values: ["left", "right"])
  attr(:variant, :string, default: "sidebar", values: ["sidebar", "floating", "inset"])

  attr(:collapsible, :string,
    default: "offcanvas",
    values: ["offcanvas", "icon"],
    doc: "What is left behind when it collapses: a strip of icons, or nothing."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)
  slot(:inner_block)

  def sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      data-state={if(@open, do: "expanded", else: "collapsed")}
      data-collapsible={if(@open, do: "", else: @collapsible)}
      data-side={@side}
      data-variant={@variant}
      phx-mounted={Sidebar.owned_attributes(:sidebar)}
      data-slot="sidebar"
      class={upstream_fact("jsx/Sidebar/class/4")}
    >
      <div
        data-slot="sidebar-gap"
        class={[
          upstream_fact("port/class/0"),
          if(@variant == "floating" || @variant == "inset",
            do: upstream_fact("jsx/Sidebar/class/8"),
            else: upstream_fact("jsx/Sidebar/class/9")
          )
        ]}
      />
      <div
        data-slot={@rest[:"data-slot"] || "sidebar-container"}
        data-side={@side}
        class={[
          upstream_fact("jsx/Sidebar/class/10"),
          if(@variant == "floating" || @variant == "inset",
            do:
              upstream_fact("jsx/Sidebar/class/11"),
            else:
              upstream_fact("jsx/Sidebar/class/12")
          ),
          @class
        ]}
        {Map.drop(@rest, [:"data-slot"])}
      >
        <div
          data-slot="sidebar-inner"
          data-sidebar="sidebar"
          class={upstream_fact("jsx/Sidebar/class/13")}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc "The `sidebar-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-content"}
      data-sidebar="content"
      class={[
        upstream_fact("jsx/SidebarContent/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-footer` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_footer(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-footer"}
      data-sidebar="footer"
      class={[upstream_fact("jsx/SidebarFooter/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-group"}
      data-sidebar="group"
      class={[upstream_fact("jsx/SidebarGroup/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-group-action` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def sidebar_group_action(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "sidebar-group-action"}
      data-sidebar="group-action"
      class={[
        upstream_fact("jsx/SidebarGroupAction/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `sidebar-group-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_group_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-group-content"}
      data-sidebar="group-content"
      class={[upstream_fact("jsx/SidebarGroupContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-group-label` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_group_label(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-group-label"}
      data-sidebar="group-label"
      class={[
        upstream_fact("jsx/SidebarGroupLabel/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_header(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-header"}
      data-sidebar="header"
      class={[upstream_fact("jsx/SidebarHeader/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-input` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "type",
      "name",
      "value",
      "placeholder",
      "checked",
      "min",
      "max",
      "step",
      "minlength",
      "maxlength",
      "pattern",
      "readonly",
      "multiple",
      "autocomplete",
      "disabled",
      "required"
    ]
  )

  def sidebar_input(assigns) do
    ~H"""
    <LiveShadcn.UI.Input.input
      data-slot={@rest[:"data-slot"] || "sidebar-input"}
      data-sidebar="input"
      class={[upstream_fact("jsx/SidebarInput/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    />
    """
  end

  @doc "The `sidebar-inset` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_inset(assigns) do
    ~H"""
    <main
      data-slot={@rest[:"data-slot"] || "sidebar-inset"}
      class={[upstream_fact("jsx/SidebarInset/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </main>
    """
  end

  @doc "The `sidebar-menu` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu(assigns) do
    ~H"""
    <ul
      data-slot={@rest[:"data-slot"] || "sidebar-menu"}
      data-sidebar="menu"
      class={[upstream_fact("jsx/SidebarMenu/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc "The `sidebar-menu-action` part."
  attr(:show_on_hover, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def sidebar_menu_action(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "sidebar-menu-action"}
      data-sidebar="menu-action"
      class={[
        upstream_fact("jsx/SidebarMenuAction/class/0"),
        if(@show_on_hover,
          do:
            upstream_fact("jsx/SidebarMenuAction/class/1"),
          else: nil
        ),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `sidebar-menu-badge` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu_badge(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-menu-badge"}
      data-sidebar="menu-badge"
      class={[
        upstream_fact("jsx/SidebarMenuBadge/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-menu-button` part."
  attr(:comp, :string, default: nil)
  attr(:is_active, :boolean, default: false)
  attr(:is_mobile, :string, default: nil)

  attr(:size, :string,
    default: @upstream_facts["cva/sidebarMenuButtonVariants/default/size"],
    values:
      @variant_classes
      |> get_in(["sidebarMenuButtonVariants", "size"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:state, :string, default: nil)
  attr(:tooltip, :string, default: nil)

  attr(:variant, :string,
    default: @upstream_facts["cva/sidebarMenuButtonVariants/default/variant"],
    values:
      @variant_classes
      |> get_in(["sidebarMenuButtonVariants", "variant"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def sidebar_menu_button(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "sidebar-menu-button"}
      data-active={to_string(@is_active)}
      data-sidebar="menu-button"
      data-size={@size}
      class={[
        variant_class("sidebarMenuButtonVariants", "size", @size),
        variant_class("sidebarMenuButtonVariants", "variant", @variant),
        upstream_fact("cva/sidebarMenuButtonVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `sidebar-menu-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu_item(assigns) do
    ~H"""
    <li
      data-slot={@rest[:"data-slot"] || "sidebar-menu-item"}
      data-sidebar="menu-item"
      class={[upstream_fact("jsx/SidebarMenuItem/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `sidebar-menu-skeleton` part."
  attr(:show_icon, :boolean, default: false)
  attr(:width, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu_skeleton(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-menu-skeleton"}
      data-sidebar="menu-skeleton"
      class={[upstream_fact("jsx/SidebarMenuSkeleton/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.UI.Skeleton.skeleton
        :if={@show_icon}
        data-sidebar="menu-skeleton-icon"
        class={upstream_fact("jsx/SidebarMenuSkeleton/class/1")}
      />
      <LiveShadcn.UI.Skeleton.skeleton
        data-sidebar="menu-skeleton-text"
        style={"--skeleton-width: #{@width}"}
        class={upstream_fact("jsx/SidebarMenuSkeleton/class/2")}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `sidebar-menu-sub` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu_sub(assigns) do
    ~H"""
    <ul
      data-slot={@rest[:"data-slot"] || "sidebar-menu-sub"}
      data-sidebar="menu-sub"
      class={[upstream_fact("jsx/SidebarMenuSub/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc "The `sidebar-menu-sub-button` part."
  attr(:is_active, :boolean, default: false)
  attr(:size, :string, default: "md", values: ["sm", "md"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"])
  slot(:inner_block)

  def sidebar_menu_sub_button(assigns) do
    ~H"""
    <a
      data-slot={@rest[:"data-slot"] || "sidebar-menu-sub-button"}
      data-active={to_string(@is_active)}
      data-sidebar="menu-sub-button"
      data-size={@size}
      class={[
        upstream_fact("jsx/SidebarMenuSubButton/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  @doc "The `sidebar-menu-sub-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_menu_sub_item(assigns) do
    ~H"""
    <li
      data-slot={@rest[:"data-slot"] || "sidebar-menu-sub-item"}
      data-sidebar="menu-sub-item"
      class={[upstream_fact("jsx/SidebarMenuSubItem/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc "The `sidebar-provider` part."
  attr(:style, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_provider(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "sidebar-wrapper"}
      style={"--sidebar-width: 16rem; --sidebar-width-icon: 3rem; #{@style}"}
      class={[
        "group/sidebar-wrapper flex w-full has-data-[variant=inset]:bg-sidebar",
        minimum_height_class(@class),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp minimum_height_class(class) do
    if Enum.any?(List.wrap(class), &(is_binary(&1) and String.starts_with?(&1, "min-h-"))) do
      nil
    else
      "min-h-svh"
    end
  end

  @doc """
  The strip down the sidebar's edge, which does what the trigger does.

  It is `tabindex="-1"` and named for a screen reader, because it is a
  second way to reach a control that already has a first one.
  """

  attr(:for, :string, required: true, doc: "The id of the sidebar this opens.")
  attr(:open, :boolean, default: true, doc: "Whether that sidebar starts expanded.")

  attr(:collapsible, :string,
    default: "offcanvas",
    values: ["offcanvas", "icon"],
    doc: "The same value the sidebar was given."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)
  slot(:inner_block)

  def sidebar_rail(assigns) do
    ~H"""
    <button
      data-lb-sidebar={@for}
      aria-expanded={to_string(@open)}
      phx-click={Sidebar.toggle(sidebar: @for, collapsible: @collapsible)}
      phx-mounted={Sidebar.owned_attributes(:trigger)}
      data-slot={@rest[:"data-slot"] || "sidebar-rail"}
      data-sidebar="rail"
      aria-label="Toggle Sidebar"
      tabindex={-1}
      title="Toggle Sidebar"
      class={[
        upstream_fact("port/class/1"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `sidebar-separator` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sidebar_separator(assigns) do
    ~H"""
    <LiveShadcn.UI.Separator.separator
      data-slot={@rest[:"data-slot"] || "sidebar-separator"}
      data-sidebar="separator"
      class={[upstream_fact("jsx/SidebarSeparator/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Separator.separator>
    """
  end

  @doc """
  The button that collapses and expands a sidebar.

      <.sidebar_trigger for="nav" collapsible="icon" />

  It names the sidebar rather than sitting inside it, because it does not:
  a trigger belongs in the header across the top of the page. React reaches
  the same fact through a context, which HEEx does not have.
  """

  attr(:for, :string, required: true, doc: "The id of the sidebar this opens.")
  attr(:open, :boolean, default: true, doc: "Whether that sidebar starts expanded.")

  attr(:collapsible, :string,
    default: "offcanvas",
    values: ["offcanvas", "icon"],
    doc: "The same value the sidebar was given."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)
  slot(:inner_block)

  def sidebar_trigger(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      data-lb-sidebar={@for}
      phx-click={Sidebar.toggle(sidebar: @for, collapsible: @collapsible)}
      phx-mounted={Sidebar.owned_attributes(:trigger)}
      data-slot={@rest[:"data-slot"] || "sidebar-trigger"}
      data-sidebar="trigger"
      variant="ghost"
      size="icon-sm"
      class={[upstream_fact("jsx/SidebarTrigger/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <LiveShadcn.Icon.icon name="panel-left" class={upstream_fact("jsx/SidebarTrigger/class/1")} /><span class={upstream_fact("jsx/Sidebar/class/2")}>Toggle Sidebar</span>{render_slot(
        @inner_block
      )}
    </LiveShadcn.UI.Button.button>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end
