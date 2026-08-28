defmodule LiveAiElements.Components.WebPreview do
  @moduledoc """
  Web preview. Built on `shadcn/input`.

  Upstream exports 2 more parts, each a thin
  wrapper around a part of `<.tooltip>`, `<.collapsible>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/WebPreview/class/0" => "flex size-full flex-col rounded-lg border bg-card",
    "jsx/WebPreviewBody/class/0" => "flex-1",
    "jsx/WebPreviewBody/class/1" => "size-full",
    "jsx/WebPreviewNavigation/class/0" => "flex items-center gap-1 border-b p-2",
    "port/class/0" =>
      "cn-input w-full min-w-0 outline-none file:inline-flex file:border-0 file:bg-transparent file:text-foreground placeholder:text-muted-foreground disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 h-8 flex-1 text-sm"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `web_preview` part."
  attr(:id, :string, required: true)
  attr(:default_url, :string, default: "")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def web_preview(assigns) do
    ~H"""
    <div
      id={@id}
      data-default-url={@default_url}
      phx-hook="LiveAiElements.WebPreview"
      class={[upstream_fact("jsx/WebPreview/class/0"), @class || ""]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `web_preview_navigation` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def web_preview_navigation(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/WebPreviewNavigation/class/0"), @class || ""]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `input` part."
  attr(:input_value, :string, default: nil)
  attr(:type, :string, default: nil)
  attr(:value, :string, default: nil)
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

  def web_preview_url(assigns) do
    ~H"""
    <input
      data-slot={@rest[:"data-slot"] || "input"}
      data-web-preview-url
      type={@type}
      placeholder="Enter URL..."
      value={@value || @input_value}
      class={[
        Shadcn.input_class(),
        "!h-8 flex-1 text-sm",
        @class || ""
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    />
    """
  end

  @doc "The `web_preview_body` part."
  attr(:loading, :string, default: nil)
  attr(:src, :string, default: nil)
  attr(:url, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def web_preview_body(assigns) do
    ~H"""
    <div class={upstream_fact("jsx/WebPreviewBody/class/0")}>
      <iframe
        data-web-preview-body
        sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-presentation"
        src={@src || @url || nil}
        title="Preview"
        class={[upstream_fact("jsx/WebPreviewBody/class/1"), @class || ""]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </iframe>
      {@loading}
    </div>
    """
  end
end
