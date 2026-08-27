import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@upstream/shadcn/ui/accordion";

// Ported from `StorybookWeb.Examples.accordion_states/1`.
//
// Base UI names an item by value and opens it by listing that value; the
// reviewed port takes `open` on the item, because a HEEx slot has no
// value to be named by. The two spellings say the same thing.
export default function AccordionStates() {
  return (
    <Accordion className="max-w-80" openMultiple defaultValue={["open"]}>
      <AccordionItem value="open">
        <AccordionTrigger>Open on first paint</AccordionTrigger>
        <AccordionContent keepMounted>
          The server renders this panel visible, so it is readable before any JavaScript has run.
        </AccordionContent>
      </AccordionItem>
      <AccordionItem disabled value="disabled">
        <AccordionTrigger>Disabled</AccordionTrigger>
        <AccordionContent keepMounted>This panel cannot be opened.</AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
