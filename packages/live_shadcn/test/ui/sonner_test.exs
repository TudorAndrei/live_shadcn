defmodule LiveShadcn.UI.SonnerTest do
  use ExUnit.Case, async: true

  import LiveShadcn.Test.Markup
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Sonner

  test "renders Sonner's persistent empty list" do
    html =
      render_component(&Sonner.toaster/1, %{
        id: "notices",
        dismiss: "dismiss_toast",
        toast: []
      })

    document = Floki.parse_fragment!(html)
    assert Floki.find(document, "section[aria-live='polite'][data-react-aria-top-layer]") != []
    assert Floki.find(document, "ol#notices[data-sonner-toaster]") != []
  end

  test "renders a title and description without an invented type icon" do
    html =
      render_component(&Sonner.toaster/1, %{
        id: "history-notice",
        dismiss: "dismiss_toast",
        duration: 4_000,
        toast: [
          %{
            __slot__: :toast,
            id: "loaded",
            title: "History loaded",
            type: nil,
            inner_block: fn _, _ -> "Scroll up to see earlier messages." end
          }
        ]
      })

    document = Floki.parse_fragment!(html)
    [toast] = Floki.find(document, "li[data-sonner-toast]")

    assert attribute(toast, "id") == "history-notice-loaded"
    assert attribute(toast, "data-type") == "default"
    assert attribute(toast, "role") == nil
    assert attribute(toast, "tabindex") == "0"
    assert Floki.find([toast], "div[data-title]") |> Floki.text() == "History loaded"

    assert Floki.find([toast], "div[data-description]")
           |> Floki.text() == "Scroll up to see earlier messages."

    assert attribute(toast, "data-sonner-toast") == :present
    assert attribute(toast, "class") =~ "absolute"
    assert Floki.find([toast], "[data-slot]") == []
    assert Floki.find([toast], "[data-close-button]") == []
  end
end
