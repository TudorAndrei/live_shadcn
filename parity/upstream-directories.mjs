import { dirname, join } from "node:path";

// Keep every file in the registry family that an official example can import.
// The source files keep their upstream import paths. Vite resolves those paths
// to this copied tree, rather than changing the pinned source.
export function pinnedSourceDirectories({ ai, shadcn, manifest }) {
  return {
    // Keep the base/ui layout that the official examples import.
    shadcn: dirname(join(shadcn, manifest.sources.shadcn.dir)),
    // Official Base examples can also use the New York v4 registry. Chart is
    // one such example. Copy the complete registry family, not only its
    // current imports, so later official examples stay source exact.
    shadcn_new_york_v4: join(shadcn, "apps/v4/registry/new-york-v4"),
    // The component documentation renders these examples. Keep them separate
    // from the registry examples above because they are the public reference
    // for the states that the Storybook copies.
    shadcn_examples: join(shadcn, "apps/v4/examples/base"),
    shadcn_app_components: join(shadcn, "apps/v4/components"),
    shadcn_app_hooks: join(shadcn, "apps/v4/hooks"),
    shadcn_app_lib: join(shadcn, "apps/v4/lib"),
    shadcn_icons: join(shadcn, "apps/v4/registry/icons"),
    shadcn_helpers: join(shadcn, "packages/helpers/src"),
    ai_elements: join(ai, manifest.sources.ai_elements.dir),
    ai_examples: join(ai, manifest.sources.ai_elements.examples_dir),
    ai_shadcn: join(ai, manifest.sources.ai_elements.shadcn_dir),
  };
}
