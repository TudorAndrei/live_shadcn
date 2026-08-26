defmodule LiveShadcnTools.LucideTest do
  use ExUnit.Case, async: true

  alias LiveShadcnTools.Lucide

  # The shape of lucide's own declaration: one export line, each icon listed
  # under its canonical name and again under every name it answers to.
  @declaration """
  declare const CircleCheckBig: React.ForwardRefExoticComponent<LucideProps>;
  export { CircleCheckBig, CircleCheckBig as CheckCircle, CircleCheckBig as CheckCircleIcon, Ellipsis, Ellipsis as MoreHorizontal, Ellipsis as MoreHorizontalIcon, Wrench, Wrench as WrenchIcon };
  """

  describe "reading the alias table" do
    test "an alias answers with the name lucide draws" do
      assert Lucide.aliases(@declaration)["CheckCircleIcon"] == "CircleCheckBig"
      assert Lucide.aliases(@declaration)["MoreHorizontalIcon"] == "Ellipsis"
    end

    test "a name that is already canonical answers with itself" do
      assert Lucide.aliases(@declaration)["CircleCheckBig"] == "CircleCheckBig"
    end

    # `WrenchIcon` is the suffixed export of an icon nobody renamed. It has to
    # be in the table too, or the fifty-odd icons that were always right would
    # depend on the caller falling back to the name as written.
    test "the suffixed export of an unrenamed icon is still an alias" do
      assert Lucide.aliases(@declaration)["WrenchIcon"] == "Wrench"
    end

    test "a declaration with no export line reads as an empty table" do
      assert Lucide.aliases("declare const Wrench: unknown;\n") == %{}
    end
  end
end
