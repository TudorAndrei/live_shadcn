defmodule LiveShadcn.UI.ComboboxTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, except: [render: 1]

  alias LiveShadcn.UI.Combobox

  test "the root renders no wrapper and its legacy option facade places the popup beside its input anchor" do
    html =
      render_component(&Combobox.combobox/1, %{
        id: "framework",
        default_value: "next",
        auto_highlight: true,
        option: [
          slot(:option, value: "next", label: "Next.js"),
          slot(:option, value: "remix", label: "Remix")
        ]
      })

    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "#framework") == []

    [anchor] = Floki.find(document, "#base-ui-_r_0_")
    assert Floki.attribute([anchor], "phx-hook") == ["LiveBase.Combobox"]
    assert Floki.attribute([anchor], "phx-mounted") |> hd() =~ "data-combobox-value"
    assert Floki.attribute([anchor], "phx-mounted") |> hd() =~ "aria-expanded"
    assert Floki.attribute([anchor], "data-combobox-value") == ["next"]
    assert Floki.attribute([anchor], "data-combobox-auto-highlight") == [""]
    assert Floki.attribute([anchor], "data-combobox-controller") == ["framework"]

    [input] = Floki.find(document, "input[role='combobox']")
    assert Floki.attribute([input], "aria-autocomplete") == ["list"]
    assert Floki.attribute([input], "aria-controls") == []

    [list] = Floki.find(document, "#_r_1_")
    assert Floki.attribute([list], "role") == ["listbox"]
    assert Floki.find([anchor], "#framework-positioner") == []

    [positioner] = Floki.find(document, "#framework-positioner")
    assert Floki.attribute([positioner], "data-combobox-controller") == ["framework"]

    [hidden_input] = Floki.find(document, "#framework-hidden-input")
    assert Floki.attribute([hidden_input], "aria-hidden") == ["true"]
    assert Floki.attribute([hidden_input], "tabindex") == ["-1"]
    assert Floki.attribute([hidden_input], "style") |> hd() =~ "clip-path: inset(50%)"

    [item] = Floki.find(document, "#framework-item-next")
    assert Floki.attribute([item], "role") == ["option"]
    assert Floki.attribute([item], "data-value") == ["next"]
    assert Floki.attribute([item], "phx-mounted") |> hd() =~ "data-highlighted"
  end

  test "a named single root renders the pinned visually hidden form control" do
    html =
      render_component(&Combobox.combobox/1, %{
        id: "named-framework",
        name: "framework",
        form: "framework-form",
        default_value: "Next.js",
        required: true
      })

    [input] = Floki.find(Floki.parse_fragment!(html), "input[name='framework']")
    assert Floki.attribute([input], "type") == ["text"]
    assert Floki.attribute([input], "name") == ["framework"]
    assert Floki.attribute([input], "form") == ["framework-form"]
    assert Floki.attribute([input], "value") == ["Next.js"]
    assert Floki.attribute([input], "required") == ["required"]
    assert Floki.attribute([input], "style") |> hd() =~ "position: absolute"
  end

  test "a named multiple root renders one form input for each selected value" do
    html =
      render_component(&Combobox.combobox/1, %{
        id: "named-categories",
        name: "categories[]",
        multiple: true,
        default_value: ["Technology", "Design"],
        disabled: true,
        required: true,
        form: "categories-form"
      })

    document = Floki.parse_fragment!(html)
    [primary] = Floki.find(document, "#named-categories-hidden-input")
    assert Floki.attribute([primary], "type") == ["text"]
    assert Floki.attribute([primary], "value") == [""]
    assert Floki.attribute([primary], "disabled") == ["disabled"]
    assert Floki.attribute([primary], "style") |> hd() =~ "position: fixed"

    values =
      document
      |> Floki.find("input[data-lb-combobox-form-value='named-categories']")
      |> Enum.map(fn input ->
        %{
          disabled: Floki.attribute([input], "disabled"),
          form: Floki.attribute([input], "form"),
          name: Floki.attribute([input], "name"),
          value: Floki.attribute([input], "value")
        }
      end)

    assert values == [
             %{
               disabled: ["disabled"],
               form: ["categories-form"],
               name: ["categories[]"],
               value: ["Technology"]
             },
             %{
               disabled: ["disabled"],
               form: ["categories-form"],
               name: ["categories[]"],
               value: ["Design"]
             }
           ]
  end

  test "the input supports invalid, disabled, clear, and input-group composition" do
    html =
      render_component(&Combobox.combobox_input/1, %{
        combobox_id: "country",
        disabled: true,
        show_clear: true,
        placeholder: "Search countries",
        rest: %{"aria-invalid": "true"}
      })

    document = Floki.parse_fragment!(html)
    [input] = Floki.find(document, "input[role='combobox']")
    assert Floki.attribute([input], "disabled") == ["disabled"]
    assert Floki.attribute([input], "aria-invalid") == ["true"]
    assert Floki.attribute([input], "data-slot") == ["input-group-control"]
    assert Floki.find(document, "[data-slot='input-group-addon']") != []

    [clear] = Floki.find(document, "[data-slot='combobox-clear']")
    assert Floki.attribute([clear], "hidden") == ["hidden"]
    assert Floki.attribute([clear], "aria-label") == ["Clear selection"]
    assert Floki.attribute([clear], "phx-mounted") |> hd() =~ "data-visible"

    [trigger] = Floki.find(document, "[data-slot='input-group-button']")
    assert Floki.attribute([trigger], "phx-mounted") |> hd() =~ "data-popup-open"
    assert Floki.attribute([trigger], "data-size") == ["icon-xs"]
    assert Floki.attribute([trigger], "data-placeholder") == [""]
    assert Floki.attribute([trigger], "tabindex") == ["0"]
    assert Floki.attribute([trigger], "aria-haspopup") == ["listbox"]

    assert Floki.attribute([trigger], "class") == [
             "cn-combobox-trigger cn-button group/button shrink-0 justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-default cn-input-group-button flex items-center shadow-none cn-input-group-button-size-icon-xs group-has-data-[slot=combobox-clear]/input-group:hidden data-pressed:bg-transparent"
           ]

    assert Floki.attribute([trigger], "class") |> hd() =~ "cn-combobox-trigger"

    [addon] = Floki.find(document, "[data-slot='input-group-addon']")
    assert Floki.attribute([addon], "phx-mounted") |> hd() =~ "aria-hidden"
  end

  test "content carries floating offsets and an RTL direction without wrapper parts" do
    html =
      render_component(&Combobox.combobox_content/1, %{
        combobox_id: "timezone",
        anchor: "timezone-chips",
        align_offset: -28,
        class: "w-60",
        rest: %{dir: "rtl", "data-lang": "ar"}
      })

    document = Floki.parse_fragment!(html)
    [positioner] = Floki.find(document, "#timezone-positioner")
    assert Floki.attribute([positioner], "data-lb-anchor") == ["timezone-chips"]
    assert Floki.attribute([positioner], "data-lb-align-offset") == ["-28"]

    [content] = Floki.find(document, "#base-ui-_r_0_-popup")
    assert Floki.attribute([content], "dir") == ["rtl"]
    assert Floki.attribute([content], "data-lang") == ["ar"]

    assert Floki.attribute([content], "class") == [
             "cn-combobox-content cn-combobox-content-logical cn-menu-target cn-menu-translucent group/combobox-content relative max-h-(--available-height) max-w-(--available-width) min-w-[calc(var(--anchor-width)+--spacing(7))] origin-(--transform-origin) data-[chips=true]:min-w-(--anchor-width) w-60"
           ]

    assert Floki.attribute([content], "role") == ["presentation"]
  end

  test "the empty message is a persistent polite live region" do
    html =
      render_component(&Combobox.combobox_empty/1, %{
        inner_block: [slot(:inner_block, "No items found.")]
      })

    [empty] = Floki.find(Floki.parse_fragment!(html), "[data-slot='combobox-empty']")
    assert Floki.attribute([empty], "role") == ["status"]
    assert Floki.attribute([empty], "aria-live") == ["polite"]
    assert Floki.attribute([empty], "aria-atomic") == ["true"]
  end

  test "the value part renders direct trigger text before the trigger icon" do
    document = render_component(&popup_value_example/1, %{}) |> Floki.parse_fragment!()
    [trigger] = Floki.find(document, "[data-slot='combobox-trigger']")

    children =
      trigger
      |> elem(2)
      |> Enum.reject(&(is_binary(&1) and String.trim(&1) == ""))

    assert children |> Enum.at(0) |> String.trim() == "Select country"
    assert children |> Enum.at(1) |> Floki.find("svg") != []
  end

  test "groups, custom labels, chips, and chips input expose the public state targets" do
    group =
      render_component(&Combobox.combobox_group/1, %{
        combobox_id: "timezones",
        label: "Americas",
        inner_block: [slot(:inner_block, "items")]
      })

    group_document = Floki.parse_fragment!(group)
    [group_element] = Floki.find(group_document, "[data-slot='combobox-group']")

    assert Floki.attribute([group_element], "aria-labelledby") == [
             "timezones-group-Americas-label"
           ]

    assert Floki.find(group_document, "[data-slot='combobox-label']") != []

    item =
      render_component(&Combobox.combobox_item/1, %{
        combobox_id: "countries",
        value: "argentina",
        label: "Argentina",
        inner_block: [slot(:inner_block, "Argentina South America")]
      })

    [item_element] = Floki.find(Floki.parse_fragment!(item), "[data-slot='combobox-item']")
    assert Floki.attribute([item_element], "data-combobox-label") == ["Argentina"]

    selected_item =
      render_component(&Combobox.combobox_item/1, %{
        combobox_id: "countries",
        value: "argentina",
        selected: true,
        inner_block: [slot(:inner_block, "Argentina")]
      })

    [indicator] =
      Floki.find(Floki.parse_fragment!(selected_item), ".cn-combobox-item-indicator")

    assert Floki.attribute([indicator], "aria-hidden") == ["true"]

    chips_input =
      render_component(&Combobox.combobox_chips_input/1, %{
        combobox_id: "categories",
        placeholder: "Add categories"
      })

    [chips_input_element] =
      Floki.find(Floki.parse_fragment!(chips_input), "input[role='combobox']")

    assert Floki.attribute([chips_input_element], "data-slot") == ["combobox-chip-input"]
    assert Floki.attribute([chips_input_element], "aria-controls") == []

    list =
      render_component(&Combobox.combobox_list/1, %{
        combobox_id: "categories",
        inner_block: [slot(:inner_block, "items")]
      })

    [list_element] = Floki.find(Floki.parse_fragment!(list), "[data-slot='combobox-list']")
    assert Floki.attribute([list_element], "aria-orientation") == ["vertical"]

    separator = render_component(&Combobox.combobox_separator/1, %{})

    [separator_element] =
      Floki.find(Floki.parse_fragment!(separator), "[data-slot='combobox-separator']")

    assert Floki.attribute([separator_element], "role") == ["presentation"]

    multiple_list =
      render_component(&Combobox.combobox_list/1, %{
        combobox_id: "categories",
        multiple: true,
        inner_block: [slot(:inner_block, "items")]
      })

    [multiple_list_element] =
      Floki.find(Floki.parse_fragment!(multiple_list), "[data-slot='combobox-list']")

    assert Floki.attribute([multiple_list_element], "aria-multiselectable") == ["true"]

    chip =
      render_component(&Combobox.combobox_chip/1, %{
        value: "Technology",
        inner_block: [slot(:inner_block, "Technology")]
      })

    [remove] = Floki.find(Floki.parse_fragment!(chip), "[data-slot='combobox-chip-remove']")
    assert Floki.attribute([remove], "aria-disabled") == ["false"]

    collection_document =
      render_component(&group_collection_example/1, %{})
      |> Floki.parse_fragment!()

    [collection_group] = Floki.find(collection_document, "[data-slot='combobox-group']")

    assert collection_group
           |> elem(2)
           |> Enum.filter(&is_tuple/1)
           |> Enum.map(&(Floki.attribute([&1], "data-slot") |> List.first())) == [
             "combobox-label",
             "combobox-item",
             "combobox-item"
           ]

    assert collection_group
           |> Floki.find("[data-slot='combobox-item']")
           |> Enum.map(&Floki.text/1)
           |> Enum.map(&String.trim/1) == ["New York", "London"]
  end

  defp group_collection_example(assigns) do
    ~H"""
    <Combobox.combobox_group combobox_id="timezones" label="Timezones">
      <Combobox.combobox_collection>
        <Combobox.combobox_item combobox_id="timezones" value="new-york">New York</Combobox.combobox_item>
        <Combobox.combobox_item combobox_id="timezones" value="london">London</Combobox.combobox_item>
      </Combobox.combobox_collection>
    </Combobox.combobox_group>
    """
  end

  test "the context binds a chips anchor and a portal sibling to one controller" do
    html = render_component(&chips_context_example/1, %{})
    document = Floki.parse_fragment!(html)

    assert Floki.find(document, "[data-slot='combobox']") == []

    [chips] = Floki.find(document, "#categories-chips")
    assert Floki.attribute([chips], "phx-hook") == ["LiveBase.Combobox"]
    assert Floki.attribute([chips], "data-combobox-controller") == ["categories"]
    assert Floki.attribute([chips], "data-combobox-multiple") == [""]
    assert Floki.attribute([chips], "role") == ["toolbar"]

    [chips_input] = Floki.find([chips], "[data-slot='combobox-chip-input']")
    assert Floki.attribute([chips_input], "role") == ["combobox"]
    assert Floki.attribute([chips_input], "aria-haspopup") == ["listbox"]

    [positioner] = Floki.find(document, "#categories-positioner")
    assert Floki.attribute([positioner], "data-combobox-controller") == ["categories"]
    assert Floki.find([chips], "#categories-positioner") == []
  end

  test "a popup trigger uses the pinned Base UI controller identities and relationships" do
    html = render_component(&popup_context_example/1, %{})
    document = Floki.parse_fragment!(html)

    [trigger] = Floki.find(document, "#base-ui-_r_0_")
    assert Floki.attribute([trigger], "phx-hook") == ["LiveBase.Combobox"]
    assert Floki.attribute([trigger], "data-combobox-controller") == ["country"]
    assert Floki.attribute([trigger], "data-combobox-has-value") == [""]
    assert Floki.attribute([trigger], "role") == ["combobox"]
    assert Floki.attribute([trigger], "aria-haspopup") == ["dialog"]
    assert Floki.text(trigger) =~ "Select country"

    [popup_input] = Floki.find(document, "#base-ui-_r_4_")
    assert Floki.attribute([popup_input], "phx-hook") == []
    assert Floki.attribute([popup_input], "data-combobox-controller") == ["country"]

    [content] = Floki.find(document, "#base-ui-_r_0_-popup")
    assert Floki.attribute([content], "role") == ["dialog"]

    [list] = Floki.find(document, "#_r_1_")
    assert Floki.attribute([list], "role") == ["listbox"]

    [positioner] = Floki.find(document, "#country-positioner")
    assert Floki.attribute([positioner], "data-combobox-controller") == ["country"]
    assert Floki.find([trigger], "#country-positioner") == []
  end

  defp chips_context_example(assigns) do
    ~H"""
    <Combobox.combobox id="categories" multiple default_value={["technology"]} :let={combobox}>
      <Combobox.combobox_chips id="categories-chips" combobox={combobox}>
        <Combobox.combobox_chips_input combobox_id="categories" combobox={combobox} />
      </Combobox.combobox_chips>
      <Combobox.combobox_content combobox_id="categories" combobox={combobox} anchor="categories-chips">
        <Combobox.combobox_list combobox_id="categories" />
      </Combobox.combobox_content>
    </Combobox.combobox>
    """
  end

  defp popup_context_example(assigns) do
    ~H"""
    <Combobox.combobox id="country" default_value="" :let={combobox}>
      <Combobox.combobox_trigger combobox_id="country" combobox={combobox}>
        <Combobox.combobox_value>Select country</Combobox.combobox_value>
      </Combobox.combobox_trigger>
      <Combobox.combobox_content combobox_id="country" combobox={combobox} anchor="country-trigger" input_in_popup>
        <Combobox.combobox_input combobox_id="country" combobox={combobox} controller={false} show_trigger={false} />
        <Combobox.combobox_list combobox_id="country" />
      </Combobox.combobox_content>
    </Combobox.combobox>
    """
  end

  defp popup_value_example(assigns) do
    ~H"""
    <Combobox.combobox id="country" default_value="" :let={combobox}>
      <Combobox.combobox_trigger combobox_id="country" combobox={combobox}>
        <Combobox.combobox_value>Select country</Combobox.combobox_value>
      </Combobox.combobox_trigger>
    </Combobox.combobox>
    """
  end

  defp slot(name, value) when is_binary(value) do
    %{__slot__: name, inner_block: fn _, _ -> value end}
  end

  defp slot(name, attrs) when is_list(attrs) do
    attrs |> Map.new() |> Map.put(:__slot__, name)
  end
end
