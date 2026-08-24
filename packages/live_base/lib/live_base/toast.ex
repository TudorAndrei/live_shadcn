defmodule LiveBase.Toast do
  @moduledoc """
  The behavior behind a stack of messages the reader did not ask for.

  ## Who owns the list

  The server, and that is the whole design. React's toast is a manager object
  the client holds: `toast.add(…)` from anywhere, and the component reads it.
  A LiveView already has somewhere to keep a list of things, and a toast that
  the client held would disagree with it the moment the server re-rendered —
  the reader would watch a dismissed message come back.

  So the caller keeps the toasts in an assign or a stream, the component draws
  what is there, and dismissing one is an event like any other:

      def handle_event("dismiss_toast", %{"id" => id}, socket) do
        {:noreply, update(socket, :toasts, &Enum.reject(&1, fn t -> t.id == id end))}
      end

  ## What the hook owns

  Everything about the stack that only a browser knows: how tall each toast
  turned out, how far back it sits, how far a finger has pushed it. Those are
  six CSS variables and three data attributes, and shadcn's class strings read
  every one of them to place the stack, fan it out under a pointer, and slide a
  pushed toast away.

  | Variable | What it holds |
  |---|---|
  | `--toast-index` | how far back this one is, 0 at the front |
  | `--toast-height` | how tall it is, measured |
  | `--toast-frontmost-height` | how tall the front one is |
  | `--toast-offset-y` | how far down the stack this one starts |
  | `--toast-swipe-movement-x` | how far a finger has pushed it |
  | `--toast-swipe-movement-y` | the same, down |

  ## Timing out is still an event

  A toast that stays for four seconds asks the server to remove it after four
  seconds. One round trip per toast, which is one more than none and far fewer
  than a component that asked what to draw.
  """

  @hook "LiveBase.Toast"

  @doc "The client hook name the viewport declares in `phx-hook`."
  def hook, do: @hook

  @doc "The id of one toast, given the toaster and the toast's own id."
  def toast_id(toaster, id), do: "#{toaster}-#{id}"
end
