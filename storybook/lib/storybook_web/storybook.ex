defmodule StorybookWeb.Storybook do
  @moduledoc """
  The storybook backend.

  `sandbox_class` is the shadcn style class. Every `cn-` rule upstream publishes
  is nested inside `.style-<name>`, so putting that class on the sandbox is what
  makes a component in the storybook look like the same component on
  ui.shadcn.com.
  """

  use PhoenixStorybook,
    otp_app: :storybook,
    content_path: Path.expand("../../storybook", __DIR__),
    js_path: "/assets/storybook.js",
    css_path: "/assets/storybook.css",
    sandbox_class: "style-vega",
    title: "live_shadcn",
    color_mode: true,
    color_mode_sandbox_dark_class: "dark"
end
