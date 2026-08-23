defmodule LiveBase.DisclosureTest do
  use ExUnit.Case, async: true

  alias LiveBase.Disclosure

  defp ops(%Phoenix.LiveView.JS{ops: ops}), do: ops

  defp op(js, kind), do: Enum.filter(ops(js), &(hd(&1) == kind))

  describe "identifiers" do
    test "every id inside an item derives from the item id" do
      assert Disclosure.header_id("faq-1") == "faq-1-header"
      assert Disclosure.trigger_id("faq-1") == "faq-1-trigger"
      assert Disclosure.panel_id("faq-1") == "faq-1-panel"
    end
  end

  describe "toggling an item" do
    test "flips the three attributes the contract names, and nothing else" do
      js = Disclosure.toggle(item: "faq-1", root: "faq", multiple: true)

      attributes = for ["toggle_attr", %{attr: [name | _]}] <- ops(js), do: name

      assert attributes == ["aria-expanded", "data-panel-open", "data-open"]
    end

    test "marks the item, its heading, and its panel together" do
      js = Disclosure.toggle(item: "faq-1", root: "faq", multiple: true)

      assert [["toggle_attr", %{to: to}]] =
               for(
                 ["toggle_attr", %{attr: ["data-open" | _]} = args] <- ops(js),
                 do: ["toggle_attr", args]
               )

      assert to == "#faq-1, #faq-1-header, #faq-1-panel"
    end

    test "never reaches the server, because the open panel is not application state" do
      js = Disclosure.toggle(item: "faq-1", root: "faq")

      assert op(js, "push") == []
    end
  end

  describe "single-open mode" do
    test "closes every other item before flipping this one" do
      js = Disclosure.toggle(item: "faq-1", root: "faq")

      assert [%{to: "#faq [data-panel-open]:not(#faq-1 *)"}, %{to: open}] =
               for(["remove_attr", args] <- op(js, "remove_attr"), do: args)

      assert open == "#faq [data-open]:not(#faq-1):not(#faq-1 *)"
    end

    test "the exclusion is what keeps the flip that follows correct" do
      # Closing the others cannot close the clicked item, so a toggle after it
      # still sees the state the reader expects.
      js = Disclosure.toggle(item: "faq-1", root: "faq")

      for ["remove_attr", %{to: to}] <- op(js, "remove_attr") do
        assert to =~ ":not(#faq-1"
      end
    end

    test "multiple-open mode touches no other item" do
      js = Disclosure.toggle(item: "faq-1", root: "faq", multiple: true)

      assert op(js, "remove_attr") == []
      assert op(js, "set_attr") == []
    end
  end

  describe "open and close" do
    test "open sets the attributes rather than flipping them" do
      js = Disclosure.open(item: "faq-1", root: "faq", multiple: true)

      assert for(["set_attr", %{attr: [name | _]}] <- ops(js), do: name) ==
               ["aria-expanded", "data-panel-open", "data-open"]
    end

    test "close removes the flags and states the ARIA value" do
      js = Disclosure.close(item: "faq-1")

      assert [["set_attr", %{attr: ["aria-expanded", "false"]}]] = op(js, "set_attr")

      assert for(["remove_attr", %{attr: name}] <- ops(js), do: name) ==
               ["data-panel-open", "data-open"]
    end
  end

  describe "attributes the client owns" do
    test "the trigger keeps its own open state across a server render" do
      assert [["ignore_attrs", %{attrs: attrs}]] = ops(Disclosure.owned_attributes(:trigger))
      assert attrs == ["aria-expanded", "data-panel-open"]
    end

    test "the panel keeps the measurement and the transition attributes too" do
      assert [["ignore_attrs", %{attrs: attrs}]] = ops(Disclosure.owned_attributes(:panel))

      assert "data-starting-style" in attrs
      assert "data-ending-style" in attrs
      assert "style" in attrs
    end
  end
end
