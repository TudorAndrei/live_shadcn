defmodule StorybookWeb.AiMediaContracts do
  @moduledoc "Caller-owned voice and workflow examples used by browser verification."
  use Phoenix.LiveComponent

  alias LiveAiElements.Components.{Connection, Controls, Node, Panel, Toolbar, VoiceSelector}

  def render_example(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id="ai-media-contract" component={@component} />
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, zoom: 100, running: false, details: false, playing: false, moved: false)}
  end

  @impl true
  def handle_event("zoom-in", _params, socket),
    do: {:noreply, update(socket, :zoom, &min(&1 + 25, 200))}

  def handle_event("zoom-out", _params, socket),
    do: {:noreply, update(socket, :zoom, &max(&1 - 25, 25))}

  def handle_event("run", _params, socket), do: {:noreply, assign(socket, :running, true)}

  def handle_event("details", _params, socket),
    do: {:noreply, update(socket, :details, &(!&1))}

  def handle_event("play", _params, socket),
    do: {:noreply, update(socket, :playing, &(!&1))}

  def handle_event("move", _params, socket), do: {:noreply, assign(socket, :moved, true)}

  @impl true
  def render(assigns) do
    ~H"""
    <section id="ai-media-contract" class="max-w-md space-y-4">
      <%= case @component do %>
        <% "voice-selector" -> %>
          <VoiceSelector.voice_selector_name>Vega</VoiceSelector.voice_selector_name>
          <VoiceSelector.voice_selector_description>
            Clear spoken instructions.
          </VoiceSelector.voice_selector_description>
          <VoiceSelector.voice_selector_attributes>
            <VoiceSelector.voice_selector_gender value="female" />
            <VoiceSelector.voice_selector_bullet />
            <VoiceSelector.voice_selector_accent value="british" />
            <VoiceSelector.voice_selector_age>Adult</VoiceSelector.voice_selector_age>
          </VoiceSelector.voice_selector_attributes>
          <VoiceSelector.voice_selector_preview
            playing={@playing}
            phx-click="play"
            phx-target={@myself}
          />
          <VoiceSelector.voice_selector_preview loading aria-label="Loading preview" />
          <output aria-label="Preview state">{if @playing, do: "Playing", else: "Paused"}</output>
        <% "controls" -> %>
          <Controls.controls aria-label="Graph controls" role="group">
            <button type="button" phx-click="zoom-in" phx-target={@myself} aria-label="Zoom in">+</button>
            <button type="button" phx-click="zoom-out" phx-target={@myself} aria-label="Zoom out">-</button>
          </Controls.controls>
          <output aria-label="Zoom">{@zoom}%</output>
        <% "toolbar" -> %>
          <Toolbar.toolbar role="toolbar" aria-label="Node actions">
            <button type="button" phx-click="run" phx-target={@myself}>Run node</button>
          </Toolbar.toolbar>
          <output aria-label="Node status">{if @running, do: "Running", else: "Ready"}</output>
        <% "panel" -> %>
          <Panel.panel aria-label="Graph details" role="region">
            <button
              type="button"
              phx-click="details"
              phx-target={@myself}
              aria-expanded={to_string(@details)}
            >Details</button>
            <p :if={@details}>2 nodes connected</p>
          </Panel.panel>
        <% "node" -> %>
          <Node.node id="plain-node">
            <Node.node_content>No connections</Node.node_content>
          </Node.node>
          <Node.node id="connected-node" handles={%{target: true, source: true}}>
            <Node.node_header>
              <Node.node_title class="text-blue-600">Reader</Node.node_title>
              <Node.node_description>Reads the input</Node.node_description>
              <Node.node_action>
                <button type="button" phx-click="run" phx-target={@myself}>Run node</button>
              </Node.node_action>
            </Node.node_header>
            <Node.node_content>input.txt</Node.node_content>
            <Node.node_footer>{if @running, do: "Running", else: "Ready"}</Node.node_footer>
          </Node.node>
        <% "connection" -> %>
          <svg viewBox="0 0 240 96" role="img" aria-label="Connection path">
            <Connection.connection
              from_x={8}
              from_y={16}
              to_x={if(@moved, do: 120, else: 220)}
              to_y={80}
            />
          </svg>
          <button type="button" phx-click="move" phx-target={@myself}>Move target</button>
      <% end %>
    </section>
    """
  end
end
