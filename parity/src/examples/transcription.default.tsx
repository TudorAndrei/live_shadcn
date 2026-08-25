import { Transcription, TranscriptionSegment } from "@upstream/ai_elements/transcription";

// Ported from `StorybookWeb.Examples.transcription_default/1`.
//
// Upstream takes the segments as a prop and the children as a function of one;
// the generated component takes each segment where it is drawn, because a HEEx
// slot is content rather than a callback. Both draw the same two.
//
// The times put the playhead before either segment, which is the state a page
// starts in and the one the generated component draws: not active and not past.
const SEGMENTS = [
  { endSecond: 12, startSecond: 10, text: "It is eighteen degrees" },
  { endSecond: 14, startSecond: 12, text: "and clear in Cluj." },
];

export default function TranscriptionDefault() {
  return (
    <Transcription className="max-w-md" segments={SEGMENTS}>
      {(segment, index) => <TranscriptionSegment index={index} key={index} segment={segment} />}
    </Transcription>
  );
}
