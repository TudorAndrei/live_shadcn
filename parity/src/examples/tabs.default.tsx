import { Tabs, TabsContent, TabsList, TabsTrigger } from "@upstream/shadcn/ui/tabs";

const tabs = [
  ["fetch", "Fetch", "Pins each upstream repository to a commit and records a digest per file."],
  ["spec", "Spec", "Reads the component source, the Base UI page, and the style sheets into one JSON document."],
  ["gen", "Generate", "Turns that document into a HEEx module. Twice on the same spec gives the same bytes."],
];

// Ported from `StorybookWeb.Examples.tabs_default/1`.
export default function TabsDefault() {
  return (
    <Tabs defaultValue="spec" className="max-w-md">
      <TabsList>
        {tabs.map(([value, label]) => <TabsTrigger key={value} value={value}>{label}</TabsTrigger>)}
      </TabsList>
      {tabs.map(([value, _label, content]) => (
        <TabsContent key={value} value={value} keepMounted>{content}</TabsContent>
      ))}
    </Tabs>
  );
}
