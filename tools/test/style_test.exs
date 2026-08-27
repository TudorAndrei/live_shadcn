defmodule LiveShadcnTools.StyleTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Style

  @sheet """
  .style-vega {
    /* MARK: Accordion */
    .cn-accordion-item {
      @apply not-last:border-b;
    }

    .cn-accordion-content {
      @apply data-open:animate-accordion-down data-closed:animate-accordion-up text-sm;
    }

    .cn-alert {
      @apply grid gap-1;

      .cn-alert-title {
        @apply font-medium;
      }
    }
  }
  """

  describe "reading a style sheet" do
    test "returns the utilities each cn- class applies" do
      assert Style.rules(@sheet)["cn-accordion-item"] == "not-last:border-b"
    end

    test "a nested rule belongs to its own class, not to the one around it" do
      rules = Style.rules(@sheet)

      assert rules["cn-alert"] == "grid gap-1"
      assert rules["cn-alert-title"] == "font-medium"
    end

    test "collapses the line breaks a long rule is wrapped on" do
      sheet = ".cn-thing {\n  @apply flex\n    items-center;\n}"

      assert Style.rules(sheet)["cn-thing"] == "flex items-center"
    end
  end

  describe "the style index" do
    test "lists the styles in the order upstream prefers them" do
      index = ~s|export const STYLES = [{ name: "vega" }, { name: "nova" }]|

      assert Style.names(index) == ["vega", "nova"]
    end
  end
end
