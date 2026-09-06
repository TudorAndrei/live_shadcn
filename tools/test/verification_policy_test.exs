defmodule LiveShadcnTools.VerificationPolicyTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.VerificationPolicy

  test "Sonner is standard because pinned source publishes public examples" do
    assert VerificationPolicy.get("shadcn", "sonner") == %{
             behavior: :required,
             kind: :standard,
             local_fixture: nil,
             reason: nil,
             required_checks:
               ~w(generated snapshot examples browser behavior accessibility parity pixel)
           }

    assert VerificationPolicy.status("shadcn", "sonner") == nil
  end

  test "Direction is no-DOM because it provides context only" do
    assert VerificationPolicy.get("shadcn", "direction") == %{
             behavior: :required,
             kind: :no_dom,
             local_fixture: nil,
             reason: "the component only provides direction context and renders no DOM",
             required_checks: []
           }

    assert VerificationPolicy.status("shadcn", "direction") == :no_dom
  end

  test "ordinary components keep normal verification" do
    assert VerificationPolicy.get("shadcn", "button") == %{
             behavior: :required,
             kind: :standard,
             local_fixture: nil,
             reason: nil,
             required_checks:
               ~w(generated snapshot examples browser behavior accessibility parity pixel)
           }

    assert VerificationPolicy.status("shadcn", "button") == nil
  end

  test "only standard components can enter an upstream comparison batch" do
    components = [{"shadcn", "button"}, {"shadcn", "sonner"}, {"shadcn", "direction"}]

    comparison_components =
      Enum.filter(components, fn {source, name} ->
        VerificationPolicy.get(source, name).kind == :standard
      end)

    assert comparison_components == [{"shadcn", "button"}, {"shadcn", "sonner"}]
  end
end
