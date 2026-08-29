import {
  WebPreview,
  WebPreviewBody,
  WebPreviewNavigation,
  WebPreviewUrl,
} from "@upstream/ai_elements/web-preview";

// Ported from `StorybookWeb.Examples.web_preview_default/1`.
//
// The address bar reads the URL off a context upstream and takes it as a value
// here, which is the same answer every context in this registry gets: a HEEx
// component has no ancestor to ask.
//
// The frame is given nothing to load on purpose. A preview that fetched a page
// would make the pixel check depend on a network, and an empty `<iframe>` is
// what upstream draws before anybody types an address.
export default function WebPreviewDefault() {
  return (
    <WebPreview className="h-64 max-w-md">
      <WebPreviewNavigation>
        <WebPreviewUrl value="https://example.com" />
      </WebPreviewNavigation>
      <WebPreviewBody />
    </WebPreview>
  );
}
