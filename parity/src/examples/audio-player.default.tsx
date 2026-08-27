import {
  AudioPlayer,
  AudioPlayerControlBar,
  AudioPlayerMuteButton,
  AudioPlayerPlayButton,
  AudioPlayerTimeDisplay,
  AudioPlayerTimeRange,
} from "@upstream/ai_elements/audio-player";

// Ported from `StorybookWeb.Examples.audio_player_default/1`.
//
// media-chrome is a set of custom elements, and its React package renders
// them. What the reviewed port writes is those same tags, which is why
// this is a port rather than a second design.
export default function AudioPlayerDefault() {
  return (
    <AudioPlayer className="max-w-md">
      <AudioPlayerControlBar>
        <AudioPlayerPlayButton />
        <AudioPlayerTimeDisplay />
        <AudioPlayerTimeRange />
        <AudioPlayerMuteButton />
      </AudioPlayerControlBar>
    </AudioPlayer>
  );
}
