import { Button } from "@upstream/shadcn/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@upstream/shadcn/ui/dialog";

// Ported from `StorybookWeb.Examples.dialog_default/1`.
export default function DialogDefault() {
  return (
    <Dialog>
      <DialogTrigger>Delete the accordion</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Are you sure?</DialogTitle>
          <DialogDescription>This removes the component and its spec.</DialogDescription>
        </DialogHeader>
        The upstream sources stay where they are. <code>mix ui.spec</code> restores safe upstream
        facts after the port is reviewed.
        <DialogFooter>
          <Button variant="ghost">Cancel</Button>
          <Button variant="destructive">Delete</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
