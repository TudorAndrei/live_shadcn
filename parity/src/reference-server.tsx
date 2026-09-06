import { renderToString } from "react-dom/server";

import { ReferencePage } from "./reference-page";

export function renderReferencePreview(requestUrl: string) {
  const pathname = new URL(requestUrl, "http://127.0.0.1").pathname;

  return renderToString(<ReferencePage pathname={pathname} />);
}
