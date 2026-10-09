defmodule StorybookWeb.DocsLive do
  @moduledoc """
  One component, documented.

  The page has the shape ui.shadcn.com uses — the component, the markup that
  drew it, how to install it, and what it takes — and every one of those four
  comes from somewhere rather than being typed. `StorybookWeb.Docs` says where.

  The examples are rendered inline rather than in a frame. They are the same
  functions `/preview/:component/:example` renders, so a difference between the
  two pages would be a difference in the chrome, and there is a link to the bare
  page for anyone who wants to check.
  """

  use StorybookWeb, :docs_live_view

  import LiveShadcn.UI.Badge
  import LiveShadcn.UI.Table
  import LiveShadcn.UI.Tabs

  alias StorybookWeb.Docs
  alias StorybookWeb.Examples

  defmodule NotFound do
    @moduledoc "A component nobody documented. A 404, not a blank page."
    defexception [:message, plug_status: 404]
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <header>
      <div class="flex flex-wrap items-center gap-2">
        <h1 class="text-3xl font-semibold tracking-tight">{Docs.title(@component)}</h1>
        <.badge
          data-component-status={@status}
          variant={if(@status == :verified, do: "default", else: "secondary")}
          class={["capitalize", Docs.status_classes(@status)]}
        >
          {@status_label}
        </.badge>
        <%!-- Which of the three libraries this one is. Two components are called
              `Message` and they are not the same component; without this the
              page gives a reader no way to tell which one they are reading. --%>
        <.badge variant="secondary"><code>{@library.package}</code></.badge>
        <%!-- Where the page comes from. The spec is the whole answer, so it is
              a badge beside the package rather than a sentence about it. --%>
        <.badge variant="outline"><code>{@library.spec}</code></.badge>
      </div>
      <details :if={@verification.checks != []} class="mt-3 text-sm">
        <summary class="cursor-pointer text-muted-foreground">
          Verification checks
          <span :if={@verification.reason} class="ml-1">— {@verification.reason}</span>
        </summary>
        <ul class="mt-2 space-y-1">
          <li :for={check <- @verification.checks} class="flex flex-wrap gap-x-2">
            <span class="font-medium">{check.name}</span>
            <span>{Docs.check_outcome_label(check.outcome)}</span>
            <span class="text-muted-foreground">{check.reason}</span>
          </li>
        </ul>
      </details>
      <p
        :if={@verification.checks == [] and @verification.reason}
        class="mt-2 text-sm text-muted-foreground"
      >
        {@verification.reason}
      </p>
    </header>

    <section :for={example <- @examples} class="mt-10">
      <h2 class="text-lg font-medium">{example.title}</h2>
      <p :if={example.description} class="mt-1 text-sm text-muted-foreground">
        {example.description}
      </p>

      <.tabs id={"example-#{example.id}"} value="preview" class="mt-4">
        <:tab value="preview" label="Preview">
          <div class="flex min-h-40 items-center justify-center rounded-md border p-8">
            {example.render.(assigns)}
          </div>
        </:tab>
        <:tab value="code" label="Code">
          <pre class="overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>{example.source}</code></pre>
        </:tab>
      </.tabs>
    </section>

    <section class="mt-14">
      <h2 class="text-lg font-medium">
        {if @status == :no_dom or is_nil(Docs.module(@component)),
          do: "Usage",
          else: "Installation"}
      </h2>
      <pre class="mt-3 overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>{@install}</code></pre>
    </section>

    <section :for={function <- @api} class="mt-14">
      <h2 class="text-lg font-medium">
        <code>{function.name}/1</code>
      </h2>

      <.table :if={function.attrs != []} class="mt-3">
        <.table_header>
          <.table_row>
            <.table_head>Attribute</.table_head>
            <.table_head>Type</.table_head>
            <.table_head>Default</.table_head>
            <.table_head>Notes</.table_head>
          </.table_row>
        </.table_header>
        <.table_body>
          <.table_row :for={attr <- function.attrs}>
            <.table_cell>
              <code class="text-xs">{attr.name}</code>
              <span :if={attr.required} class="text-xs text-muted-foreground">required</span>
            </.table_cell>
            <.table_cell><code class="text-xs">{inspect(attr.type)}</code></.table_cell>
            <.table_cell><code class="text-xs">{default(attr)}</code></.table_cell>
            <.table_cell class="text-xs text-muted-foreground">
              {attr.doc}
              <span :if={values(attr)} class="block">One of {values(attr)}.</span>
            </.table_cell>
          </.table_row>
        </.table_body>
      </.table>

      <p :if={function.globals != []} class="mt-2 text-xs text-muted-foreground">
        Every other attribute is passed through to the element.
      </p>

      <div :if={function.slots != []} class="mt-4">
        <h3 class="text-sm font-medium">Slots</h3>
        <ul class="mt-2 space-y-1 text-xs text-muted-foreground">
          <li :for={slot <- function.slots}>
            <code>{slot.name}</code>
            <span :if={slot.doc}>— {slot.doc}</span>
            <span :if={slot_attrs(slot) != []}>
              Takes {Enum.map_join(slot_attrs(slot), ", ", &"`#{&1.name}`")}.
            </span>
          </li>
        </ul>
      </div>
    </section>

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
      :if={@component == "questionnaire"}
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
      :if={@component == "questionnaire"}
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

  @impl Phoenix.LiveView
  def mount(%{"component" => component}, _session, socket) do
    if component not in Docs.components() do
      raise NotFound, message: "no component called #{component}"
    end

    if component == "progress" do
      Process.send_after(self(), :complete_progress_demo, 500)
    end

    examples =
      component
      |> Examples.all()
      |> Enum.map(&Map.put(&1, :source, Docs.source(&1)))

    {:ok,
     socket
     |> assign(
       component: component,
       examples: examples,
       api: Docs.api(component),
       library: Docs.library(component),
       status: Docs.status(component),
       status_label: Docs.status_label(component),
       verification: Docs.evaluation(component),
       install: Docs.install(component),
       page_title: Docs.title(component)
     )
     |> assign(Examples.page_assigns())}
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

  def handle_event("questionnaire_card_submit", params, socket) do
    questionnaire_toast(socket, "card", params)
  end

  def handle_event("questionnaire_dialog_submit", params, socket) do
    questionnaire_toast(socket, "dialog", params)
  end

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
    parsed = Enum.map(values, fn value -> value |> Float.parse() |> elem(0) end)
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

  def handle_event("remove_attachment", %{"example" => example, "id" => id}, socket) do
    {:noreply,
     assign(
       socket,
       attachment_examples:
         Examples.remove_attachment(socket.assigns.attachment_examples, example, id)
     )}
  end

  def handle_event("message_scroller_send", %{"example" => example}, socket) do
    socket =
      update(socket, :message_scroller, &Examples.message_scroller_event(&1, "send", example))

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

  # Everything else belongs to the shell — the ⌘K palette's `search`. Defining
  # any clause here replaces the one `docs_live_view` installed, so the rest has
  # to be handed back explicitly rather than silently disappearing.
  def handle_event(event, params, socket), do: super(event, params, socket)

  @impl Phoenix.LiveView
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

  def handle_info({:complete_toast_promise, id}, socket) do
    toast = Examples.toast_promise_complete(id)

    {:noreply,
     assign(
       socket,
       toast_examples: Examples.replace_toast(socket.assigns.toast_examples, "promise", id, toast)
     )}
  end

  def handle_info(:complete_progress_demo, socket) do
    {:noreply, assign(socket, progress_demo_value: 66)}
  end

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

  defp calendar_month_start(date), do: Date.new!(date.year, date.month, 1)

  # A declared attribute always has a default, even when that default is `nil`.
  defp default(attr) do
    case Keyword.fetch(attr.opts, :default) do
      {:ok, value} -> inspect(value)
      :error -> "—"
    end
  end

  defp values(attr) do
    case Keyword.get(attr.opts, :values) do
      nil -> nil
      list -> Enum.map_join(list, ", ", &inspect/1)
    end
  end

  # A slot with no attributes reports them as `nil` rather than as an empty
  # list, and `Enum.map_join/3` has an opinion about that.
  defp slot_attrs(slot), do: List.wrap(slot.attrs)
end
