defmodule LiveAiElements.Components.SpeechInput do
  @moduledoc """
  Speech input.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/SpeechInput/class/0" => "relative inline-flex items-center justify-center",
    "jsx/SpeechInput/class/1" =>
      "absolute inset-0 animate-ping rounded-full border-2 border-red-400/30",
    "jsx/SpeechInput/class/2" => "relative z-10 rounded-full transition-all duration-300",
    "jsx/SpeechInput/class/3" =>
      "bg-destructive text-white hover:bg-destructive/80 hover:text-white",
    "jsx/SpeechInput/class/4" =>
      "bg-primary text-primary-foreground hover:bg-primary/80 hover:text-primary-foreground",
    "jsx/SpeechInput/class/5" => "size-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `speech_input` part."
  attr(:id, :string, required: true)
  attr(:is_disabled, :string, default: nil)
  attr(:is_listening, :boolean, default: false)
  attr(:is_processing, :boolean, default: false)
  attr(:lang, :string, default: "en-US")
  attr(:transcription_event, :string, default: nil)
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def speech_input(assigns) do
    ~H"""
    <div
      id={@id}
      data-lang={@lang}
      data-listening={to_string(@is_listening)}
      data-transcription-event={@transcription_event}
      phx-hook={hook()}
      class={upstream_fact("jsx/SpeechInput/class/0")}
    >
      <div
        :for={index <- [0, 1, 2]}
        data-speech-pulse
        hidden={!@is_listening}
        style={"animation-delay: #{"#{index * 0.3}s"}; animation-duration: 2s"}
        class={upstream_fact("jsx/SpeechInput/class/1")}
      />
      <button
        data-slot={@rest[:"data-slot"] || "button"}
        disabled={@is_disabled}
        class={[
          Shadcn.button_class(@size, @variant),
          upstream_fact("jsx/SpeechInput/class/2"),
          "!rounded-full",
          if(@is_listening,
            do: upstream_fact("jsx/SpeechInput/class/3"),
            else: upstream_fact("jsx/SpeechInput/class/4")
          ),
          @class
        ]}
        {Map.drop(@rest, [:"data-slot"])}
      >
        <LiveShadcn.UI.Spinner.spinner :if={@is_processing} />
        <LiveShadcn.Icon.icon
          :if={!@is_processing && @is_listening}
          name="square"
          class={upstream_fact("jsx/SpeechInput/class/5")}
          data-speech-stop
        />
        <LiveShadcn.Icon.icon
          :if={!@is_processing && !@is_listening}
          name="mic"
          class={upstream_fact("jsx/SpeechInput/class/5")}
          data-speech-mic
        />
        {render_slot(@inner_block)}
      </button>
    </div>
    """
  end

  @doc "The client hook name the speech input root declares in `phx-hook`."
  def hook, do: "LiveAiElements.Components.SpeechInput.SpeechInput"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook speech_input.js#SpeechInput --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".SpeechInput">
      const IDLE_CLASSES = [
        "bg-primary",
        "text-primary-foreground",
        "hover:bg-primary/80",
        "hover:text-primary-foreground"
      ];
      const LISTENING_CLASSES = [
        "bg-destructive",
        "text-white",
        "hover:bg-destructive/80",
        "hover:text-white"
      ];
      const SpeechInput = {
        mounted() {
          this.button = this.el.querySelector("button");
          this.pulses = this.el.querySelectorAll("[data-speech-pulse]");
          this.mic = this.el.querySelector("[data-speech-mic]");
          this.stopIcon = this.el.querySelector("[data-speech-stop]");
          this.example = this.el.closest("[data-speech-example]");
          this.clear = this.example?.querySelector("[data-speech-clear]");
          this.onClear = () => this.showTranscript("");
          this.clear?.addEventListener("click", this.onClear);
          this.mode = this.detectMode();
          this.button.disabled = this.mode === "none";
          this.onClick = () => this.listening ? this.stop() : this.start();
          this.button?.addEventListener("click", this.onClick);
          this.draw(this.el.dataset.listening === "true");
        },
        destroyed() {
          this.button?.removeEventListener("click", this.onClick);
          this.recognition?.abort?.();
          this.recorder?.stop?.();
          this.stream?.getTracks().forEach((track) => track.stop());
          this.clear?.removeEventListener("click", this.onClear);
        },
        detectMode() {
          if (window.SpeechRecognition || window.webkitSpeechRecognition) return "speech-recognition";
          if (window.MediaRecorder && navigator.mediaDevices?.getUserMedia) return "media-recorder";
          return "none";
        },
        start() {
          if (this.mode === "media-recorder") {
            this.startRecorder();
            return;
          }
          const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (!Recognition) {
            this.el.dispatchEvent(new CustomEvent("live_ai_elements:speech-error", {
              bubbles: true,
              detail: { reason: "unsupported" }
            }));
            return;
          }
          this.recognition = new Recognition();
          this.recognition.lang = this.el.dataset.lang || "en-US";
          this.recognition.interimResults = true;
          this.recognition.continuous = true;
          this.recognition.onstart = () => this.draw(true);
          this.recognition.onend = () => this.draw(false);
          this.recognition.onerror = () => this.draw(false);
          this.recognition.onresult = (event) => {
            const text = [...event.results].slice(event.resultIndex).filter((result) => result.isFinal).map((result) => result[0]?.transcript || "").join("").trim();
            if (!text) return;
            this.el.dispatchEvent(new CustomEvent("live_ai_elements:transcription-change", {
              bubbles: true,
              detail: { text }
            }));
            this.showTranscript(text);
            const serverEvent = this.el.dataset.transcriptionEvent;
            if (serverEvent) this.pushEvent(serverEvent, { text });
          };
          this.recognition.start();
        },
        stop() {
          if (this.mode === "media-recorder") {
            this.recorder?.stop();
            this.draw(false);
            return;
          }
          this.recognition?.stop();
        },
        async startRecorder() {
          try {
            this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            this.chunks = [];
            this.recorder = new MediaRecorder(this.stream);
            this.recorder.ondataavailable = (event) => {
              if (event.data.size > 0) this.chunks.push(event.data);
            };
            this.recorder.onstop = () => {
              this.stream?.getTracks().forEach((track) => track.stop());
              const audio = new Blob(this.chunks, { type: "audio/webm" });
              this.el.dispatchEvent(new CustomEvent("live_ai_elements:audio-recorded", {
                bubbles: true,
                detail: { audio }
              }));
            };
            this.recorder.onerror = () => this.draw(false);
            this.recorder.start();
            this.draw(true);
          } catch {
            this.draw(false);
          }
        },
        showTranscript(text) {
          if (!this.example) return;
          const transcript = this.example.querySelector("[data-speech-transcript]");
          const card = this.example.querySelector("[data-speech-transcript-card]");
          const empty = this.example.querySelector("[data-speech-empty]");
          if (transcript) transcript.textContent = text;
          if (card) card.hidden = !text;
          if (empty) empty.hidden = Boolean(text);
          if (this.clear) this.clear.hidden = !text;
        },
        draw(listening) {
          this.listening = listening;
          this.el.dataset.listening = String(listening);
          for (const pulse of this.pulses) pulse.hidden = !listening;
          if (this.mic) this.mic.hidden = listening;
          if (this.stopIcon) this.stopIcon.hidden = !listening;
          this.button?.classList.remove(...listening ? IDLE_CLASSES : LISTENING_CLASSES);
          this.button?.classList.add(...listening ? LISTENING_CLASSES : IDLE_CLASSES);
        }
      };
      export default SpeechInput;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
