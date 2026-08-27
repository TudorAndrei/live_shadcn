import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@upstream/shadcn/ui/accordion";

// Ported from `StorybookWeb.Examples.accordion_multiple/1`.
//
// `openMultiple` is Base UI's default and the reviewed port's `multiple`
// is not, so the storybook example asks for it and this one does not have to.
// It is written out anyway: an example that relies on a default reads as though
// the two sides agreed by accident.
export default function AccordionMultiple() {
  return (
    <Accordion className="max-w-80" openMultiple>
      <AccordionItem>
        <AccordionTrigger>Added</AccordionTrigger>
        <AccordionContent keepMounted>
          The disclosure contract, and the accordion reviewed against it.
        </AccordionContent>
      </AccordionItem>
      <AccordionItem>
        <AccordionTrigger>Changed</AccordionTrigger>
        <AccordionContent keepMounted>
          The spec now records what the shadcn style sheets read, not only the component source.
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
