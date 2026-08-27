defmodule LiveAiElements.Components.FileTree do
  @moduledoc """
  File tree. Built on `shadcn/collapsible`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/FileTree/class/0" => "rounded-lg border bg-background font-mono text-sm",
    "jsx/FileTree/class/1" => "p-2",
    "jsx/FileTreeActions/class/0" => "ml-auto flex items-center gap-1",
    "jsx/FileTreeFile/class/0" =>
      "flex cursor-pointer items-center gap-1 rounded px-2 py-1 transition-colors hover:bg-muted/50",
    "jsx/FileTreeFile/class/1" => "bg-muted",
    "jsx/FileTreeFile/class/2" => "size-4 shrink-0",
    "jsx/FileTreeFile/class/3" => "size-4 text-muted-foreground",
    "jsx/FileTreeFolder/class/1" =>
      "flex w-full items-center gap-1 rounded px-2 py-1 text-left transition-colors hover:bg-muted/50",
    "jsx/FileTreeFolder/class/3" =>
      "flex shrink-0 cursor-pointer items-center border-none bg-transparent p-0",
    "jsx/FileTreeFolder/class/4" => "size-4 shrink-0 text-muted-foreground transition-transform",
    "jsx/FileTreeFolder/class/5" => "rotate-90",
    "jsx/FileTreeFolder/class/6" =>
      "flex min-w-0 flex-1 cursor-pointer items-center gap-1 border-none bg-transparent p-0 text-left",
    "jsx/FileTreeFolder/class/7" => "size-4 text-blue-500",
    "jsx/FileTreeFolder/class/9" => "ml-4 border-l pl-2",
    "jsx/FileTreeIcon/class/0" => "shrink-0",
    "jsx/FileTreeName/class/0" => "truncate"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `file_tree` part."
  attr(:default_expanded, :string, default: nil)
  attr(:expanded, :string, default: nil)
  attr(:selected_path, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def file_tree(assigns) do
    ~H"""
    <div role="tree" class={[upstream_fact("jsx/FileTree/class/0"), (@class || "")]} {@rest}>
      <div role="group" class={upstream_fact("jsx/FileTree/class/1")}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `file_tree_icon` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def file_tree_icon(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/FileTreeIcon/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `file_tree_name` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def file_tree_name(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/FileTreeName/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `file_tree_folder` part."
  attr(:is_expanded, :string, default: nil)
  attr(:is_selected, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:path, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def file_tree_folder(assigns) do
    ~H"""
    <div
      role="none"
      data-slot={@rest[:"data-slot"] || "collapsible"}
      open={@is_expanded}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div role="treeitem" tabindex={0} aria-expanded={@is_expanded} class={[@class]} {@rest}>
        <div class={[
          upstream_fact("jsx/FileTreeFolder/class/1"),
          (if(@is_selected, do: upstream_fact("jsx/FileTreeFile/class/1"), else: nil) || "")
        ]}>
          <button
            aria-hidden="true"
            tabindex="-1"
            data-slot={@rest[:"data-slot"] || "collapsible-trigger"}
            type="button"
            class={upstream_fact("jsx/FileTreeFolder/class/3")}
            {Map.drop(@rest, [:"data-slot"])}
          >
            <LiveShadcn.Icon.icon
              name="chevron-right"
              class={[
                upstream_fact("jsx/FileTreeFolder/class/4"),
                (if(@is_expanded, do: upstream_fact("jsx/FileTreeFolder/class/5"), else: nil) || "")
              ]}
            />
          </button>
          <button
            type="button"
            class={upstream_fact("jsx/FileTreeFolder/class/6")}
          >
            <.file_tree_icon>
              <LiveShadcn.Icon.icon
                :if={@is_expanded}
                name="folder-open"
                class={upstream_fact("jsx/FileTreeFolder/class/7")}
              />
              <LiveShadcn.Icon.icon :if={!@is_expanded} name="folder" class={upstream_fact("jsx/FileTreeFolder/class/7")} />
            </.file_tree_icon>
            <.file_tree_name>
              {@name}
            </.file_tree_name>
          </button>
        </div>
        <div
          data-slot={@rest[:"data-slot"] || "collapsible-content"}
          {Map.drop(@rest, [:"data-slot"])}
        >
          <div role="group" class={upstream_fact("jsx/FileTreeFolder/class/9")}>
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc "The `file_tree_file` part."
  attr(:is_selected, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:path, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:icon)
  slot(:inner_block)

  def file_tree_file(assigns) do
    ~H"""
    <div
      role="treeitem"
      tabindex={0}
      class={[
        upstream_fact("jsx/FileTreeFile/class/0"),
        if(@is_selected, do: upstream_fact("jsx/FileTreeFile/class/1"), else: nil),
        (@class || "")
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <span class={upstream_fact("jsx/FileTreeFile/class/2")} />
        <.file_tree_icon>
          <%= if @icon == [] do %>
            <LiveShadcn.Icon.icon name="file" class={upstream_fact("jsx/FileTreeFile/class/3")} />
          <% end %>
          {render_slot(@icon)}
        </.file_tree_icon>
        <.file_tree_name>
          {@name}
        </.file_tree_name>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `file_tree_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def file_tree_actions(assigns) do
    ~H"""
    <div role="group" class={[upstream_fact("jsx/FileTreeActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
