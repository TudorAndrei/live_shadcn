const IDLE_CLASSES = [
  "bg-primary",
  "text-primary-foreground",
  "hover:bg-primary/80",
  "hover:text-primary-foreground",
];
const LISTENING_CLASSES = [
  "bg-destructive",
  "text-white",
  "hover:bg-destructive/80",
  "hover:text-white",
];

export const SpeechInput = {
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
    this.onClick = () => (this.listening ? this.stop() : this.start());
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
      this.el.dispatchEvent(
        new CustomEvent("live_ai_elements:speech-error", {
          bubbles: true,
          detail: { reason: "unsupported" },
        }),
      );
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
      const text = [...event.results]
        .slice(event.resultIndex)
        .filter((result) => result.isFinal)
        .map((result) => result[0]?.transcript || "")
        .join("")
        .trim();

      if (!text) return;

      this.el.dispatchEvent(
        new CustomEvent("live_ai_elements:transcription-change", {
          bubbles: true,
          detail: { text },
        }),
      );

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
        this.el.dispatchEvent(
          new CustomEvent("live_ai_elements:audio-recorded", {
            bubbles: true,
            detail: { audio },
          }),
        );
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
    this.button?.setAttribute("aria-pressed", String(listening));
    for (const pulse of this.pulses) pulse.hidden = !listening;
    if (this.mic) this.mic.hidden = listening;
    if (this.stopIcon) this.stopIcon.hidden = !listening;

    this.button?.classList.remove(...(listening ? IDLE_CLASSES : LISTENING_CLASSES));
    this.button?.classList.add(...(listening ? LISTENING_CLASSES : IDLE_CLASSES));
  },
};
