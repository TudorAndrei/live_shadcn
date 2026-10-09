const IMAGE_SELECTOR = '[data-slot="avatar-image"]';
const FALLBACK_SELECTOR = '[data-slot="avatar-fallback"]';

function syncImage(image) {
  if (!(image instanceof HTMLImageElement) || !image.complete) {
    return;
  }

  const fallback = image.parentElement?.querySelector(FALLBACK_SELECTOR);

  const failed = image.naturalWidth === 0;
  if (image.hidden !== failed) image.hidden = failed;
  fallback?.toggleAttribute("hidden", !failed);
}

function syncImages(node) {
  if (!(node instanceof Element)) {
    return;
  }

  if (node.matches(IMAGE_SELECTOR)) {
    syncImage(node);
  }

  node.querySelectorAll(IMAGE_SELECTOR).forEach(syncImage);
}

function syncEventImage(event) {
  if (event.target instanceof Element && event.target.matches(IMAGE_SELECTOR)) {
    syncImage(event.target);
  }
}

export function installAvatarImages(root = document) {
  root.addEventListener("load", syncEventImage, true);
  root.addEventListener("error", syncEventImage, true);

  syncImages(root.documentElement);

  const observer = new MutationObserver((records) => {
    records.forEach((record) => {
      if (record.type === "attributes") {
        syncImage(record.target);
      } else {
        record.addedNodes.forEach(syncImages);
      }
    });
  });

  observer.observe(root.documentElement, {
    attributeFilter: ["hidden", "src"],
    attributes: true,
    childList: true,
    subtree: true,
  });

  return observer;
}
