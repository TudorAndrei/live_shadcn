import { Button } from "@upstream/shadcn/ui/button";
import { Alert, AlertAction, AlertDescription, AlertTitle } from "@upstream/shadcn/ui/alert";

// Ported from `StorybookWeb.Examples.alert_default/1`.
export default function AlertDefault() {
  return (
    <Alert className="max-w-md">
      <AlertTitle>Upstream moved</AlertTitle>
      <AlertDescription>Four class strings changed and one component is new.</AlertDescription>
      <AlertAction>
        <Button variant="outline" size="sm">
          Review
        </Button>
      </AlertAction>
    </Alert>
  );
}
