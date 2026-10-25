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
  So a reviewed port draws both, each marked with the state it belongs to,
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

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Clipboard.Clipboard"

  @doc "The client hook name the button declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook clipboard.js#Clipboard --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Clipboard">
      const TIMEOUT = 2e3;
      const Clipboard = {
        mounted() {
          this.el.addEventListener("click", () => this.copy());
          this.el.toggleAttribute("data-lb-ready", true);
        },
        destroyed() {
          clearTimeout(this.timer);
        },
        async copy() {
          if (!navigator?.clipboard?.writeText) return this.announce("lb:copy-error", { error: "the clipboard API is not available" });
          try {
            await navigator.clipboard.writeText(this.el.getAttribute("data-lb-clipboard") ?? "");
          } catch (error) {
            return this.announce("lb:copy-error", { error: String(error) });
          }
          this.show("copied");
          this.announce("lb:copied", {});
          clearTimeout(this.timer);
          this.timer = setTimeout(() => this.show("idle"), this.timeout());
        },
        timeout() {
          return Number(this.el.getAttribute("data-lb-timeout")) || TIMEOUT;
        },
        show(state) {
          for (const branch of this.el.querySelectorAll("[data-lb-state]")) branch.toggleAttribute("hidden", branch.getAttribute("data-lb-state") !== state);
          if (this.el.hasAttribute("data-lb-copy-label")) {
            const copied = state === "copied";
            this.el.setAttribute("aria-label", copied ? "Copied" : "Copy");
            this.el.toggleAttribute("data-copied", copied);
            const status = document.getElementById(this.el.getAttribute("data-lb-copy-status"));
            if (status) status.textContent = copied ? "Copied" : "";
          }
        },
        announce(name, detail) {
          this.el.dispatchEvent(new CustomEvent(name, {
            bubbles: true,
            detail
          }));
        }
      };
      export default Clipboard;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

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
