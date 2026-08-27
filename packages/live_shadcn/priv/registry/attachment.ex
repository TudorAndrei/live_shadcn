defmodule LiveShadcn.UI.Attachment do
  @moduledoc """
  Attachment.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/attachmentMediaVariants/base" =>
      "cn-attachment-media relative flex aspect-square shrink-0 items-center justify-center overflow-hidden group-data-[state=error]/attachment:bg-destructive/10 group-data-[state=error]/attachment:text-destructive [&_svg]:pointer-events-none",
    "cva/attachmentMediaVariants/default/variant" => "icon",
    "cva/attachmentMediaVariants/variant/variant/icon" => "cn-attachment-media-variant-icon",
    "cva/attachmentMediaVariants/variant/variant/image" =>
      "cn-attachment-media-variant-image *:[img]:aspect-square *:[img]:w-full *:[img]:object-cover",
    "cva/attachmentVariants/base" =>
      "cn-attachment group/attachment relative flex max-w-full min-w-0 shrink-0 flex-wrap border bg-card text-card-foreground transition-colors has-[>a,>button]:hover:bg-muted/50 data-[state=error]:border-destructive/30 data-[state=idle]:border-dashed",
    "cva/attachmentVariants/variant/orientation/horizontal" =>
      "cn-attachment-orientation-horizontal items-center",
    "cva/attachmentVariants/variant/orientation/vertical" =>
      "cn-attachment-orientation-vertical flex-col",
    "cva/attachmentVariants/variant/size/default" => "cn-attachment-size-default",
    "cva/attachmentVariants/variant/size/sm" => "cn-attachment-size-sm",
    "cva/attachmentVariants/variant/size/xs" => "cn-attachment-size-xs",
    "jsx/AttachmentAction/class/0" => "cn-attachment-action",
    "jsx/AttachmentActions/class/0" => "cn-attachment-actions flex shrink-0 items-center",
    "jsx/AttachmentContent/class/0" => "cn-attachment-content max-w-full min-w-0 flex-1",
    "jsx/AttachmentGroup/class/0" =>
      "cn-attachment-group flex min-w-0 scroll-fade-x snap-x snap-mandatory scrollbar-none overflow-x-auto overscroll-x-contain *:data-[slot=attachment]:flex-none *:data-[slot=attachment]:snap-start",
    "jsx/AttachmentTitle/class/0" =>
      "cn-attachment-title block max-w-full min-w-0 truncate group-data-[state=processing]/attachment:shimmer group-data-[state=uploading]/attachment:shimmer",
    "jsx/AttachmentTrigger/class/0" => "cn-attachment-trigger absolute inset-0 z-10 outline-none",
    "port/class/0" =>
      "cn-attachment-description block min-w-0 truncate text-muted-foreground group-data-[state=error]/attachment:text-destructive/80 max-w-full"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                       [table, "variant", group, choice] <- [String.split(path, "/")],
                       reduce: %{} do
    variants ->
      put_in(
        variants,
        [
          Access.key(table, %{}),
          Access.key(group, %{}),
          Access.key(choice, nil)
        ],
        value
      )
  end)

  @doc "The `attachment` part."
  attr(:orientation, :string,
    default: "horizontal",
    values:
      @variant_classes
      |> get_in(["attachmentVariants", "orientation"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:size, :string,
    default: "default",
    values:
      @variant_classes |> get_in(["attachmentVariants", "size"]) |> Map.keys() |> Enum.sort()
  )

  attr(:state, :string,
    default: "done",
    values: ["idle", "uploading", "processing", "error", "done"]
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "attachment"}
      data-state={@state}
      data-size={@size}
      data-orientation={@orientation}
      class={[
        variant_class("attachmentVariants", "orientation", @orientation),
        variant_class("attachmentVariants", "size", @size),
        upstream_fact("cva/attachmentVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "attachment-group"}
      class={[
        upstream_fact("jsx/AttachmentGroup/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment-media` part."
  attr(:variant, :string,
    default: @upstream_facts["cva/attachmentMediaVariants/default/variant"],
    values:
      @variant_classes
      |> get_in(["attachmentMediaVariants", "variant"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_media(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "attachment-media"}
      data-variant={@variant}
      class={[
        variant_class("attachmentMediaVariants", "variant", @variant),
        upstream_fact("cva/attachmentMediaVariants/base"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment-content` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_content(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "attachment-content"}
      class={[upstream_fact("jsx/AttachmentContent/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment-title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_title(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "attachment-title"}
      class={[
        upstream_fact("jsx/AttachmentTitle/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `attachment-description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_description(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "attachment-description"}
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `attachment-actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_actions(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "attachment-actions"}
      class={[upstream_fact("jsx/AttachmentActions/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment-action` part."
  attr(:size, :string, default: "icon-xs")
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def attachment_action(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      data-slot={@rest[:"data-slot"] || "attachment-action"}
      variant={@variant || "ghost"}
      size={@size}
      class={[upstream_fact("jsx/AttachmentAction/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `attachment-trigger` part."
  attr(:type, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def attachment_trigger(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "attachment-trigger"}
      class={[upstream_fact("jsx/AttachmentTrigger/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end