defmodule LiveShadcnTools.Gen.Pagination do
  @moduledoc "The pagination recipe."

  alias LiveShadcnTools.Gen.Presentational

  @doc "The module source for one pagination component."
  def module(spec, opts) do
    link = Enum.find(spec["parts"], &(&1["name"] == "pagination_link"))

    spec
    |> Presentational.module(
      Keyword.put(opts, :function_overrides, %{"pagination_link" => link_function(link, spec)})
    )
  end

  # Upstream renders a Button as an anchor. The tag is different, but the
  # Button variant table remains the source of its classes.
  defp link_function(part, spec) do
    declarations =
      part
      |> Presentational.attributes(spec)
      |> Enum.map_join("\n", &Presentational.declaration/1)

    """
      @doc "The `pagination_link` part."
    #{declarations}
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global, include: ["data-slot", "href", "target", "rel", "download", "hreflang"]
      slot :inner_block

      def pagination_link(assigns) do
        ~H\"\"\"
        <a
          data-slot={@rest[:"data-slot"] || "pagination-link"}
          aria-current={if(@is_active, do: "page", else: nil)}
          data-active={@is_active}
          class={[
            LiveShadcn.UI.Button.part_class("button"),
            LiveShadcn.UI.Button.variant_class("buttonVariants", "size", @size),
            LiveShadcn.UI.Button.variant_class("buttonVariants", "variant", if(@is_active, do: "outline", else: "ghost")),
            #{inspect(part["tree"]["class"])},
            @class
          ]}
          {Map.drop(@rest, [:"data-slot"])}
        >
          {render_slot(@inner_block)}
        </a>
        \"\"\"
      end
    """
  end
end
