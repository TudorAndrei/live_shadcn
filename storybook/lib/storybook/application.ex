defmodule Storybook.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Storybook.PubSub},
      StorybookWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Storybook.Supervisor)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    StorybookWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
