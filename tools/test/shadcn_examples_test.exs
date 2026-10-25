defmodule LiveShadcnTools.ShadcnExamplesTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.ShadcnExamples

  describe "parse/2" do
    test "reads all documented previews, keeps their order, and removes duplicates" do
      markdown = """
      <ComponentPreview styleName="base-nova" name="dropdown-menu-demo" />
      <ComponentPreview
        direction="rtl"
        name="dropdown-menu-rtl"
        styleName="base-nova"
      />
      <ComponentPreview name="dropdown-menu-demo" />
      """

      assert ShadcnExamples.parse("dropdown-menu", markdown) == [
               %{"id" => "default", "source" => "dropdown-menu-demo"},
               %{"id" => "rtl", "source" => "dropdown-menu-rtl"}
             ]
    end

    test "reads a preview with an explicit closing tag" do
      markdown = "<ComponentPreview name=\"button-size\"></ComponentPreview>"

      assert ShadcnExamples.parse("button", markdown) == [
               %{"id" => "size", "source" => "button-size"}
             ]
    end

    test "keeps an example from a related component under its full source name" do
      markdown = """
      <ComponentPreview name="label-demo" />
      <ComponentPreview name="field-demo" />
      """

      assert ShadcnExamples.parse("label", markdown) == [
               %{"id" => "default", "source" => "label-demo"},
               %{"id" => "field-demo", "source" => "field-demo"}
             ]
    end

    test "does not give two official examples the same local id" do
      markdown = """
      <ComponentPreview name="button-demo" />
      <ComponentPreview name="button-default" />
      """

      assert ShadcnExamples.parse("button", markdown) == [
               %{"id" => "default", "source" => "button-demo"},
               %{"id" => "button-default", "source" => "button-default"}
             ]
    end

    test "classifies the Card RTL fixture under Card, not the Direction helper" do
      discovered = %{
        "card" => ShadcnExamples.from_sources("card", ["card-demo", "card-rtl"]),
        "direction" => ShadcnExamples.from_sources("direction", ["card-rtl"])
      }

      assert discovered["card"] == [
               %{"id" => "default", "source" => "card-demo"},
               %{"id" => "rtl", "source" => "card-rtl"}
             ]

      assert discovered["direction"] == []
    end

    test "keeps explicit fixtures from a pinned registry source" do
      assert ShadcnExamples.from_sources("sonner", [
               %{
                 "id" => "basic",
                 "source" => "shadcn/examples/sonner-example.tsx#SonnerBasic"
               },
               %{
                 "id" => "with-description",
                 "source" => "shadcn/examples/sonner-example.tsx#SonnerWithDescription"
               }
             ]) == [
               %{"id" => "basic", "source" => "shadcn/examples/sonner-example.tsx#SonnerBasic"},
               %{
                 "id" => "with-description",
                 "source" => "shadcn/examples/sonner-example.tsx#SonnerWithDescription"
               }
             ]
    end

    test "keeps the interactive Chart source under its published demo id" do
      assert ShadcnExamples.parse("chart", ~s(<ComponentPreview name="chart-demo" />)) == [
               %{"id" => "demo", "source" => "chart-demo"}
             ]
    end

    test "keeps every Base Date Picker source under its published id" do
      assert ShadcnExamples.from_sources("date-picker", [
               "date-picker-demo",
               "date-picker-basic",
               "date-picker-range",
               "date-picker-dob",
               "date-picker-input",
               "date-picker-time",
               "date-picker-natural-language",
               "date-picker-rtl"
             ]) == [
               %{"id" => "default", "source" => "date-picker-demo"},
               %{"id" => "basic", "source" => "date-picker-basic"},
               %{"id" => "range", "source" => "date-picker-range"},
               %{"id" => "dob", "source" => "date-picker-dob"},
               %{"id" => "input", "source" => "date-picker-input"},
               %{"id" => "time", "source" => "date-picker-time"},
               %{"id" => "natural-language", "source" => "date-picker-natural-language"},
               %{"id" => "rtl", "source" => "date-picker-rtl"}
             ]
    end

    test "keeps every Base Typography source under its published id" do
      assert ShadcnExamples.from_sources("typography", [
               "typography-demo",
               "typography-h1",
               "typography-h2",
               "typography-h3",
               "typography-h4",
               "typography-p",
               "typography-blockquote",
               "typography-table",
               "typography-list",
               "typography-inline-code",
               "typography-lead",
               "typography-large",
               "typography-small",
               "typography-muted",
               "typography-rtl"
             ]) == [
               %{"id" => "default", "source" => "typography-demo"},
               %{"id" => "h1", "source" => "typography-h1"},
               %{"id" => "h2", "source" => "typography-h2"},
               %{"id" => "h3", "source" => "typography-h3"},
               %{"id" => "h4", "source" => "typography-h4"},
               %{"id" => "p", "source" => "typography-p"},
               %{"id" => "blockquote", "source" => "typography-blockquote"},
               %{"id" => "table", "source" => "typography-table"},
               %{"id" => "list", "source" => "typography-list"},
               %{"id" => "inline-code", "source" => "typography-inline-code"},
               %{"id" => "lead", "source" => "typography-lead"},
               %{"id" => "large", "source" => "typography-large"},
               %{"id" => "small", "source" => "typography-small"},
               %{"id" => "muted", "source" => "typography-muted"},
               %{"id" => "rtl", "source" => "typography-rtl"}
             ]
    end
  end

  describe "doc_pages/3" do
    test "unites registry and documentation pages without duplicates" do
      assert ShadcnExamples.doc_pages(
               ["button", "table"],
               ["data-table", "date-picker", "table", "typography"],
               nil
             ) == ["button", "table", "data-table", "date-picker", "typography"]
    end

    test "keeps a targeted fetch to its requested page" do
      assert ShadcnExamples.doc_pages(["button"], ["data-table", "typography"], "data-table") == [
               "data-table"
             ]
    end
  end

  describe "coverage/2" do
    test "passes only when each official example has HEEx" do
      expected = [
        %{"id" => "default", "source" => "dropdown-menu-demo"},
        %{"id" => "rtl", "source" => "dropdown-menu-rtl"}
      ]

      assert ShadcnExamples.coverage(expected, ["default", "rtl"]) == %{
               "pass" => true,
               "detail" => "2 of 2 official examples have HEEx previews"
             }
    end

    test "reports every missing HEEx preview" do
      expected = [
        %{"id" => "default", "source" => "dropdown-menu-demo"},
        %{"id" => "rtl", "source" => "dropdown-menu-rtl"},
        %{"id" => "complex", "source" => "dropdown-menu-complex"}
      ]

      assert ShadcnExamples.coverage(expected, ["default"]) == %{
               "pass" => false,
               "detail" =>
                 "missing HEEx: rtl (dropdown-menu-rtl), complex (dropdown-menu-complex)"
             }
    end
  end
end
