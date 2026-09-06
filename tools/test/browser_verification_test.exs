defmodule LiveShadcnTools.BrowserVerificationTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.BrowserVerification

  test "a skipped or budgeted pixel result cannot pass verification" do
    passing = %{"pass" => true}

    refute BrowserVerification.finalize_pixel(passing, "button.default", {:skipped, "no source"})[
             "pass"
           ]

    refute BrowserVerification.finalize_pixel(passing, "button.default", {:budgeted, 1})[
             "pass"
           ]
  end

  test "an unfinished pixel result cannot pass verification" do
    refute BrowserVerification.finalize_pixel(%{"pass" => true}, "button.default", :pending)[
             "pass"
           ]
  end

  test "a strict zero-budget pixel failure remains a pixel failure" do
    failure = %{
      "pass" => false,
      "detail" => "button / default paints what React paints\ndefault: 42 px differ"
    }

    result = BrowserVerification.finalize_pixel(failure, "button.default", {:budgeted, 0})

    refute result["pass"]
    assert result["detail"] == failure["detail"]
  end
end
