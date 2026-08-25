defmodule LiveBase.Clipboard do
  @moduledoc """
  The behavior behind a button that copies, and says so for a moment.

  ## Why none of this is an assign

  Writing to the clipboard is `navigator.clipboard.writeText`, which exists in a
  browser and nowhere else. No assign can do it, and no package on hex can
  supply it — a clipboard is a browser API, so the only thing to decide is where
  the few lines that call it live.

  What is left is the tick afterwards: the copy icon becomes a check for two
  seconds and then goes back. Held in an assign, that is a round trip to say
  "copied", a `Process.send_after` on the server per button, and a
  `handle_event/3` every caller has to write for an icon. Held here, it is a
  `setTimeout` in the browser that pressed the button, which is the only place
  that has an opinion about it.

  ## The two states, and how they are drawn

  The server cannot draw one icon or the other, because it does not know which.
  So a generated component draws both, each marked with the state it belongs to,
  and the one the client does not start in is `hidden`:

      <button id="copy" phx-hook={LiveBase.Clipboard.hook()} data-lb-clipboard="mix deps.get">
        <.icon data-lb-state="copied" hidden name="check" />
        <.icon data-lb-state="idle" name="copy" />
      </button>

  The hook swaps which one is hidden. `owned_attributes/1` is what keeps the
  next patch from putting the server's guess back over it.

  ## What the markup declares

  | Attribute | What it holds |
  |---|---|
  | `data-lb-clipboard` | the text to copy |
  | `data-lb-timeout` | how long the copied state lasts, in milliseconds |
  | `data-lb-state` | on each branch: `copied` or `idle` |

  And one the hook writes back: `data-lb-ready`, once it is listening. A button
  on a page that has not connected yet copies nothing, and a style sheet — or a
  test that would otherwise click into that window — can see which it is.

  The text is an attribute rather than something the hook goes looking for in
  the page, because what to copy is the caller's decision. A value the page was
  never given cannot be copied from the page — which is the answer for a secret,
  stated rather than worked around.

  ## Nothing is pushed to the server

  A copy is not an event the server has any use for, so none is sent. The
  element dispatches `lb:copied` and `lb:copy-error` for a page that wants to
  know, which is upstream's `onCopy` and `onError` without the round trip.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Clipboard"

  @doc "The client hook name the button declares in `phx-hook`."
  def hook, do: @hook

  @doc """
  The attributes the client owns once the page is live.

  `hidden` on each branch, and only on the branches: the server renders the
  state a fresh page is in — nothing copied — so a patch arriving during those
  two seconds would put the copy icon back while the check is still meant to be
  showing. And `data-lb-ready` on the button, which the server never renders
  because it is not true until the hook has mounted.
  """
  def owned_attributes(js \\ %JS{}) do
    js
    |> JS.ignore_attributes(["data-lb-ready"], [])
    |> JS.ignore_attributes(["hidden"], to: {:inner, "[data-lb-state]"})
  end
end
