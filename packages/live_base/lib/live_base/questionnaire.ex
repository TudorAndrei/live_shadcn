defmodule LiveBase.Questionnaire do
  @moduledoc "The client controller for a multi-step questionnaire."

  @hook "LiveBase.Questionnaire"

  @doc "The client hook name the questionnaire root declares."
  def hook, do: @hook
end
