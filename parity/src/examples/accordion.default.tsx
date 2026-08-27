import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@upstream/shadcn/ui/accordion";

// Ported from `StorybookWeb.Examples.accordion_default/1`.
//
// The reviewed port takes one `id` and derives every id inside it; Base
// UI generates its own. Ids are among the things the comparison never looks at,
// for exactly that reason.
//
// `keepMounted` because the reviewed port always keeps the panel: it
// hides it and lets a client hook measure it, which is how the panel animates
// to its own height. Base UI unmounts by default, and a page with no panel in
// it has nothing to compare. Both sides have to be asked for the same thing.
export default function AccordionDefault() {
  return (
    <Accordion className="max-w-80">
      <AccordionItem>
        <AccordionTrigger>What is Base UI?</AccordionTrigger>
        <AccordionContent keepMounted>
          Base UI is a library of unstyled components for design systems and web apps.
        </AccordionContent>
      </AccordionItem>
      <AccordionItem>
        <AccordionTrigger>How do I get started?</AccordionTrigger>
        <AccordionContent keepMounted>
          Read the quick start guide. If you have used unstyled libraries before, you will feel at
          home.
        </AccordionContent>
      </AccordionItem>
      <AccordionItem>
        <AccordionTrigger>Can I use it for my project?</AccordionTrigger>
        <AccordionContent keepMounted>
          Of course. Base UI is free and open source.
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
}
