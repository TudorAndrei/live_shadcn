defmodule LiveAiElements.Transcription do
  @moduledoc """
  The names that connect a transcription to its client hook.

  The hook reads the audio time, updates each timed segment, and seeks the
  audio when a user selects a segment. It does this work in the browser, with
  no LiveView event.
  """

  use Phoenix.Component

  @hook "LiveAiElements.Transcription.Transcription"

  @doc "The client hook name the transcription root declares in `phx-hook`."
  @spec hook() :: String.t()
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook transcription.js#Transcription --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Transcription">
      const SEGMENT = "[data-slot='transcription-segment']";
      const STATE_CLASSES = [
        "text-primary",
        "font-semibold",
        "text-muted-foreground",
        "text-foreground/80"
      ];
      const Transcription = {
        mounted() {
          this.onClick = (event) => {
            const segment = event.target.closest(SEGMENT);
            if (!segment || !this.el.contains(segment) || segment.disabled || !this.media) return;
            const start = Number(segment.dataset.startSecond);
            if (!Number.isFinite(start)) return;
            this.media.currentTime = start;
            this.draw(start);
          };
          this.onTimeUpdate = () => this.draw(this.media?.currentTime || 0);
          this.el.addEventListener("click", this.onClick);
          this.bindMedia();
        },
        updated() {
          this.bindMedia();
          this.onTimeUpdate();
        },
        destroyed() {
          this.el.removeEventListener("click", this.onClick);
          this.media?.removeEventListener("timeupdate", this.onTimeUpdate);
        },
        bindMedia() {
          const media = this.el.ownerDocument.getElementById(this.el.dataset.mediaId);
          if (media === this.media) return;
          this.media?.removeEventListener("timeupdate", this.onTimeUpdate);
          this.media = media;
          this.media?.addEventListener("timeupdate", this.onTimeUpdate);
          this.onTimeUpdate();
        },
        draw(currentTime) {
          for (const segment of this.el.querySelectorAll(SEGMENT)) {
            const start = Number(segment.dataset.startSecond);
            const end = Number(segment.dataset.endSecond);
            const active = currentTime >= start && currentTime < end;
            const past = currentTime >= end;
            segment.dataset.active = String(active);
            if (active) segment.setAttribute("aria-current", "true");
            else segment.removeAttribute("aria-current");
            segment.classList.remove(...STATE_CLASSES);
            segment.classList.add(active ? "text-primary" : past ? "text-foreground/80" : "text-muted-foreground");
            segment.classList.toggle("font-semibold", active);
          }
        }
      };
      export default Transcription;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
