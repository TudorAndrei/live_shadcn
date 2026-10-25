defmodule LiveBase.Shimmer do
  @moduledoc """
  The behavior behind a line of text that shimmers while it is still arriving.

  ## Why it is a hook and not a class string

  Upstream animates one property — `background-position` — from one end of a
  gradient to the other, for ever. It writes that with `motion`, and `motion`
  for a plain property like this one calls the browser's own Web Animations API.

  A CSS animation would say the same thing, and this pipeline cannot write one:
  a `@keyframes` rule is a style rule, and no style rule here is typed by a
  person. The two positions are upstream's, they are in the markup, and this
  hands them to the same API `motion` hands them to.

  ## What the markup declares

  | Attribute | What it holds |
  |---|---|
  | `data-lb-shimmer` | the two background positions, `from,to` |
  | `data-lb-duration` | how long one pass takes, in milliseconds |
  | `data-lb-spread` | pixels of gradient spread per character |

  ## Nothing is pushed to the server

  Whether a shimmer is moving is not a fact a server has any use for. The hook
  starts the animation when the element mounts and restarts it only if the
  keyframes themselves change — the text under it changes constantly, which is
  the whole point, and that is not a reason to start the gradient again.

  A reader who has asked for less motion gets the gradient and no movement.
  """

  use Phoenix.Component

  @hook "LiveBase.Shimmer.Shimmer"

  @doc "The client hook name the element declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook shimmer.js#Shimmer --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Shimmer">
      const DURATION = 2e3;
      const Shimmer = {
        mounted() {
          this.setSpread();
          this.start();
        },
        updated() {
          this.setSpread();
          if (this.frames !== this.el.getAttribute("data-lb-shimmer")) this.start();
        },
        destroyed() {
          this.animation?.cancel();
        },
        start() {
          this.animation?.cancel();
          this.frames = this.el.getAttribute("data-lb-shimmer");
          const [from, to] = (this.frames ?? "").split(",");
          if (!from || !to) return;
          if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) {
            this.el.style.backgroundPosition = to.trim();
            return;
          }
          this.animation = this.el.animate([{ backgroundPosition: from.trim() }, { backgroundPosition: to.trim() }], {
            duration: this.duration(),
            easing: "linear",
            iterations: Number.POSITIVE_INFINITY
          });
        },
        duration() {
          return Number(this.el.getAttribute("data-lb-duration")) || DURATION;
        },
        setSpread() {
          const spread = Number(this.el.getAttribute("data-lb-spread")) || 2;
          this.el.style.setProperty("--spread", `${this.el.textContent.trim().length * spread}px`);
        }
      };
      export default Shimmer;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
