defmodule StorybookWeb.Storybook.Root do
  use PhoenixStorybook.Index

  def folder_open?, do: true

  def entry("accordion"), do: [icon: {:fa, "bars-staggered", :thin}]
end
