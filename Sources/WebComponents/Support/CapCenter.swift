import CSSBuilder
import CSSOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import WebTypes

/// How far a mark `size` tall rises so its middle stands half a cap height
/// above the baseline: on the middle of the capitals and digits beside it,
/// by the font's own metrics (`cap`), whatever the font.
public func capCenterOffset(_ size: CSS.Length) -> CSS.Length {
  cap(0.5) - size / 2
}

/// Centers each matched mark—an icon, a status dot, `size` tall—on the
/// capitals of the text it sits in (user, 2026-10-10). The text keeps its
/// own line box: nothing is trimmed, wrapped lines keep their leading, and
/// the words beside the mark stay on one baseline.
///
/// Only for a mark SMALLER than its line (user, 2026-10-21), such as an icon
/// at the font size standing in for punctuation. A mark as tall as the line
/// of the text beside it—every icon sized by a line-height token—needs no
/// offset: a line's middle is the capitals' middle (within 0.2px), so its
/// flex row aligns `center` (or `flex-start`, the mark one line tall, where
/// the text wraps and the mark keeps the first line). Here, such a mark's
/// baseline alignment would put its bottom on the text's baseline and push
/// the row's text down by the descent, which the offset then only half
/// undoes.
///
/// An inline mark (inline-block, inline-flex) in a line of text takes
/// `vertical-align: calc(0.5cap - size / 2)`. A flex item ignores
/// `vertical-align`, so with `flexItem` the mark aligns on the row's
/// baseline—a box without text sits its bottom edge there—and moves by the
/// same distance relatively, which leaves the row's layout as it is. Its
/// row aligns its items on their baseline.
@CSSBuilder
public func centerOnCapitals(_ selectors: String..., size: CSS.Length, flexItem: Bool = false) -> [CSSOM.CSSRule] {
  if flexItem {
    selector(stringJoin(selectors, separator: ", ")) {
      alignSelf(.baseline)
      position(.relative)
      insetBlockStart(-capCenterOffset(size))
    }
  } else {
    selector(stringJoin(selectors, separator: ", ")) {
      verticalAlign(capCenterOffset(size))
    }
  }
}
