defmodule LiveShadcn.UI.Sonner do
  @moduledoc """
  Sonner.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Toaster/class/0" => "toaster group",
    "jsx/Toaster/class/1" => "size-4",
    "jsx/Toaster/class/2" => "size-4",
    "jsx/Toaster/class/3" => "size-4",
    "jsx/Toaster/class/4" => "size-4",
    "jsx/Toaster/class/5" => "size-4 animate-spin"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Toast
  alias Phoenix.LiveView.JS

  @doc """
  A stack of messages the reader did not ask for.

      <.toaster id="toasts" dismiss="dismiss_toast">
        <:toast :for={t <- @toasts} id={t.id} type={t.type} title={t.title}>
          {t.description}
        </:toast>
      </.toaster>

  The list is yours. React's toast is a manager the client holds; a
  LiveView already has somewhere to keep a list, and one the client held
  would disagree with the server's the moment it re-rendered — the reader
  would watch a dismissed message come back.

  So closing one is an event, and so is timing out:

      def handle_event("dismiss_toast", %{"id" => id}, socket) do
        {:noreply, update(socket, :toasts, &Enum.reject(&1, fn t -> t.id == id end))}
      end

  How the stack is placed — how tall each toast turned out, how far back it
  sits, how far a finger has pushed it — is measured in the browser, which
  is the only place any of it is known.
  """

  attr(:id, :string, required: true, doc: "The hook needs one, and each toast derives its own.")

  attr(:dismiss, :string,
    required: true,
    doc: "The event pushed when a toast is closed or times out. Its payload is `%{id: id}`."
  )

  attr(:duration, :integer,
    default: 4000,
    doc: "How long a toast stays, in milliseconds. Zero to leave it until it is closed."
  )

  attr(:limit, :integer,
    default: 3,
    doc:
      "How many newest toasts stay visible. Older toasts stay in the server list and are marked limited."
  )

  attr(:label, :string, default: "Notifications", doc: "Names the region to a screen reader.")
  attr(:close_button, :boolean, default: false, doc: "Shows the optional close button.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)

  slot :toast, doc: "One message. The slot's content is its description." do
    attr(:id, :string, required: true, doc: "What comes back with the dismiss event.")
    attr(:title, :string)
    attr(:type, :string, doc: "`success`, `info`, `warning` or `error`.")
  end

  def toaster(assigns) do
    ~H"""
    <section
      aria-label={@label}
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      data-react-aria-top-layer
    >
      <ol
        id={@id}
        tabindex="-1"
        data-sonner-toaster
        data-sonner-theme="light"
        data-y-position="bottom"
        data-x-position="right"
      data-lb-toasts
      data-lb-dismiss={@dismiss}
      data-lb-duration={@duration}
      data-lb-limit={@limit}
      phx-hook={Toast.hook()}
        class={[
          upstream_fact("jsx/Toaster/class/0"),
          "fixed right-8 bottom-8 z-[999999999] m-0 w-[356px] list-none p-0",
          (@class || "")
        ]}
        style="--width: 356px; --gap: 14px; --offset-right: 32px; --offset-bottom: 32px; --border-radius: var(--radius); --normal-bg: var(--popover); --normal-border: var(--border); --normal-text: var(--popover-foreground)"
        {@rest}
      >
        <li
          :for={toast <- Enum.reverse(@toast)}
          id={Toast.toast_id(@id, toast[:id])}
          tabindex="0"
          data-sonner-toast
          data-rich-colors="false"
          data-styled="true"
          data-mounted="true"
          data-promise="false"
          data-swiped="false"
          data-removed="false"
          data-visible="true"
          data-y-position="bottom"
          data-x-position="right"
          data-index="0"
          data-front="true"
          data-swiping="false"
          data-dismissible="true"
          data-type={toast[:type] || "default"}
          data-invert="false"
          data-swipe-out="false"
          data-expanded="false"
          style="--index: 0; --toasts-before: 0; --z-index: 1; --offset: 0px; --initial-height: auto"
          class="cn-toast absolute right-0 bottom-0 flex w-full items-center gap-1.5 rounded-[var(--border-radius)] border bg-[var(--normal-bg)] p-4 text-[13px] text-[var(--normal-text)] shadow-[0_4px_12px_rgba(0,0,0,0.1)]"
        >
          <div :if={toast[:type]} data-icon>
            <LiveShadcn.Icon.icon name={icon(toast[:type])} class={icon_class(toast[:type])} />
          </div>
          <div data-content class="flex min-w-0 flex-1 flex-col gap-0.5">
            <div :if={toast[:title]} data-title class="leading-[1.5]">{toast[:title]}</div>
            <div data-description class="leading-[1.4] text-[#3f3f3f]">{render_slot(toast)}</div>
          </div>
          <button
            :if={@close_button}
            type="button"
            aria-label="Close toast"
            data-close-button
            phx-click={JS.push(@dismiss, value: %{id: Toast.toast_id(@id, toast[:id])})}
          >
            <LiveShadcn.Icon.icon name="x" />
          </button>
        </li>
      </ol>
    </section>
    """
  end

  defp icon("success"), do: "circle-check"
  defp icon("warning"), do: "triangle-alert"
  defp icon("error"), do: "octagon-x"
  defp icon("loading"), do: "loader-2"
  defp icon("info"), do: "info"

  defp icon_class("success"), do: upstream_fact("jsx/Toaster/class/1")
  defp icon_class("info"), do: upstream_fact("jsx/Toaster/class/2")
  defp icon_class("warning"), do: upstream_fact("jsx/Toaster/class/3")
  defp icon_class("error"), do: upstream_fact("jsx/Toaster/class/4")
  defp icon_class("loading"), do: upstream_fact("jsx/Toaster/class/5")
end
