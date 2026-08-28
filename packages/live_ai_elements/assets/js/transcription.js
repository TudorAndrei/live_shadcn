// Keep a timed transcript and its media element in sync in the browser.

const SEGMENT = "[data-slot='transcription-segment']";
const STATE_CLASSES = ["text-primary", "text-muted-foreground", "text-muted-foreground/60"];

export const Transcription = {
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
      segment.classList.remove(...STATE_CLASSES);
      segment.classList.add(
        active ? "text-primary" : past ? "text-muted-foreground" : "text-muted-foreground/60",
      );
    }
  },
};
