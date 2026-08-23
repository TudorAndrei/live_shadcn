defmodule LiveShadcn.UI.AccordionTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Accordion

  defp render(assigns) do
    assigns =
      Map.merge(
        %{
          id: "faq",
          item: [
            %{
              __slot__: :item,
              id: "faq-1",
              title: "What is Base UI?",
              inner_block: fn _, _ -> "Unstyled components." end
            }
          ]
        },
        assigns
      )

    render_component(&Accordion.accordion/1, assigns)
  end

  defp with_item(overrides) do
    render(%{
      item: [
        Map.merge(
          %{
            __slot__: :item,
            id: "faq-1",
            title: "What is Base UI?",
            inner_block: fn _, _ -> "Unstyled components." end
          },
          overrides
        )
      ]
    })
  end

  describe "the anatomy shadcn renders" do
    test "every part carries the data-slot upstream gives it" do
      html = render(%{})

      for name <- ~w(accordion accordion-item accordion-trigger accordion-content) do
        assert slot(html, name)
      end
    end

    test "the parts nest the way the Base UI anatomy says" do
      html = render(%{})

      assert [{"div", _, _}] =
               Floki.find(
                 Floki.parse_fragment!(html),
                 "[data-slot='accordion'] > [data-slot='accordion-item']"
               )

      assert [_] =
               Floki.find(
                 Floki.parse_fragment!(html),
                 "[data-slot='accordion-item'] > h3 > [data-slot='accordion-trigger']"
               )

      assert [_] =
               Floki.find(
                 Floki.parse_fragment!(html),
                 "[data-slot='accordion-item'] > [data-slot='accordion-content']"
               )
    end

    test "the trigger is a heading button, which is what makes it navigable" do
      html = render(%{})

      assert [_] = Floki.find(Floki.parse_fragment!(html), "h3 > button")
      assert attribute(slot(html, "accordion-trigger"), "type") == "button"
    end

    test "class strings are copied from upstream, not retyped" do
      classes = classes(slot(render(%{}), "accordion"))

      assert "cn-accordion" in classes
      assert "flex" in classes
      assert "w-full" in classes
    end

    test "the caller's class is appended to the class string upstream renders" do
      classes = classes(slot(render(%{class: "mt-4"}), "accordion"))

      assert "cn-accordion" in classes
      assert "mt-4" in classes
    end
  end

  describe "the ARIA contract" do
    test "the trigger names the panel it controls" do
      html = render(%{})

      assert attribute(slot(html, "accordion-trigger"), "aria-controls") == "faq-1-panel"
      assert attribute(slot(html, "accordion-content"), "id") == "faq-1-panel"
    end

    test "the panel is a region labelled by its own heading" do
      html = render(%{})
      panel = slot(html, "accordion-content")

      assert attribute(panel, "role") == "region"
      assert attribute(panel, "aria-labelledby") == "faq-1-header"
    end

    test "a closed panel is hidden and its trigger says so" do
      html = render(%{})

      assert attribute(slot(html, "accordion-trigger"), "aria-expanded") == "false"
      assert attribute(slot(html, "accordion-content"), "hidden") == :present
    end

    test "an open panel is not hidden and its trigger says so" do
      html = with_item(%{open: true})

      assert attribute(slot(html, "accordion-trigger"), "aria-expanded") == "true"
      assert attribute(slot(html, "accordion-content"), "hidden") == nil
    end
  end

  describe "the data-attribute contract" do
    test "an open item marks every part Base UI documents" do
      html = with_item(%{open: true})

      assert attribute(slot(html, "accordion-item"), "data-open") == :present
      assert attribute(slot(html, "accordion-content"), "data-open") == :present
      assert attribute(slot(html, "accordion-trigger"), "data-panel-open") == :present
    end

    test "a closed item marks nothing, because Base UI marks state by presence" do
      html = render(%{})

      assert attribute(slot(html, "accordion-item"), "data-open") == nil
      assert attribute(slot(html, "accordion-trigger"), "data-panel-open") == nil
    end

    test "a disabled item sets both the attribute Base UI documents and the one shadcn styles" do
      html = with_item(%{disabled: true})
      trigger = slot(html, "accordion-trigger")

      assert attribute(trigger, "data-disabled") == :present
      assert attribute(trigger, "aria-disabled") == :present
    end

    test "the accordion and its panels carry the documented orientation" do
      html = render(%{})

      assert attribute(slot(html, "accordion"), "data-orientation") == "vertical"
      assert attribute(slot(html, "accordion-content"), "data-orientation") == "vertical"
    end

    test "each item carries its index, which Base UI documents on three parts" do
      html =
        render(%{
          item:
            for id <- ~w(a b) do
              %{__slot__: :item, id: id, title: id, inner_block: fn _, _ -> id end}
            end
        })

      assert Floki.attribute(
               Floki.parse_fragment!(html),
               "[data-slot='accordion-item']",
               "data-index"
             ) ==
               ["0", "1"]
    end
  end

  describe "what the client hook is told" do
    test "the panel declares the hook and the variable it has to measure into" do
      panel = slot(render(%{}), "accordion-content")

      assert attribute(panel, "phx-hook") == "LiveBase.Disclosure"
      assert attribute(panel, "data-lb-height-var") == "--accordion-panel-height"
      assert attribute(panel, "data-lb-width-var") == "--accordion-panel-width"
    end

    test "the element whose class string reads a measured variable is the one marked for it" do
      inner = Floki.find(Floki.parse_fragment!(render(%{})), "[data-lb-measure]")

      assert [element] = inner
      assert classes(element) |> Enum.any?(&String.contains?(&1, "--accordion-panel-height"))
    end

    test "the element whose class string reads a transition attribute is marked for the hook" do
      [element] = Floki.find(Floki.parse_fragment!(render(%{})), "[data-lb-style-target]")

      assert "data-starting-style:h-0" in classes(element)
      assert "data-ending-style:h-0" in classes(element)
    end
  end

  describe "opening a panel" do
    test "the trigger carries the client command, so no click reaches the server" do
      command = attribute(slot(render(%{}), "accordion-trigger"), "phx-click")

      assert command =~ "toggle_attr"
      assert command =~ "aria-expanded"
      assert command =~ "data-panel-open"
      refute command =~ "push"
    end

    test "single-open mode closes the other items first" do
      command = attribute(slot(render(%{}), "accordion-trigger"), "phx-click")

      assert command =~ "#faq [data-open]:not(#faq-1)"
    end

    test "multiple-open mode leaves the other items alone" do
      command = attribute(slot(render(%{multiple: true}), "accordion-trigger"), "phx-click")

      refute command =~ ":not(#faq-1)"
    end

    test "every attribute the client owns is protected from the next server render" do
      html = render(%{})

      assert attribute(slot(html, "accordion-trigger"), "phx-mounted") =~ "aria-expanded"
      assert attribute(slot(html, "accordion-content"), "phx-mounted") =~ "data-starting-style"
    end
  end

  describe "icons" do
    test "both chevrons are rendered, and the class string decides which one shows" do
      icons =
        Floki.find(Floki.parse_fragment!(render(%{})), "[data-slot='accordion-trigger-icon']")

      # Which glyph is drawn belongs to the icon set. Which one is visible is
      # the class string's business, and that is what the component owes.
      assert [down, up] = icons
      assert "group-aria-expanded/accordion-trigger:hidden" in classes(down)
      assert "group-aria-expanded/accordion-trigger:inline" in classes(up)
      assert "hidden" in classes(up)
    end

    test "an icon inside a labelled control is decorative" do
      [icon | _] =
        Floki.find(Floki.parse_fragment!(render(%{})), "[data-slot='accordion-trigger-icon']")

      assert attribute(icon, "aria-hidden") == "true"
    end
  end
end
