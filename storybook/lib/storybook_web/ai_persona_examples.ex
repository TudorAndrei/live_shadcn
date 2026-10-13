defmodule StorybookWeb.AiPersonaExamples do
  @moduledoc "Pinned Persona variants with caller-owned animation state."
  use Phoenix.LiveComponent

  alias LiveAiElements.Components.Persona
  alias LiveShadcn.UI.{ButtonGroup, Tooltip}

  @states [
    {"idle", "Idle", "circle"},
    {"listening", "Listening", "mic"},
    {"thinking", "Thinking", "brain"},
    {"speaking", "Speaking", "megaphone"},
    {"asleep", "Asleep", "eye-closed"}
  ]

  def all do
    for variant <- ~w(command glint halo mana obsidian opal) do
      %{
        id: variant,
        title: String.capitalize(variant),
        description: "The pinned Persona variant with five animation states.",
        render: fn assigns -> render_example(assign(assigns, :variant, variant)) end,
        snapshot_component: __MODULE__,
        snapshot_assigns: [id: "persona-example-#{variant}", variant: variant]
      }
    end
  end

  def render_example(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={"persona-example-#{@variant}"} variant={@variant} />
    """
  end

  @impl true
  def mount(socket), do: {:ok, assign(socket, state: "idle", states: @states)}

  @impl true
  def handle_event("state", %{"state" => state}, socket)
      when state in ~w(idle listening thinking speaking asleep),
      do: {:noreply, assign(socket, :state, state)}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex size-full flex-col items-center justify-center gap-4">
      <Persona.persona id={"#{@id}-visual"} class="size-32" variant={@variant} state={@state} />
      <ButtonGroup.button_group orientation="horizontal" aria-label="Persona state">
        <Tooltip.tooltip
          :for={{state, label, icon} <- @states}
          id={"#{@id}-#{state}-tooltip"}
          trigger_size="icon-sm"
          trigger_variant={if(@state == state, do: "default", else: "outline")}
          trigger_label={label}
          trigger_attrs={%{"aria-pressed" => to_string(@state == state)}}
          trigger_click={Phoenix.LiveView.JS.push("state", target: @myself, value: %{state: state})}
        >
          <:trigger>
            <LiveShadcn.Icon.icon name={icon} class="size-4" />
          </:trigger>
          {label}
        </Tooltip.tooltip>
      </ButtonGroup.button_group>
    </div>
    """
  end
end
