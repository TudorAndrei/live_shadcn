import { Calendar } from "@upstream/shadcn/ui/calendar";

// Ported from `StorybookWeb.Examples.calendar_default/1`.
export default function CalendarDefault() {
  return <Calendar month={new Date(2026, 3, 1)} selected={new Date(2026, 3, 15)} className="max-w-md" />;
}
