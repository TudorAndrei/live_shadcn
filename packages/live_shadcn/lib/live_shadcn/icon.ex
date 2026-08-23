defmodule LiveShadcn.Icon do
  @moduledoc """
  The one indirection every generated component points at for an icon.

  shadcn does not name a single icon library. Its registry sources render an
  `IconPlaceholder` that carries a name for each of five sets:

      lucide="ChevronDownIcon"  tabler="IconChevronDown"  phosphor="CaretDownIcon"
      hugeicons="ArrowDown01Icon"  remixicon="RiArrowDownSLine"

  The generator records all five in the spec and asks for the lucide name,
  because that is the name shadcn's own documentation uses. Which set actually
  draws it is the application's decision.

  ## Lucide, by default

  Add `lucide_icons` to your dependencies and icons draw themselves:

      {:lucide_icons, "~> 2.3"}

  It is an optional dependency, so nothing is pulled in for an application that
  wants a different set.

  ## Any other set

      config :live_shadcn, :icon, {MyAppWeb.Icons, :render}

  The configured function is a function component. It is given `:name` — the
  lucide name in kebab case, without the `Icon` suffix — plus the class string
  and the `data-slot` the spec recorded. Map that name onto your own set.

  ## With neither

  An icon renders as an empty, decorative `<span>` carrying its class string and
  its name. The layout and the state variants shadcn styles the icon with —
  `group-aria-expanded/accordion-trigger:hidden` and the rest — all still work,
  because they key on the class string and the ancestor's attributes rather than
  on the glyph. Only the glyph is missing.
  """

  use Phoenix.Component

  # Optional, so an application that uses a different set never loads it.
  @compile {:no_warn_undefined, Lucideicons}

  attr(:name, :string, required: true, doc: "The lucide icon name, in kebab case.")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(data-slot))

  @doc """
  Renders an icon through the configured icon component.

  An icon inside a control is decorative: the control is already labelled, and
  a second announcement of the same thing is noise. So every path here hides it
  from assistive technology, and a replacement is expected to do the same.
  """
  def icon(assigns) do
    case Application.get_env(:live_shadcn, :icon, :lucide) do
      {module, function} -> apply(module, function, [assigns])
      :lucide -> lucide(assigns)
      :placeholder -> placeholder(assigns)
    end
  end

  # Lucideicons turns every assign into an SVG attribute, so it is handed a flat
  # map of attributes rather than a component's assigns: a `:global` map nested
  # inside one would be written out as a single attribute called `rest`.
  defp lucide(assigns) do
    if Code.ensure_loaded?(Lucideicons) do
      assigns
      |> Map.get(:rest, %{})
      |> Map.new(fn {name, value} -> {attribute(name), value} end)
      |> Map.merge(%{
        :"aria-hidden" => "true",
        :name => assigns.name,
        # A function component is called with change tracking, and Lucideicons
        # is one, so its assigns have to carry the same marker.
        :__changed__ => assigns[:__changed__]
      })
      |> put_class(assigns[:class])
      |> then(&apply(Lucideicons, :render, [&1]))
    else
      placeholder(assigns)
    end
  end

  # Lucideicons keys its attributes by atom. The names come from generated
  # markup rather than from user input, so the set of them is fixed at compile
  # time and cannot grow at runtime.
  defp attribute(name) when is_atom(name), do: name
  defp attribute(name), do: String.to_atom(name)

  defp put_class(attrs, nil), do: attrs
  defp put_class(attrs, class), do: Map.put(attrs, :class, class)

  defp placeholder(assigns) do
    ~H"""
    <span class={@class} data-icon={@name} aria-hidden="true" {@rest}></span>
    """
  end
end
