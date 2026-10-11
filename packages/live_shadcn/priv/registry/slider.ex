defmodule LiveShadcn.UI.Slider do
  @moduledoc """
  Slider. Groups all parts of the slider.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Slider/class/0" => "data-horizontal:w-full data-vertical:h-full",
    "jsx/Slider/class/1" =>
      "cn-slider relative flex w-full touch-none items-center select-none data-disabled:opacity-50 data-vertical:h-full data-vertical:w-auto data-vertical:flex-col",
    "jsx/Slider/class/2" => "cn-slider-track relative grow overflow-hidden select-none",
    "jsx/Slider/class/3" =>
      "cn-slider-range select-none data-horizontal:h-full data-vertical:w-full",
    "jsx/Slider/class/4" =>
      "cn-slider-thumb block shrink-0 select-none disabled:pointer-events-none disabled:opacity-50"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Slider

  @doc """
  A value between two ends, chosen by dragging.

      <.slider id="price" name="price" value={[20, 80]} />

  One `<input type="range">` per thumb, drawn. The input is what a reader
  drags, what a keyboard moves, what a screen reader announces and what a
  form submits — so `phx-change` on the form around it reports the value
  the same way a text field does, and this component has no event of its
  own.
  """

  attr(:id, :string, required: true, doc: "The hook needs one, and each input derives its own.")
  attr(:name, :string, default: nil, doc: "What the form submits every value under.")

  attr(:value, :any,
    default: nil,
    doc: "A scalar makes one thumb. A list supplies one value per thumb."
  )

  attr(:thumb_count, :integer,
    default: 1,
    doc:
      "A positive number of operable thumbs for one scalar value. Each thumb controls the same value. Lists keep one thumb per value and require the default count."
  )

  attr(:min, :any, default: 0)
  attr(:max, :any, default: 100)
  attr(:step, :any, default: 1)
  attr(:disabled, :boolean, default: false)
  attr(:label, :string, default: nil, doc: "Names each thumb to a screen reader.")
  attr(:on_change, :string, default: nil, doc: "A LiveView change event for each range input.")

  attr(:orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"]
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)

  def slider(assigns) do
    unless is_integer(assigns.thumb_count) and assigns.thumb_count > 0 do
      raise ArgumentError, "thumb_count must be a positive integer"
    end

    if assigns.thumb_count != 1 and (is_nil(assigns.value) or is_list(assigns.value)) do
      raise ArgumentError, "thumb_count can duplicate only a scalar value"
    end

    {scalar?, values} =
      case assigns.value do
        nil -> {false, [assigns.min, assigns.max]}
        value when is_list(value) -> {false, value}
        value -> {true, List.duplicate(value, assigns.thumb_count)}
      end

    assigns =
      assigns
      |> assign(:scalar?, scalar?)
      |> assign(:values, values)

    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "slider"}
      role="group"
      id={@id}
      phx-hook={Slider.hook()}
      phx-mounted={Slider.owned_attributes()}
      data-lb-slider-scalar={flag(@scalar?)}
      data-lb-change-event={@on_change}
      data-orientation={@orientation}
      data-disabled={flag(@disabled)}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/Slider/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div
        data-orientation={@orientation}
        data-disabled={flag(@disabled)}
        class={upstream_fact("jsx/Slider/class/1")}
      >
        <div
          data-slot="slider-track"
          data-orientation={@orientation}
          data-disabled={flag(@disabled)}
          class={upstream_fact("jsx/Slider/class/2")}
        >
          <div
            data-slot="slider-range"
            data-lb-slider-range
            data-orientation={@orientation}
            data-disabled={flag(@disabled)}
            class={upstream_fact("jsx/Slider/class/3")}
          />
        </div>
        <div
          :for={index <- 0..(length(@values) - 1)//1}
          data-slot="slider-thumb"
          data-index={if(@scalar?, do: 0, else: index)}
          data-lb-slider-thumb
          style="position: absolute"
          data-orientation={@orientation}
          data-disabled={flag(@disabled)}
          class={upstream_fact("jsx/Slider/class/4")}
        >
          <input
            type="range"
            id={Slider.input_id(@id, index)}
            name={@name}
            value={Enum.at(@values, index)}
            min={@min}
            max={@max}
            step={@step}
            disabled={@disabled}
            aria-label={@label}
            data-lb-slider-input
            class="absolute inset-0 size-full cursor-pointer opacity-0 disabled:cursor-not-allowed"
          />
        </div>
      </div>
    </div>
    """
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end
