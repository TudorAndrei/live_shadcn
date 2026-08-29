import { Task, TaskContent, TaskTrigger } from "@upstream/ai_elements/task";

// Ported from `StorybookWeb.Examples.task_default/1`.
//
// `defaultOpen={false}` and `keepMounted` are both the disclosure recipe's
// contract, said out loud. Upstream's `Task` opens by default and the generated
// component starts closed, so the reference asks for the state the page is in;
// and Base UI unmounts a closed panel where the recipe hides it, because a hook
// has to measure the panel to animate it.
export default function TaskDefault() {
  return (
    <Task className="max-w-80" defaultOpen={false}>
      <TaskTrigger title="Searched the registry" />
      <TaskContent keepMounted>Read 62 component sources and 41 Base UI pages.</TaskContent>
    </Task>
  );
}
