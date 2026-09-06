defmodule LiveShadcn.UI.Dialog do
  @moduledoc """
  Dialog. Groups all parts of the dialog.

  Reviewed from shadcn/ui. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveBase.Dialog
  alias LiveShadcn.UI.Button

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/DialogContent/class/0" =>
      "cn-dialog-content fixed top-1/2 left-1/2 z-50 w-full -translate-x-1/2 -translate-y-1/2 outline-none",
    "jsx/DialogContent/class/1" => "cn-dialog-close",
    "jsx/DialogContent/class/2" => "sr-only",
    "jsx/DialogDescription/class/0" => "cn-dialog-description",
    "jsx/DialogFooter/class/0" =>
      "cn-dialog-footer flex flex-col-reverse gap-2 sm:flex-row sm:justify-end",
    "jsx/DialogHeader/class/0" => "cn-dialog-header flex flex-col",
    "jsx/DialogOverlay/class/0" => "cn-dialog-overlay fixed inset-0 isolate z-50",
    "jsx/DialogTitle/class/0" => "cn-dialog-title cn-font-heading"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  @doc """
  Groups all parts of the dialog.

      <.dialog id="confirm">
        <:trigger>Delete</:trigger>
        <:title>Are you sure?</:title>
        <:description>This cannot be undone.</:description>
        Deleting removes the component and its spec.
      </.dialog>

  Opening and closing runs entirely on the client. The focus moves in when it
  opens and returns to the trigger when it closes, because a keyboard reader
  who loses their place on the page has lost the page.
  """
  attr(:id, :string, required: true, doc: "Every id inside the dialog derives from it.")
  attr(:open, :boolean, default: false, doc: "Whether it starts open.")
  attr(:alert, :boolean, default: false, doc: "An alert dialog interrupts; a dialog does not.")
  attr(:dismissable, :boolean, default: true, doc: "Whether Escape and the backdrop close it.")
  attr(:disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction.")

  attr(:show_close_button, :boolean,
    default: true,
    doc: "Whether the popup draws its own close button."
  )

  attr(:show_trigger, :boolean,
    default: true,
    doc: "Whether this call renders the trigger."
  )

  attr(:class, :any, default: nil, doc: "Appended to the dialog's own class string.")
  attr(:overlay_class, :any, default: nil)
  attr(:close_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:footer_class, :any, default: nil)
  attr(:header_class, :any, default: nil)

  attr(:header_outside_content, :boolean,
    default: false,
    doc: "Whether the title and description are siblings of the popup."
  )

  attr(:portal_class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:trigger_label, :string, default: nil)
  attr(:trigger_slot, :string, default: "dialog-trigger")

  attr(:trigger_variant, :string,
    default: nil,
    values: [nil, "default", "destructive", "outline", "secondary", "ghost", "link"]
  )

  attr(:trigger_size, :string,
    default: "default",
    values: ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"]
  )

  attr(:rest, :global)

  slot(:trigger, doc: "What opens it.")
  slot(:title, doc: "What names it. Required for a dialog to be announced.")
  slot(:description, doc: "What describes it, beyond the title.")
  slot(:footer, doc: "Actions, along the bottom.")
  slot(:inner_block, doc: "The dialog's body.")

  def dialog(assigns) do
    ~H"""
    <button
      :if={@show_trigger}
      data-slot={@trigger_slot}
      id={Dialog.trigger_id(@id)}
      type="button"
      disabled={@disabled}
      aria-label={@trigger_label}
      aria-haspopup="dialog"
      aria-expanded={to_string(@open)}
      aria-controls={Dialog.popup_id(@id)}
      phx-click={if(not @disabled, do: Dialog.open(@id))}
      phx-mounted={Dialog.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-disabled={flag(@disabled)}
      class={trigger_classes(@trigger_variant, @trigger_size, @trigger_class)}
    >
      {render_slot(@trigger)}
    </button>
    <.dialog_header
      :if={@header_outside_content && has_header?(@title, @description)}
      id={@id}
      title_class={@title_class}
      description_class={@description_class}
      header_class={@header_class}
    >
      <:title>{render_slot(@title)}</:title>
      <:description>{render_slot(@description)}</:description>
    </.dialog_header>
    <div
      data-slot="dialog-overlay"
      id={Dialog.backdrop_id(@id)}
      role="presentation"
      aria-hidden="true"
      hidden={not @open}
      phx-click={if(@dismissable, do: Dialog.close(@id))}
      phx-mounted={Dialog.owned_attributes(:backdrop)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={[upstream_fact("jsx/DialogOverlay/class/0"), @overlay_class || ""]}
    />
    <div
      data-slot="dialog-content"
      id={Dialog.popup_id(@id)}
      role={if(@alert, do: "alertdialog", else: "dialog")}
      aria-labelledby={if(@title != [], do: Dialog.title_id(@id))}
      aria-describedby={if(@description != [], do: Dialog.description_id(@id))}
      tabindex="-1"
      hidden={not @open}
      phx-window-keydown={if(@dismissable, do: Dialog.close(@id))}
      phx-key="Escape"
      phx-hook={Dialog.hook()}
      data-lb-backdrop={Dialog.backdrop_id(@id)}
      data-lb-modal
      phx-mounted={Dialog.owned_attributes(:popup)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={[
        upstream_fact("jsx/DialogContent/class/0"),
        @class || ""
      ]}
      {@rest}
    >
      <.dialog_header
        :if={not @header_outside_content && has_header?(@title, @description)}
        id={@id}
        title_class={@title_class}
        description_class={@description_class}
        header_class={@header_class}
      >
        <:title>{render_slot(@title)}</:title>
        <:description>{render_slot(@description)}</:description>
      </.dialog_header>
      {render_slot(@inner_block)}
      <div
        :if={@footer != []}
        data-slot="dialog-footer"
        class={[upstream_fact("jsx/DialogFooter/class/0"), @footer_class]}
      >
        {render_slot(@footer)}
      </div>
      <LiveShadcn.UI.Button.button
        :if={@show_close_button}
        data-slot="dialog-close"
        type="button"
        phx-click={Dialog.close(@id)}
        data-disabled={flag(@disabled)}
        variant="ghost"
        size="icon-sm"
        class={upstream_fact("jsx/DialogContent/class/1")}
      >
        <LiveShadcn.Icon.icon name="x" />
        <span class={upstream_fact("jsx/DialogContent/class/2")}>Close</span>
      </LiveShadcn.UI.Button.button>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:header_class, :any, default: nil)
  slot(:title)
  slot(:description)

  defp dialog_header(assigns) do
    ~H"""
    <div
      data-slot="dialog-header"
      class={[upstream_fact("jsx/DialogHeader/class/0"), @header_class]}
    >
      <h2
        data-slot="dialog-title"
        id={Dialog.title_id(@id)}
        class={[upstream_fact("jsx/DialogTitle/class/0"), @title_class]}
      >
        {render_slot(@title)}
      </h2>
      <p
        data-slot="dialog-description"
        id={Dialog.description_id(@id)}
        class={[upstream_fact("jsx/DialogDescription/class/0"), @description_class]}
      >
        {render_slot(@description)}
      </p>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil

  defp has_header?(title, description), do: title != [] or description != []

  defp trigger_classes(nil, _size, class), do: class

  defp trigger_classes(variant, size, class) do
    LiveShadcn.Cn.merge([
      Button.part_class("button"),
      Button.variant_class("buttonVariants", "variant", variant),
      Button.variant_class("buttonVariants", "size", size),
      class
    ])
  end

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)
end
