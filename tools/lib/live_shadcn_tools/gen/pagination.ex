defmodule LiveShadcnTools.Gen.Pagination do
  @moduledoc """
  The pagination recipe.

  A pagination link is a Button rendered as an anchor. The presentational
  recipe can read its anchor, but it cannot carry the Button class table.
  """

  alias LiveShadcnTools.Gen.Presentational

  @doc "The module source for one pagination component."
  def module(spec, opts) do
    spec
    |> Presentational.module(opts)
    |> String.replace(~s| variant={if(@is_active, do: "outline", else: "ghost")}|, "",
      global: false
    )
    |> String.replace(~s| size={@size}|, "", global: false)
    |> String.replace(~s| nativeButton={false}|, "", global: false)
    |> String.replace(
      ~s| class="cn-pagination-link"|,
      ~s| class={["cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0", button_class("size", @size), button_class("variant", if(@is_active, do: "outline", else: "ghost")), "cn-pagination-link", @class]}|,
      global: false
    )
    |> String.replace_suffix("end\n", helpers())
  end

  defp helpers do
    """
      @pagination_button_variants %{
        "size" => %{
          "default" => "cn-button-size-default",
          "icon" => "cn-button-size-icon",
          "icon-lg" => "cn-button-size-icon-lg",
          "icon-sm" => "cn-button-size-icon-sm",
          "icon-xs" => "cn-button-size-icon-xs",
          "lg" => "cn-button-size-lg",
          "sm" => "cn-button-size-sm",
          "xs" => "cn-button-size-xs"
        },
        "variant" => %{
          "default" => "cn-button-variant-default",
          "destructive" => "cn-button-variant-destructive",
          "ghost" => "cn-button-variant-ghost",
          "link" => "cn-button-variant-link",
          "outline" => "cn-button-variant-outline",
          "secondary" => "cn-button-variant-secondary"
        }
      }

      defp button_class(group, value), do: get_in(@pagination_button_variants, [group, value])
    end
    """
  end
end
