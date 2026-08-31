defmodule StorybookWeb.ProductionImageTest do
  use ExUnit.Case, async: true

  @dockerfile Path.expand("../../Dockerfile", __DIR__)

  test "the production image includes every parity verification input" do
    dockerfile = File.read!(@dockerfile)

    assert dockerfile =~ ~r/^COPY parity \.\/parity$/m
  end
end
