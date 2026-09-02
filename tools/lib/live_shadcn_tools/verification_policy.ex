defmodule LiveShadcnTools.VerificationPolicy do
  @moduledoc """
  States the small set of reviewed components that cannot use normal React
  comparison evidence.

  A policy is explicit evidence. It is not a passing parity or pixel result.
  """

  @policy_path Path.expand("../../../registry/VERIFICATION_POLICY.json", __DIR__)
  @external_resource @policy_path
  @policies @policy_path
            |> File.read!()
            |> Jason.decode!()
            |> Map.new(fn {reference, %{"kind" => kind, "reason" => reason} = entry} ->
              kind =
                case kind do
                  "local_only" -> :local_only
                  "no_dom" -> :no_dom
                end

              behavior =
                case entry["behavior"] do
                  "not_applicable" -> {:not_applicable, entry["behavior_reason"] || reason}
                  _ -> :required
                end

              {reference, %{kind: kind, reason: reason, behavior: behavior}}
            end)

  @type kind :: :standard | :local_only | :no_dom
  @type behavior :: :required | {:not_applicable, String.t()}
  @type policy :: %{kind: kind(), reason: String.t() | nil, behavior: behavior()}

  @doc "Returns the verification policy for one source component."
  @spec get(String.t(), String.t()) :: policy()
  def get(source, name),
    do:
      Map.get(@policies, source <> "/" <> name, %{
        kind: :standard,
        reason: nil,
        behavior: :required
      })

  @doc "Whether a component needs a mapped interaction suite."
  @spec behavior(String.t(), String.t()) :: behavior()
  def behavior(source, name) do
    case get(source, name) do
      %{kind: :no_dom, reason: reason} -> {:not_applicable, reason}
      %{behavior: behavior} -> behavior
    end
  end

  @doc "Returns the inventory status that an exceptional policy requires."
  @spec status(String.t(), String.t()) :: :local_only | :no_dom | nil
  def status(source, name) do
    case get(source, name).kind do
      :standard -> nil
      kind -> kind
    end
  end
end
