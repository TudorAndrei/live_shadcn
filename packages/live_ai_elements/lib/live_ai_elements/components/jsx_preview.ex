defmodule LiveAiElements.Components.JsxPreview do
  @moduledoc """
  Jsx preview.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/anonymous/class/0" => "relative",
    "jsx/anonymous/class/1" => "jsx-preview-content",
    "jsx/anonymous/class/2" => "flex items-center gap-2 rounded-md border border-destructive/50 bg-destructive/10 p-3 text-destructive text-sm",
    "jsx/anonymous/class/3" => "size-4 shrink-0"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `jsx_preview` part."
  attr(:bindings, :string, default: nil)
  attr(:components, :string, default: nil)
  attr(:is_streaming, :boolean, default: false)
  attr(:jsx, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def jsx_preview(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/anonymous/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `jsx_preview_content` part."
  attr(:bindings, :string, default: nil)
  attr(:components, :string, default: nil)
  attr(:display_jsx, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def jsx_preview_content(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/anonymous/class/1"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `jsx_preview_error` part."
  attr(:error, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def jsx_preview_error(assigns) do
    ~H"""
    <div
      :if={@error}
      class={[
        upstream_fact("jsx/anonymous/class/2"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
      <LiveShadcn.Icon.icon :if={!@children} name="circle-alert" class={upstream_fact("jsx/anonymous/class/3")} /><span :if={
        !@children
      }>{@error.message}</span>
    </div>
    """
  end
end
