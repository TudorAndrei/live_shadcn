defmodule LiveShadcnTools.SpecTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Spec

  describe "what a class string reads" do
    test "a data variant means the element must carry that attribute" do
      assert %{"self" => ["data-ending-style", "data-starting-style"]} =
               Spec.reads(
                 "h-(--accordion-panel-height) data-ending-style:h-0 data-starting-style:h-0"
               )
    end

    test "an aria variant is a contract too, because shadcn styles against it" do
      assert %{"self" => ["aria-disabled"]} = Spec.reads("aria-disabled:pointer-events-none")
    end

    test "a group variant names the ancestor that must carry the attribute" do
      assert %{"group" => [%{"group" => "accordion-trigger", "attr" => "aria-expanded"}]} =
               Spec.reads("group-aria-expanded/accordion-trigger:hidden")
    end

    test "an arbitrary variant holds no attribute contract" do
      assert %{"self" => [], "group" => []} =
               Spec.reads("[&_p:not(:last-child)]:mb-4 hover:underline")
    end
  end

  describe "the CSS variables a class string interpolates" do
    test "finds the variable no static class string can compute" do
      assert Spec.vars("h-(--accordion-panel-height) overflow-hidden") ==
               ["--accordion-panel-height"]
    end

    test "a class string with no variable needs nothing at runtime" do
      assert Spec.vars("flex w-full flex-col") == []
    end
  end

  describe "building a spec" do
    @tsx """
    import { Thing as ThingPrimitive } from "@base-ui/react/thing"

    import { cn } from "@/registry/bases/base/lib/utils"

    function Thing({ className, children, ...props }: ThingPrimitive.Panel.Props) {
      return (
        <ThingPrimitive.Panel data-slot="thing" className={cn("p-2", className)} {...props}>
          {children}
        </ThingPrimitive.Panel>
      )
    }

    export { Thing }
    """

    @markdown """
    ## Anatomy

    ```jsx title="Anatomy"
    <Thing.Panel />;
    ```

    ### Panel

    The panel.
    Renders a `<section>` element.

    **Panel Data Attributes:**

    | Attribute | Type | Description |
    | :-------- | :--- | :---------- |
    | data-open | -    | Open.       |
    """

    defp build do
      Spec.build("thing",
        tsx: @tsx,
        markdown: %{"thing" => @markdown},
        module: "thing",
        recipe: "disclosure",
        upstream: %{}
      )
    end

    test "the element comes from Base UI, never from the shadcn wrapper" do
      assert [%{"tree" => %{"tag" => "section", "part" => "Panel"}}] = build()["parts"]
    end

    test "the heex function name is derived from the shadcn export" do
      assert [%{"name" => "thing", "export" => "Thing"}] = build()["parts"]
    end

    test "an element that shadcn renders but Base UI does not document is an error" do
      tsx =
        String.replace(@tsx, "ThingPrimitive.Panel data-slot", "ThingPrimitive.Ghost data-slot")

      tsx = String.replace(tsx, "</ThingPrimitive.Panel>", "</ThingPrimitive.Ghost>")

      assert_raise RuntimeError, ~r/no fetched Base UI page documents/, fn ->
        Spec.build("thing",
          tsx: tsx,
          markdown: %{"thing" => @markdown},
          module: "thing",
          recipe: "disclosure",
          upstream: %{}
        )
      end
    end

    test "a bare value is content the caller supplies, not markup" do
      tsx = String.replace(@tsx, "{children}", "{title}")

      spec =
        Spec.build("thing",
          tsx: tsx,
          markdown: %{"thing" => @markdown},
          module: "thing",
          recipe: "disclosure",
          upstream: %{}
        )

      assert [%{"tree" => %{"children" => [%{"type" => "value", "code" => "title"}]}}] =
               spec["parts"]
    end

    test "an expression the reader cannot render is an error, never a silent drop" do
      tsx = String.replace(@tsx, "{children}", "{items.map((item) => item.label)}")

      assert_raise RuntimeError, ~r/renders no markup/, fn ->
        Spec.build("thing",
          tsx: tsx,
          markdown: %{"thing" => @markdown},
          module: "thing",
          recipe: "disclosure",
          upstream: %{}
        )
      end
    end
  end
end
