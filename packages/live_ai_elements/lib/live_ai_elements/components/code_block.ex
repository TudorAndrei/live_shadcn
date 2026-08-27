defmodule LiveAiElements.Components.CodeBlock do
  @moduledoc """
  Code block.

  Upstream exports 5 more parts, each a thin
  wrapper around a part of `<.select>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/CodeBlockActions/class/0" => "-my-1 -mr-1 flex items-center gap-2",
    "jsx/CodeBlockContainer/class/0" =>
      "group relative w-full overflow-hidden rounded-md border bg-background text-foreground",
    "jsx/CodeBlockContent/class/0" => "relative overflow-auto",
    "jsx/CodeBlockCopyButton/class/0" => "shrink-0",
    "jsx/CodeBlockFilename/class/0" => "font-mono",
    "jsx/CodeBlockHeader/class/0" =>
      "flex items-center justify-between border-b bg-muted/80 px-3 py-2 text-muted-foreground text-xs",
    "jsx/CodeBlockTitle/class/0" => "flex items-center gap-2",
    "jsx/TokenSpan/class/0" => "dark:!bg-[var(--shiki-dark-bg)] dark:!text-[var(--shiki-dark)]",
    "jsx/anonymous/class/0" => "block",
    "jsx/anonymous/class/10" =>
      "dark:!bg-[var(--shiki-dark-bg)] dark:!text-[var(--shiki-dark)] m-0 p-4 text-sm",
    "jsx/anonymous/class/11" => "font-mono text-sm",
    "jsx/anonymous/class/12" => "[counter-increment:line_0] [counter-reset:line]",
    "port/class/0" =>
      "block before:content-[counter(line)] before:inline-block before:[counter-increment:line] before:w-8 before:mr-4 before:text-right before:text-muted-foreground/50 before:font-mono before:select-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `code_block_container` part."
  attr(:language, :string, default: nil)
  attr(:style, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_container(assigns) do
    ~H"""
    <div
      data-language={@language}
      style={"#{@style}; contain-intrinsic-size: auto 200px; content-visibility: auto"}
      class={[
        upstream_fact("jsx/CodeBlockContainer/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `code_block_header` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_header(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/CodeBlockHeader/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `code_block_title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_title(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CodeBlockTitle/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `code_block_filename` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_filename(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/CodeBlockFilename/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `code_block_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/CodeBlockActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `code_block_content` part."
  attr(:code, :string, default: nil)
  attr(:keyed_line, :any, default: nil)
  attr(:keyed_lines, :any, default: nil)
  attr(:language, :string, default: nil)
  attr(:pre_style, :string, default: nil)
  attr(:show_line_numbers, :boolean, default: false)
  attr(:token, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block_content(assigns) do
    ~H"""
    <div class={upstream_fact("jsx/CodeBlockContent/class/0")}>
      <pre
        phx-no-format
        style=""
        class={[
          upstream_fact("jsx/anonymous/class/10"),
          @class
        ]}
      ><code class={[upstream_fact("jsx/anonymous/class/11"), if(@show_line_numbers, do: upstream_fact("jsx/anonymous/class/12"), else: nil)]}>
      <span :for={keyedLine <- @keyed_lines} class={[if(@show_line_numbers, do: upstream_fact("port/class/0"), else: upstream_fact("jsx/anonymous/class/0"))]}>
        \n
        <span :if={!(length(keyedLine.tokens) == 0)} :for={item <- keyedLine.tokens} style={"background-color: #{item.token.bgColor}; color: #{item.token.color}; font-style: #{if(Bitwise.band(item.token.fontStyle || 0, 1) != 0, do: "italic", else: nil)}; font-weight: #{if(Bitwise.band(item.token.fontStyle || 0, 2) != 0, do: "bold", else: nil)}; text-decoration: #{if(Bitwise.band(item.token.fontStyle || 0, 4) != 0, do: "underline", else: nil)}"} class={upstream_fact("jsx/TokenSpan/class/0")}>
          {item.token.content}
        </span>
      </span>
    </code></pre>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `code_block` part."
  attr(:code, :string, default: nil)
  attr(:language, :string, default: nil)
  attr(:show_line_numbers, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def code_block(assigns) do
    ~H"""
    <.code_block_container language={@language} class={[@class]} {@rest}>
      {render_slot(@inner_block)}
      <.code_block_content code={@code} language={@language} show_line_numbers={@show_line_numbers} />
    </.code_block_container>
    """
  end

  @doc "The `code_block_copy_button` part."
  attr(:size, :string, default: "icon")
  attr(:timeout, :any, default: 2000)
  attr(:variant, :string, default: "ghost")
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:code, :string, required: true, doc: "The code the button copies.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def code_block_copy_button(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      id={@id}
      phx-hook={LiveBase.Clipboard.hook()}
      phx-mounted={LiveBase.Clipboard.owned_attributes()}
      data-lb-clipboard={@code}
      data-lb-timeout={@timeout}
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/CodeBlockCopyButton/class/0"), @class]}
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
end
