// The pinned React reference catalog is the action manifest for visual checks.
// It already drives the shadcn behaviour suite. Do not copy component names
// into parity, pixel, or accessibility tests.

import { officialShadcnReferences } from "./react-references.mjs";

const componentName = (reference) => reference.slice(0, reference.indexOf("."));

/**
 * Every official shadcn family. The interaction probe handles only controls
 * that can change a rendered state, so a static family adds no action states.
 */
export const OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS = Object.freeze(
  [...new Set([...officialShadcnReferences].map(componentName))].sort(),
);

export const isOfficialInteractiveShadcnComponent = (component) =>
  OFFICIAL_INTERACTIVE_SHADCN_COMPONENTS.includes(component);
