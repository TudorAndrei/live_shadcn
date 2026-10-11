defmodule LiveShadcnTools.IncrementalVerificationTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.IncrementalVerification

  @layers ~w(interaction behavior accessibility parity pixel)

  test "merges one batch without dropping earlier example evidence" do
    identity = identity(~w(default basic))

    record =
      %{}
      |> IncrementalVerification.merge(identity, "interaction", %{"default" => pass()})
      |> IncrementalVerification.merge(identity, "interaction", %{"basic" => pass()})

    assert get_in(record, ["examples", "default", "interaction", "pass"])
    assert get_in(record, ["examples", "basic", "interaction", "pass"])
  end

  test "does not count evidence after its identity changes" do
    record =
      IncrementalVerification.merge(
        %{},
        identity(["default"], "before"),
        "interaction",
        %{"default" => pass()}
      )

    result = IncrementalVerification.aggregate(record, identity(["default"], "after"))

    refute result["pass"]
    refute result["checks"]["browser"]["pass"]
    assert result["checks"]["interaction"]["detail"] =~ "identity changed"
  end

  test "a failure replaces an earlier pass for the same example and layer" do
    identity = identity(["default"])

    record =
      %{}
      |> IncrementalVerification.merge(identity, "pixel", %{"default" => pass()})
      |> IncrementalVerification.merge(identity, "pixel", %{"default" => fail("4 pixels differ")})

    result = IncrementalVerification.aggregate(record, identity)

    refute result["checks"]["pixel"]["pass"]
    assert result["checks"]["pixel"]["detail"] =~ "4 pixels differ"
  end

  test "requires every layer for every current example" do
    identity = identity(["default"])

    record =
      Enum.reduce(@layers -- ["pixel"], %{}, fn layer, record ->
        IncrementalVerification.merge(record, identity, layer, %{"default" => pass()})
      end)

    result = IncrementalVerification.aggregate(record, identity)

    refute result["pass"]
    assert result["checks"]["pixel"]["detail"] =~ "missing"
  end

  test "requires evidence for a new official example and removes retired examples" do
    old_identity = identity(~w(default retired))

    old_record =
      Enum.reduce(@layers, %{}, fn layer, record ->
        IncrementalVerification.merge(record, old_identity, layer, %{
          "default" => pass(),
          "retired" => pass()
        })
      end)

    current_identity = identity(~w(default new))

    record =
      IncrementalVerification.merge(old_record, current_identity, "interaction", %{
        "default" => pass()
      })

    result = IncrementalVerification.aggregate(record, current_identity)

    refute result["pass"]
    refute Map.has_key?(record["examples"], "retired")
    assert result["checks"]["interaction"]["detail"] =~ "new"
  end

  test "accepts complete evidence for all twelve Calendar routes" do
    examples =
      ~w(default hijri basic multiple range caption presets time booked-dates custom-days week-numbers rtl)

    identity = identity(examples)

    record =
      Enum.reduce(@layers, %{}, fn layer, record ->
        results = Map.new(examples, &{&1, pass()})
        IncrementalVerification.merge(record, identity, layer, results)
      end)

    assert IncrementalVerification.aggregate(record, identity)["pass"]
  end

  test "rejects out-of-scope examples during merge" do
    identity = identity(["default"])

    assert_raise ArgumentError, ~r/out-of-scope examples: basic/, fn ->
      IncrementalVerification.merge(%{}, identity, "interaction", %{
        "default" => pass(),
        "basic" => pass()
      })
    end
  end

  test "AI evidence needs authored behavior and accessibility for every example" do
    identity = identity(~w(default contract)) |> Map.put("source", "ai_elements")

    record =
      IncrementalVerification.merge(%{}, identity, "behavior", %{
        "default" => pass(),
        "contract" => pass()
      })

    refute IncrementalVerification.aggregate(record, identity)["pass"]

    record =
      IncrementalVerification.merge(record, identity, "accessibility", %{
        "default" => pass(),
        "contract" => pass()
      })

    assert IncrementalVerification.aggregate(record, identity)["pass"]

    assert_raise ArgumentError, ~r/unknown incremental verification layer/, fn ->
      IncrementalVerification.merge(record, identity, "parity", %{"default" => pass()})
    end
  end

  defp identity(examples, evidence \\ "current") do
    %{"evidence" => evidence, "examples" => examples}
  end

  defp pass, do: %{"pass" => true}
  defp fail(detail), do: %{"pass" => false, "detail" => detail}
end
