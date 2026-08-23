defmodule StorybookWeb.Layouts do
  @moduledoc """
  The two layouts the demo application renders in.

  `root` carries the shadcn style class, because every `cn-` rule is nested
  inside `.style-<name>` in the sheet upstream publishes. Choosing a style is
  therefore a class on the document, exactly as it is on ui.shadcn.com.
  """

  use StorybookWeb, :html

  embed_templates "layouts/*"

  @doc "The shadcn style the demo renders in, from `mix ui.fetch`."
  def style, do: Application.get_env(:storybook, :style, "vega")
end
