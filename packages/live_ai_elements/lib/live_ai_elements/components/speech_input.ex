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
      phx-hook="LiveAiElements.SpeechInput"
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
        aria-pressed={to_string(@is_listening)}
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
end
