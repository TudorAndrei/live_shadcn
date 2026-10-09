defmodule StorybookWeb.PreviewLive do
  @moduledoc """
  One example on a page of its own.

  The page carries nothing but the component: no navigation, no headings that
  are not the component's. That is deliberate. `mix ui.verify` runs axe-core
  against this page, and a violation has to belong to the component rather than
  to the chrome around it.
  """

  use StorybookWeb, :live_view

  alias StorybookWeb.Examples

  defmodule NotFound do
    @moduledoc "An example nobody defined. A 404, not a blank page."
    defexception [:message, plug_status: 404]
  end

  @impl Phoenix.LiveView
  def mount(%{"component" => component, "example" => id}, _session, socket) do
    case Examples.fetch(component, id) do
      {:ok, example} ->
        if component == "progress" and id == "default" do
          Process.send_after(self(), :complete_progress_demo, 500)
        end

        {:ok,
         socket
         |> assign(component: component, example: example, page_title: example.title)
         |> assign(Examples.page_assigns())}

      :error ->
        raise NotFound, message: "no #{component} example called #{id}"
    end
  end

  @impl Phoenix.LiveView
  def handle_event("dismiss_toast", %{"id" => id}, socket) do
    {:noreply,
     assign(socket, toast_examples: Examples.dismiss_toast(socket.assigns.toast_examples, id))}
  end

  def handle_event("toast_add", %{"example" => example} = params, socket) do
    sequence = socket.assigns.toast_sequence + 1
    toast = Examples.toast_notice(example, params["type"], "toast-#{sequence}")

    {:noreply,
     socket
     |> assign(toast_sequence: sequence)
     |> assign(toast_examples: Examples.add_toast(socket.assigns.toast_examples, example, toast))}
  end

  def handle_event("sonner_add", %{"example" => example}, socket) do
    sequence = socket.assigns.sonner_sequence + 1
    toast = Examples.sonner_notice(example, "sonner-#{sequence}")

    {:noreply,
     socket
     |> assign(sonner_sequence: sequence)
     |> assign(
       sonner_examples: Examples.add_sonner_toast(socket.assigns.sonner_examples, example, toast)
     )}
  end

  def handle_event("dismiss_sonner_toast", %{"id" => id}, socket) do
    {:noreply,
     assign(
       socket,
       sonner_examples: Examples.dismiss_sonner_toast(socket.assigns.sonner_examples, id)
     )}
  end

  def handle_event("drawer_delivery_time", %{"drawer-delivery-times" => value}, socket) do
    if Examples.drawer_delivery_label(value) do
      {:noreply, assign(socket, drawer_delivery_time: value)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("drawer_confirm_delivery_time", _params, socket) do
    sequence = socket.assigns.drawer_delivery_sequence + 1

    notice =
      Examples.drawer_delivery_notice(socket.assigns.drawer_delivery_time, "delivery-#{sequence}")

    {:noreply,
     socket
     |> assign(drawer_delivery_sequence: sequence)
     |> assign(drawer_delivery_toasts: socket.assigns.drawer_delivery_toasts ++ [notice])}
  end

  def handle_event("dismiss_drawer_delivery_toast", %{"id" => id}, socket) do
    {:noreply,
     assign(socket,
       drawer_delivery_toasts:
         Enum.reject(socket.assigns.drawer_delivery_toasts, fn notice ->
           LiveBase.Toast.toast_id("drawer-delivery-toasts", notice.id) == id
         end)
     )}
  end

  def handle_event("bubble_collapsible_toggle", _params, socket) do
    {:noreply,
     assign(socket, bubble_collapsible_open: not socket.assigns.bubble_collapsible_open)}
  end

  def handle_event("bubble_toast", %{"message" => message}, socket) do
    sequence = socket.assigns.bubble_sequence + 1
    toast = Examples.bubble_notice(message, "bubble-#{sequence}")

    {:noreply,
     socket
     |> assign(bubble_sequence: sequence)
     |> assign(bubble_toasts: Examples.add_bubble_notice(socket.assigns.bubble_toasts, toast))}
  end

  def handle_event("dismiss_bubble_toast", %{"id" => id}, socket) do
    {:noreply,
     assign(
       socket,
       bubble_toasts: Examples.dismiss_bubble_notice(socket.assigns.bubble_toasts, id)
     )}
  end

  def handle_event("toast_promise", _params, socket) do
    sequence = socket.assigns.toast_sequence + 1
    id = "toast-#{sequence}"
    toast = Examples.toast_promise_loading(id)
    Process.send_after(self(), {:complete_toast_promise, id}, 2000)

    {:noreply,
     socket
     |> assign(toast_sequence: sequence)
     |> assign(
       toast_examples: Examples.add_toast(socket.assigns.toast_examples, "promise", toast)
     )}
  end

  # One round trip to reveal a secret, which is the whole design of the
  # environment variables component: the page is given the value when it asks,
  # and not before.
  def handle_event("toggle_values", _params, socket) do
    {:noreply, assign(socket, show_values: not socket.assigns.show_values)}
  end

  def handle_event("card_spacing", %{"spacing" => spacing}, socket) do
    {:noreply, assign(socket, card_spacing: spacing)}
  end

  def handle_event("chart_demo_select", %{"series" => series}, socket) do
    if Examples.chart_demo_series?(series) do
      {:noreply, assign(socket, chart_demo_series: series)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("data_table", %{"action" => action} = params, socket) do
    {:noreply, update(socket, :data_table, &Examples.data_table_event(&1, action, params))}
  end

  def handle_event(event, %{"selected" => selected}, socket)
      when event in ~w(date_picker_default_select date_picker_basic_select date_picker_range_select date_picker_dob_select date_picker_input_select date_picker_time_select date_picker_natural_language_select date_picker_rtl_select) do
    example =
      event
      |> String.replace_prefix("date_picker_", "")
      |> String.replace_suffix("_select", "")
      |> String.replace("_", "-")

    date_picker = Examples.date_picker_select(socket.assigns.date_picker, example, selected)

    {:noreply,
     socket
     |> assign(date_picker: date_picker)
     |> assign(
       date_picker_values:
         Examples.date_picker_selection_values(
           socket.assigns.date_picker_values,
           date_picker,
           example
         )
     )
     |> assign(
       date_picker_selection_versions:
         Examples.date_picker_selection_versions(
           socket.assigns.date_picker_selection_versions,
           example
         )
     )}
  end

  def handle_event("date_picker_input", %{"example" => example, "value" => value}, socket) do
    {date_picker, date_picker_values} =
      Examples.date_picker_input_change(
        socket.assigns.date_picker,
        socket.assigns.date_picker_values,
        example,
        value
      )

    {:noreply,
     socket |> assign(date_picker: date_picker) |> assign(date_picker_values: date_picker_values)}
  end

  def handle_event("progress_value", %{"value" => value}, socket) do
    {:noreply, assign(socket, progress_value: String.to_integer(value))}
  end

  def handle_event("field_slider_value", %{"values" => values}, socket) do
    {:noreply, assign(socket, field_slider_values: Enum.map(values, &String.to_integer/1))}
  end

  def handle_event("slider_controlled_value", %{"values" => values}, socket) do
    parsed =
      Enum.map(values, fn value ->
        {number, ""} = Float.parse(value)
        if number == trunc(number), do: trunc(number), else: number
      end)

    {:noreply, assign(socket, slider_controlled_values: parsed)}
  end

  def handle_event("field_switch_toggle", _params, socket) do
    {:noreply, assign(socket, field_switch_checked: not socket.assigns.field_switch_checked)}
  end

  def handle_event("select_align_item", _params, socket) do
    {:noreply, assign(socket, select_align_item: not socket.assigns.select_align_item)}
  end

  def handle_event("sidebar_team_select", %{"team" => team}, socket) do
    if Examples.sidebar_team?(team) do
      {:noreply, assign(socket, sidebar_active_team: team)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("calendar_preset", %{"days" => days}, socket) do
    case Integer.parse(days) do
      {offset, ""} ->
        date = Date.add(Date.utc_today(), offset)

        {:noreply,
         socket
         |> assign(calendar_presets_date: date)
         |> assign(calendar_presets_month: calendar_month_start(date))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("calendar_presets_select", %{"selected" => ""}, socket) do
    {:noreply, assign(socket, calendar_presets_date: nil)}
  end

  def handle_event("calendar_presets_select", %{"selected" => selected}, socket) do
    case Date.from_iso8601(selected) do
      {:ok, date} -> {:noreply, assign(socket, calendar_presets_date: date)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_event("calendar_presets_month_change", %{"month" => month}, socket) do
    case Date.from_iso8601(month) do
      {:ok, date} ->
        {:noreply, assign(socket, calendar_presets_month: calendar_month_start(date))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("questionnaire_controlled_item", %{"item" => item}, socket) do
    {:noreply, assign(socket, questionnaire_controlled_item: item)}
  end

  def handle_event("questionnaire_controlled_submit", _params, socket), do: {:noreply, socket}

  def handle_event(
        "question_submit",
        %{"selected_values" => selected_values, "text" => text},
        socket
      ) do
    response = %{selected_values: selected_values, text: text}
    answers = Map.put(socket.assigns.question_answers, socket.assigns.example.id, response)
    {:noreply, assign(socket, question_answers: answers)}
  end

  def handle_event("questionnaire_card_submit", params, socket) do
    questionnaire_toast(socket, "card", params)
  end

  def handle_event("questionnaire_dialog_submit", params, socket) do
    questionnaire_toast(socket, "dialog", params)
  end

  def handle_event("questionnaire_resume_reset", _params, socket), do: {:noreply, socket}

  def handle_event("questionnaire_navigation_item", %{"item" => item}, socket)
      when item in ["permission", "verification"] do
    {:noreply, assign(socket, questionnaire_navigation_item: item)}
  end

  def handle_event(
        "questionnaire_navigation_status",
        %{"name" => name, "status" => status},
        socket
      )
      when name in ["permission", "verification"] and
             status in ["unanswered", "answered", "skipped"] do
    statuses = Map.put(socket.assigns.questionnaire_navigation_statuses, name, status)
    {:noreply, assign(socket, questionnaire_navigation_statuses: statuses)}
  end

  def handle_event("questionnaire_validation_item", %{"item" => item}, socket) do
    {:noreply, assign(socket, questionnaire_validation_item: item)}
  end

  def handle_event("questionnaire_validation_submit", params, socket) do
    detail = params["detail"]
    audience = params["audience"]

    errors =
      %{}
      |> maybe_questionnaire_error("detail", is_nil(detail), "Choose an answer to continue.")
      |> maybe_questionnaire_error("audience", is_nil(audience), "Choose an answer to continue.")
      |> maybe_questionnaire_error(
        "detail",
        audience == "public" and detail == "summary",
        "Public answers need enough context. Choose a complete answer."
      )

    item =
      cond do
        Map.has_key?(errors, "detail") -> "detail"
        Map.has_key?(errors, "audience") -> "audience"
        true -> socket.assigns.questionnaire_validation_item
      end

    {:noreply,
     assign(socket, questionnaire_validation_errors: errors, questionnaire_validation_item: item)}
  end

  def handle_event("questionnaire_runtime", %{"runtime" => runtime}, socket)
      when runtime in ["local", "cloud"] do
    {:noreply, assign(socket, questionnaire_runtime: runtime)}
  end

  def handle_event("questionnaire_runtime", _params, socket), do: {:noreply, socket}

  def handle_event("questionnaire_shortcuts", %{"shortcut_mode" => mode}, socket)
      when mode in ["none", "letters", "numbers"] do
    {:noreply, assign(socket, questionnaire_shortcuts: mode)}
  end

  def handle_event("remove_attachment", %{"example" => example, "id" => id}, socket) do
    {:noreply,
     assign(
       socket,
       attachment_remove_count: Map.get(socket.assigns, :attachment_remove_count, 0) + 1,
       attachment_examples:
         Examples.remove_attachment(socket.assigns.attachment_examples, example, id)
     )}
  end

  def handle_event("message_scroller_send", %{"example" => example}, socket) do
    socket =
      update(socket, :message_scroller, &Examples.message_scroller_event(&1, "send", example))

    if example == "default" and socket.assigns.message_scroller.default_busy do
      Process.send_after(self(), :message_scroller_default_reply, 1000)
    end

    if example == "streaming" and socket.assigns.message_scroller.streaming_busy do
      Process.send_after(self(), :message_scroller_stream_reply, 1000)
    end

    if example == "animation" and socket.assigns.message_scroller.animation_busy do
      Process.send_after(self(), :message_scroller_animation_reply, 1000)
    end

    if example == "previous-context" and socket.assigns.message_scroller.previous_context_busy do
      Process.send_after(self(), :message_scroller_previous_context_reply, 1000)
    end

    {:noreply, socket}
  end

  def handle_event("message_scroller_reset", %{"example" => example}, socket) do
    {:noreply,
     update(socket, :message_scroller, &Examples.message_scroller_event(&1, "reset", example))}
  end

  def handle_event("message_scroller_group_next", _params, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "group-next", "group-chat")
     )}
  end

  def handle_event("message_scroller_load_history", _params, socket) do
    can_load_history = socket.assigns.message_scroller.load_history < 10

    socket =
      update(
        socket,
        :message_scroller,
        &Examples.message_scroller_event(&1, "load-history", "load-history")
      )

    socket =
      if can_load_history do
        sequence = socket.assigns.toast_sequence + 1
        toast = Examples.message_scroller_history_notice("message-scroller-history-#{sequence}")

        socket
        |> assign(toast_sequence: sequence)
        |> assign(
          toast_examples:
            Examples.add_toast(
              socket.assigns.toast_examples,
              "message-scroller-load-history",
              toast
            )
        )
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("message_scroller_anchor_role", %{"role" => role}, socket) do
    {:noreply,
     update(socket, :message_scroller, &Examples.message_scroller_event(&1, "anchor-role", role))}
  end

  def handle_event("message_scroller_peek", %{"value" => value}, socket) do
    case Integer.parse(value) do
      {peek, ""} ->
        {:noreply,
         update(
           socket,
           :message_scroller,
           &Examples.message_scroller_event(&1, "previous-context-peek", peek)
         )}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("message_scroller_opening_position", %{"position" => position}, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "opening-position", position)
     )}
  end

  def handle_event("message_scroller_animation_preset", %{"preset" => preset}, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "animation-preset", preset)
     )}
  end

  defp maybe_questionnaire_error(errors, _name, false, _message), do: errors

  defp maybe_questionnaire_error(errors, name, true, message),
    do: Map.put_new(errors, name, message)

  defp calendar_month_start(date), do: Date.new!(date.year, date.month, 1)

  defp questionnaire_toast(socket, example, params) do
    sequence = socket.assigns.toast_sequence + 1
    toast = Examples.questionnaire_notice(example, params, "questionnaire-#{sequence}")

    socket =
      socket
      |> assign(toast_sequence: sequence)
      |> assign(
        toast_examples:
          Examples.add_toast(socket.assigns.toast_examples, "questionnaire-#{example}", toast)
      )

    socket =
      if example == "dialog" do
        push_event(socket, "questionnaire:submitted", %{id: "questionnaire-dialog"})
      else
        socket
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:message_scroller_default_reply, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "default-reply", "default")
     )}
  end

  def handle_info(:message_scroller_stream_reply, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "stream-reply", "streaming")
     )}
  end

  def handle_info(:message_scroller_animation_reply, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "animation-reply", "animation")
     )}
  end

  def handle_info(:message_scroller_previous_context_reply, socket) do
    {:noreply,
     update(
       socket,
       :message_scroller,
       &Examples.message_scroller_event(&1, "previous-context-reply", "previous-context")
     )}
  end

  def handle_info(:complete_progress_demo, socket) do
    {:noreply, assign(socket, progress_demo_value: 66)}
  end

  def handle_info({:complete_toast_promise, id}, socket) do
    toast = Examples.toast_promise_complete(id)

    {:noreply,
     assign(
       socket,
       toast_examples: Examples.replace_toast(socket.assigns.toast_examples, "promise", id, toast)
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="sr-only">{@component}</h1>
    <h2 class="sr-only">{@example.title}</h2>
    <div
      id={"preview-#{@component}-#{@example.id}"}
      data-preview={@component}
      data-attachment-remove-count={
        if @component == "attachments", do: Map.get(assigns, :attachment_remove_count, 0)
      }
      data-visual-settle-ms={if @component == "progress" and @example.id == "default", do: "600"}
      data-visual-actions={
        cond do
          @component == "toast" -> ""
          @component == "message-scroller" -> "message-scroller"
          @component == "data-table" -> "data-table"
          @component == "date-picker" -> "date-picker"
          true -> nil
        end
      }
      data-visual-action-settle-ms={if @component == "toast" and @example.id == "promise", do: "2200"}
    >
      {@example.render.(assigns)}
    </div>
    <LiveShadcn.UI.Sonner.toaster
      :if={@component == "bubble"}
      id="bubble-toasts"
      dismiss="dismiss_bubble_toast"
      duration={0}
    >
      <:toast
        :for={notice <- @bubble_toasts}
        id={notice.id}
        type={notice[:type]}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </LiveShadcn.UI.Sonner.toaster>
    <LiveShadcn.UI.Sonner.toaster
      :if={@component == "questionnaire" && @example.id == "card"}
      id="questionnaire-card-toasts"
      dismiss="dismiss_toast"
      duration={0}
    >
      <:toast
        :for={notice <- @toast_examples["questionnaire-card"]}
        id={notice.id}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </LiveShadcn.UI.Sonner.toaster>
    <LiveShadcn.UI.Sonner.toaster
      :if={@component == "questionnaire" && @example.id == "dialog"}
      id="questionnaire-dialog-toasts"
      dismiss="dismiss_toast"
      duration={0}
    >
      <:toast
        :for={notice <- @toast_examples["questionnaire-dialog"]}
        id={notice.id}
        title={notice.title}
      >
        {notice.description}
      </:toast>
    </LiveShadcn.UI.Sonner.toaster>
    """
  end
end
