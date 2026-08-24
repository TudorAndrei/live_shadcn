defmodule LiveShadcnTools.AstTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Ast
  alias LiveShadcnTools.Cva
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
      assert Ast.parse!(@source).exports == ["Accordion", "AccordionTrigger"]
    end

    test "keeps the props type, which names the Base UI part" do
      [accordion, _] = Ast.parse!(@source).functions
      assert accordion.props_type == "AccordionPrimitive.Root.Props"
    end

    test "reads attributes, spreads, and nesting" do
      [_, trigger] = Ast.parse!(@source).functions

      assert trigger.jsx.tag == "AccordionPrimitive.Header"
      assert Tsx.attr(trigger.jsx, "className") == {:string, "flex"}
      refute Tsx.spread?(trigger.jsx)

      [inner] = trigger.jsx.children
      assert inner.tag == "AccordionPrimitive.Trigger"
      assert Tsx.spread?(inner)
      assert [%{type: :expr, code: "children"}, icon] = inner.children
      assert Tsx.attr(icon, "aria-hidden") == true
    end

    test "the local names an import binds are what the file writes" do
      assert Ast.parse!(@source).imports["AccordionPrimitive"] == "@base-ui/react/accordion"
    end

    test "a return without parentheses is read too" do
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

      assert [item, link] = Ast.parse!(source).functions
      assert item.jsx.tag == "li"
      assert link.jsx.tag == "a"
    end
  end

  describe "the shapes the regular expressions used to get wrong" do
    test "a return belonging to a callback is not the component's" do
      # This is what took the trigger out of `Reasoning`: the first `return (`
      # in the text belongs to the effect's cleanup, and counting from there
      # asked for a JSX element and found an empty pair of brackets.
      source = """
      const Panel = ({ children }) => {
        useEffect(() => {
          const timer = setTimeout(() => {}, 1000)
          return () => clearTimeout(timer)
        }, [])

        return (
          <div data-slot="panel">{children}</div>
        )
      }
      """

      assert [panel] = Ast.parse!(source).functions
      assert panel.jsx.tag == "div"
    end

    test "an arrow whose body is an expression renders that expression" do
      source = ~S"""
      const Icon = ({ className, children, ...props }) =>
        children ?? (
          <BookmarkIcon className={cn("size-4", className)} {...props} />
        );
      """

      assert [icon] = Ast.parse!(source).functions
      assert %{type: :expr, code: code} = icon.jsx
      assert code =~ "children ??"
    end

    test "a brace inside a string does not end the statement" do
      source = ~S"""
      const Row = ({ label }) => <span title={"a } brace"}>{label}</span>;
      """

      assert [row] = Ast.parse!(source).functions
      assert row.jsx.tag == "span"
      assert {:expr, ~s|"a } brace"|, %{"type" => "Literal"}} = Tsx.attr(row.jsx, "title")
    end

    test "a class name inside a string does not merge the caller class" do
      source = ~S"""
      const Row = () => <span className={cn("className")} />;
      """

      assert [row] = Ast.parse!(source).functions
      refute Tsx.merges_class?(Tsx.attr(row.jsx, "className"))
    end

    test "variant calls read the class expression node" do
      source = ~S"""
      const Row = () => <span className={cn(buttonVariants({ variant, size }))} />;
      """

      assert [row] = Ast.parse!(source).functions

      assert [%{"table" => "buttonVariants", "args" => ["variant", "size"]}] =
               Tsx.variant_calls(Tsx.attr(row.jsx, "className"), ["buttonVariants"])
    end

    test "conditional classes read the class expression node" do
      source = ~S"""
      const Row = ({ active }) => <span className={cn(active ? "is-active" : "is-idle")} />;
      """

      assert [row] = Ast.parse!(source).functions

      assert Tsx.conditional_classes(Tsx.attr(row.jsx, "className")) == [
               %{"when" => "active", "then" => "is-active", "else" => "is-idle"}
             ]
    end

    test "mapped JSX reads its collection and body from the expression node" do
      source = ~S"""
      const Row = ({ rows }) => <ul>{rows.map((row, index) => <li>{row.label}</li>)}</ul>;
      """

      assert [row] = Ast.parse!(source).functions
      [expression] = row.jsx.children

      expression = {:expr, expression.code, expression.node}

      assert {{:expr, "rows", _}, "row", [], "index", {:expr, "<li>{row.label}</li>", _}} =
               Ast.mapped(expression)
    end

    test "logical JSX reads each side from the expression node" do
      source = ~S"""
      const Row = ({ active }) => <div>{active && <span>ready</span>}</div>;
      """

      assert [row] = Ast.parse!(source).functions
      [expression] = row.jsx.children
      expression = {:expr, expression.code, expression.node}

      assert {"&&", {:expr, "active", _}, {:expr, "<span>ready</span>", right}} =
               Ast.logical(expression)

      assert %{type: :element, tag: "span"} = Ast.jsx({:expr, "<span>ready</span>", right})
    end

    test "local TypeScript aliases describe component props" do
      source = ~S"""
      type RowProps = {
        enabled?: boolean
        count: number
        side?: "left" | "right"
      }

      const Row = ({ enabled, count, side }: RowProps) => <span>{side}</span>;
      """

      assert [row] = Ast.parse!(source).functions

      assert row.param_types == %{
               "enabled" => %{"optional" => true, "type" => "boolean"},
               "count" => %{"optional" => false, "type" => "integer"},
               "side" => %{"optional" => true, "values" => ["left", "right"]}
             }
    end

    test "CVA tables read their nested object nodes" do
      source = ~S"""
      const rowVariants = cva("row", {
        variants: { side: { left: "left", right: "right" } },
        defaultVariants: { side: "left" },
      })
      """

      assert {:ok, table} = Ast.parse!(source).const_nodes["rowVariants"] |> Cva.parse()
      assert table["base"] == "row"
      assert table["variants"]["side"] == %{"left" => "left", "right" => "right"}
      assert table["defaults"] == %{"side" => "left"}
    end

    test "object entries retain the expression node and exact source" do
      source = ~S"""
      const labels = { ready: "Ready", waiting: <span>Waiting</span> }
      """

      entries = Ast.parse!(source).const_nodes["labels"] |> Ast.object_entries()

      assert {:expr, ~s|"Ready"|, _} = entries["ready"]
      assert {:expr, "<span>Waiting</span>", _} = entries["waiting"]
    end

    test "member roots come from member expression nodes" do
      source = ~S"""
      const Row = ({ error, label }) => <span title={error?.message ?? label["text"]} />;
      """

      assert [row] = Ast.parse!(source).functions
      assert {:expr, _code, node} = Tsx.attr(row.jsx, "title")
      assert Ast.member_roots(node) == ["error", "label"]
      assert Ast.identifiers(node) == ["error", "label"]
    end

    test "identifiers exclude a member property that is not computed" do
      source = ~S"""
      const Row = ({ state }) => <span>{state === "ready" ? state.label : state["label"]}</span>;
      """

      assert [row] = Ast.parse!(source).functions
      [%{node: node}] = row.jsx.children
      assert Ast.identifiers(node) == ["state"]
    end

    test "a parameter reference comes from scope analysis, not a word search" do
      source = ~S"""
      const Row = ({ title, usedByHandler, unused }) => {
        const click = () => usedByHandler()
        return <span>{title}</span>
      }
      """

      assert [row] = Ast.parse!(source).functions
      assert row.refs == ["title"]
    end

    test "memo and forwardRef are read through" do
      source = """
      export const Badge = memo(({ children }) => <span data-slot="badge">{children}</span>);
      """

      assert [badge] = Ast.parse!(source).functions
      assert badge.name == "Badge"
      assert badge.jsx.tag == "span"
    end

    test "a prop renamed to hold a component is recorded by both names" do
      source = """
      export const Step = ({ icon: Icon = DotIcon, label }) => <Icon />;
      """

      assert [step] = Ast.parse!(source).functions
      assert step.renames == {"Icon", "icon"} |> then(&Map.new([&1]))
      assert step.params["icon"] == "DotIcon"
    end

    test "state and locals are props, because the server owns state" do
      source = """
      export const Branches = ({ defaultBranch }) => {
        const [current, setCurrent] = useState(0)
        const { isOpen } = usePanel()

        return <span>{current}</span>
      }
      """

      assert [branches] = Ast.parse!(source).functions
      assert branches.params["current"] == "0"
      assert Map.has_key?(branches.params, "isOpen")
      refute Map.has_key?(branches.params, "setCurrent")
    end
  end

  describe "a file it cannot parse" do
    test "is an error with the parser's own reason, never a skip" do
      assert_raise RuntimeError, ~r/could not read this source/, fn ->
        Ast.parse!("function Broken( {\n")
      end
    end
  end
end
