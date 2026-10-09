defmodule StorybookWeb.ExamplesTest do
  use StorybookWeb.ConnCase, async: true

  alias StorybookWeb.Examples

  describe "every example" do
    test "renders on a page of its own", %{conn: conn} do
      for component <- Examples.components(), example <- Examples.all(component) do
        {:ok, _view, html} = live(conn, "/preview/#{component}/#{example.id}")

        assert html =~ ~s(data-preview="#{component}")
      end
    end

    test "component documentation is reachable from the index", %{conn: conn} do
      {:ok, _view, index} = live(conn, "/")

      for component <- Examples.components() do
        assert index =~ "/docs/#{component}"
      end
    end
  end

  describe "Message Scroller pre-LiveSocket opening" do
    test "pre-scrolls a held end opening before the hook mounts" do
      root_layout =
        Path.expand("../../lib/storybook_web/layouts/root.html.heex", __DIR__)
        |> File.read!()

      assert root_layout =~
               "[data-lb-message-scroller][data-lb-message-default-position=end][data-pending-scroll]"

      assert root_layout =~ "viewport.scrollTop = viewport.scrollHeight;"
      assert root_layout =~ "viewport.__liveBaseMessageOpeningTop = viewport.scrollTop;"
      assert root_layout =~ "viewport.__liveBaseMessageOpeningApplied = true;"
      assert root_layout =~ "root.removeAttribute(\"data-pending-scroll\");"
      assert root_layout =~ "viewport.removeAttribute(\"data-pending-scroll\");"
    end

    test "leaves unheld end openings for the Message Scroller hook", %{
      conn: conn
    } do
      root_layout =
        Path.expand("../../lib/storybook_web/layouts/root.html.heex", __DIR__)
        |> File.read!()

      assert root_layout =~ "const shouldPreScrollOpening = (root) =>"
      assert root_layout =~ ~s|data-lb-message-pre-live-scroll") !== "false"|
      assert root_layout =~ ~s|data-lb-message-opening-hold") !== "false"|
      assert root_layout =~ "if (!shouldPreScrollOpening(root)) continue;"

      {:ok, _view, history_html} = live(conn, "/preview/message-scroller/load-history")
      history_document = Floki.parse_fragment!(history_html)
      [history_root] = Floki.find(history_document, "[data-lb-message-scroller]")
      assert Floki.attribute([history_root], "data-lb-message-pre-live-scroll") == []
      assert Floki.attribute([history_root], "data-pending-scroll") == [""]

      {:ok, _view, opening_html} = live(conn, "/preview/message-scroller/opening-position")
      opening_document = Floki.parse_fragment!(opening_html)
      [opening_root] = Floki.find(opening_document, "[data-lb-message-scroller]")

      assert Floki.attribute([opening_root], "data-lb-message-pre-live-scroll") == []
      assert Floki.attribute([opening_root], "data-pending-scroll") == [""]
    end
  end

  describe "Base Date Picker official examples" do
    test "accepts an explicit reference date for deterministic snapshots" do
      first = Examples.page_assigns(reference_date: ~D[2025-06-01])
      second = Examples.page_assigns(reference_date: ~D[2030-09-03])

      assert first.date_picker_reference_date == ~D[2025-06-01]
      assert first.date_picker["range"] == %{from: ~D[2025-01-20], to: ~D[2025-02-09]}
      assert first.date_picker["natural-language"] == ~D[2025-06-03]

      assert second.date_picker_reference_date == ~D[2030-09-03]
      assert second.date_picker["range"] == %{from: ~D[2030-01-20], to: ~D[2030-02-09]}
      assert second.date_picker["natural-language"] == ~D[2030-09-05]
    end

    test "renders all eight sources and keeps their server-owned selection state", %{conn: conn} do
      assert Examples.all("date-picker") |> Enum.map(& &1.id) ==
               ~w(default basic range dob input time natural-language rtl)

      {:ok, view, html} = live(conn, "/preview/date-picker/default")
      assert html =~ "Pick a date"
      assert html =~ "date-picker-demo-calendar"

      document = Floki.parse_fragment!(html)
      [default_trigger] = Floki.find(document, "#date-picker-demo-trigger")

      assert Floki.find(document, "#date-picker-demo") == []
      assert Floki.attribute([default_trigger], "data-empty") == ["true"]

      {:ok, _basic_view, basic_html} = live(conn, "/preview/date-picker/basic")
      basic_document = Floki.parse_fragment!(basic_html)

      assert Floki.find(basic_document, "#date-picker-basic") == []
      assert Floki.find(basic_document, "#date-picker-basic-trigger") != []

      {:ok, _range_view, range_html} = live(conn, "/preview/date-picker/range")
      range_document = Floki.parse_fragment!(range_html)

      assert Floki.find(range_document, "#date-picker-range") == []
      assert Floki.find(range_document, "#date-picker-range-trigger") != []

      {:ok, _time_view, time_html} = live(conn, "/preview/date-picker/time")
      time_document = Floki.parse_fragment!(time_html)

      assert Floki.find(time_document, "#date-picker-time") == []
      assert Floki.find(time_document, "button#date-picker-time-trigger") != []

      html = render_hook(view, "date_picker_default_select", %{"selected" => "2025-06-01"})
      assert html =~ "June 1st, 2025"

      [selected_default_trigger] =
        Floki.find(Floki.parse_fragment!(html), "#date-picker-demo-trigger")

      assert Floki.attribute([selected_default_trigger], "data-empty") == ["false"]

      {:ok, input_view, input_html} = live(conn, "/preview/date-picker/input")
      assert input_html =~ "June 01, 2025"

      [input] = Floki.find(Floki.parse_fragment!(input_html), "#date-required")
      assert Floki.attribute([input], "phx-key") == ["ArrowDown"]
      assert Floki.attribute([input], "phx-hook") == ["DatePickerInput"]
      assert Floki.attribute([input], "data-date-picker-selection") == ["0"]
      assert Floki.attribute([input], "data-date-picker-value") == ["June 01, 2025"]
      assert Floki.attribute([input], "data-date-picker-focus-target") == ["date-required"]
      assert Floki.attribute([input], "phx-change") == []
      assert Floki.attribute([input], "phx-value-example") == []

      [input_form] = Floki.find(Floki.parse_fragment!(input_html), "#date-picker-input-form")
      assert Floki.attribute([input_form], "class") == ["contents"]
      assert Floki.attribute([input_form], "phx-change") == ["date_picker_input"]
      assert Floki.attribute([input_form], "phx-value-example") == ["input"]

      assert [input_command] = Floki.attribute([input], "phx-keydown")
      assert input_command =~ "date-picker-input-trigger"
      refute input_command =~ "focus"

      assert Floki.find(Floki.parse_fragment!(input_html), "#date-picker-input") == []

      [input_trigger] =
        Floki.find(Floki.parse_fragment!(input_html), "button#date-picker-input-trigger")

      assert Floki.attribute([input_trigger], "data-size") == ["icon-xs"]
      assert Floki.attribute([input_trigger], "aria-haspopup") == ["dialog"]
      assert Floki.attribute([input_trigger], "aria-expanded") == ["false"]
      assert Floki.attribute([input_trigger], "aria-controls") == ["date-picker-input-popup"]

      assert Floki.attribute([input_trigger], "class") |> hd() =~
               "cn-input-group-button-size-icon-xs"

      assert Floki.attribute(
               Floki.parse_fragment!(input_html),
               "#date-picker-input-positioner",
               "data-lb-return-focus-to-trigger"
             ) == [""]

      assert Floki.attribute(
               Floki.parse_fragment!(input_html),
               "#date-picker-input-calendar",
               "data-lb-calendar-return-focus"
             ) == ["date-required"]

      assert render_hook(input_view, "date_picker_input", %{
               "example" => "input",
               "value" => "June 02, 2025"
             }) =~ "June 02, 2025"

      selected_input_html =
        render_hook(input_view, "date_picker_input_select", %{"selected" => "2025-06-02"})

      [selected_input] = Floki.find(Floki.parse_fragment!(selected_input_html), "#date-required")
      assert Floki.attribute([selected_input], "value") == ["June 02, 2025"]
      assert Floki.attribute([selected_input], "data-date-picker-selection") == ["1"]
      assert Floki.attribute([selected_input], "data-date-picker-value") == ["June 02, 2025"]

      {:ok, _natural_language_view, natural_language_html} =
        live(conn, "/preview/date-picker/natural-language")

      [natural_language] =
        Floki.find(Floki.parse_fragment!(natural_language_html), "#date-optional")

      assert Floki.attribute([natural_language], "phx-key") == ["ArrowDown"]
      assert Floki.attribute([natural_language], "phx-hook") == ["DatePickerInput"]
      assert Floki.attribute([natural_language], "data-date-picker-selection") == ["0"]
      assert Floki.attribute([natural_language], "data-date-picker-value") == ["In 2 days"]

      assert Floki.attribute([natural_language], "data-date-picker-focus-target") == [
               "date-optional"
             ]

      assert Floki.attribute([natural_language], "phx-change") == []
      assert Floki.attribute([natural_language], "phx-value-example") == []

      [natural_language_form] =
        Floki.find(
          Floki.parse_fragment!(natural_language_html),
          "#date-picker-natural-language-form"
        )

      assert Floki.attribute([natural_language_form], "class") == ["contents"]
      assert Floki.attribute([natural_language_form], "phx-change") == ["date_picker_input"]
      assert Floki.attribute([natural_language_form], "phx-value-example") == ["natural-language"]

      assert [natural_language_command] = Floki.attribute([natural_language], "phx-keydown")
      assert natural_language_command =~ "date-picker-natural-language-trigger"
      refute natural_language_command =~ "focus"

      assert Floki.find(
               Floki.parse_fragment!(natural_language_html),
               "#date-picker-natural-language"
             ) == []

      [natural_language_trigger] =
        Floki.find(
          Floki.parse_fragment!(natural_language_html),
          "button#date-picker-natural-language-trigger"
        )

      assert Floki.attribute([natural_language_trigger], "data-size") == ["icon-xs"]
      assert Floki.attribute([natural_language_trigger], "aria-haspopup") == ["dialog"]

      assert Floki.attribute(
               Floki.parse_fragment!(natural_language_html),
               "#date-picker-natural-language-positioner",
               "data-lb-return-focus-to-trigger"
             ) == [""]

      assert Floki.attribute(
               Floki.parse_fragment!(natural_language_html),
               "#date-picker-natural-language-calendar",
               "data-lb-calendar-return-focus"
             ) == ["date-optional"]

      {:ok, range_view, _html} = live(conn, "/preview/date-picker/range")

      assert render_hook(range_view, "date_picker_range_select", %{
               "selected" => "2025-06-01/2025-06-05"
             }) =~ "Jun 01, 2025 - Jun 05, 2025"
    end

    test "updates every calendar, typed input, and native time control" do
      initial = Examples.page_assigns()

      for example <- ~w(default basic dob input time natural-language rtl) do
        updated = Examples.date_picker_select(initial.date_picker, example, "2025-06-01")
        assert updated[example] == ~D[2025-06-01]
      end

      range = Examples.date_picker_select(initial.date_picker, "range", "2025-06-01/2025-06-05")
      assert range["range"] == %{from: ~D[2025-06-01], to: ~D[2025-06-05]}

      {input_dates, input_values} =
        Examples.date_picker_input_change(
          initial.date_picker,
          initial.date_picker_values,
          "input",
          "not a date"
        )

      assert input_dates["input"] == ~D[2025-06-01]
      assert input_values["input"] == "not a date"

      selected_input = Examples.date_picker_select(initial.date_picker, "input", "2025-06-02")

      assert Examples.date_picker_selection_values(
               initial.date_picker_values,
               selected_input,
               "input"
             )["input"] == "June 02, 2025"

      assert Examples.date_picker_selection_versions(
               initial.date_picker_selection_versions,
               "input"
             ) == %{
               "input" => 1,
               "natural-language" => 0
             }

      {natural_dates, natural_values} =
        Examples.date_picker_input_change(
          initial.date_picker,
          initial.date_picker_values,
          "natural-language",
          "next monday"
        )

      assert Date.day_of_week(natural_dates["natural-language"]) == 1
      assert natural_values["natural-language"] == "next monday"
    end

    test "renders the RTL direction on the trigger, popup, and calendar", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/date-picker/rtl")
      document = Floki.parse_fragment!(html)

      assert Floki.find(document, "#date-picker-rtl") == []
      assert Floki.attribute(document, "#date-picker-rtl-trigger", "dir") == ["rtl"]
      assert Floki.attribute(document, "#date-picker-rtl-trigger", "data-empty") == ["true"]
      assert Floki.attribute(document, "#date-picker-rtl-popup", "dir") == ["rtl"]
      assert Floki.attribute(document, "#date-picker-rtl-calendar", "dir") == ["rtl"]

      assert render_hook(view, "date_picker_rtl_select", %{"selected" => "2026-09-09"}) =~
               "سبتمبر 9, 2026"
    end
  end

  describe "Calendar snapshot date" do
    test "accepts an explicit reference date for deterministic snapshots" do
      first = Examples.page_assigns(reference_date: ~D[2025-06-01])
      second = Examples.page_assigns(reference_date: ~D[2030-09-03])

      assert first.calendar_reference_date == ~D[2025-06-01]
      assert first.calendar_presets_date == ~D[2025-02-12]
      assert first.calendar_presets_month == ~D[2025-06-01]

      assert second.calendar_reference_date == ~D[2030-09-03]
      assert second.calendar_presets_date == ~D[2030-02-12]
      assert second.calendar_presets_month == ~D[2030-09-01]
    end
  end

  describe "Base Data Table official examples" do
    test "keeps both pinned examples and applies filter, sort, selection, and column state" do
      assert Examples.all("data-table") |> Enum.map(& &1.id) == ~w(default rtl)

      state = Examples.page_assigns().data_table

      filtered = Examples.data_table_event(state, "filter", %{"filter" => "carmella"})

      assert Examples.data_table_payments(filtered) |> Enum.map(& &1.email) == [
               "carmella@example.com"
             ]

      selected = Examples.data_table_event(state, "toggle-row", %{"id" => "m5gr84i9"})
      assert selected.selected == ["m5gr84i9"]

      sorted = Examples.data_table_event(state, "sort", %{})

      assert Examples.data_table_payments(sorted) |> hd() |> Map.fetch!(:email) ==
               "Abe45@example.com"

      hidden = Examples.data_table_event(state, "toggle-column", %{"column" => "amount"})
      refute "amount" in hidden.visible
    end

    test "renders the official Data Table tree and Arabic copy", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/data-table/default")
      assert html =~ "Filter emails..."
      assert html =~ "ken99@example.com"

      document = Floki.parse_fragment!(html)
      assert Floki.find(document, "#data-table form") == []
      assert Floki.find(document, "#data-table tbody td > div.capitalize") |> length() == 5
      assert Floki.find(document, "#data-table tbody td > div.lowercase") |> length() == 5

      assert Floki.find(document, "#data-table tbody td > div.text-right.font-medium") |> length() ==
               5

      {:ok, _view, rtl_html} = live(conn, "/preview/data-table/rtl")
      assert rtl_html =~ "تصفية البريد الإلكتروني"

      rtl_document = Floki.parse_fragment!(rtl_html)
      assert Floki.find(rtl_document, "#data-table-rtl form") == []
      assert Floki.attribute(rtl_document, "#data-table-rtl", "dir") == []
      assert Floki.attribute(rtl_document, "#data-table-rtl-columns-popup", "data-lang") == ["ar"]

      assert Floki.find(rtl_document, "#data-table-rtl tbody td > div.text-start.font-medium")
             |> length() == 5
    end
  end

  describe "Base Typography official examples" do
    test "renders all fifteen pinned sources", %{conn: conn} do
      assert Examples.all("typography") |> Enum.map(& &1.id) ==
               ~w(default h1 h2 h3 h4 p blockquote table list inline-code lead large small muted rtl)

      for example <- Examples.all("typography") do
        {:ok, _view, html} = live(conn, "/preview/typography/#{example.id}")
        assert html =~ ~s(data-preview="typography")
      end

      {:ok, _view, demo} = live(conn, "/preview/typography/default")
      assert demo =~ "Taxing Laughter: The Joke Tax Chronicles"
      assert demo =~ "The People&#39;s Rebellion"

      {:ok, _view, rtl} = live(conn, "/preview/typography/rtl")
      assert rtl =~ ~s(dir="rtl")
      assert rtl =~ "فرض الضرائب على الضحك"
    end
  end

  describe "attachment examples" do
    test "the generated API documents the scoped variant context" do
      attachments =
        StorybookWeb.Docs.api("attachments")
        |> Enum.find(&(to_string(&1.name) == "attachments"))

      [inner_block] = Enum.filter(attachments.slots, &(to_string(&1.name) == "inner_block"))

      assert inner_block.doc =~ ":let={attachments}"
      assert inner_block.doc =~ "%{variant: variant}"
    end

    test "inline attachments render entries with omitted optional fields", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/attachments/inline")

      # The pinned data has entries without :title, :filename, or :url.
      assert html =~ "mountain-landscape.jpg"
      assert html =~ "quarterly-report.pdf"
      assert html =~ "React Documentation"
      assert html =~ "podcast-episode.mp3"
    end

    test "removing an attachment changes only its official example" do
      attachments = Examples.page_assigns().attachment_examples
      updated = Examples.remove_attachment(attachments, "list", "mountain-landscape")

      assert 4 = Enum.count_until(updated["list"], 5)
      assert 4 = Enum.count_until(updated["default"], 5)
      assert 4 = Enum.count_until(updated["inline"], 5)
      refute Enum.any?(updated["list"], &(&1.id == "mountain-landscape"))
    end

    test "an inline remove sends its caller action once", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/attachments/inline")

      assert html =~ ~s(data-attachment-remove-count="0")

      html =
        view
        |> element("button[phx-click*='mountain-landscape']")
        |> render_click()

      assert html =~ ~s(data-attachment-remove-count="1")
      refute html =~ "mountain-landscape.jpg"
    end
  end

  describe "Sidebar official example" do
    test "changes the active team and renders the official avatar with its fallback", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/preview/sidebar/default")

      assert html =~ ~s(src="/avatars/shadcn.jpg")
      assert html =~ ~s(alt="shadcn")
      assert html =~ "CN"

      document = Floki.parse_fragment!(html)

      for trigger <- ["#sidebar-team-trigger", "#sidebar-user-trigger"] do
        assert Floki.attribute(document, trigger, "aria-controls") == []
      end

      image_conn = get(build_conn(), "/avatars/shadcn.jpg")
      assert response(image_conn, 200)
      assert {"content-type", "image/jpeg"} in image_conn.resp_headers

      assert html =~ "sidebar_team_select"
      render_hook(view, "sidebar_team_select", %{"team" => "acme-corp"})

      trigger = view |> element("#sidebar-team-trigger") |> render()
      assert trigger =~ "Acme Corp."
      assert trigger =~ "Startup"
    end

    test "does not accept an unknown active team", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/preview/sidebar/default")

      render_hook(view, "sidebar_team_select", %{"team" => "unknown"})

      trigger = view |> element("#sidebar-team-trigger") |> render()
      assert trigger =~ "Acme Inc"
      assert trigger =~ "Enterprise"
    end
  end

  describe "Chart interactive official example" do
    test "renders every official day and changes the active series", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/chart/demo")

      assert html =~ ~s(data-chart-demo-series="desktop")
      assert html =~ "Bar Chart - Interactive"
      assert html =~ "Showing total visitors for the last 3 months"
      assert html =~ "7,324"
      assert html =~ "7,250"

      document = Floki.parse_fragment!(html)
      assert 30 = document |> Floki.find("#chart-demo [data-chart-date]") |> Enum.count_until(31)

      html = view |> element("#chart-demo-mobile") |> render_click()
      document = Floki.parse_fragment!(html)

      assert html =~ ~s(data-chart-demo-series="mobile")
      [mobile] = Floki.find(document, "#chart-demo-mobile")
      [desktop] = Floki.find(document, "#chart-demo-desktop")
      assert Floki.attribute([mobile], "data-active") == ["true"]
      assert Floki.attribute([desktop], "data-active") == ["false"]

      assert Floki.attribute(
               Floki.find(document, "#chart-demo [data-chart-date]"),
               "data-chart-series"
             )
             |> Enum.uniq() == ["mobile"]
    end
  end

  describe "Message Scroller streaming example" do
    test "starts empty, submits the queued user message, and completes its reply" do
      state = Examples.page_assigns().message_scroller

      assert state.streaming == []
      refute state.streaming_busy

      submitted = Examples.message_scroller_event(state, "send", "streaming")
      assert submitted.streaming == [1]
      assert submitted.streaming_busy

      completed = Examples.message_scroller_event(submitted, "stream-reply", "streaming")
      assert completed.streaming == [1, 2]
      refute completed.streaming_busy
    end
  end

  describe "Message Scroller default example" do
    test "submits one queued user message, completes one assistant reply, and resets" do
      initial = Examples.page_assigns().message_scroller
      assert initial.default == []
      refute initial.default_busy

      submitted = Examples.message_scroller_event(initial, "send", "default")
      assert submitted.default == [1]
      assert submitted.default_busy
      assert Examples.message_scroller_event(submitted, "send", "default") == submitted

      completed = Examples.message_scroller_event(submitted, "default-reply", "default")
      assert completed.default == [1, 2]
      refute completed.default_busy

      reset = Examples.message_scroller_event(completed, "reset", "default")
      assert reset.default == []
      refute reset.default_busy
    end

    test "renders the official composer, menu, and busy reset state", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/message-scroller/default")

      assert html =~ ~s(id="message-scroller-default-form")
      assert html =~ "Add Photos &amp; Files"
      assert html =~ "Create Image"
      assert html =~ "Deep Research"
      assert html =~ "Web Search"

      document = Floki.parse_fragment!(html)
      [reset] = Floki.find(document, "button[aria-label='Reset conversation']")
      hover = Floki.attribute([reset], "data-lb-hover-command") |> hd()
      escape = Floki.attribute([reset], "phx-window-keydown") |> hd()
      refute hover =~ "aria-expanded"
      refute escape =~ "aria-expanded"

      [add_files] = Floki.find(document, "button[aria-label='Add files']")

      [add_files_positioner] =
        Floki.find(document, "#message-scroller-default-add-files-positioner")

      refute Floki.attribute([add_files], "aria-controls") != []
      assert Floki.attribute([add_files], "phx-click") |> hd() =~ "aria-controls"

      assert Floki.attribute([add_files_positioner], "phx-window-keydown") |> hd() =~
               "aria-controls"

      assert Floki.attribute([add_files_positioner], "data-lb-no-return-focus") == []

      html = view |> element("#message-scroller-default-form") |> render_submit()
      assert html =~ ~s(data-message-id="msg-1")
      assert html =~ ~s(aria-busy="true")
      document = Floki.parse_fragment!(html)
      [reset] = Floki.find(document, "button[aria-label='Reset conversation']")
      assert Floki.attribute([reset], "disabled") == [""]

      send(view.pid, :message_scroller_default_reply)
      html = render(view)
      assert html =~ ~s(data-message-id="msg-2")
      assert html =~ ~s(aria-busy="false")
    end
  end

  describe "Message Scroller anchoring example" do
    test "keeps the selected role server-controlled and without a native value", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/message-scroller/anchoring")
      document = Floki.parse_fragment!(html)

      [assistant] = Floki.find(document, "#message-scroller-anchor-role-assistant")
      click = Floki.attribute([assistant], "phx-click") |> hd()

      assert click =~ "message_scroller_anchor_role"
      refute click =~ "live-base:toggle-group"
      assert Floki.attribute([assistant], "value") == [""]
    end
  end

  describe "Message Scroller transient composer menus" do
    test "does not retain Add files controls and restores trigger focus after close", %{
      conn: conn
    } do
      for example <- ~w(previous-context streaming) do
        {:ok, _view, html} = live(conn, "/preview/message-scroller/#{example}")
        document = Floki.parse_fragment!(html)
        menu_id = "message-scroller-#{example}-add-files"

        assert Floki.attribute(document, "##{menu_id}-trigger", "aria-controls") == []

        assert Floki.attribute(document, "##{menu_id}-trigger", "phx-click") |> hd() =~
                 "aria-controls"

        assert Floki.attribute(document, "##{menu_id}-positioner", "phx-window-keydown") |> hd() =~
                 "aria-controls"

        assert Floki.attribute(document, "##{menu_id}-positioner", "data-lb-no-return-focus") ==
                 []
      end
    end

    test "keeps reset tooltips out of the Add files disclosure order", %{conn: conn} do
      for {example, label} <- [
            {"previous-context", "Reset context example"},
            {"streaming", "Reset stream"}
          ] do
        {:ok, _view, html} = live(conn, "/preview/message-scroller/#{example}")
        document = Floki.parse_fragment!(html)
        [reset] = Floki.find(document, "button[aria-label='#{label}']")

        assert Floki.attribute([reset], "aria-expanded") == []

        for attribute <- ["data-lb-hover-command", "phx-window-keydown"] do
          assert Floki.attribute([reset], attribute)
                 |> Enum.all?(&(not String.contains?(&1, "aria-expanded")))
        end
      end
    end
  end

  describe "Message Scroller Commands example" do
    test "keeps the pinned one-time end opening through later row layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/message-scroller/commands")

      assert html =~ ~s(data-lb-message-default-position="end")
      assert html =~ ~s(data-lb-message-opening-hold="false")
    end

    test "removes Jump to controls and restores normal trigger focus after close", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/message-scroller/commands")
      document = Floki.parse_fragment!(html)
      menu_id = "message-scroller-commands-menu"

      assert Floki.attribute(document, "##{menu_id}-trigger", "aria-controls") == []

      assert Floki.attribute(document, "##{menu_id}-trigger", "phx-click") |> hd() =~
               "aria-controls"

      assert Floki.attribute(document, "##{menu_id}-positioner", "phx-window-keydown") |> hd() =~
               "aria-controls"

      assert Floki.attribute(document, "##{menu_id}-positioner", "data-lb-no-return-focus") == []
    end
  end

  describe "Message Scroller Load History example" do
    test "keeps the last five pinned messages, prepends the earlier five, and resets" do
      initial = Examples.page_assigns().message_scroller
      assert initial.load_history == 5

      loaded = Examples.message_scroller_event(initial, "load-history", "load-history")
      assert loaded.load_history == 10

      reset = Examples.message_scroller_event(loaded, "reset", "load-history")
      assert reset.load_history == 5
      assert initial.load_history_generation == 0
      assert reset.load_history_generation == 1
    end

    test "renders pinned history without anchors and announces the completed load", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/message-scroller/load-history")
      document = Floki.parse_fragment!(html)

      assert Floki.find(document, "[data-message-id='history-1']") == []
      assert Floki.find(document, "[data-message-id='history-6']") != []
      assert Floki.find(document, "#message-scroller-load-history-0") != []
      assert Floki.find(document, "#message-scroller-load-history-viewport-0") != []

      html =
        view
        |> element("button[phx-click='message_scroller_load_history']")
        |> render_click()

      document = Floki.parse_fragment!(html)

      [reset] = Floki.find(document, "button[aria-label='Reset loaded messages']")
      assert Floki.attribute([reset], "data-lb-caller-click") == [""]
      assert Floki.attribute([reset], "phx-click") |> hd() =~ "message_scroller_reset"

      for index <- 1..10 do
        [item] = Floki.find(document, "[data-message-id='history-#{index}']")
        assert Floki.attribute([item], "data-scroll-anchor") == ["false"]
        assert Floki.attribute([item], "data-lb-message-animation") == []
      end

      [toast] = Floki.find(document, "#message-scroller-load-history-toast [data-sonner-toast]")
      assert Floki.attribute([toast], "data-type") == ["default"]

      assert Floki.find([toast], "[data-title]")
             |> Floki.text() == "History loaded"

      assert Floki.find([toast], "[data-description]")
             |> Floki.text()
             |> String.trim() == "Scroll up to see earlier messages."

      html =
        view
        |> element("button[aria-label='Reset loaded messages']")
        |> render_click()

      document = Floki.parse_fragment!(html)
      assert Floki.find(document, "#message-scroller-load-history-1") != []
      assert Floki.find(document, "#message-scroller-load-history-viewport-1") != []
      assert Floki.find(document, "#message-scroller-load-history-0") == []

      [root] = Floki.find(document, "#message-scroller-load-history-1")
      assert Floki.attribute([root], "data-lb-message-opening-generation") == ["1"]
    end

    test "opens Load History at the end, then resets its replacement viewport at the start", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/preview/message-scroller/load-history")
      document = Floki.parse_fragment!(html)

      [initial_root] = Floki.find(document, "#message-scroller-load-history-0")
      [initial_viewport] = Floki.find(document, "#message-scroller-load-history-viewport-0")
      assert Floki.attribute([initial_root], "data-lb-message-default-position") == ["end"]
      assert Floki.attribute([initial_viewport], "data-pending-scroll") == [""]

      view
      |> element("button[phx-click='message_scroller_load_history']")
      |> render_click()

      html =
        view
        |> element("button[aria-label='Reset loaded messages']")
        |> render_click()

      document = Floki.parse_fragment!(html)
      [reset_root] = Floki.find(document, "#message-scroller-load-history-1")
      [reset_viewport] = Floki.find(document, "#message-scroller-load-history-viewport-1")

      assert Floki.attribute([reset_root], "data-lb-message-default-position") == ["start"]
      assert Floki.attribute([reset_viewport], "data-pending-scroll") == []
    end
  end

  describe "Message Scroller Previous Context example" do
    test "keeps the selected peek and streams one assistant reply after each user turn" do
      initial = Examples.page_assigns().message_scroller
      assert Enum.map(initial.previous_context, & &1.id) == ["msg-1", "msg-2"]
      assert initial.previous_context_peek == 64
      refute initial.previous_context_busy

      adjusted = Examples.message_scroller_event(initial, "previous-context-peek", 96)
      assert adjusted.previous_context_peek == 96
      assert Examples.message_scroller_event(adjusted, "previous-context-peek", 129) == adjusted

      submitted = Examples.message_scroller_event(adjusted, "send", "previous-context")
      assert Enum.map(submitted.previous_context, & &1.id) == ["msg-1", "msg-2", "msg-3"]
      assert submitted.previous_context_busy
      assert Examples.message_scroller_event(submitted, "send", "previous-context") == submitted

      completed =
        Examples.message_scroller_event(submitted, "previous-context-reply", "previous-context")

      assert Enum.map(completed.previous_context, & &1.id) == ["msg-1", "msg-2", "msg-3", "msg-4"]
      refute completed.previous_context_busy

      reset = Examples.message_scroller_event(completed, "reset", "previous-context")
      assert Enum.map(reset.previous_context, & &1.id) == ["msg-1", "msg-2"]
      assert reset.previous_context_peek == 64
      refute reset.previous_context_busy
      assert initial.previous_context_generation == 0
      assert reset.previous_context_generation == 1
    end

    test "renders the provider configuration, dynamic peek, menu, and busy flow", %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/message-scroller/previous-context")

      assert html =~ ~s(data-lb-message-scroll-margin="24")
      assert html =~ ~s(data-lb-message-previous-peek="64")
      assert html =~ ~s(id="message-scroller-previous-context")
      assert html =~ ~s(id="message-scroller-previous-context-viewport")
      assert html =~ ~s(data-lb-message-controller="message-scroller-previous-context")
      assert html =~ ~s(data-lb-message-opening-generation="0")
      assert html =~ "Add Photos &amp; Files"
      assert html =~ "Create Image"
      assert html =~ "Deep Research"
      assert html =~ "Web Search"

      document = Floki.parse_fragment!(html)

      assert Floki.find(document, "input[aria-label='Previous context peek']") |> length() == 1
      assert Floki.find(document, "[data-slot='slider-thumb']") |> length() == 1

      html = render_hook(view, "message_scroller_peek", %{"value" => "96"})
      assert html =~ ~s(data-lb-message-previous-peek="96")
      assert html =~ "96px"

      html =
        view
        |> element("#message-scroller-previous-context-form")
        |> render_submit()

      assert html =~ ~s(data-message-id="msg-3")
      assert html =~ ~s(aria-busy="true")
      document = Floki.parse_fragment!(html)
      assert Floki.find(document, "#message-scroller-previous-context-peek-0[disabled]") != []
      [user] = Floki.find(document, "[data-message-id='msg-3']")
      assert Floki.attribute([user], "data-lb-message-animation") == ["slide-up"]

      send(view.pid, :message_scroller_previous_context_reply)
      html = render(view)
      assert html =~ ~s(data-message-id="msg-4")
      assert html =~ ~s(aria-busy="false")

      html =
        view
        |> element("button[aria-label='Reset context example']")
        |> render_click()

      assert html =~ ~s(id="message-scroller-previous-context")
      assert html =~ ~s(id="message-scroller-previous-context-viewport")
      assert html =~ ~s(data-lb-message-controller="message-scroller-previous-context")
      assert html =~ ~s(data-lb-message-opening-generation="1")
    end
  end

  describe "Message Scroller Opening Position example" do
    test "accepts only the three pinned opening positions" do
      initial = Examples.page_assigns().message_scroller

      for position <- ["start", "end", "last-anchor"] do
        assert Examples.message_scroller_event(initial, "opening-position", position).opening_position ==
                 position
      end

      assert Examples.message_scroller_event(initial, "opening-position", "middle") == initial
    end

    test "drives each selected position through the scroller state without row padding", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/preview/message-scroller/opening-position")
      assert html =~ ~s(data-lb-message-default-position="end")
      assert html =~ ~s(data-lb-message-opening-hold="false")
      refute html =~ ~s(data-lb-message-pre-live-scroll="false")
      assert html =~ ~s(data-lb-opening-position-target="message-scroller-opening")

      assert html =~
               ~s(class="cn-tabs-list-variant-default bg-muted cn-tabs-list group/tabs-list inline-flex items-center justify-center text-muted-foreground group-data-vertical/tabs:h-fit group-data-vertical/tabs:flex-col w-full")

      assert html =~
               "Toggle the defaultScrollPosition to see where the transcript starts when you open the thread"

      html = render_hook(view, "message_scroller_opening_position", %{"position" => "start"})
      document = Floki.parse_fragment!(html)
      assert html =~ ~s(data-lb-message-default-position="end")
      assert Floki.find(document, "#message-scroller-opening[data-pending-scroll]") != []

      html = render_hook(view, "message_scroller_opening_position", %{"position" => "end"})
      assert html =~ ~s(data-lb-message-default-position="end")

      document = Floki.parse_fragment!(html)

      for id <- ["open-1", "open-2", "open-3", "open-4"] do
        [item] = Floki.find(document, "[data-message-id='#{id}']")
        refute "py-4" in Floki.attribute([item], "class")
        assert Floki.attribute([item], "data-lb-message-animation") == []
      end
    end
  end

  describe "Message Scroller animation example" do
    @official_animation_presets [
      "fade",
      "slide-up",
      "slide-side",
      "pop",
      "spring-bounce",
      "blur-fade",
      "scale-fade"
    ]

    test "keeps every pinned preset and its exact turn state transitions" do
      initial = Examples.page_assigns().message_scroller
      assert Examples.message_scroller_event(initial, "animation-preset", "unknown") == initial

      for preset <- @official_animation_presets do
        selected = Examples.message_scroller_event(initial, "animation-preset", preset)
        assert selected.animation_preset == preset

        submitted = Examples.message_scroller_event(selected, "send", "animation")
        assert submitted.animation == [1]
        assert submitted.animation_busy
        assert Examples.message_scroller_event(submitted, "send", "animation") == submitted

        completed = Examples.message_scroller_event(submitted, "animation-reply", "animation")
        assert completed.animation == [1, 2]
        refute completed.animation_busy

        assert Examples.message_scroller_event(completed, "animation-reply", "animation") ==
                 completed

        reset = Examples.message_scroller_event(completed, "reset", "animation")
        assert reset.animation == []
        refute reset.animation_busy
      end
    end

    test "renders the selected entrance only on a user message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/preview/message-scroller/animation")

      render_change(view, "message_scroller_animation_preset", %{"preset" => "pop"})

      html =
        view
        |> element(~s(button[phx-click="message_scroller_send"][phx-value-example="animation"]))
        |> render_click()

      [user] = Floki.find(Floki.parse_fragment!(html), "[data-message-id=msg-1]")
      assert Floki.attribute([user], "data-lb-message-animation") == ["pop"]

      send(view.pid, :message_scroller_animation_reply)
      html = render(view)
      [assistant] = Floki.find(Floki.parse_fragment!(html), "[data-message-id=msg-2]")
      assert Floki.attribute([assistant], "data-lb-message-animation") == []
    end
  end

  describe "Question examples" do
    test "each pinned Question preview renders its native accessible controls", %{conn: conn} do
      for {id, selector} <- [
            {"default", ~s([role="group"][aria-label="Project features"])},
            {"freeform", ~s(textarea[aria-label="Project name"])},
            {"multi-select", ~s([role="group"][aria-label="Features"])},
            {"single-select", ~s([role="radiogroup"][aria-label="Framework"])}
          ] do
        {:ok, _view, html} = live(conn, "/preview/question/#{id}")
        document = Floki.parse_fragment!(html)

        assert Floki.find(document, selector) != []
      end
    end

    test "Question previews render the pinned response after the hook event", %{conn: conn} do
      responses = [
        {"default",
         %{"selected_values" => ["authentication", "database"], "text" => "Deploy in Europe"},
         "Answered: authentication, database — Deploy in Europe"},
        {"freeform", %{"selected_values" => [], "text" => "Atlas"}, "Answered: Atlas"},
        {"multi-select", %{"selected_values" => ["Database"], "text" => ""},
         "Selected: Database"},
        {"single-select", %{"selected_values" => ["Nuxt"], "text" => ""}, "Selected: Nuxt"}
      ]

      for {id, params, expected} <- responses do
        {:ok, view, _html} = live(conn, "/preview/question/#{id}")
        html = render_hook(view, "question_submit", params)

        assert html
               |> Floki.parse_fragment!()
               |> Floki.text()
               |> String.replace(~r/\s+/, " ") =~ expected
      end
    end
  end

  describe "Calendar examples" do
    test "the twelve pinned Calendar previews use the official order and public roots", %{
      conn: conn
    } do
      assert Enum.map(Examples.all("calendar"), & &1.id) == [
               "default",
               "hijri",
               "basic",
               "multiple",
               "range",
               "caption",
               "presets",
               "time",
               "booked-dates",
               "custom-days",
               "week-numbers",
               "rtl"
             ]

      for example <- Examples.all("calendar") do
        {:ok, _view, html} = live(conn, "/preview/calendar/#{example.id}")
        document = Floki.parse_fragment!(html)

        assert [_] = Floki.find(document, "#calendar-#{example.id}[phx-hook='LiveBase.Calendar']")
      end
    end

    test "the preset action updates the controlled Calendar in preview and documentation", %{
      conn: conn
    } do
      expected = Date.utc_today() |> Date.add(14) |> Date.to_iso8601()

      {:ok, preview, _html} = live(conn, "/preview/calendar/presets")

      preview_html =
        preview
        |> element("#preview-calendar-presets button[phx-value-days='14']")
        |> render_click()

      assert preview_html =~ ~s(data-lb-calendar-selected="#{expected}")

      {:ok, docs, _html} = live(conn, "/docs/calendar")
      docs_html = render_hook(docs, "calendar_preset", %{"days" => "14"})

      assert docs_html =~ ~s(data-lb-calendar-selected="#{expected}")
    end

    test "Calendar Presets uses its pinned Base Nova class facts", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/preview/calendar/presets")
      document = Floki.parse_fragment!(html)

      day = Floki.find(document, "#calendar-presets td.rdp-day") |> List.first()
      preset = Floki.find(document, "button[phx-value-days='0']") |> List.first()

      assert Floki.attribute(
               Floki.find(document, "#calendar-presets"),
               "data-lb-calendar-day-group-after-select"
             ) == [
               "true"
             ]

      refute String.contains?(List.first(Floki.attribute([day], "class")), "group/day")
      refute "shrink-0" in (Floki.attribute([preset], "class") |> List.first() |> String.split())
    end
  end

  describe "a component's documentation page" do
    test "shows the current verification result for each component", %{conn: conn} do
      for component <- ["badge", "dropdown-menu", "transcription"] do
        {:ok, _view, html} = live(conn, "/docs/#{component}")
        status = StorybookWeb.Docs.status(component)

        assert html =~ ~s(data-component-status="#{status}")
      end
    end

    test "shows AI Elements outside the verification pipeline", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/attachments")

      status = StorybookWeb.Docs.status("attachments")
      assert status == :excluded
      assert html =~ ~s(data-component-status="#{status}")
      assert html =~ "Outside verification"
    end

    test "uses the verification result for Sonner", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/sonner")
      {:ok, _view, index_html} = live(conn, "/")

      status = StorybookWeb.Docs.status("sonner")

      assert status in [:verified, :failed, :stale, :not_verified]
      assert html =~ ~s(data-component-status="#{status}")
      refute html =~ ~s(data-component-status="local_only")
      refute index_html =~ ~s(data-component-status="local_only")
    end

    test "shows the same verification label on the index and component page", %{conn: _conn} do
      for component <- ["button", "data-table", "typography"] do
        status = StorybookWeb.Docs.status(component)
        label = StorybookWeb.Docs.status_label(component)

        {:ok, _view, index_html} = live(build_conn(), "/")
        assert index_html =~ ~s(data-component-status="#{status}")
        assert index_html =~ label

        {:ok, _view, docs_html} = live(build_conn(), "/docs/#{component}")
        assert docs_html =~ ~s(data-component-status="#{status}")
        assert docs_html =~ label
      end
    end

    test "direction is documented with No DOM status on both pages", %{conn: conn} do
      {:ok, _view, index_html} = live(conn, "/")

      row =
        index_html
        |> Floki.parse_fragment!()
        |> Floki.find("li")
        |> Enum.find(fn row ->
          Floki.attribute(Floki.find([row], "a"), "href") == ["/docs/direction"] and
            Floki.find([row], "[data-component-status]") != []
        end)

      assert row
      [index_badge] = Floki.find([row], "[data-component-status]")
      assert Floki.attribute([index_badge], "data-component-status") == ["no_dom"]
      assert String.trim(Floki.text(index_badge)) == "No DOM"

      {:ok, _view, docs_html} = live(conn, "/docs/direction")
      [docs_badge] = Floki.find(Floki.parse_fragment!(docs_html), "[data-component-status]")
      assert Floki.attribute([docs_badge], "data-component-status") == ["no_dom"]
      assert String.trim(Floki.text(docs_badge)) == "No DOM"
      assert docs_html =~ "only provides direction context and renders no DOM"
    end

    test "shows the markup each example is written with", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      # Read out of `examples.ex` rather than typed here, so this checks that
      # the source reached the page and not that somebody kept two copies of it.
      example = hd(Examples.all("badge"))
      source = StorybookWeb.Docs.source(example)

      assert source =~ "<.badge"
      assert html =~ Phoenix.HTML.html_escape(source) |> Phoenix.HTML.safe_to_string()
    end

    test "shows source in Code tabs for locally delegated renderers", %{conn: conn} do
      for {component, id, marker} <- [
            {"message-scroller", "load-history", "<.message_scroller_provider>"},
            {"button-group", "default", "<.button_group>"}
          ] do
        example = Enum.find(Examples.all(component), &(&1.id == id))
        source = StorybookWeb.Docs.source(example)

        assert source =~ marker

        {:ok, _view, html} = live(conn, "/docs/#{component}")
        document = Floki.parse_document!(html)
        [code] = Floki.find(document, "#example-#{id}-panel-code code")

        assert Floki.text(code) =~ marker
      end
    end

    test "shows every attribute the component declares", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      for %{attrs: attrs} <- StorybookWeb.Docs.api("badge"), attr <- attrs do
        assert html =~ to_string(attr.name)
      end
    end

    test "is a 404 for a component nobody documented", %{conn: conn} do
      assert_raise StorybookWeb.DocsLive.NotFound, fn ->
        live(conn, "/docs/nothing-by-that-name")
      end
    end
  end

  describe "an example that does not exist" do
    test "is a 404, not a blank page", %{conn: conn} do
      assert_raise StorybookWeb.PreviewLive.NotFound, fn ->
        live(conn, "/preview/accordion/nothing-by-that-name")
      end
    end
  end

  describe "the navigation" do
    test "puts every documented component in exactly one group" do
      grouped = StorybookWeb.Docs.groups() |> Enum.flat_map(& &1.components)

      assert Enum.sort(grouped) == Enum.sort(StorybookWeb.Docs.components())
      assert Enum.uniq(grouped) == grouped
    end

    test "groups them by the section their own documentation files them under", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/docs/badge")

      # Read from the manifest `mix ui.fetch` writes, not typed here: the
      # sections are upstream's, and a test that named them would be a second
      # copy of the thing being checked.
      #
      # A section may name a component this repository does not build —
      # `canvas` is `unsupported`, see ROADMAP.md — and one that has a page is
      # in its own section.
      for %{"title" => title, "components" => components} <- sections() do
        assert html =~ title

        for name <- components, documented?(name) do
          assert html =~ ~s(/docs/#{name}") or html =~ "-#{name}\""
        end
      end
    end

    defp documented?(name) do
      components = Examples.components()
      name in components or "ai_elements-#{name}" in components
    end

    test "names each package once, on the first group that ships in it" do
      # A group says the package in its title or beside it, and a package that
      # draws components is said once — not on all five of its sections.
      said =
        StorybookWeb.Docs.groups()
        |> Enum.flat_map(&[&1.package, &1.title])
        |> Enum.reject(&is_nil/1)

      for library <- StorybookWeb.Docs.libraries(), library.components != [] do
        assert Enum.count(said, &(&1 == library.package)) == 1
      end
    end

    defp sections do
      "../../../registry/UPSTREAM.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()
      |> get_in(["groups", "ai_elements"])
    end
  end

  describe "the page around the component" do
    test "the Questionnaire shortcut selector updates the controlled root", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/preview/questionnaire/shortcuts")

      html =
        view
        |> element("select[name='shortcut_mode'][form='questionnaire-shortcuts']")
        |> render_change(%{"shortcut_mode" => "numbers"})

      assert html =~ ~s(data-shortcuts="numbers")
    end

    test "gives every Questionnaire hook root a unique stable id", %{conn: conn} do
      ids =
        for example <- Examples.all("questionnaire") do
          {:ok, _view, html} = live(conn, "/preview/questionnaire/#{example.id}")
          document = Floki.parse_fragment!(html)

          [root] =
            Floki.find(document, "[data-slot='questionnaire'][phx-hook='LiveBase.Questionnaire']")

          [id] = Floki.attribute([root], "id")
          assert id == "questionnaire-#{example.id}"
          id
        end

      assert Enum.uniq(ids) == ids
    end

    test "the card keeps its declared choice metadata and reports its official result", %{
      conn: conn
    } do
      {:ok, view, html} = live(conn, "/preview/questionnaire/card")
      document = Floki.parse_fragment!(html)
      [form] = Floki.find(document, "#questionnaire-card")
      [items_json] = Floki.attribute([form], "data-lb-items")

      [task_title | _] =
        Floki.find(document, "#questionnaire-card [data-slot='questionnaire-title']")

      assert Floki.attribute([task_title], "class") == [
               "cn-card-title cn-font-heading cn-questionnaire-title cn-font-heading text-pretty"
             ]

      assert Jason.decode!(items_json) == [
               %{
                 "choices" => [
                   %{"value" => "fix"},
                   %{"value" => "refactor"},
                   %{"value" => "docs"}
                 ],
                 "name" => "task",
                 "required" => true
               },
               %{
                 "choices" => [
                   %{"value" => "summary"},
                   %{"value" => "files"},
                   %{"value" => "review"}
                 ],
                 "name" => "output",
                 "required" => true
               }
             ]

      html =
        view
        |> element("#questionnaire-card")
        |> render_submit(%{"task" => "fix", "output" => "files"})

      assert html =~ "Agent task created"
      assert html =~ "Task: fix · Handoff: files"

      assert Floki.find(Floki.parse_fragment!(html), "[data-preview] #questionnaire-card-toasts") ==
               []
    end

    test "the dialog names itself from the active questionnaire item and reports its official result",
         %{conn: conn} do
      {:ok, view, html} = live(conn, "/preview/questionnaire/dialog")
      document = Floki.parse_fragment!(html)

      assert Floki.find(document, "#questionnaire-dialog-title") == []
      assert Floki.find(document, "#questionnaire-dialog-description") == []

      assert 2 =
               document
               |> Floki.find("#questionnaire-dialog-popup [data-slot='dialog-header']")
               |> Enum.count_until(3)

      assert Floki.find(document, "#questionnaire-dialog [aria-labelledby]") == []

      [scope_title | _] =
        Floki.find(document, "#questionnaire-dialog [data-slot='questionnaire-title']")

      assert Floki.attribute([scope_title], "class") == [
               "cn-dialog-title cn-font-heading cn-questionnaire-title text-pretty"
             ]

      html =
        view
        |> element("#questionnaire-dialog")
        |> render_submit(%{"scope" => "feature", "tests" => "package"})

      assert_push_event(view, "questionnaire:submitted", %{id: "questionnaire-dialog"})
      assert html =~ "Clarification sent"
      assert html =~ "Scope: feature · Verification: package"

      assert Floki.find(
               Floki.parse_fragment!(html),
               "[data-preview] #questionnaire-dialog-toasts"
             ) == []
    end

    test "supplies the heading levels above the component's own", %{conn: conn} do
      # The accordion's headings are `h3`, which Base UI documents. A page that
      # jumps from `h1` to `h3` fails axe-core, and the component is not the
      # place to fix it.
      {:ok, _view, html} = live(conn, "/preview/accordion/default")
      document = Floki.parse_fragment!(html)

      assert [_] = Floki.find(document, "h1")
      assert [_] = Floki.find(document, "h2")
      assert Floki.find(document, "h3") != []
    end
  end

  describe "Combobox examples" do
    test "the twelve pinned Combobox previews use the manifest order and public parts", %{
      conn: conn
    } do
      assert Enum.map(Examples.all("combobox"), & &1.id) == [
               "default",
               "basic",
               "multiple",
               "clear",
               "groups",
               "custom",
               "invalid",
               "disabled",
               "auto-highlight",
               "popup",
               "input-group",
               "rtl"
             ]

      for example <- Examples.all("combobox") do
        {:ok, _view, html} = live(conn, "/preview/combobox/#{example.id}")
        document = Floki.parse_fragment!(html)

        assert [_] = Floki.find(document, "[data-lb-combobox][phx-hook='LiveBase.Combobox']")
        assert [_] = Floki.find(document, "[data-slot='combobox-content']")
        assert [_] = Floki.find(document, "[role='listbox']")
      end
    end

    test "the special Combobox variants retain their pinned state and structure", %{conn: conn} do
      {:ok, _view, multiple} = live(conn, "/preview/combobox/multiple")
      assert multiple =~ ~s(data-combobox-multiple="")
      assert multiple =~ ~s(data-combobox-auto-highlight="")
      assert multiple =~ ~s(data-combobox-value="Next.js")

      multiple_document = Floki.parse_fragment!(multiple)

      [multiple_chips] = Floki.find(multiple_document, "#combobox-multiple-chips")
      assert Floki.attribute([multiple_chips], "data-combobox-value") == ["Next.js"]
      assert Floki.attribute([multiple_chips], "data-combobox-multiple") == [""]
      assert Floki.attribute([multiple_chips], "data-combobox-auto-highlight") == [""]

      [multiple_chip] =
        Floki.find(multiple_document, "#combobox-multiple-chips [data-slot='combobox-chip']")

      assert Floki.text(multiple_chip) =~ "Next.js"
      assert Floki.find([multiple_chip], "[data-slot='combobox-chip-remove']") != []

      [multiple_item] =
        Floki.find(multiple_document, "#combobox-multiple-item-Next-js")

      assert Floki.attribute([multiple_item], "aria-selected") == ["true"]
      assert Floki.attribute([multiple_item], "data-selected") == [""]

      {:ok, _view, clear} = live(conn, "/preview/combobox/clear")
      clear_document = Floki.parse_fragment!(clear)

      [clear_input] =
        Floki.find(
          clear_document,
          "input[data-slot='input-group-control'][data-combobox-controller='combobox-clear']"
        )

      assert Floki.attribute([clear_input], "value") == ["Next.js"]

      [clear_control] = Floki.find(clear_document, "[data-slot='combobox-clear']")
      assert Floki.attribute([clear_control], "aria-label") == ["Clear selection"]
      assert Floki.attribute([clear_control], "data-visible") == [""]
      assert Floki.attribute([clear_control], "hidden") == []

      [clear_item] = Floki.find(clear_document, "#combobox-clear-item-Next-js")
      assert Floki.attribute([clear_item], "aria-selected") == ["true"]
      assert Floki.attribute([clear_item], "data-selected") == [""]

      {:ok, _view, groups} = live(conn, "/preview/combobox/groups")
      groups_document = Floki.parse_fragment!(groups)

      assert 3 =
               groups_document
               |> Floki.find("[data-slot='combobox-group']")
               |> Enum.count_until(4)

      assert 2 =
               groups_document
               |> Floki.find("[data-slot='combobox-separator']")
               |> Enum.count_until(3)

      for {example, id} <- [
            {"groups", "combobox-groups"},
            {"input-group", "combobox-input-group"}
          ] do
        {:ok, _view, html} = live(conn, "/preview/combobox/#{example}")
        document = Floki.parse_fragment!(html)

        controls =
          document
          |> Floki.find("[data-slot='input-group'] [aria-expanded]")
          |> Enum.map(fn control ->
            {
              elem(control, 0),
              Floki.attribute([control], "role"),
              Floki.attribute([control], "data-slot"),
              Floki.attribute([control], "aria-haspopup"),
              Floki.attribute([control], "aria-expanded"),
              Floki.attribute([control], "data-placeholder"),
              Floki.attribute([control], "tabindex")
            }
          end)

        assert controls == [
                 {"input", ["combobox"], ["input-group-control"], ["listbox"], ["false"], [], []},
                 {"button", [], ["input-group-button"], ["listbox"], ["false"], [""], ["0"]}
               ],
               "#{id} must retain the pinned Combobox input and trigger order"
      end

      {:ok, _view, rtl} = live(conn, "/preview/combobox/rtl")
      rtl_document = Floki.parse_fragment!(rtl)
      [content] = Floki.find(rtl_document, "[data-slot='combobox-content']")
      assert Floki.attribute([content], "dir") == ["rtl"]
      assert Floki.attribute([content], "data-lang") == ["ar"]
      assert rtl =~ "الفئات"
      assert rtl =~ "أضف فئات"

      [rtl_chips] = Floki.find(rtl_document, "#combobox-rtl-chips")
      assert Floki.attribute([rtl_chips], "data-combobox-value") == ["technology"]
      assert Floki.attribute([rtl_chips], "data-combobox-multiple") == [""]
      assert Floki.attribute([rtl_chips], "data-combobox-auto-highlight") == [""]

      [rtl_chip] =
        Floki.find(rtl_document, "#combobox-rtl-chips [data-slot='combobox-chip']")

      assert Floki.text(rtl_chip) =~ "التكنولوجيا"
      assert Floki.find([rtl_chip], "[data-slot='combobox-chip-remove']") != []

      [rtl_item] = Floki.find(rtl_document, "#combobox-rtl-item-technology")
      assert Floki.attribute([rtl_item], "aria-selected") == ["true"]
      assert Floki.attribute([rtl_item], "data-selected") == [""]
    end
  end

  describe "Sonner examples" do
    test "uses both public pinned examples", %{conn: conn} do
      assert Enum.map(Examples.all("sonner"), & &1.id) == ["basic", "with-description"]

      {:ok, basic, basic_html} = live(conn, "/preview/sonner/basic")
      assert basic_html =~ "Show Toast"
      refute basic_html =~ "Event has been created"

      basic_html = basic |> element("button", "Show Toast") |> render_click()
      basic_document = Floki.parse_fragment!(basic_html)

      assert basic_html =~ "Event has been created"
      assert Floki.find(basic_document, "ol#sonner-basic[data-sonner-toaster]") != []
      assert Floki.find(basic_document, "[data-sonner-toast]") != []
      refute basic_html =~ "Monday, January 3rd at 6:00pm"

      {:ok, with_description, _html} = live(conn, "/preview/sonner/with-description")

      with_description_html =
        with_description
        |> element("button", "Show Toast")
        |> render_click()

      assert with_description_html =~ "Event has been created"
      assert with_description_html =~ "Monday, January 3rd at 6:00pm"
    end

    test "keeps Sonner messages in the server-owned list" do
      initial = Examples.page_assigns().sonner_examples
      notice = Examples.sonner_notice("basic", "sonner-1")
      added = Examples.add_sonner_toast(initial, "basic", notice)

      assert added["basic"] == [notice]

      assert Examples.dismiss_sonner_toast(added, "sonner-basic-sonner-1")["basic"] == []
    end
  end
end
