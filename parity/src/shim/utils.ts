import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

// shadcn's own `cn`, which its registry imports and does not publish. Every
// class string upstream builds goes through it, so the parity page has to build
// them the same way — a `cn` that did not merge would leave two conflicting
// utilities on an element and the browser would pick by source order.
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
