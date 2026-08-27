defmodule LiveShadcn.UI.Sheet do
  @moduledoc """
  Sheet. Groups all parts of the dialog.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/SheetContent/class/0" =>
      "cn-sheet-content data-ending-style:opacity-0 data-starting-style:opacity-0 data-[side=bottom]:data-ending-style:translate-y-[2.5rem] data-[side=bottom]:data-starting-style:translate-y-[2.5rem] data-[side=left]:data-ending-style:translate-x-[-2.5rem] data-[side=left]:data-starting-style:translate-x-[-2.5rem] data-[side=right]:data-ending-style:translate-x-[2.5rem] data-[side=right]:data-starting-style:translate-x-[2.5rem] data-[side=top]:data-ending-style:translate-y-[-2.5rem] data-[side=top]:data-starting-style:translate-y-[-2.5rem]",
    "jsx/SheetContent/class/1" => "cn-sheet-close",
    "jsx/SheetContent/class/2" => "sr-only",
    "jsx/SheetDescription/class/0" => "cn-sheet-description",
    "jsx/SheetFooter/class/0" => "cn-sheet-footer mt-auto flex flex-col",
    "jsx/SheetHeader/class/0" => "cn-sheet-header flex flex-col",
    "jsx/SheetOverlay/class/0" =>
      "cn-sheet-overlay fixed inset-0 z-50 transition-opacity duration-150 data-ending-style:opacity-0 data-starting-style:opacity-0",
    "jsx/SheetTitle/class/0" => "cn-sheet-title cn-font-heading"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Dialog

  @doc """
  Groups all parts of the dialog.

      <.sheet id="confirm">
        <:trigger>Delete</:trigger>
        <:title>Are you sure?</:title>
        <:description>This cannot be undone.</:description>
        Deleting removes the component and its spec.
      </.sheet>

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

  attr(:class, :any, default: nil, doc: "Appended to the dialog's own class string.")
  attr(:close_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:side, :string, default: "right", values: ["top", "right", "bottom", "left"])
  attr(:rest, :global)

  slot(:trigger, required: true, doc: "What opens it.")
  slot(:title, doc: "What names it. Required for a dialog to be announced.")
  slot(:description, doc: "What describes it, beyond the title.")
  slot(:footer, doc: "Actions, along the bottom.")
  slot(:inner_block, required: true, doc: "The dialog's body.")

  def sheet(assigns) do
    ~H"""
    <button
      data-slot="sheet-trigger"
      id={Dialog.trigger_id(@id)}
      type="button"
      aria-haspopup="dialog"
      aria-expanded={to_string(@open)}
      aria-controls={Dialog.popup_id(@id)}
      phx-click={Dialog.open(@id)}
      phx-mounted={Dialog.owned_attributes(:trigger)}
      data-popup-open={flag(@open)}
      data-disabled={flag(@disabled)}
    >
      {render_slot(@trigger)}
    </button>
    <div
      data-slot="sheet-overlay"
      id={Dialog.backdrop_id(@id)}
      hidden={not @open}
      phx-click={if(@dismissable, do: Dialog.close(@id))}
      phx-mounted={Dialog.owned_attributes(:backdrop)}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={[
        upstream_fact("jsx/SheetOverlay/class/0"),
        (@class || "")
      ]}
      data-lb-style-target
    />
    <div
      data-slot="sheet-content"
      id={Dialog.popup_id(@id)}
      role={if(@alert, do: "alertdialog", else: "dialog")}
      aria-modal="true"
      aria-labelledby={Dialog.title_id(@id)}
      aria-describedby={Dialog.description_id(@id)}
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
      data-side={@side}
      class={[
        upstream_fact("jsx/SheetContent/class/0"),
        (@class || "")
      ]}
    >
      <div data-slot="sheet-header" class={upstream_fact("jsx/SheetHeader/class/0")}>
        <h2
          data-slot="sheet-title"
          id={Dialog.title_id(@id)}
          class={[upstream_fact("jsx/SheetTitle/class/0"), (@title_class || "")]}
        >
          {render_slot(@title)}
        </h2>
        <p
          data-slot="sheet-description"
          id={Dialog.description_id(@id)}
          class={[upstream_fact("jsx/SheetDescription/class/0"), (@description_class || "")]}
        >
          {render_slot(@description)}
        </p>
      </div>
      {render_slot(@inner_block)}
      <div :if={@footer != []} data-slot="sheet-footer" class={upstream_fact("jsx/SheetFooter/class/0")}>
        {render_slot(@footer)}
      </div>
      <LiveShadcn.UI.Button.button
        :if={@show_close_button}
        data-slot="sheet-close"
        type="button"
        phx-click={Dialog.close(@id)}
        data-disabled={flag(@disabled)}
        variant="ghost"
        size="icon-sm"
        class={upstream_fact("jsx/SheetContent/class/1")}
      >
        <LiveShadcn.Icon.icon name="x" /><span class={upstream_fact("jsx/SheetContent/class/2")}>Close</span>
      </LiveShadcn.UI.Button.button>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end