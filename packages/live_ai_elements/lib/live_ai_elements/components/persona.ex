defmodule LiveAiElements.Components.Persona do
  @moduledoc """
  Persona.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/anonymous/class/0" => "size-16 shrink-0"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @sources %{
    "command" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/command-2.0.riv",
    "glint" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/glint-2.0.riv",
    "halo" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/halo-2.0.riv",
    "mana" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/mana-2.0.riv",
    "obsidian" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/obsidian-2.0.riv",
    "opal" => "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/orb-1.2.riv"
  }

  @doc "The `persona` part."
  attr(:id, :string, required: true)
  attr(:rive, :string, default: nil)
  attr(:source, :string, default: nil)
  attr(:state, :string, default: "idle")
  attr(:variant, :string, default: "obsidian", values: Map.keys(@sources) |> Enum.sort())
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def persona(assigns) do
    assigns =
      assign(assigns, :rive_source, assigns.source || assigns.rive || @sources[assigns.variant])

    ~H"""
    <div
      id={@id}
      data-persona-state={@state}
      data-persona-variant={@variant}
      data-rive-source={@rive_source}
      phx-hook={hook()}
      class={[upstream_fact("jsx/anonymous/class/0"), @class || ""]}
      {@rest}
    >
      <canvas id={"#{@id}-canvas"} data-persona-canvas phx-update="ignore" class="block size-full" />
    </div>
    {render_slot(@inner_block)}
    """
  end

  @doc "The client hook name the persona root declares in `phx-hook`."
  def hook, do: "LiveAiElements.Components.Persona.Persona"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook persona.js#Persona --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Persona">
      import { Rive } from "@rive-app/webgl2";
      const STATE_MACHINE = "default";
      const INPUTS = [
        "listening",
        "thinking",
        "speaking",
        "asleep"
      ];
      const DYNAMIC_COLOR_VARIANTS = new Set([
        "command",
        "glint",
        "halo",
        "obsidian"
      ]);
      const Persona = {
        mounted() {
          this.canvas = this.el.querySelector("[data-persona-canvas]");
          this.frame = requestAnimationFrame(() => {
            this.rive = new Rive({
              autoplay: true,
              autoBind: true,
              canvas: this.canvas,
              src: this.el.dataset.riveSource,
              stateMachines: STATE_MACHINE,
              onLoad: () => {
                this.rive.resizeDrawingSurfaceToCanvas();
                this.inputs = new Map(this.rive.stateMachineInputs(STATE_MACHINE).map((input) => [input.name, input]));
                if (DYNAMIC_COLOR_VARIANTS.has(this.el.dataset.personaVariant)) {
                  this.color = this.rive.viewModelInstance?.color("color");
                  this.themeChanged = () => this.updateColor();
                  this.themeObserver = new MutationObserver(this.themeChanged);
                  this.themeObserver.observe(document.documentElement, {
                    attributes: true,
                    attributeFilter: ["class"]
                  });
                  this.updateColor();
                }
                this.draw(this.el.dataset.personaState);
                this.el.dataset.riveReady = "true";
              },
              onLoadError: () => {
                this.el.dataset.riveReady = "false";
              }
            });
          });
        },
        updated() {
          this.draw(this.el.dataset.personaState);
        },
        destroyed() {
          cancelAnimationFrame(this.frame);
          this.themeObserver?.disconnect();
          this.rive?.cleanup();
        },
        updateColor() {
          const channel = document.documentElement.classList.contains("dark") ? 255 : 0;
          this.color?.rgb(channel, channel, channel);
        },
        draw(state) {
          if (!this.inputs) return;
          for (const name of INPUTS) {
            const input = this.inputs.get(name);
            if (input) input.value = name === state;
          }
        }
      };
      export default Persona;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
