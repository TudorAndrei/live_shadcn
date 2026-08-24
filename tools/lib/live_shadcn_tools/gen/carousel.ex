defmodule LiveShadcnTools.Gen.Carousel do
  @moduledoc """
  The carousel recipe: a scroll-snap viewport with browser-measured controls.

  A carousel is one composition. Its viewport, slides, and previous and next
  controls share its orientation and its measured scroll range, so this recipe
  writes them together instead of exposing parts that can disagree.
  """

  alias LiveShadcnTools.Gen.Heex

  @doc "The module source for one carousel component."
  def module(spec, opts) do
    previous = part!(spec, "carousel_previous")
    next = part!(spec, "carousel_next")

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Carousel

    #{function_doc()}
    #{declarations()}
      def carousel(assigns) do
        ~H\"\"\"
        <div
          id={@id}
          phx-hook={Carousel.hook()}
          data-orientation={@orientation}
          data-slot="carousel"
          class={["relative", @class]}
          role="region"
          aria-roledescription="carousel"
          {@rest}
        >
          {render_slot(@inner_block)}
        </div>
        \"\"\"
      end

      attr :orientation, :string,
        default: "horizontal",
        values: ["horizontal", "vertical"]

      attr :class, :any, default: nil
      attr :rest, :global, include: ["data-slot"]
      slot :inner_block, required: true

      def carousel_content(assigns) do
        ~H\"\"\"
        <div
          data-lb-carousel-viewport
          data-slot="carousel-content"
          class={[
            "overflow-hidden",
            if(@orientation == "horizontal",
              do: "snap-x snap-mandatory scroll-smooth",
              else: "snap-y snap-mandatory scroll-smooth"
            ),
            @class
          ]}
          {@rest}
        >
          <div class={["flex", if(@orientation == "horizontal", do: "-ml-4", else: "-mt-4 flex-col")]}>
            {render_slot(@inner_block)}
          </div>
        </div>
        \"\"\"
      end

      attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
      attr :class, :any, default: nil
      attr :rest, :global, include: ["aria-label", "data-slot"]
      slot :inner_block, required: true

      def carousel_item(assigns) do
        ~H\"\"\"
        <div
          role="group"
          aria-roledescription="slide"
          data-slot="carousel-item"
          class={["min-w-0 shrink-0 grow-0 basis-full snap-start", if(@orientation == "horizontal", do: "pl-4", else: "pt-4"), @class]}
          {@rest}
        >
          {render_slot(@inner_block)}
        </div>
        \"\"\"
      end

      attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
      attr :class, :any, default: nil
      attr :rest, :global, include: ["data-slot"]

    #{control(previous, "previous", "chevron-left")}

      attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
      attr :class, :any, default: nil
      attr :rest, :global, include: ["data-slot"]

    #{control(next, "next", "chevron-right")}
    end
    """
  end

  defp part!(spec, name), do: Enum.find(spec["parts"], &(&1["name"] == name))

  # The controls are Button parts in upstream. Calling Button carries its
  # classes and variant table from its own specification, rather than copying
  # them into this recipe.
  defp control(part, direction, icon) do
    tree = part["tree"]
    [icon_node, label_node] = tree["children"]
    [position] = tree["class_when"]

    """
      def carousel_#{direction}(assigns) do
        ~H\"\"\"
        <LiveShadcn.UI.Button.button
          type="button"
          variant="outline"
          size="icon-sm"
          data-lb-carousel-#{direction}
          data-slot="carousel-#{direction}"
          phx-mounted={Carousel.owned_attributes()}
          class={[
            #{inspect(tree["class"])},
            if(@orientation == "horizontal", do: #{inspect(position["then"])}, else: #{inspect(position["else"])}) ,
            @class
          ]}
          {@rest}
        >
          <LiveShadcn.Icon.icon name=#{inspect(icon)} class=#{inspect(icon_node["class"])} />
          <span class=#{inspect(label_node["class"])}>#{label(label_node)}</span>
        </LiveShadcn.UI.Button.button>
        \"\"\"
      end
    """
  end

  defp label(%{"children" => [%{"value" => value}]}), do: value

  defp declarations do
    """
      attr :id, :string, required: true, doc: "The hook needs one root element."

      attr :orientation, :string,
        default: "horizontal",
        values: ["horizontal", "vertical"],
        doc: "The scroll and slide direction."

      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global, include: ["aria-label", "data-slot"]
      slot :inner_block, required: true, doc: "Use `carousel_item` for each slide."
    """
  end

  defp function_doc do
    ~s'''
      @doc """
      A scroll-snap carousel with previous and next controls.

          <.carousel id="highlights">
            <.carousel_content>
              <.carousel_item>First slide</.carousel_item>
              <.carousel_item>Second slide</.carousel_item>
            </.carousel_content>
            <.carousel_previous />
            <.carousel_next />
          </.carousel>

      The browser owns the scroll position and the disabled state of the two
      controls. Arrow keys move in the carousel's orientation.
      """
    '''
  end

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every class
      string and every `data-slot` below came from upstream. Change the spec
      or the recipe, not this file.
      \"\"\"\
    """
  end
end
