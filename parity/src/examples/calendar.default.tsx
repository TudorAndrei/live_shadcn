import { Calendar } from "@upstream/shadcn/ui/calendar";

// Ported from `StorybookWeb.Examples.calendar_default/1`.
//
// `mode="single"` is what makes the two examples ask the same question.
// Without it react-day-picker draws a read-only month: every day is a bare
// `<td>` with no button in it. The generated calendar always renders a day
// button, because a server-rendered calendar is something a person clicks, so
// a reference without `mode` compares a grid of buttons against a grid of text.
export default function CalendarDefault() {
  return (
    <Calendar
      mode="single"
      month={new Date(2026, 3, 1)}
      selected={new Date(2026, 3, 15)}
      className="max-w-md"
    />
  );
}
