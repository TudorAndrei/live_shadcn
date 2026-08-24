defmodule LiveBase.Sidebar do
  @moduledoc """
  The behavior behind a navigation panel that collapses.

  ## Why there is no hook

  Every other module here owns something a `JS` command cannot express: a
  measurement, a timed attribute, a floating position, a roving focus. A
  sidebar owns none of them.

  What a sidebar is, is one attribute. `data-state` is `expanded` or
  `collapsed`, and every class string shadcn writes for it keys off that
  through the group it sits on — `group-data-[collapsible=icon]:w-…`,
  `group-data-[collapsible=offcanvas]:w-0`. Widths, offsets, which way the
  rail's cursor points: all of it is CSS reading one attribute. So flipping
  the attribute is the whole of the behavior, and `JS.toggle_attribute/2`
  flips attributes.

  The approach is Salad UI's (MIT, github.com/bluzky/salad_ui), which reaches
  the same place from the Radix-era markup: a `data-state` on a root and no
  JavaScript at all.

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | sidebar | `data-state` | `expanded` or `collapsed`, always one |
  | sidebar | `data-collapsible` | the collapse mode while collapsed, empty while expanded |
  | trigger | `aria-expanded` | `true` while the sidebar is expanded |

  `data-collapsible` carries the mode rather than a presence, because shadcn
  writes two collapse modes and styles them differently: `icon` leaves a strip
  of icons behind and `offcanvas` leaves nothing. Upstream computes it as
  `state === "collapsed" ? collapsible : ""`, so it is the mode *while
  collapsed* and empty otherwise — one attribute saying both whether and how.

  ## What the server knows

  Nothing, and that is deliberate. Whether a reader has the navigation open is
  a fact about their window, not about the application's data. Opening it
  costs no round trip and survives no reload, which is the same trade the
  disclosure recipe makes.
  """

  alias Phoenix.LiveView.JS

  @doc """
  Expands the sidebar if it is collapsed, collapses it if it is expanded.

  ## Options

    * `:sidebar` — required, the sidebar's id
    * `:collapsible` — the mode to write into `data-collapsible` while
      collapsed. Defaults to `"offcanvas"`, which is shadcn's own default.

  Both attributes flip together. They have to: a sidebar with `data-state`
  saying collapsed and `data-collapsible` saying nothing has no width rule to
  match, and draws at full width with its content hidden.
  """
  def toggle(js \\ %JS{}, opts) do
    sidebar = Keyword.fetch!(opts, :sidebar)
    collapsible = Keyword.get(opts, :collapsible, "offcanvas")

    js
    |> JS.toggle_attribute({"data-state", "collapsed", "expanded"}, to: "##{sidebar}")
    |> JS.toggle_attribute({"data-collapsible", collapsible, ""}, to: "##{sidebar}")
    |> JS.toggle_attribute({"aria-expanded", "false", "true"}, to: trigger(sidebar))
  end

  @doc """
  Every element that opens this sidebar.

  A sidebar has two: the button in the header and the rail down its edge. Both
  flip the same attribute, so both report the same state, and a selector is how
  one command reaches both without either knowing about the other.
  """
  def trigger(sidebar), do: "[data-lb-sidebar='#{sidebar}']"

  @doc """
  The attributes the client owns once the page is live.

  `data-state` and the two that move with it are flipped in the browser and
  never re-rendered from the server, so a patch that re-rendered the sidebar
  would otherwise put it back the way it was first drawn.
  """
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :sidebar),
    do: JS.ignore_attributes(js, ["data-state", "data-collapsible"], [])

  def owned_attributes(js, :trigger), do: JS.ignore_attributes(js, ["aria-expanded"], [])
end
