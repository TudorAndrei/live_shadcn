defmodule LiveAiElements.Components.Attachments do
  @moduledoc """
  Attachments.

  The hover-card parts keep the same public composition as upstream.
  They compose the local hover-card component.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn
  alias LiveBase.Popover

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Attachment/class/0" => "group relative",
    "jsx/Attachment/class/1" => "size-24 overflow-hidden rounded-lg",
    "jsx/AttachmentEmpty/class/0" =>
      "flex items-center justify-center p-4 text-muted-foreground text-sm",
    "jsx/AttachmentHoverCardContent/class/0" => "w-auto p-2",
    "jsx/AttachmentInfo/class/0" => "min-w-0 flex-1",
    "jsx/AttachmentInfo/class/1" => "block truncate",
    "jsx/AttachmentInfo/class/2" => "block truncate text-muted-foreground text-xs",
    "jsx/AttachmentPreview/class/0" =>
      "flex shrink-0 items-center justify-center overflow-hidden",
    "jsx/AttachmentPreview/class/1" => "size-full bg-muted",
    "jsx/AttachmentPreview/class/2" => "size-5 rounded bg-background",
    "jsx/AttachmentPreview/class/3" => "size-12 rounded bg-muted",
    "jsx/AttachmentRemove/class/0" => "absolute top-2 right-2 size-6 rounded-full p-0",
    "jsx/AttachmentRemove/class/1" => "bg-background/80 backdrop-blur-sm",
    "jsx/AttachmentRemove/class/10" => "sr-only",
    "jsx/AttachmentRemove/class/3" => "hover:bg-background",
    "jsx/AttachmentRemove/class/4" => "[&>svg]:size-3",
    "jsx/AttachmentRemove/class/5" => "size-5 rounded p-0",
    "jsx/AttachmentRemove/class/6" => "opacity-0 transition-opacity group-hover:opacity-100",
    "jsx/AttachmentRemove/class/7" => "[&>svg]:size-2.5",
    "jsx/AttachmentRemove/class/8" => "size-8 shrink-0 rounded p-0",
    "jsx/AttachmentRemove/class/9" => "[&>svg]:size-4",
    "jsx/Attachments/class/0" => "flex items-start",
    "jsx/Attachments/class/1" => "flex-col gap-2",
    "jsx/Attachments/class/2" => "flex-wrap gap-2",
    "jsx/Attachments/class/3" => "ml-auto w-fit",
    "port/class/0" =>
      "absolute top-2 right-2 size-6 rounded-full p-0 bg-background/80 backdrop-blur-sm opacity-0 transition-opacity group-hover:opacity-100 hover:bg-background [&>svg]:size-3",
    "port/class/1" =>
      "flex h-8 cursor-pointer select-none items-center gap-1.5 rounded-md border border-border px-1.5 font-medium text-sm transition-all hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
    "port/class/2" => "flex w-full items-center gap-3 rounded-lg border p-3 hover:bg-accent/50",
    "port/class/3" =>
      "size-5 rounded p-0 opacity-0 transition-opacity group-hover:opacity-100 [&>svg]:size-2.5",
    "port/class/4" => "size-8 shrink-0 rounded p-0 [&>svg]:size-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `attachments` part."
  attr(:variant, :string, default: "grid", values: ~w(grid inline list))
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])

  slot(:inner_block,
    doc:
      "The attachments. Bind `:let={attachments}` to receive `%{variant: variant}` for each child attachment."
  )

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
      {render_slot(@inner_block, %{variant: @variant})}
    </div>
    """
  end

  @doc "The `attachment` part."
  attr(:data, :map, required: true)
  attr(:variant, :string, default: "grid", values: ~w(grid inline list))
  attr(:on_remove, :any, default: nil, doc: "The caller-owned remove action.")

  attr(:hover_card, :map,
    default: nil,
    doc: "The trigger context from `attachment_hover_card_trigger/1`."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment(assigns) do
    hover_card = assigns.hover_card || %{}

    assigns =
      assigns
      |> assign(:hover_card, hover_card)
      |> assign(
        :attachment_rest,
        Map.merge(Map.drop(assigns.rest, [:"data-slot"]), Map.get(hover_card, :rest, %{}))
      )

    ~H"""
    <div
      id={@hover_card[:trigger_id]}
      data-slot={if @hover_card == %{}, do: @rest[:"data-slot"], else: "hover-card-trigger"}
      aria-controls={@hover_card[:popup_id]}
      phx-window-keydown={@hover_card[:close]}
      phx-key={if @hover_card == %{}, do: nil, else: "Escape"}
      phx-hook={if @hover_card == %{}, do: nil, else: "LiveBase.InteractionTrigger"}
      data-lb-anchor={@hover_card[:trigger_id]}
      data-lb-positioner={@hover_card[:positioner_id]}
      data-lb-open-on-hover={if @hover_card == %{}, do: nil, else: ""}
      data-lb-open-delay={if @hover_card == %{}, do: nil, else: to_string(@hover_card[:delay])}
      data-lb-close-delay={if @hover_card == %{}, do: nil, else: to_string(@hover_card[:close_delay])}
      phx-click={@hover_card[:toggle]}
      phx-mounted={@hover_card[:mounted]}
      data-popup-open={if(@hover_card[:open], do: "", else: nil)}
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
        @class,
        @hover_card[:class]
      ]}
      {@attachment_rest}
    >
      <%= if @inner_block == [] do %>
        <%= if @variant == "inline" do %>
          <div class="relative size-5 shrink-0">
            <div class="absolute inset-0 transition-opacity group-hover:opacity-0">
              <.attachment_preview data={@data} variant={@variant} />
            </div>
            <.attachment_remove
              on_remove={@on_remove}
              variant={@variant}
              class="absolute inset-0"
            />
          </div>
          <.attachment_info data={@data} variant={@variant} />
        <% else %>
          <.attachment_preview data={@data} variant={@variant} />
          <.attachment_info
            :if={@variant == "list"}
            data={@data}
            show_media_type
            variant={@variant}
          />
          <.attachment_remove on_remove={@on_remove} variant={@variant} />
        <% end %>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  @doc "The `attachment_preview` part."
  attr(:data, :map, required: true)
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:fallback_icon)
  slot(:render_content)
  slot(:inner_block)

  def attachment_preview(assigns) do
    assigns =
      assigns
      |> assign(:attachment, assigns.data)
      |> assign(:media_category, media_category(assigns.data))
      |> assign(:label, attachment_label(assigns.data))
      |> assign(:variant, assigns.variant || "grid")

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
      <img
        :if={@media_category == :image and attachment_url(@attachment)}
        alt={@label}
        class={if(@variant == "grid", do: "size-full object-cover", else: "size-full rounded object-cover")}
        height={if(@variant == "grid", do: 96, else: 20)}
        src={attachment_url(@attachment)}
        width={if(@variant == "grid", do: 96, else: 20)}
      />
      <video
        :if={@media_category == :video and attachment_url(@attachment)}
        class="size-full object-cover"
        muted
        src={attachment_url(@attachment)}
      ></video>
      <%= if !((@media_category == :image or @media_category == :video) and attachment_url(@attachment)) do %>
        {render_slot(@fallback_icon)}{render_slot(@render_content)}{render_slot(@inner_block)}
        <LiveShadcn.Icon.icon
          :if={@fallback_icon == [] and @render_content == [] and @inner_block == []}
          name={media_icon(@media_category)}
          class={if(@variant == "inline", do: "size-3 text-muted-foreground", else: "size-4 text-muted-foreground")}
        />
      <% end %>
    </div>
    """
  end

  @doc "The `attachment_info` part."
  attr(:data, :map, required: true)
  attr(:label, :string, default: nil)
  attr(:show_media_type, :boolean, default: false)
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_info(assigns) do
    assigns =
      assigns
      |> assign(:label, assigns.label || attachment_label(assigns.data))
      |> assign(:variant, assigns.variant || "grid")

    ~H"""
    <div
      :if={!(@variant == "grid")}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/AttachmentInfo/class/0"), @class])}
      {@rest}
    >
      <span class={upstream_fact("jsx/AttachmentInfo/class/1")}>
        {@label}
      </span>
      <span
        :if={@show_media_type && data_value(@data, :mediaType)}
        class={upstream_fact("jsx/AttachmentInfo/class/2")}
      >
        {data_value(@data, :mediaType)}
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `attachment_remove` part."
  attr(:label, :string, default: "Remove")
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default", values: ~w(default grid inline list))
  attr(:on_remove, :any, default: nil, doc: "The caller-owned remove action.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def attachment_remove(assigns) do
    assigns =
      assigns
      |> assign(:variant, if(assigns.variant == "default", do: "grid", else: assigns.variant))

    ~H"""
    <button
      :if={!is_nil(@on_remove)}
      data-slot={@rest[:"data-slot"] || "button"}
      data-lb-attachment-remove="v1"
      aria-label={@label}
      type="button"
      phx-click={@on_remove}
      class={LiveShadcn.Cn.merge([
        Shadcn.button_class("default", "ghost"),
        remove_class(@variant),
        @class
      ])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon name="x" />
      <% end %>
      {render_slot(@inner_block)}
      <span class={upstream_fact("jsx/AttachmentRemove/class/10")}>
        {@label}
      </span>
    </button>
    """
  end

  @doc "The `attachment_hover_card` part."
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  attr(:side, :string,
    default: "bottom",
    values: ~w(top right bottom left inline-start inline-end)
  )

  attr(:align, :string, default: "start", values: ~w(start center end))
  attr(:offset, :integer, default: 4)
  attr(:autofocus, :boolean, default: false)
  attr(:dir, :string, default: "ltr", values: ~w(ltr rtl))
  attr(:delay, :integer, default: 0)
  attr(:close_delay, :integer, default: 0)
  attr(:align_offset, :integer, default: 0)
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_variant, :string, default: "link")
  attr(:trigger_size, :string, default: "default")
  attr(:trigger_as, :string, default: "span", values: ~w(button span))

  slot(:inner_block,
    required: true,
    doc:
      "Bind `:let={hover_card}` and pass it to `attachment_hover_card_trigger/1` and `attachment_hover_card_content/1`."
  )

  def attachment_hover_card(assigns) do
    context = %{
      id: assigns.id,
      open: assigns.open,
      disabled: assigns.disabled,
      side: assigns.side,
      align: assigns.align,
      offset: assigns.offset,
      autofocus: assigns.autofocus,
      dir: assigns.dir,
      delay: assigns.delay,
      close_delay: assigns.close_delay,
      align_offset: assigns.align_offset,
      trigger_class: assigns.trigger_class,
      trigger_variant: assigns.trigger_variant,
      trigger_size: assigns.trigger_size,
      trigger_as: assigns.trigger_as
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    {render_slot(@inner_block, @context)}
    """
  end

  @doc "The `attachment_hover_card_trigger` part."
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:delay, :integer, default: 0)
  attr(:close_delay, :integer, default: 0)
  attr(:variant, :string, default: "link")
  attr(:size, :string, default: "default")
  attr(:as, :string, default: "span", values: ~w(button span))

  attr(:as_child, :boolean,
    default: false,
    doc: "Pass the trigger context to a child attachment with `:let`."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def attachment_hover_card_trigger(assigns) do
    trigger = %{
      trigger_id: Popover.trigger_id(assigns.id),
      popup_id: Popover.popup_id(assigns.id),
      positioner_id: Popover.positioner_id(assigns.id),
      open: assigns.open,
      delay: assigns.delay,
      close_delay: assigns.close_delay,
      toggle: if(not assigns.disabled, do: Popover.toggle(assigns.id)),
      close: Popover.close(assigns.id),
      mounted: Popover.owned_attributes(:trigger),
      class: assigns.class,
      rest: assigns.rest
    }

    assigns = assign(assigns, :trigger, trigger)

    ~H"""
    <%= if @as_child do %>
      {render_slot(@inner_block, @trigger)}
    <% else %>
      <LiveShadcn.UI.HoverCard.hover_card_trigger
        id={@id}
        open={@open}
        disabled={@disabled}
        delay={@delay}
        close_delay={@close_delay}
        variant={@variant}
        size={@size}
        as={@as}
        class={@class}
        {@rest}
      >
        {render_slot(@inner_block)}
      </LiveShadcn.UI.HoverCard.hover_card_trigger>
    <% end %>
    """
  end

  @doc "The `attachment_hover_card_content` part."
  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)

  attr(:side, :string,
    default: "bottom",
    values: ~w(top right bottom left inline-start inline-end)
  )

  attr(:align, :string, default: "start", values: ~w(start center end))
  attr(:offset, :integer, default: 4)
  attr(:autofocus, :boolean, default: false)
  attr(:dir, :string, default: "ltr", values: ~w(ltr rtl))
  attr(:align_offset, :integer, default: 0)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def attachment_hover_card_content(assigns) do
    ~H"""
    <LiveShadcn.UI.HoverCard.hover_card_content
      id={@id}
      open={@open}
      side={@side}
      align={@align}
      offset={@offset}
      autofocus={@autofocus}
      dir={@dir}
      align_offset={@align_offset}
      class={LiveShadcn.Cn.merge([
        upstream_fact("jsx/AttachmentHoverCardContent/class/0"),
        "!w-auto !rounded-md !border !p-2 !text-base !leading-6 !ring-0",
        @class
      ])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.HoverCard.hover_card_content>
    """
  end

  @doc "The `attachment_empty` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def attachment_empty(assigns) do
    ~H"""
    <div
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/AttachmentEmpty/class/0"), @class])}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        No attachments
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp media_category(data) do
    cond do
      data_value(data, :type) == "source-document" -> :source
      String.starts_with?(data_value(data, :mediaType) || "", "image/") -> :image
      String.starts_with?(data_value(data, :mediaType) || "", "video/") -> :video
      String.starts_with?(data_value(data, :mediaType) || "", "audio/") -> :audio
      String.starts_with?(data_value(data, :mediaType) || "", "application/") -> :document
      String.starts_with?(data_value(data, :mediaType) || "", "text/") -> :document
      true -> :unknown
    end
  end

  defp attachment_label(data) do
    if data_value(data, :type) == "source-document" do
      data_value(data, :title) || data_value(data, :filename) || "Source"
    else
      data_value(data, :filename) ||
        if(media_category(data) == :image, do: "Image", else: "Attachment")
    end
  end

  defp attachment_url(data), do: data_value(data, :url)
  defp data_value(data, key), do: Map.get(data, key) || Map.get(data, Atom.to_string(key))

  defp remove_class("grid") do
    [
      upstream_fact("jsx/AttachmentRemove/class/0"),
      upstream_fact("jsx/AttachmentRemove/class/1"),
      upstream_fact("jsx/AttachmentRemove/class/6"),
      upstream_fact("jsx/AttachmentRemove/class/3"),
      upstream_fact("jsx/AttachmentRemove/class/4")
    ]
  end

  defp remove_class("inline") do
    [
      upstream_fact("jsx/AttachmentRemove/class/5"),
      upstream_fact("jsx/AttachmentRemove/class/6"),
      upstream_fact("jsx/AttachmentRemove/class/7")
    ]
  end

  defp remove_class("list") do
    [
      upstream_fact("jsx/AttachmentRemove/class/8"),
      upstream_fact("jsx/AttachmentRemove/class/9")
    ]
  end

  defp media_icon(:audio), do: "music-2"
  defp media_icon(:document), do: "file-text"
  defp media_icon(:image), do: "image"
  defp media_icon(:source), do: "globe"
  defp media_icon(:video), do: "video"
  defp media_icon(:unknown), do: "paperclip"
end
