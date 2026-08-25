import { Plan, PlanContent, PlanTrigger } from "@upstream/ai_elements/plan";

// Ported from `StorybookWeb.Examples.plan_default/1`.
//
// `title` is what the disclosure recipe calls the trigger's content, and
// upstream's trigger draws the chevron and a screen-reader label around it.
// `keepMounted` for the same reason every other collapsible reference passes it:
// Base UI unmounts a closed panel where the recipe hides it, so a hook can
// measure the height a class string interpolates.
export default function PlanDefault() {
  return (
    <Plan className="max-w-md">
      <PlanTrigger>Three steps to a verified component</PlanTrigger>
      <PlanContent keepMounted>Read the source, write the spec, generate the module.</PlanContent>
    </Plan>
  );
}
