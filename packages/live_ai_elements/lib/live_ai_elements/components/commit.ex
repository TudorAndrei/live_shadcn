defmodule LiveAiElements.Components.Commit do
  @moduledoc """
  Commit.

  Upstream exports 2 more parts, each a thin
  wrapper around a part of `<.collapsible>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/CommitActions/class/0" => "flex items-center gap-1",
    "jsx/CommitAuthor/class/0" => "flex items-center",
    "jsx/CommitAuthorAvatar/class/0" => "size-8",
    "jsx/CommitAuthorAvatar/class/1" => "text-xs",
    "jsx/CommitCopyButton/class/0" => "size-7 shrink-0",
    "jsx/CommitFile/class/0" => "flex items-center justify-between gap-2 rounded px-2 py-1 text-sm hover:bg-muted/50",
    "jsx/CommitFileAdditions/class/0" => "text-green-600 dark:text-green-400",
    "jsx/CommitFileAdditions/class/1" => "inline-block size-3",
    "jsx/CommitFileChanges/class/0" => "flex shrink-0 items-center gap-1 font-mono text-xs",
    "jsx/CommitFileDeletions/class/0" => "text-red-600 dark:text-red-400",
    "jsx/CommitFileIcon/class/0" => "size-3.5 shrink-0 text-muted-foreground",
    "jsx/CommitFileInfo/class/0" => "flex min-w-0 items-center gap-2",
    "jsx/CommitFilePath/class/0" => "truncate font-mono text-xs",
    "jsx/CommitFileStatus/class/0" => "font-medium font-mono text-xs",
    "jsx/CommitFiles/class/0" => "space-y-1",
    "jsx/CommitHash/class/0" => "font-mono text-xs",
    "jsx/CommitHash/class/1" => "mr-1 inline-block size-3",
    "jsx/CommitHeader/class/0" => "group flex cursor-pointer items-center justify-between gap-4 p-3 text-left transition-colors hover:opacity-80",
    "jsx/CommitInfo/class/0" => "flex flex-1 flex-col",
    "jsx/CommitMessage/class/0" => "font-medium text-sm",
    "jsx/CommitMetadata/class/0" => "flex items-center gap-2 text-muted-foreground text-xs"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `commit_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_header(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/CommitHeader/class/0"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_hash` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_hash(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/CommitHash/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="git-commit-horizontal" class={upstream_fact("jsx/CommitHash/class/1")} />{render_slot(
        @inner_block
      )}
    </span>
    """
  end

  @doc "The `commit_message` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_message(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/CommitMessage/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `commit_metadata` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_metadata(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitMetadata/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_separator` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_separator(assigns) do
    ~H"""
    <span class={[@class]} {@rest}>
      <%= if @inner_block == [] do %>
        •
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `commit_info` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_info(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitInfo/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_author` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_author(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitAuthor/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_author_avatar` part."
  attr(:initials, :string, default: nil)
  attr(:size, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_author_avatar(assigns) do
    ~H"""
    <LiveShadcn.UI.Avatar.avatar size={@size} class={[upstream_fact("jsx/CommitAuthorAvatar/class/0"), @class]} {@rest}>
      <LiveShadcn.UI.Avatar.avatar_fallback class={upstream_fact("jsx/CommitAuthorAvatar/class/1")}>
        {@initials}
      </LiveShadcn.UI.Avatar.avatar_fallback>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Avatar.avatar>
    """
  end

  @doc "The `commit_timestamp` part."
  attr(:date, :any, default: nil)
  attr(:formatted, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "datetime"])
  slot(:inner_block)

  def commit_timestamp(assigns) do
    ~H"""
    <time datetime={@date} class={[upstream_fact("jsx/CommitAuthorAvatar/class/1"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@formatted}
      <% end %>
      {render_slot(@inner_block)}
    </time>
    """
  end

  @doc "The `commit_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_actions(assigns) do
    ~H"""
    <div role="group" class={[upstream_fact("jsx/CommitActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_copy_button` part."
  attr(:hash, :string, default: nil)
  attr(:size, :string, default: "icon")
  attr(:timeout, :any, default: 2000)
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def commit_copy_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={@hash}
      data-lb-timeout={@timeout}
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/CommitCopyButton/class/0"), @class]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon data-lb-state="copied" hidden name="check" width="14" height="14" />
        <LiveShadcn.Icon.icon data-lb-state="idle" name="copy" width="14" height="14" />
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `commit_files` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_files(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitFiles/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_file` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/CommitFile/class/0"),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_file_info` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_info(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitFileInfo/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_file_status` part."
  attr(:status, :string, default: nil, values: [nil, "added", "modified", "deleted", "renamed"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_status(assigns) do
    ~H"""
    <span
      class={[
        upstream_fact("jsx/CommitFileStatus/class/0"),
        if(@status == "added", do: upstream_fact("jsx/CommitFileAdditions/class/0"), else: nil),
        if(@status == "deleted", do: upstream_fact("jsx/CommitFileDeletions/class/0"), else: nil),
        if(@status == "modified", do: "text-yellow-600 dark:text-yellow-400", else: nil),
        if(@status == "renamed", do: "text-blue-600 dark:text-blue-400", else: nil),
        @class
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {Map.get(%{"added" => "A", "deleted" => "D", "modified" => "M", "renamed" => "R"}, @status)}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `commit_file_icon` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_icon(assigns) do
    ~H"""
    <LiveShadcn.Icon.icon
      name="file"
      class={[upstream_fact("jsx/CommitFileIcon/class/0"), (@class || "")]}
      {@rest}
    />
    """
  end

  @doc "The `commit_file_path` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_path(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/CommitFilePath/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `commit_file_changes` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_changes(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CommitFileChanges/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `commit_file_additions` part."
  attr(:count, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_additions(assigns) do
    ~H"""
    <span :if={!(@count <= 0)} class={[upstream_fact("jsx/CommitFileAdditions/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="plus" class={upstream_fact("jsx/CommitFileAdditions/class/1")} />{@count}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `commit_file_deletions` part."
  attr(:count, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def commit_file_deletions(assigns) do
    ~H"""
    <span :if={!(@count <= 0)} class={[upstream_fact("jsx/CommitFileDeletions/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="minus" class={upstream_fact("jsx/CommitFileAdditions/class/1")} />{@count}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
