import { Button } from "@upstream/shadcn/ui/button";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@upstream/shadcn/ui/alert-dialog";

// Ported from `StorybookWeb.Examples.alert_dialog_default/1`.
export default function AlertDialogDefault() {
  return (
    <AlertDialog>
      <AlertDialogTrigger>Publish 0.1.0</AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Publish to hex?</AlertDialogTitle>
          <AlertDialogDescription>A published version cannot be taken back.</AlertDialogDescription>
        </AlertDialogHeader>
        Every check has to have passed first: <code>mix ui.verify</code> on every component.
        <AlertDialogFooter>
          <Button variant="ghost">Not yet</Button>
          <Button>Publish</Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
