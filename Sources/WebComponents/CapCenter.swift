import CSSBuilder
import CSSOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import WebTypes

/// Trims each matched label's box to its capitals and digits, with the
/// standard `text-box: trim-both cap alphabetic` (user, 2026-10-10): in a
/// flex row with `align-items: center`, a status mark or an icon beside the
/// label then centers on the middle of its capitals and digits, not on the
/// middle of its line box—no nudge, no offset.
///
/// A label that clips its overflow (an edge-faded one, `fadeOverflow`)
/// would clip the ink the trim leaves outside its box—ascenders above the
/// capitals, descenders below the baseline—so `clipsOverflow` gives it one
/// inset (4) of room on both block sides, equal, so the centering holds.
@CSSBuilder
public func trimToCapitals(_ selectors: String..., clipsOverflow: Bool = false) -> [CSSOM.CSSRule] {
  selector(stringJoin(selectors, separator: ", ")) {
    textBox(.trimBoth, .edges(.cap, .alphabetic))
  }
  if clipsOverflow {
    selector(stringJoin(selectors, separator: ", ")) {
      paddingBlock(spacing4)
    }
  }
}
