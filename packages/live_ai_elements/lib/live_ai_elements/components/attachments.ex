defmodule LiveAiElements.Components.Attachments do
  @moduledoc """
  Attachments.

  Upstream exports 3 more parts, each a thin
  wrapper around a part of `<.hover_card>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Attachment/class/0" => "group relative",
    "jsx/Attachment/class/1" => "size-24 overflow-hidden rounded-lg",
    "jsx/AttachmentEmpty/class/0" => "flex items-center justify-center p-4 text-muted-foreground text-sm",
    "jsx/AttachmentInfo/class/0" => "min-w-0 flex-1",
    "jsx/AttachmentInfo/class/1" => "block truncate",
    "jsx/AttachmentInfo/class/2" => "block truncate text-muted-foreground text-xs",
    "jsx/AttachmentPreview/class/0" => "flex shrink-0 items-center justify-center overflow-hidden",
    "jsx/AttachmentPreview/class/1" => "size-full bg-muted",
    "jsx/AttachmentPreview/class/2" => "size-5 rounded bg-background",
    "jsx/AttachmentPreview/class/3" => "size-12 rounded bg-muted",
    "jsx/AttachmentRemove/class/10" => "sr-only",
    "jsx/Attachments/class/0" => "flex items-start",
    "jsx/Attachments/class/1" => "flex-col gap-2",
    "jsx/Attachments/class/2" => "flex-wrap gap-2",
    "jsx/Attachments/class/3" => "ml-auto w-fit",
    "port/class/0" => "absolute top-2 right-2 size-6 rounded-full p-0 bg-background/80 backdrop-blur-sm opacity-0 transition-opacity group-hover:opacity-100 hover:bg-background [&>svg]:size-3",
    "port/class/1" => "flex h-8 cursor-pointer select-none items-center gap-1.5 rounded-md border border-border px-1.5 font-medium text-sm transition-all hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
    "port/class/2" => "flex w-full items-center gap-3 rounded-lg border p-3 hover:bg-accent/50",
    "port/class/3" => "size-5 rounded p-0 opacity-0 transition-opacity group-hover:opacity-100 [&>svg]:size-2.5",
    "port/class/4" => "size-8 shrink-0 rounded p-0 [&>svg]:size-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `attachments` part."
  attr(:variant, :string, default: "grid")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachments(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/Attachments/class/0"),
        if(@variant == "list", do: upstream_fact("jsx/Attachments/class/1"), else: upstream_fact("jsx/Attachments/class/2")),
        if(@variant == "grid", do: upstream_fact("jsx/Attachments/class/3"), else: nil),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment` part."
  attr(:data, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/Attachment/class/0"),
        if(@variant == "grid", do: upstream_fact("jsx/Attachment/class/1"), else: nil),
        if(@variant == "inline",
          do:
            upstream_fact("port/class/1"),
          else: nil
        ),
        if(@variant == "list",
          do: upstream_fact("port/class/2"),
          else: nil
        ),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment_preview` part."
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:render_content)
  slot(:inner_block)

  def attachment_preview(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/AttachmentPreview/class/0"),
        if(@variant == "grid", do: upstream_fact("jsx/AttachmentPreview/class/1"), else: nil),
        if(@variant == "inline", do: upstream_fact("jsx/AttachmentPreview/class/2"), else: nil),
        if(@variant == "list", do: upstream_fact("jsx/AttachmentPreview/class/3"), else: nil),
        @class
      ]}
      {@rest}
    >
      {render_slot(@render_content)}{render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment_info` part."
  attr(:data, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:show_media_type, :boolean, default: false)
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_info(assigns) do
    ~H"""
    <div :if={!(@variant == "grid")} class={[upstream_fact("jsx/AttachmentInfo/class/0"), (@class || "")]} {@rest}>
      <span class={upstream_fact("jsx/AttachmentInfo/class/1")}>
        {@label}
      </span>
      <span
        :if={@show_media_type && @data.mediaType}
        class={upstream_fact("jsx/AttachmentInfo/class/2")}
      >
        {@data.mediaType}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment_remove` part."
  attr(:label, :string, default: "Remove")
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def attachment_remove(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      :if={true}
      aria-label={@label}
      type="button"
      size={@size}
      variant="ghost"
      class={[
        if(@variant == "grid",
          do:
            upstream_fact("port/class/0"),
          else: nil
        ),
        if(@variant == "inline",
          do:
            upstream_fact("port/class/3"),
          else: nil
        ),
        if(@variant == "list", do: upstream_fact("port/class/4"), else: nil),
        @class
      ]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="x" />
      <% end %>
      {render_slot(@inner_block)}
      <span class={upstream_fact("jsx/AttachmentRemove/class/10")}>
        {@label}
      </span>
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `attachment_empty` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_empty(assigns) do
    ~H"""
    <div
      class={[upstream_fact("jsx/AttachmentEmpty/class/0"), (@class || "")]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        No attachments
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
