const MOBILE_QUERY = "(max-width: 767px)";

export function popupSide(isMobile) {
  return isMobile ? "bottom" : "right";
}

export function syncSidebarPopupPlacement(popups, isMobile) {
  for (const popup of popups) {
    const positioner = popup.closest("[data-lb-anchor]");
    if (!positioner) continue;

    positioner.setAttribute("data-lb-side", popupSide(isMobile));
    positioner.dispatchEvent(new CustomEvent("live-base:reposition"));
  }
}

// The upstream sidebar changes menu placement when its responsive drawer is
// active. The server cannot know the reader's viewport, so this hook updates
// only the client-owned positioning request.
export const SidebarPopupPlacement = {
  mounted() {
    this.media = window.matchMedia(MOBILE_QUERY);
    this.syncPlacement = () =>
      syncSidebarPopupPlacement(
        document.querySelectorAll("[data-lb-mobile-side]"),
        this.media.matches,
      );
    this.media.addEventListener("change", this.syncPlacement);
    this.syncPlacement();
  },

  destroyed() {
    this.media?.removeEventListener("change", this.syncPlacement);
  },
};
