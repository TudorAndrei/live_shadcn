import { test as base, expect } from "@playwright/test";

// React references use the light palette. Set the same reader preference
// before any Storybook script runs, including on pages opened by a test.
export const test = base.extend({
  storybookTheme: ["light", { option: true }],
  context: async ({ context, baseURL, storybookTheme }, use) => {
    if (storybookTheme) {
      await context.addInitScript(({ origin, theme }) => {
        if (location.origin === origin && !sessionStorage.getItem("storybook-theme")) {
          sessionStorage.setItem("storybook-theme", theme);
        }
      }, { origin: new URL(baseURL).origin, theme: storybookTheme });
    }
    await use(context);
  },
});

export { expect };
