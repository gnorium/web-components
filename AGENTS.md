# Repository guidance

This directory is its own Git repository. The parent Gnorium workspace is not a repository; run Git commands here and inspect sibling repositories separately.

- Preserve unrelated working changes. When renaming an internal API, update callers in sibling packages rather than leave obsolete aliases.
- Run focused checks for the changed behavior. Do not run full server/browser suites unless requested.
- Keep build caches and `.build` directories. Diagnose build/toolchain errors before rebuilding; do not wipe caches to troubleshoot.
- Batch related changes before building. Deployment requires an explicit user request; a local build or server restart is not deployment.
- If committing authorized work, omit attribution trailers and push normally after the commit; never force-push.

## Interface rules

- Use existing components and semantic design tokens. Use logical CSS properties for direction-aware layout, flex gaps for spacing, equal padding, and the four-unit spacing grid.
- A reusable view belongs in its own file. Its root owns the type's kebab-case class; descendant classes omit the redundant `-view` segment.
- Use semibold for emphasis. Icons fit their long edge tightly; an icon beside a label uses that label's type size.
- Controls use base borders; decorative grouping uses subtle borders. State rings are a 1px border plus a 1px outline of the same color, never a box shadow.
- Diff additions are green, modifications orange, removals red. Find highlights remain yellow. A green check denotes success/acceptance/commitment; Apply remains a text action.
- Tooltip containers and info icons are neutral. Only the UUID link inside the tooltip is blue; keep format controls and identifier tooltips compact on the bottom-left border legend.
- Format controls are `XMLToggleButtonView`, `JSONToggleButtonView`, and `MarkdownToggleButtonView`. Code mode is where editing occurs; rendered mode is a preview. Disabled controls do not change color on hover.
- Show unknown values as an em dash; empty text/code stays empty. Placeholders match labels. Use American spelling for UI and code; quoted source text stays unchanged.

## Embedded Swift client

- CLIENT-reachable code includes unguarded helpers called by hydration. Use `EmbeddedSwiftUtilities` string helpers rather than Unicode normalization, String-keyed dictionaries/sets, or String equality/hash operations.
- Prefer pattern matching for optional strings and String-backed enums. Diagnose undefined WASM symbols from their call sites instead of guessing or clearing caches.
- Separate DOM queries return fresh Swift wrappers. Compare the bridge's stable numeric node IDs, not Swift reference identity (`===`).
- Add missing standard browser APIs to the bridge and typed API packages rather than simulate them in views.

## Shared components

These components are a reusable library; an unreferenced component is not evidence that it should be deleted. Keep source-specific components in separate files and update all callers when renaming them.

Read-only syntax coloring can be emitted in safe HTML spans. Editable code must preserve caret, selection, and undo; do not rewrite its contents just to color it. Line-based diff synchronization must move the boxes only and suppress scroll echoes.
