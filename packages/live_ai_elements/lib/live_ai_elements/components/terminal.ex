defmodule LiveAiElements.Components.Terminal do
  @moduledoc """
  Terminal.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Terminal/class/0" => "flex flex-col overflow-hidden rounded-lg border bg-zinc-950 text-zinc-100",
    "jsx/Terminal/class/1" => "flex items-center gap-1",
    "jsx/TerminalClearButton/class/0" => "size-7 shrink-0 text-zinc-400 hover:bg-zinc-800 hover:text-zinc-100",
    "jsx/TerminalContent/class/0" => "max-h-96 overflow-auto p-4 font-mono text-sm leading-relaxed",
    "jsx/TerminalContent/class/1" => "whitespace-pre-wrap break-words",
    "jsx/TerminalContent/class/2" => "ml-0.5 inline-block h-4 w-2 animate-pulse bg-zinc-100",
    "jsx/TerminalHeader/class/0" => "flex items-center justify-between border-zinc-800 border-b px-4 py-2",
    "jsx/TerminalStatus/class/0" => "flex items-center gap-2 text-xs text-zinc-400",
    "jsx/TerminalTitle/class/0" => "flex items-center gap-2 text-sm text-zinc-400",
    "jsx/TerminalTitle/class/1" => "size-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `terminal_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal_header(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/TerminalHeader/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `terminal_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal_title(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TerminalTitle/class/0"), (@class || "")]} {@rest}>
      <LiveShadcn.Icon.icon name="terminal" class={upstream_fact("jsx/TerminalTitle/class/1")} />
      <%= if @inner_block == [] do %>
        Terminal
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `terminal_status` part."
  attr(:is_streaming, :boolean, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal_status(assigns) do
    ~H"""
    <div :if={@is_streaming} class={[upstream_fact("jsx/TerminalStatus/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `terminal_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/Terminal/class/1"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `terminal_copy_button` part."
  attr(:size, :string, default: "icon")
  attr(:timeout, :any, default: 2000)
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:output, :string, required: true, doc: "The output the button copies.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def terminal_copy_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={@output}
      data-lb-timeout={@timeout}
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/TerminalClearButton/class/0"), @class]}
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

  @doc "The `terminal_clear_button` part."
  attr(:size, :string, default: "icon")
  attr(:variant, :string, default: "ghost")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def terminal_clear_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      :if={true}
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/TerminalClearButton/class/0"), @class]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="trash-2" width="14" height="14" />
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `terminal_content` part."
  attr(:is_streaming, :boolean, default: nil)
  attr(:output, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/TerminalContent/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        <pre phx-no-format class={upstream_fact("jsx/TerminalContent/class/1")}><LiveAiElements.Ansi.ansi content={@output} /><span :if={@is_streaming} class={upstream_fact("jsx/TerminalContent/class/2")} /></pre>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `terminal` part."
  attr(:auto_scroll, :boolean, default: true)
  attr(:id, :string, default: nil)
  attr(:is_streaming, :boolean, default: false)
  attr(:output, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def terminal(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/Terminal/class/0"), (@class || "")]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <.terminal_header>
          <.terminal_title />
          <div class={upstream_fact("jsx/Terminal/class/1")}>
            <.terminal_status is_streaming={@is_streaming} />
            <.terminal_actions>
              <.terminal_copy_button id={@id} output={@output} />
              <.terminal_clear_button :if={true} />
            </.terminal_actions>
          </div>
        </.terminal_header>
        <.terminal_content is_streaming={@is_streaming} output={@output} />
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
