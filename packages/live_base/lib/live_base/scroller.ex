defmodule LiveBase.Scroller do
  @moduledoc """
  The behavior behind a scroll area whose scrollbar the style sheet can reach.

  ## What the hook owns

  All of it, and that is unusual here. Every other module in this package puts
  the decision in a `Phoenix.LiveView.JS` command on the server and keeps the
  hook for the one thing a command cannot express. A scroll area has no
  decision: it has a measurement, and then another one every time the reader
  moves.

  How much there is to scroll, how far down they are, how tall the thumb should
  be — the server knows none of it and never will. So the hook measures and
  writes, and the class strings shadcn already wrote read what it writes.

  ## The attribute contract

  | Attribute | When |
  |---|---|
  | `data-has-overflow-x` | there is more content than fits, across |
  | `data-has-overflow-y` | the same, down |
  | `data-overflow-x-start` | content is hidden off the start edge |
  | `data-overflow-x-end` | …off the end edge |
  | `data-overflow-y-start` | the same, above |
  | `data-overflow-y-end` | the same, below |
  | `data-scrolling` | while the reader is scrolling, and briefly after |

  And six CSS variables: `--scroll-area-thumb-height` and `-width` for the size
  of the thumb, and `--scroll-area-overflow-{x,y}-{start,end}` for how far along
  it is. Base UI documents every one of them, which is why the generated
  component can be held to them.

  ## Why the thumb is never moved directly

  Dragging it scrolls the viewport; scrolling the viewport moves it. One
  direction of travel, so the two can never disagree — a thumb that was moved
  by a drag *and* by the scroll it caused would fight itself at the ends.
  """

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Scroller"

  @doc "The client hook name the root declares in `phx-hook`."
  def hook, do: @hook

  @doc """
  The attributes the client owns once the page is live.

  Every one of them is a measurement, so a patch that re-rendered the scroll
  area would put back what the server guessed on the first paint: nothing
  overflowing and a thumb of no height.
  """
  def owned_attributes(js \\ %JS{}) do
    JS.ignore_attributes(
      js,
      ~w(data-has-overflow-x data-has-overflow-y data-overflow-x-start data-overflow-x-end
         data-overflow-y-start data-overflow-y-end data-scrolling style),
      []
    )
  end
end
