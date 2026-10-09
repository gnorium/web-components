import CSSBuilder
import CSSOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import WebTypes

// A block that can run to any length—a model's reasoning, a prompt with a
// page transcript in it, a tool's dump, a work's pedigree of tens of
// thousands of lines—is capped at `size256` tall and scrolls inside, so the
// page around it stays in view and does not grow with it. Both SERVER and
// CLIENT: session cards are drawn on either side.

/// Cap `selectors` at `height` (256 by default), scrolling overflow inside.
///
/// Cap the scrolling body, not its shell: a capped `<details>` or accordion
/// would clip its own summary too.
@CSSBuilder
public func capHeight(_ selectors: String..., height: CSS.Length = size256) -> [CSSOM.CSSRule] {
  selector(stringJoin(selectors, separator: ", ")) {
    maxHeight(height)
    overflowY(.auto)
  }
}
