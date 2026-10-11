defmodule LiveShadcnTools.VerificationPolicy do
  @moduledoc """
  States the small set of reviewed components that cannot use normal React
  comparison evidence.

  A policy is explicit evidence. It is not a passing parity or pixel result.
  """

  @policy_path Path.expand("../../../registry/VERIFICATION_POLICY.json", __DIR__)
  @external_resource @policy_path
  @policy_data @policy_path |> File.read!() |> Jason.decode!()
  @standard_required_checks get_in(@policy_data, ["_standard", "required_checks"])
  @ai_policy Map.fetch!(@policy_data, "_ai_elements")
  @policies @policy_data
            |> Map.drop(["_standard", "_ai_elements"])
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

              required_checks =
                Map.get(
                  entry,
                  "required_checks",
                  if(kind == :standard, do: @standard_required_checks, else: [])
                )

              fixture = Map.get(entry, "local_fixture")

              {reference,
               %{
                 kind: kind,
                 reason: reason,
                 behavior: behavior,
                 local_fixture: fixture,
                 required_checks: required_checks
               }}
            end)

  @type kind :: :standard | :docs_only | :authored | :local_only | :no_dom
  @type behavior :: :required | {:not_applicable, String.t()}
  @type policy :: %{
          kind: kind(),
          reason: String.t() | nil,
          behavior: behavior(),
          local_fixture: String.t() | nil,
          required_checks: [String.t()]
        }

  @doc "Returns the verification policy for one source component."
  @spec get(String.t(), String.t()) :: policy()
  def get("ai_elements", _name),
    do: %{
      kind: :authored,
      reason: @ai_policy["reason"],
      behavior: :required,
      local_fixture: nil,
      required_checks: @ai_policy["required_checks"]
    }

  def get(source, name),
    do:
      Map.get(@policies, source <> "/" <> name, %{
        kind: :standard,
        reason: nil,
        behavior: :required,
        local_fixture: nil,
        required_checks: @standard_required_checks
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
      kind when kind in [:standard, :authored] -> nil
      kind -> kind
    end
  end

  @doc "The checks that must complete under this policy."
  @spec required_checks(String.t(), String.t()) :: [String.t()]
  def required_checks(source, name), do: get(source, name).required_checks
end
