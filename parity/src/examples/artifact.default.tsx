import {
  Artifact,
  ArtifactClose,
  ArtifactContent,
  ArtifactDescription,
  ArtifactHeader,
  ArtifactTitle,
} from "@upstream/ai_elements/artifact";

// Ported from `StorybookWeb.Examples.artifact_default/1`.
export default function ArtifactDefault() {
  return (
    <Artifact className="max-w-md">
      <ArtifactHeader>
        <div>
          <ArtifactTitle>accordion.ex</ArtifactTitle>
          <ArtifactDescription>
            Generated from registry/spec/shadcn/accordion.json
          </ArtifactDescription>
        </div>
        <ArtifactClose />
      </ArtifactHeader>
      <ArtifactContent>
        Four functions, one hook, and no class string typed by a person.
      </ArtifactContent>
    </Artifact>
  );
}
