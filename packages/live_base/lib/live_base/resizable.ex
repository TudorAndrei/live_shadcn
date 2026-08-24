defmodule LiveBase.Resizable do
  @moduledoc "The browser behavior behind a pointer-resizable panel group."

  @hook "LiveBase.Resizable"

  @doc "The client hook name the group declares."
  def hook, do: @hook
end
