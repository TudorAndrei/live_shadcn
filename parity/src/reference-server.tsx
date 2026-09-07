import { renderToString } from "react-dom/server";

import { ReferencePage, loadReferencePage } from "./reference-page";

export async function renderReferencePreview(requestUrl: string) {
  const pathname = new URL(requestUrl, "http://127.0.0.1").pathname;

  const props = await loadReferencePage(pathname);
  return renderToString(<ReferencePage {...props} />);
}
