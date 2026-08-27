import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@upstream/shadcn/ui/table";

const stages = [
  ["ui.fetch", "registry/UPSTREAM.json"],
  ["ui.spec", "registry/spec/*.json"],
  ["ui.verify", "registry/VERIFY.json"],
];

// Ported from `StorybookWeb.Examples.table_default/1`.
export default function TableDefault() {
  return (
    <Table className="max-w-lg">
      <TableCaption>What each pipeline stage leaves behind.</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead>Stage</TableHead>
          <TableHead>Output</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {stages.map(([stage, output]) => (
          <TableRow key={stage}>
            <TableCell>{stage}</TableCell>
            <TableCell>{output}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
