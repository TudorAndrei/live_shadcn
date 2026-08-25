defmodule StorybookWeb.Layouts do
  @moduledoc """
  The three layouts the demo application renders in.

  `root` carries the shadcn style class, because every `cn-` rule is nested
  inside `.style-<name>` in the sheet upstream publishes. Choosing a style is
  therefore a class on the document, exactly as it is on ui.shadcn.com.

  `docs` is the documentation shell: a sidebar, a header and a content column,
  built out of the components it documents.

  `app` carries nothing but the page. `PreviewLive` renders in it, and
  `mix ui.verify` runs axe-core against those pages — so a violation there has
  to belong to the component rather than to any chrome around it. That is why
  the documentation shell is a second layout rather than a change to this one.
  """

  use StorybookWeb, :html

  import LiveShadcn.UI.Separator
  import LiveShadcn.UI.Sidebar

  alias StorybookWeb.Docs

  embed_templates "layouts/*"

  @doc "The shadcn style the demo renders in, from `mix ui.fetch`."
  def style, do: Application.get_env(:storybook, :style, "vega")
end
