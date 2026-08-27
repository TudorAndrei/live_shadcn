defmodule LiveAiElements.Components.PackageInfo do
  @moduledoc """
  Package info.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/PackageInfo/class/0" => "rounded-lg border bg-background p-4",
    "jsx/PackageInfoChangeType/class/0" => "gap-1 text-xs capitalize",
    "jsx/PackageInfoContent/class/0" => "mt-3 border-t pt-3",
    "jsx/PackageInfoDependencies/class/0" => "space-y-2",
    "jsx/PackageInfoDependencies/class/1" => "font-medium text-muted-foreground text-xs uppercase tracking-wide",
    "jsx/PackageInfoDependencies/class/2" => "space-y-1",
    "jsx/PackageInfoDependency/class/0" => "flex items-center justify-between text-sm",
    "jsx/PackageInfoDependency/class/1" => "font-mono text-muted-foreground",
    "jsx/PackageInfoDependency/class/2" => "font-mono text-xs",
    "jsx/PackageInfoDescription/class/0" => "mt-2 text-muted-foreground text-sm",
    "jsx/PackageInfoHeader/class/0" => "flex items-center justify-between gap-2",
    "jsx/PackageInfoName/class/0" => "flex items-center gap-2",
    "jsx/PackageInfoName/class/1" => "size-4 text-muted-foreground",
    "jsx/PackageInfoName/class/2" => "font-medium font-mono text-sm",
    "jsx/PackageInfoVersion/class/0" => "mt-2 flex items-center gap-2 font-mono text-muted-foreground text-sm",
    "jsx/PackageInfoVersion/class/1" => "size-3",
    "jsx/PackageInfoVersion/class/2" => "font-medium text-foreground"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `package_info_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_header(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfoHeader/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `package_info_name` part."
  attr(:name, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_name(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfoName/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="package" class={upstream_fact("jsx/PackageInfoName/class/1")} />
      <span class={upstream_fact("jsx/PackageInfoName/class/2")}>
        <%= if @inner_block == [] do %>
          {@name}
        <% end %>
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  @doc "The `package_info_change_type` part."
  attr(:change_type, :string, default: nil)
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_change_type(assigns) do
    ~H"""
    <LiveShadcn.UI.Badge.badge
      :if={@change_type}
      variant={@variant}
      class={[
        upstream_fact("jsx/PackageInfoChangeType/class/0"),
        if(@change_type == "added",
          do: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
          else: nil
        ),
        if(@change_type == "major",
          do: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
          else: nil
        ),
        if(@change_type == "minor",
          do: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
          else: nil
        ),
        if(@change_type == "patch",
          do: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
          else: nil
        ),
        if(@change_type == "removed",
          do: "bg-gray-100 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400",
          else: nil
        ),
        @class
      ]}
      {@rest}
    >
      <LiveShadcn.Icon.icon :if={@change_type == "added"} name="plus" class={upstream_fact("jsx/PackageInfoVersion/class/1")} />
      <LiveShadcn.Icon.icon :if={@change_type == "major"} name="arrow-right" class={upstream_fact("jsx/PackageInfoVersion/class/1")} />
      <LiveShadcn.Icon.icon :if={@change_type == "minor"} name="arrow-right" class={upstream_fact("jsx/PackageInfoVersion/class/1")} />
      <LiveShadcn.Icon.icon :if={@change_type == "patch"} name="arrow-right" class={upstream_fact("jsx/PackageInfoVersion/class/1")} />
      <LiveShadcn.Icon.icon :if={@change_type == "removed"} name="minus" class={upstream_fact("jsx/PackageInfoVersion/class/1")} />
      <%= if @inner_block == [] do %>
        {@change_type}
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Badge.badge>
    """
  end

  @doc "The `package_info_version` part."
  attr(:current_version, :string, default: nil)
  attr(:new_version, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_version(assigns) do
    ~H"""
    <div
      :if={@current_version || @new_version}
      class={[upstream_fact("jsx/PackageInfoVersion/class/0"), (@class || "")]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <span :if={@current_version}>
          {@current_version}
        </span>
        <LiveShadcn.Icon.icon
          :if={@current_version && @new_version}
          name="arrow-right"
          class={upstream_fact("jsx/PackageInfoVersion/class/1")}
        />
        <span :if={@new_version} class={upstream_fact("jsx/PackageInfoVersion/class/2")}>
          {@new_version}
        </span>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `package_info` part."
  attr(:change_type, :string, default: nil)
  attr(:current_version, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:new_version, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfo/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <.package_info_header>
          <.package_info_name name={@name} />
          <.package_info_change_type :if={@change_type} change_type={@change_type} />
        </.package_info_header>
        <.package_info_version
          :if={@current_version || @new_version}
          current_version={@current_version}
          new_version={@new_version}
        />
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `package_info_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_description(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/PackageInfoDescription/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `package_info_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfoContent/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `package_info_dependencies` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_dependencies(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfoDependencies/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/PackageInfoDependencies/class/1")}>
        Dependencies
      </span>
      <div class={upstream_fact("jsx/PackageInfoDependencies/class/2")}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `package_info_dependency` part."
  attr(:name, :string, default: nil)
  attr(:version, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def package_info_dependency(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PackageInfoDependency/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <span class={upstream_fact("jsx/PackageInfoDependency/class/1")}>
          {@name}
        </span>
        <span :if={@version} class={upstream_fact("jsx/PackageInfoDependency/class/2")}>
          {@version}
        </span>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
