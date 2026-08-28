import { useCallback, useRef, useState } from "react";

import { Transcription, TranscriptionSegment } from "@upstream/ai_elements/transcription";

const AUDIO_SRC =
  "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/ElevenLabs_2025-11-10T22_10_24_Hayden_pvc_sp110_s50_sb75_se0_b_m2.mp3";

const SEGMENTS = [
  { startSecond: 0.119, endSecond: 0.219, text: "You" },
  { startSecond: 0.259, endSecond: 0.439, text: "can" },
  { startSecond: 0.459, endSecond: 0.699, text: "build" },
  { startSecond: 0.72, endSecond: 0.799, text: "and" },
  { startSecond: 0.879, endSecond: 1.339, text: "host" },
  { startSecond: 1.36, endSecond: 1.539, text: "many" },
  { startSecond: 1.6, endSecond: 1.86, text: "different" },
  { startSecond: 1.899, endSecond: 2.099, text: "types" },
  { startSecond: 2.119, endSecond: 2.2, text: "of" },
  { startSecond: 2.259, endSecond: 2.96, text: "applications" },
  { startSecond: 3.48, endSecond: 3.699, text: "from" },
  { startSecond: 3.779, endSecond: 4.099, text: "static" },
  { startSecond: 4.179, endSecond: 4.519, text: "sites" },
  { startSecond: 4.539, endSecond: 4.759, text: "with" },
  { startSecond: 4.799, endSecond: 4.939, text: "your" },
  { startSecond: 4.96, endSecond: 5.219, text: "favorite" },
  { startSecond: 5.319, endSecond: 5.939, text: "framework," },
  { startSecond: 5.96, endSecond: 6.519, text: "multi-tenant" },
  { startSecond: 6.559, endSecond: 7.259, text: "applications" },
  { startSecond: 7.699, endSecond: 7.759, text: "or" },
  { startSecond: 7.859, endSecond: 8.739, text: "micro-frontends" },
  { startSecond: 8.78, endSecond: 8.96, text: "to" },
  { startSecond: 9.099, endSecond: 9.779, text: "AI-powered" },
  { startSecond: 9.82, endSecond: 10.439, text: "agents." },
];

// Ported from the pinned AI Elements Transcription example. The source uses a
// native audio element, drives the current segment from its playhead, and seeks
// when a segment is selected.
export default function TranscriptionDefault() {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [currentTime, setCurrentTime] = useState(0);

  const seek = useCallback((time: number) => {
    if (audioRef.current) audioRef.current.currentTime = time;
  }, []);

  return (
    <div className="space-y-6 p-6">
      <audio
        aria-describedby="transcription-copy"
        controls
        id="transcription-audio"
        onTimeUpdate={() => setCurrentTime(audioRef.current?.currentTime ?? 0)}
        preload="metadata"
        ref={audioRef}
      >
        <source src={AUDIO_SRC} type="audio/mpeg" />
      </audio>
      <Transcription
        currentTime={currentTime}
        id="transcription-copy"
        onSeek={seek}
        segments={SEGMENTS}
      >
        {(segment, index) => (
          <TranscriptionSegment
            className="text-lg"
            index={index}
            key={`${segment.startSecond}-${segment.endSecond}`}
            segment={segment}
          />
        )}
      </Transcription>
    </div>
  );
}
