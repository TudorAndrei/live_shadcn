defmodule LiveShadcn do
  @moduledoc """
  shadcn/ui components for Phoenix LiveView.

  Components are not called from this dependency. `mix ui.add` copies their
  source into your own application, the way the shadcn CLI does, so you own and
  can edit every file:

      mix ui.add button dialog
      #=> lib/my_app_web/components/ui/button.ex   (registry ac60ef5)
      #=> lib/my_app_web/components/ui/dialog.ex   (registry ac60ef5)

  `mix ui.sync` later compares each installed file against the registry, reports
  what changed upstream, and skips files you have edited.

  This package holds the registry, the two mix tasks, and the styling layer. The
  behavior lives in `LiveBase`.
  """
end
