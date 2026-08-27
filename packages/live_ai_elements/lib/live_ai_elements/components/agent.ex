defmodule LiveAiElements.Components.Agent do
  @moduledoc """
  Agent. Built on `shadcn/accordion`.

  Upstream exports 1 more part, each a thin
  wrapper around a part of `<.accordion>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "file/ai_elements/agent.tsx/jsx/anonymous/class/0" => "not-prose w-full rounded-md border",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/1" =>
      "flex w-full items-center justify-between gap-4 p-3",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/10" => "space-y-2",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/11" =>
      "font-medium text-muted-foreground text-sm",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/2" => "flex items-center gap-2",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/3" => "size-4 text-muted-foreground",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/4" => "font-medium text-sm",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/5" => "font-mono text-xs",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/6" => "space-y-4 p-4 pt-0",
    "file/ai_elements/agent.tsx/jsx/anonymous/class/9" =>
      "rounded-md bg-muted/50 p-3 text-muted-foreground text-sm",
    "jsx/anonymous/class/16" => "rounded-md bg-muted/50",
    "port/class/0" => "cn-accordion flex w-full flex-col rounded-md border"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `agent` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `agent_header` part."
  attr(:model, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:variant, :string, default: "secondary")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent_header(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/1"), (@class || "")]} {@rest}>
      <div class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/2")}>
        <LiveShadcn.Icon.icon name="bot" class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/3")} />
        <span class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/4")}>
          {@name}
        </span>
        <LiveShadcn.UI.Badge.badge :if={@model} variant={@variant} class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/5")}>
          {@model}
        </LiveShadcn.UI.Badge.badge>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `agent_content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent_content(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/6"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `agent_instructions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent_instructions(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/10"), (@class || "")]} {@rest}>
      <span class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/11")}>
        Instructions
      </span>
      <div class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/9")}>
        <p>
          {render_slot(@inner_block)}
        </p>
      </div>
    </div>
    """
  end

  @doc "The `agent_tools` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent_tools(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/10"), (@class || "")]}>
      <span class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/11")}>
        Tools
      </span>
      <div
        data-slot={@rest[:"data-slot"] || "accordion"}
        class={upstream_fact("port/class/0")}
        {Map.drop(@rest, [:"data-slot"])}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "The `agent_output` part."
  attr(:schema, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def agent_output(assigns) do
    ~H"""
    <div class={[upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/10"), (@class || "")]} {@rest}>
      <span class={upstream_fact("file/ai_elements/agent.tsx/jsx/anonymous/class/11")}>
        Output Schema
      </span>
      <div class={upstream_fact("jsx/anonymous/class/16")}>
        <LiveAiElements.Components.CodeBlock.code_block code={@schema} language="typescript" />
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
