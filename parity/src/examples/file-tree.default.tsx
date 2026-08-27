import {
  FileTree,
  FileTreeFile,
  FileTreeFolder,
} from "@upstream/ai_elements/file-tree";

// Ported from `StorybookWeb.Examples.file_tree_default/1`.
//
// Which folders are open is a set the tree root owns upstream, and a folder
// asks it whether its own path is in there. A HEEx component has no ancestor to
// ask, so the folder takes `is_expanded` — which is the same answer every React
// context in this registry gets, and the reason the reference says it once at
// the root and the port says it on the folder.
//
// The reviewed port carries ARIA upstream does not: two `role="group"`,
// a `role="none"`, an `aria-expanded`, and a chevron taken out of the
// accessibility tree. Every one of them follows from the `role="tree"` and
// `role="treeitem"` upstream *does* write, and none of them draws a pixel.
export default function FileTreeDefault() {
  return (
    <FileTree className="max-w-xs" defaultExpanded={new Set(["registry"])}>
      <FileTreeFolder name="registry" path="registry">
        <FileTreeFile name="INVENTORY.json" path="registry/INVENTORY.json" />
        <FileTreeFile name="UPSTREAM.json" path="registry/UPSTREAM.json" />
      </FileTreeFolder>
      <FileTreeFile name="ROADMAP.md" path="ROADMAP.md" />
    </FileTree>
  );
}
