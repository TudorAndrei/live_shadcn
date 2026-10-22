"use client";

import { Calendar } from "@upstream/shadcn/ui/calendar";
import { Card, CardContent } from "@upstream/shadcn/ui/card";

// The pinned Calendar example keeps this function private. Render its body
// without the documentation wrapper, as the Storybook example does.
export function CalendarMultiple() {
  return (
    <Card className="mx-auto w-fit p-0">
      <CardContent className="p-0">
        <Calendar mode="multiple" />
      </CardContent>
    </Card>
  );
}
