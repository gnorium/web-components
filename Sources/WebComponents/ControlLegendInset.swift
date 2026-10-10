import CSSBuilder
import CSSOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import WebTypes

// A bordered box whose legend sits on its bottom border is inset 16 on every
// side. When that legend holds a button-size control—a Raw switch, an info
// button, a pager—half the control hangs inside the box, so the box takes
// 24 (16 + 8) at its bottom instead; a legend of text alone keeps the even
// 16 (user, 2026-10-10). Both SERVER and CLIENT: session cards are drawn on
// either side.

/// Inset the bottom of `selectors`—boxes whose bottom legend holds a
/// button-size control—by 24 instead of 16.
///
/// Name the box only when its legend always holds a control; otherwise
/// select it by that control (`&:has(> legend .raw-toggle)`). Call it after
/// the box's own `padding`, which it overrides.
@CSSBuilder
public func controlLegendInset(_ selectors: String...) -> [CSSOM.CSSRule] {
  selector(stringJoin(selectors, separator: ", ")) {
    paddingBlockEnd(spacing24)
  }
}
