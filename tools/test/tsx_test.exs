defmodule LiveShadcnTools.TsxTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Tsx

  describe "reading a registry component" do
    @source """
    import { Accordion as AccordionPrimitive } from "@base-ui/react/accordion"

    import { cn } from "@/registry/bases/base/lib/utils"

    function Accordion({ className, ...props }: AccordionPrimitive.Root.Props) {
      return (
        <AccordionPrimitive.Root
          data-slot="accordion"
          className={cn("cn-accordion flex w-full flex-col", className)}
          {...props}
        />
      )
    }

    function AccordionTrigger({ className, children, ...props }) {
      return (
        <AccordionPrimitive.Header className="flex">
          <AccordionPrimitive.Trigger data-slot="accordion-trigger" {...props}>
            {children}
            <ChevronIcon aria-hidden />
          </AccordionPrimitive.Trigger>
        </AccordionPrimitive.Header>
      )
    }

    export { Accordion, AccordionTrigger }
    """

    test "returns the exports in the order upstream lists them" do
      assert Tsx.parse!(@source).exports == ["Accordion", "AccordionTrigger"]
    end

    test "keeps the props type, which names the Base UI part" do
      [accordion, _] = Tsx.parse!(@source).functions
      assert accordion.props_type == "AccordionPrimitive.Root.Props"
    end

    test "reads attributes, spreads, and nesting" do
      [_, trigger] = Tsx.parse!(@source).functions

      assert trigger.jsx.tag == "AccordionPrimitive.Header"
      assert Tsx.attr(trigger.jsx, "className") == {:string, "flex"}
      refute Tsx.spread?(trigger.jsx)

      [inner] = trigger.jsx.children
      assert inner.tag == "AccordionPrimitive.Trigger"
      assert Tsx.spread?(inner)
      assert [%{type: :expr, code: "children"}, icon] = inner.children
      assert Tsx.attr(icon, "aria-hidden") == true
    end

    test "a return without parentheses is read too, and only within its own body" do
      source = """
      function Item({ ...props }) {
        return <li data-slot="item" {...props} />
      }

      function Link({ className, ...props }) {
        return (
          <a data-slot="link" className={cn("underline", className)} {...props} />
        )
      }
      """

      assert [item, link] = Tsx.parse!(source).functions
      assert item.jsx.tag == "li"
      assert link.jsx.tag == "a"
    end

    test "a function that returns nothing renderable is an error, never a skip" do
      assert_raise RuntimeError, ~r/no return to read/, fn ->
        Tsx.parse!("function Broken({}: X.Y.Props) {\n  const x = 1\n}\n")
      end
    end
  end

  describe "class strings" do
    test "keeps the literals cn() is called with and drops the rest" do
      assert Tsx.classes({:expr, ~s|cn("flex w-full", className)|}) == "flex w-full"
      assert Tsx.classes({:expr, ~s|cn("a", isOpen && "b", className)|}) == "a"
    end

    test "collapses the line breaks upstream wraps long class strings on" do
      assert Tsx.classes({:string, "flex\n  items-center\n  gap-2"}) == "flex items-center gap-2"
    end

    test "a bare string literal is a class string too" do
      assert Tsx.classes({:string, "overflow-hidden"}) == "overflow-hidden"
    end

    test "an expression that holds no literal contributes nothing" do
      assert Tsx.classes({:expr, "className"}) == ""
    end
  end
end
