import { spawn } from "node:child_process";
import { createServer } from "node:net";
import { openSync, closeSync } from "node:fs";
import { fileURLToPath } from "node:url";

const fixture = String.raw`
defmodule CheckableFixture.Live do
  use Phoenix.LiveView, layout: false

  def mount(%{"kind" => kind}, _session, socket) when kind in ["checkbox", "switch"] do
    {:ok, assign(socket,
      kind: kind,
      settings: [
        %{key: "first", label: "First setting"},
        %{key: "second", label: "Second setting"},
        %{key: "named", label: "Submitted setting"},
        %{key: "disabled", label: "Disabled setting"},
        %{key: "readonly", label: "Read-only setting"}
      ],
      checked: %{"first" => false, "second" => true, "named" => false, "disabled" => false, "readonly" => true},
      events: 0,
      applied: false,
      values: %{}
    )}
  end

  def render(assigns) do
    ~H"""
    <main>
      <h1>Checkable controls</h1>
      <form id="checkable-form" phx-change="changed">
        <label :for={setting <- @settings} class="flex items-center gap-2 p-2">
          {setting.label}
          <LiveShadcn.UI.Checkbox.checkbox
            :if={@kind == "checkbox"}
            name={if(setting.key == "named", do: "submitted")}
            checked={Map.fetch!(@checked, setting.key)}
            disabled={setting.key == "disabled"}
            readonly={setting.key == "readonly"}
            aria-label={setting.label}
            on_toggle={"toggle:" <> setting.key}
          />
          <LiveShadcn.UI.Switch.switch
            :if={@kind == "switch"}
            name={if(setting.key == "named", do: "submitted")}
            checked={Map.fetch!(@checked, setting.key)}
            disabled={setting.key == "disabled"}
            readonly={setting.key == "readonly"}
            aria-label={setting.label}
            on_toggle={"toggle:" <> setting.key}
          />
        </label>
      </form>
      <output id="checkable-events" data-count={@events}>{@events}</output>
      <output id="checkable-values">{Jason.encode!(@values)}</output>
      <button id="checkable-update" type="button" phx-click="update">Apply settings</button>
      <output id="checkable-applied">{to_string(@applied)}</output>
    </main>
    """
  end

  def handle_event("toggle:" <> key, _params, socket) do
    {:noreply, assign(socket,
      checked: Map.update!(socket.assigns.checked, key, &(!&1)),
      events: socket.assigns.events + 1
    )}
  end

  def handle_event("changed", params, socket) do
    {:noreply, assign(socket, values: Map.drop(params, ["_target"]))}
  end

  def handle_event("update", _params, socket) do
    applied = !socket.assigns.applied
    {:noreply, assign(socket,
      applied: applied,
      checked: %{"first" => applied, "second" => !applied, "named" => applied, "disabled" => false, "readonly" => true}
    )}
  end
end

defmodule CheckableFixture.Ready do
  use Phoenix.Controller, formats: [:html]
  def index(conn, _params), do: text(conn, "checkable-browser-fixture")
end

defmodule CheckableFixture.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StorybookWeb.Layouts, :root}
    plug :protect_from_forgery
  end

  scope "/" do
    pipe_through :browser
    get "/ready", CheckableFixture.Ready, :index
    live "/:kind", CheckableFixture.Live
  end
end

Application.put_env(:storybook, CheckableFixture.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.fetch_env!("CHECKABLE_FIXTURE_PORT"))],
  url: [host: "127.0.0.1", port: String.to_integer(System.fetch_env!("CHECKABLE_FIXTURE_PORT"))],
  secret_key_base: String.duplicate("checkable-browser-fixture-key", 3),
  pubsub_server: Storybook.PubSub,
  live_view: [signing_salt: "checkable-browser-fixture"],
  render_errors: [formats: [html: StorybookWeb.ErrorHTML], layout: false],
  server: true
)

defmodule CheckableFixture.Endpoint do
  use Phoenix.Endpoint, otp_app: :storybook
  @session_options [store: :cookie, key: "_checkable_fixture", signing_salt: "checkable", same_site: "Lax"]
  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
  plug Plug.Static, at: "/", from: :storybook, only: ["assets"]
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.Session, @session_options
  plug CheckableFixture.Router
end

{:ok, _pid} = CheckableFixture.Endpoint.start_link()
Process.sleep(:infinity)
`;

export async function startCheckableFixture(logPath) {
  const reservation = createServer();
  await new Promise((resolve, reject) => {
    reservation.once("error", reject);
    reservation.listen(0, "127.0.0.1", resolve);
  });
  const port = reservation.address().port;
  await new Promise((resolve) => reservation.close(resolve));

  const log = openSync(logPath, "w");
  const child = spawn("mix", ["run", "-e", fixture], {
    cwd: fileURLToPath(new URL("../..", import.meta.url)),
    env: { ...process.env, MIX_ENV: "test", CHECKABLE_FIXTURE_PORT: String(port) },
    stdio: ["ignore", log, log],
  });
  let failure;
  child.once("error", (error) => { failure = error; });
  const ended = new Promise((resolve) => child.once("exit", resolve));
  const close = async () => {
    if (child.pid && child.exitCode === null && child.signalCode === null) {
      child.kill("SIGTERM");
      await ended;
    }
    closeSync(log);
  };
  const url = `http://127.0.0.1:${port}`;
  try {
    const deadline = Date.now() + 180_000;
    while (Date.now() < deadline) {
      if (failure) throw failure;
      if (child.exitCode !== null || child.signalCode !== null) {
        throw new Error(`Checkable fixture stopped before readiness. See ${logPath}`);
      }
      try {
        const response = await fetch(`${url}/ready`, { signal: AbortSignal.timeout(1_000) });
        if (response.ok && await response.text() === "checkable-browser-fixture") return { url, close };
      } catch { /* The owned server is still starting. */ }
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    throw new Error(`Checkable fixture did not become ready. See ${logPath}`);
  } catch (error) {
    await close();
    throw error;
  }
}
