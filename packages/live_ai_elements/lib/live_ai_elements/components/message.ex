defmodule LiveAiElements.Components.Message do
  @moduledoc """
  Message.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Message/class/0" => "group flex w-full max-w-[95%] flex-col gap-2",
    "jsx/Message/class/1" => "is-user ml-auto justify-end",
    "jsx/Message/class/2" => "is-assistant",
    "jsx/MessageAction/class/0" => "sr-only",
    "jsx/MessageActions/class/0" => "flex items-center gap-1",
    "jsx/MessageBranch/class/0" => "grid w-full gap-2 [&>div]:pb-0",
    "jsx/MessageBranchContent/class/0" => "grid gap-2 overflow-hidden [&>div]:pb-0",
    "jsx/MessageBranchContent/class/1" => "block",
    "jsx/MessageBranchContent/class/2" => "hidden",
    "jsx/MessageBranchPage/class/0" =>
      "border-none bg-transparent text-muted-foreground shadow-none",
    "jsx/MessageBranchSelector/class/0" =>
      "[&>*:not(:first-child)]:rounded-l-md [&>*:not(:last-child)]:rounded-r-md",
    "jsx/MessageToolbar/class/0" => "mt-4 flex w-full items-center justify-between gap-4",
    "jsx/anonymous/class/0" => "size-full [&>*:first-child]:mt-0 [&>*:last-child]:mb-0",
    "port/class/0" =>
      "is-user:dark flex w-fit min-w-0 max-w-full flex-col gap-2 overflow-hidden text-sm group-[.is-user]:ml-auto group-[.is-user]:rounded-lg group-[.is-user]:bg-secondary group-[.is-user]:px-4 group-[.is-user]:py-3 group-[.is-user]:text-foreground group-[.is-assistant]:text-foreground"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `message` part."
  attr(:from, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/Message/class/0"),
        if(@from == "user", do: upstream_fact("jsx/Message/class/1"), else: upstream_fact("jsx/Message/class/2")),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_content(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/MessageActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message_action` part."
  attr(:button, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:size, :string, default: "icon-sm")
  attr(:tooltip, :string, default: nil)
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def message_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button type="button" size={@size} variant={@variant} {@rest}>
      {render_slot(@inner_block)}<span class={upstream_fact("jsx/MessageAction/class/0")}>{@label || @tooltip}</span>
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `message_branch` part."
  attr(:default_branch, :any, default: 0)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_branch(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/MessageBranch/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message_branch_content` part."
  attr(:children_array, :any, default: nil)
  attr(:current_branch, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_branch_content(assigns) do
    ~H"""
    <div
      :for={{branch, index} <- Enum.with_index(@children_array)}
      class={[
        upstream_fact("jsx/MessageBranchContent/class/0"),
        if(index == @current_branch, do: upstream_fact("jsx/MessageBranchContent/class/1"), else: upstream_fact("jsx/MessageBranchContent/class/2"))
      ]}
      {@rest}
    >
      {branch}{render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `message_branch_selector` part."
  attr(:orientation, :string, default: "horizontal")
  attr(:total_branches, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_branch_selector(assigns) do
    ~H"""
    <LiveShadcn.UI.ButtonGroup.button_group
      :if={!(@total_branches <= 1)}
      orientation={@orientation}
      class={[upstream_fact("jsx/MessageBranchSelector/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.ButtonGroup.button_group>
    """
  end

  @doc "The `message_branch_previous` part."
  attr(:size, :string, default: "icon-sm")
  attr(:total_branches, :string, default: nil)
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def message_branch_previous(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      aria-label="Previous branch"
      disabled={@total_branches <= 1}
      type="button"
      size={@size}
      variant={@variant}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="chevron-left" width="14" height="14" />
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `message_branch_next` part."
  attr(:size, :string, default: "icon-sm")
  attr(:total_branches, :string, default: nil)
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def message_branch_next(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      aria-label="Next branch"
      disabled={@total_branches <= 1}
      type="button"
      size={@size}
      variant={@variant}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="chevron-right" width="14" height="14" />
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `message_branch_page` part."
  attr(:current_branch, :any, default: nil)
  attr(:total_branches, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_branch_page(assigns) do
    ~H"""
    <LiveShadcn.UI.ButtonGroup.button_group_text
      class={[upstream_fact("jsx/MessageBranchPage/class/0"), (@class || "")]}
      {@rest}
    >
      {@current_branch + 1} of {@total_branches}{render_slot(@inner_block)}
    </LiveShadcn.UI.ButtonGroup.button_group_text>
    """
  end

  @doc "The `message_response` part."
  attr(:content, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_response(assigns) do
    ~H"""
    <LiveAiElements.Markdown.markdown
      content={@content}
      class={[upstream_fact("jsx/anonymous/class/0"), @class]}
    />
    """
  end

  @doc "The `message_toolbar` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def message_toolbar(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/MessageToolbar/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
