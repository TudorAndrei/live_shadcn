defmodule LiveShadcnTools.BaseUiTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.BaseUi

  @page """
  # Accordion

  ## Anatomy

  ```jsx title="Anatomy"
  import { Accordion } from '@base-ui/react/accordion';

  <Accordion.Root>
    <Accordion.Item>
      <Accordion.Header>
        <Accordion.Trigger />
      </Accordion.Header>
      <Accordion.Panel />
    </Accordion.Item>
  </Accordion.Root>;
  ```

  ## API reference

  ### Trigger

  A button that opens and closes the corresponding panel.
  Renders a `<button>` element.

  **Trigger Props:**

  | Prop         | Type      | Default | Description                     |
  | :----------- | :-------- | :------ | :------------------------------ |
  | nativeButton | `boolean` | `true`  | Whether it renders a&#xA;button. |

  **Trigger Data Attributes:**

  | Attribute       | Type | Description                               |
  | :-------------- | :--- | :---------------------------------------- |
  | data-panel-open | -    | Present when the accordion panel is open. |

  ### Trigger.Props

  Re-export of Trigger props.

  ### Panel

  A collapsible panel with the accordion item contents.
  Renders a `<div>` element.

  **Panel Data Attributes:**

  | Attribute           | Type | Description                                 |
  | :------------------ | :--- | :------------------------------------------ |
  | data-starting-style | -    | Present when the panel begins animating in. |

  **Panel CSS Variables:**

  | Variable                   | Type     | Description                   |
  | :------------------------- | :------- | :---------------------------- |
  | `--accordion-panel-height` | `number` | The accordion panel's height. |

  ### Orientation

  ```typescript
  type Orientation = 'horizontal' | 'vertical';
  ```
  """

  describe "the parts of a component" do
    test "a section is a part only when Base UI says what element it renders" do
      parsed = BaseUi.parse!(@page)

      assert parsed.order == ["Trigger", "Panel"]
      refute Map.has_key?(parsed.parts, "Orientation")
      refute Map.has_key?(parsed.parts, "Trigger.Props")
    end

    test "records the tag, the summary, and the data-attribute contract" do
      trigger = BaseUi.parse!(@page).parts["Trigger"]

      assert trigger.element == "button"
      assert trigger.summary == "A button that opens and closes the corresponding panel."
      assert trigger.data == ["data-panel-open"]
    end

    test "records the CSS variables a class string is allowed to read" do
      assert BaseUi.parse!(@page).parts["Panel"].css_vars == ["--accordion-panel-height"]
    end

    test "records props with their defaults, unwrapping the documentation escapes" do
      assert [%{"name" => "nativeButton", "type" => "boolean", "default" => "true", "doc" => doc}] =
               BaseUi.parse!(@page).parts["Trigger"].props

      assert doc == "Whether it renders a button."
    end
  end

  describe "anatomy" do
    test "reads how the parts nest from the documented JSX" do
      assert BaseUi.parse!(@page).anatomy == [
               %{
                 "part" => "Root",
                 "children" => [
                   %{
                     "part" => "Item",
                     "children" => [
                       %{
                         "part" => "Header",
                         "children" => [%{"part" => "Trigger", "children" => []}]
                       },
                       %{"part" => "Panel", "children" => []}
                     ]
                   }
                 ]
               }
             ]
    end
  end
end
