import { Button } from "@upstream/shadcn/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@upstream/shadcn/ui/card";

// Ported from `StorybookWeb.Examples.card_default/1`.
export default function CardDefault() {
  return (
    <Card className="max-w-sm">
      <CardHeader>
        <CardTitle>Accordion</CardTitle>
        <CardDescription>Generated from registry/spec/accordion.json.</CardDescription>
      </CardHeader>
      <CardContent>Every class string came from upstream. Nothing here was typed by a person.</CardContent>
      <CardFooter><Button size="sm">Read the spec</Button></CardFooter>
    </Card>
  );
}
