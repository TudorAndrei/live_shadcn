// Behaviour parity for the checkable form controls.
//
// The expectations come from the Base UI checkbox and switch pages: what
// `data-checked` and `data-unchecked` mean, that the control is a `<span>` with
// a hidden `<input>` beside it, and that a disabled control ignores everything.
//
// The last two tests are the ones that matter most. A control that looks right
// and submits nothing is worse than one that looks wrong, and only a browser
// can tell you which you have.

import { expect, test } from "@playwright/test";

import { connected, referenceReady, visit } from "./live.mjs";
import { startCheckableFixture } from "./checkable-fixture.mjs";

const checkboxControl = (page, id) => ({
  control: page.locator(`#${id}-control`),
  input: page.locator(`#${id}`),
});

test.describe("anonymous checkable pairs", () => {
  let fixture;
  test.beforeAll(async ({}, testInfo) => {
    testInfo.setTimeout(190_000);
    fixture = await startCheckableFixture(testInfo.outputPath("checkable-fixture.log"));
  });
  test.afterAll(async () => { await fixture?.close(); });

  for (const kind of ["checkbox", "switch"]) {
    test(`${kind} keeps unnamed controls independent through labels, Space, and caller updates`, async ({ page }) => {
      const response = await page.goto(`${fixture.url}/${kind}`);
      expect(response.status(), "the public defaults render on a real page").toBe(200);
      await connected(page);
      const form = page.locator("#checkable-form");
      const controls = form.getByRole(kind);
      const inputs = form.locator("input[type='checkbox']");
      const labels = form.locator("label");

      await form.evaluate((element) => {
        window.checkableChanges = [];
        element.addEventListener("change", () => {
          window.checkableChanges.push({
            controls: [...element.querySelectorAll("[aria-checked]")].map((control) => control.getAttribute("aria-checked") === "true"),
            inputs: [...element.querySelectorAll("input[type='checkbox']")].map((input) => input.checked),
          });
        });
      });

      async function expectState(checked, events) {
        await expect(page.locator("#checkable-events")).toHaveAttribute("data-count", String(events));
        for (let index = 0; index < checked.length; index += 1) {
          await expect(controls.nth(index)).toHaveAttribute("aria-checked", String(checked[index]));
          await expect(inputs.nth(index)).toBeChecked({ checked: checked[index] });
        }
        const values = await form.evaluate((element) => [...new FormData(element)]);
        expect(values).toEqual(checked[2] ? [["submitted", "true"]] : []);
        if (events > 0) {
          const changes = await page.evaluate(() => window.checkableChanges);
          expect(changes).toHaveLength(events);
          expect(changes.at(-1)).toEqual({ controls: checked, inputs: checked });
        }
      }

      await expect(controls).toHaveCount(5);
      await expect(form.getByRole(kind, { name: "First setting", exact: true })).toBeVisible();
      await expectState([false, true, false, false, true], 0);
      await labels.nth(0).click();
      await expectState([true, true, false, false, true], 1);
      await expect(controls.nth(0)).toBeFocused();
      await expect(controls.nth(0)).toHaveAttribute("data-dirty", "");
      await expect(controls.nth(0)).toHaveAttribute("data-touched", "");
      await page.keyboard.press(" ");
      await expectState([false, true, false, false, true], 2);
      await expect(controls.nth(0)).toBeFocused();
      await controls.nth(1).click();
      await expectState([false, false, false, false, true], 3);
      await expect(controls.nth(1)).toBeFocused();
      await controls.nth(2).click();
      await expectState([false, false, true, false, true], 4);
      await expect(page.locator("#checkable-values")).toHaveText('{"submitted":"true"}');
      await labels.nth(0).click();
      await expectState([true, false, true, false, true], 5);
      await expect(controls.nth(0)).toBeFocused();
      await labels.nth(3).click({ force: true });
      await labels.nth(4).click();
      await expectState([true, false, true, false, true], 5);
      const update = page.getByRole("button", { name: "Apply settings", exact: true });
      await update.click();
      await expect(page.locator("#checkable-applied")).toHaveText("true");
      await expectState([true, false, true, false, true], 5);
      await update.click();
      await expect(page.locator("#checkable-applied")).toHaveText("false");
      await expect(page.locator("#checkable-events")).toHaveAttribute("data-count", "5");
      for (let index = 0; index < 5; index += 1) {
        const checked = [false, true, false, false, true][index];
        await expect(controls.nth(index)).toHaveAttribute("aria-checked", String(checked));
        await expect(inputs.nth(index)).toBeChecked({ checked });
      }
      expect(await form.evaluate((element) => [...new FormData(element)])).toEqual([]);
      await expect(update).toBeFocused();
    });
  }

  for (const mode of ["anonymous", "named", "field"]) {
    test(`radio ${mode} items keep selection, submitted values, and caller updates aligned`, async ({ page }) => {
      const response = await page.goto(`${fixture.url}/radio-${mode}`);
      expect(response.status(), "the public radio inputs render on a real page").toBe(200);
      await connected(page);
      const form = page.locator("#radio-form");
      const group = form.getByRole("radiogroup", { name: "Choices", exact: true });
      const controls = group.getByRole("radio");
      const inputs = group.locator("input[type='radio']");
      const labels = group.locator("label");
      const values = [...(mode === "field" ? ["a b", "a-b", "a_b"] : ["first", "second", "third"]), "disabled", "readonly"];
      const name = mode === "anonymous" ? "choices" : mode === "named" ? "selection" : "settings[choice]";
      await form.evaluate((element) => {
        window.radioFixtureChanges = [];
        element.addEventListener("change", (event) => {
          window.radioFixtureChanges.push({ value: event.target.value, submitted: [...new FormData(element)] });
        });
      });

      async function expectSelection(index, events, lastChanged = index) {
        await expect(page.locator("#radio-events")).toHaveAttribute("data-count", String(events));
        for (let item = 0; item < values.length; item += 1) {
          await expect(controls.nth(item)).toHaveAttribute("aria-checked", String(item === index));
          await expect(inputs.nth(item)).toBeChecked({ checked: item === index });
        }
        const submitted = [[name, values[index]]];
        expect(await form.evaluate((element) => [...new FormData(element)])).toEqual(submitted);
        const changes = await page.evaluate(() => window.radioFixtureChanges);
        expect(changes).toHaveLength(events);
        if (events) expect(changes.at(-1)).toEqual({
          value: values[lastChanged], submitted: [[name, values[lastChanged]]],
        });
      }

      await expect(group.getByRole("radio", { name: "First choice", exact: true })).toBeVisible();
      await expectSelection(1, 0);
      if (mode === "named") {
        await form.getByText("Read-only choice outside group", { exact: true }).click();
        await expectSelection(1, 0);
      }
      await controls.nth(0).click();
      await expectSelection(0, 1);
      await expect(controls.nth(0)).toBeFocused();
      await page.keyboard.press("ArrowRight");
      await expectSelection(1, 2);
      await page.keyboard.press("ArrowRight");
      await expectSelection(2, 3);
      await labels.nth(0).click();
      await expectSelection(0, 4);
      await expect(controls.nth(0)).toBeFocused();
      await controls.nth(2).focus();
      await page.keyboard.press(" ");
      await expectSelection(2, 5);
      await labels.nth(3).click({ force: true });
      await labels.nth(4).click();
      await expectSelection(2, 5);
      if (mode === "named") {
        await form.getByText("Read-only choice outside group", { exact: true }).click();
        await expectSelection(2, 5);
        await form.getByText("First choice outside group", { exact: true }).click();
        await expectSelection(0, 6);
        await expect(controls.nth(0)).toBeFocused();
        await form.getByText("First choice outside group", { exact: true }).click();
      } else {
        await controls.nth(0).click();
      }
      await expectSelection(0, 6);

      const update = page.getByRole("button", { name: "Apply choice", exact: true });
      for (const [applied, index] of [[true, 2], [false, 1]]) {
        await update.click();
        await expect(page.locator("#radio-applied")).toHaveText(String(applied));
        await expect(page.locator("#radio-events")).toHaveAttribute("data-count", "6");
        for (let item = 0; item < values.length; item += 1) {
          await expect(controls.nth(item)).toHaveAttribute("aria-checked", String(item === index));
          await expect(inputs.nth(item)).toBeChecked({ checked: item === index });
        }
        expect(await form.evaluate((element) => [...new FormData(element)])).toEqual([[name, values[index]]]);
        await expect(update).toBeFocused();
      }
      if (mode === "named") {
        const readOnlyUpdate = page.getByRole("button", { name: "Apply read-only choice", exact: true });
        await readOnlyUpdate.click();
        await expectSelection(4, 6, 0);
        await expect(readOnlyUpdate).toBeFocused();
        await form.getByText("Read-only choice outside group", { exact: true }).click();
        await expectSelection(4, 6, 0);
      }
    });
  }
});

test.describe("a checkbox", () => {
  test.beforeEach(async ({ page }) => {
    await visit(page, "/preview/checkbox/default", "#terms-checkbox-control");
  });

  test("says what it is to a screen reader", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox-2");

    await expect(box).toHaveRole("checkbox");
    await expect(box).toHaveAttribute("aria-checked", "true");
  });

  test("an unchecked control marks itself unchecked, not merely not checked", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox");

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(box).not.toHaveAttribute("data-checked", "");
  });

  test("a click flips both the control and the input a form submits", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "terms-checkbox");

    await expect(input).not.toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "true");
    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();
  });

  test("a second click flips it back", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "terms-checkbox-2");

    await box.click();

    await expect(box).toHaveAttribute("aria-checked", "false");
    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();
  });

  test("interacting with it marks it touched, which the server never sees", async ({ page }) => {
    const { control: box } = checkboxControl(page, "terms-checkbox");

    await expect(box).not.toHaveAttribute("data-touched", "");

    await box.click();

    await expect(box).toHaveAttribute("data-touched", "");
    await expect(box).toHaveAttribute("data-dirty", "");
  });

  test("a disabled control does not flip", async ({ page }) => {
    const { control: box, input } = checkboxControl(page, "toggle-checkbox");

    await expect(box).toHaveAttribute("data-disabled", "");
    await box.click({ force: true });

    await expect(box).toHaveAttribute("aria-checked", "false");
    await expect(input).not.toBeChecked();
  });

  test("the input is out of the accessibility tree, because the control is in it", async ({
    page,
  }) => {
    const { input } = checkboxControl(page, "terms-checkbox");

    await expect(input).toHaveAttribute("aria-hidden", "true");
    await expect(input).toHaveAttribute("tabindex", "-1");
  });

  test("the control is reachable by keyboard and flips on Space", async ({ page }) => {
    await page.locator("#terms-checkbox-control").focus();
    await expect(page.locator("#terms-checkbox-control")).toBeFocused();

    await page.keyboard.press(" ");

    await expect(page.locator("#terms-checkbox-control")).toHaveAttribute("aria-checked", "true");
  });
});

test.describe("a switch", () => {
  test("carries the same contract, drawn differently", async ({ page }) => {
    await visit(page, "/preview/switch/default");
    const box = page.locator("#airplane-mode-control");
    const input = page.locator("#airplane-mode");

    await expect(box).toHaveAttribute("data-unchecked", "");
    await expect(input).not.toBeChecked();

    await box.click();

    await expect(box).toHaveAttribute("data-checked", "");
    await expect(input).toBeChecked();
  });
});

for (const side of ["React", "Phoenix"]) {
  for (const labelType of ["separate", "containing"]) {
    test(`checkbox ${labelType} label keeps state, focus, and Space aligned on ${side}`, async ({ page }, testInfo) => {
      const path = "/preview/checkbox/default";
      await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
      await (side === "React" ? referenceReady(page) : connected(page));
      const scope = page.locator("[data-preview='checkbox']");
      const name = labelType === "separate" ? "terms-checkbox" : "toggle-checkbox-2";
      const label = labelType === "separate"
        ? scope.locator("label[for='terms-checkbox']")
        : scope.locator("label:has([role='checkbox'])");
      const control = scope.getByRole("checkbox").nth(labelType === "separate" ? 0 : 3);
      const input = scope.locator(`input[name='${name}']`);
      const nativeValue = side === "React" ? "on" : "true";

      async function expectState(checked) {
        await expect(control).toHaveAttribute("aria-checked", String(checked));
        await expect(input).toBeChecked({ checked });
        const submitted = await input.evaluate((element) => element.checked ? [element.name, element.value] : []);
        expect(submitted).toEqual(checked ? [name, nativeValue] : []);
      }

      await expectState(false);
      await label.click();
      await expectState(true);
      await expect(control).toBeFocused();
      await page.keyboard.press(" ");
      await expectState(false);
      await expect(control).toBeFocused();
      await control.click();
      await expectState(true);
      await expect(control).toBeFocused();
      await label.click();
      await expectState(false);
      await expect(control).toBeFocused();
    });
  }
}

for (const side of ["React", "Phoenix"]) {
  test(`checkbox table keeps partial, full, and cleared selection aligned on ${side}`, async ({ page }, testInfo) => {
    const path = "/preview/checkbox/table";
    await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
    await (side === "React" ? referenceReady(page) : connected(page));
    const scope = page.locator("[data-preview='checkbox']");
    const header = scope.locator("thead [role='checkbox']");
    const rows = scope.locator("tbody [role='checkbox']");
    const nativeValue = side === "React" ? "on" : "true";

    async function expectSelection(selected) {
      const all = selected.every(Boolean);
      await expect(header).toHaveAttribute("aria-checked", String(all));
      for (let index = 0; index < selected.length; index += 1) {
        await expect(rows.nth(index)).toHaveAttribute("aria-checked", String(selected[index]));
      }
      await expect(scope.locator("tbody tr[data-state='selected']")).toHaveCount(selected.filter(Boolean).length);
      const submitted = await scope.locator("input[type='checkbox']").evaluateAll((inputs) =>
        inputs.filter((input) => input.checked && !input.disabled).map((input) => [input.name, input.value]),
      );
      const expected = all ? [["select-all-checkbox", nativeValue]] : [];
      selected.forEach((checked, index) => {
        if (checked) expected.push([`row-${index + 1}-checkbox`, nativeValue]);
      });
      expect(submitted).toEqual(expected);
    }

    await expectSelection([true, false, false, false]);
    await rows.nth(1).click();
    await expectSelection([true, true, false, false]);
    await header.click();
    await expectSelection([true, true, true, true]);
    await rows.nth(0).click();
    await expectSelection([false, true, true, true]);
    await header.click();
    await expectSelection([true, true, true, true]);
    await header.click();
    await expectSelection([false, false, false, false]);
  });
}

test.describe("a radio group", () => {
  const examples = [
    { example: "default", values: ["default", "comfortable", "compact"], steps: [["ArrowRight", 2], ["ArrowDown", 0], ["ArrowUp", 2], ["ArrowLeft", 1]] },
    { example: "rtl", values: ["default", "comfortable", "compact"], steps: [["ArrowLeft", 0], ["ArrowUp", 2], ["ArrowDown", 0], ["ArrowRight", 1]] },
    { example: "disabled", values: ["option1", "option2", "option3"], steps: [["ArrowUp", 2], ["ArrowDown", 1], ["ArrowRight", 2], ["ArrowLeft", 1]] },
  ];

  for (const side of ["React", "Phoenix"]) {
    for (const { example, values, steps } of examples) {
      test(`${example} radio keyboard selection keeps focus and native changes aligned on ${side}`, async ({ page }, testInfo) => {
        const path = `/preview/radio-group/${example}`;
        await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
        await (side === "React" ? referenceReady(page) : connected(page));
        const group = page.getByRole("radiogroup");
        const controls = group.getByRole("radio");
        const inputs = group.locator("input[type='radio']");
        await controls.nth(1).focus();
        await group.evaluate((element) => {
          window.radioKeyboardChanges = [];
          element.addEventListener("change", (event) => {
            window.radioKeyboardChanges.push({ value: event.target.value, checked: event.target.checked });
          });
        });

        async function expectSelection(index, changes) {
          await expect(controls.nth(index)).toBeFocused();
          for (let item = 0; item < values.length; item += 1) {
            await expect(controls.nth(item)).toHaveAttribute("aria-checked", String(item === index));
            await expect(inputs.nth(item)).toBeChecked({ checked: item === index });
          }
          const events = await page.evaluate(() => window.radioKeyboardChanges);
          expect(events).toHaveLength(changes);
          if (changes) expect(events.at(-1)).toEqual({ value: values[index], checked: true });
        }

        await expectSelection(1, 0);
        let changes = 0;
        for (const [key, index] of steps) {
          await page.keyboard.press(key);
          await expectSelection(index, ++changes);
        }
        await page.keyboard.press("Shift+ArrowDown");
        await expectSelection(2, ++changes);
        for (const key of ["Home", "End", "Enter", " "]) {
          await page.keyboard.press(key);
          await expectSelection(2, changes);
        }
        const spaceTarget = example === "disabled" ? 1 : 0;
        await controls.nth(spaceTarget).focus();
        await expect(inputs.nth(2)).toBeChecked();
        await page.keyboard.press(" ");
        await expectSelection(spaceTarget, ++changes);
        await page.keyboard.press("Tab");
        expect(await group.evaluate((element) => element.contains(document.activeElement))).toBe(false);
        await page.keyboard.press("Shift+Tab");
        await expectSelection(spaceTarget, changes);
      });
    }

    for (const example of ["default", "disabled"]) {
      test(`${example} radio Tab entry uses the selected enabled control on ${side}`, async ({ page }, testInfo) => {
        const path = `/preview/radio-group/${example}`;
        await page.goto(side === "React" ? `${testInfo.project.use.parityURL}${path}` : path);
        await (side === "React" ? referenceReady(page) : connected(page));
        const group = page.getByRole("radiogroup");
        const controls = group.getByRole("radio");
        await page.keyboard.press("Tab");
        await expect(controls.nth(1)).toBeFocused();
        await page.keyboard.press("Tab");
        expect(await group.evaluate((element) => element.contains(document.activeElement))).toBe(false);
        await page.keyboard.press("Shift+Tab");
        await expect(controls.nth(1)).toBeFocused();
      });
    }
  }

  test("choosing one unchooses the others, which is what makes it a radio", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    const comfortable = checkboxControl(page, "r2");
    const compact = checkboxControl(page, "r3");

    await expect(comfortable.control).toHaveAttribute("aria-checked", "true");
    await expect(comfortable.input).toBeChecked();

    await compact.control.click();

    await expect(compact.control).toHaveAttribute("aria-checked", "true");
    await expect(compact.input).toBeChecked();

    await expect(comfortable.control).toHaveAttribute("aria-checked", "false");
    await expect(comfortable.control).toHaveAttribute("data-unchecked", "");
    await expect(comfortable.input).not.toBeChecked();
  });

  test("each radio says it is a radio, not a checkbox", async ({ page }) => {
    await visit(page, "/preview/radio-group/default");

    await expect(page.locator("#r2-control")).toHaveRole("radio");
  });
});

test.describe("a toggle", () => {
  test("says pressed rather than checked, because it is a button", async ({ page }) => {
    await visit(page, "/preview/toggle/default");
    const bookmark = page.locator("#bookmark");

    await expect(bookmark).toHaveAttribute("aria-pressed", "false");

    await bookmark.click();

    await expect(bookmark).toHaveAttribute("aria-pressed", "true");
    await expect(bookmark).toHaveAttribute("data-pressed", "");
  });
});
