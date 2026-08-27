import {
  AudioPlayer,
  AudioPlayerControlBar,
  AudioPlayerElement,
  AudioPlayerMuteButton,
  AudioPlayerPlayButton,
  AudioPlayerTimeDisplay,
  AudioPlayerTimeRange,
} from "@upstream/ai_elements/audio-player";

const AUDIO_SRC =
  "https://ejiidnob33g9ap1r.public.blob.vercel-storage.com/ElevenLabs_2025-11-10T22_07_46_Hayden_pvc_sp108_s50_sb75_se0_b_m2.mp3";

// Ported from `StorybookWeb.Examples.audio_player_default/1`.
//
// media-chrome is a set of custom elements, and its React package renders
// them. What the reviewed port writes is those same tags, which is why
// this is a port rather than a second design.
export default function AudioPlayerDefault() {
  return (
    <AudioPlayer className="max-w-md">
      <AudioPlayerElement preload="metadata" src={AUDIO_SRC} />
      <AudioPlayerControlBar>
        <AudioPlayerPlayButton />
        <AudioPlayerTimeDisplay />
        <AudioPlayerTimeRange />
        <AudioPlayerMuteButton />
      </AudioPlayerControlBar>
    </AudioPlayer>
  );
}
