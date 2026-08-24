import { useEffect, useState } from "react";

// shadcn's own hook, which its registry imports and does not publish. Only
// `sidebar` reads it, and only to decide whether the sidebar is a sheet.
const MOBILE_BREAKPOINT = 768;

export function useIsMobile() {
  const [isMobile, setIsMobile] = useState<boolean | undefined>(undefined);

  useEffect(() => {
    const query = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`);
    const onChange = () => setIsMobile(window.innerWidth < MOBILE_BREAKPOINT);

    query.addEventListener("change", onChange);
    onChange();

    return () => query.removeEventListener("change", onChange);
  }, []);

  return !!isMobile;
}
