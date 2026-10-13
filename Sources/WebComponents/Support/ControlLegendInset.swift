import CSSBuilder
import CSSOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import WebTypes

// A bordered box whose legend sits on its bottom border is inset 16 on every
// side. When that legend holds controls—a Raw switch, an info button, a
// pager, all medium, 40 (user, 2026-10-10)—half a control, 20, hangs inside
// the box, so the box takes 36 (20 + 16) at its bottom instead, its content
// clearing the controls by 16; a legend of text alone keeps the even 16.
// Every such box, control or not, keeps 36 below it (the other 20 the
// controls hang out, and 16), so its hanging legend clears the next box by
// 16 (user, 2026-10-10). Both SERVER and CLIENT: session cards are drawn on
// either side.

/// Keep 36 below `selectors`—boxes whose legend hangs on their bottom
/// border—so the legend clears the next box by 16.
///
/// Call it after the box's own `margin`, which it overrides.
@CSSBuilder
public func bottomLegendSpacing(_ selectors: String...) -> [CSSOM.CSSRule] {
  selector(stringJoin(selectors, separator: ", ")) {
    marginBlockEnd(calc(spacing16 + spacing20))
  }
}

/// Inset the bottom of `selectors`—boxes whose bottom legend holds a
/// medium control—by 36 instead of 16.
///
/// Name the box only when its legend always holds a control; otherwise
/// select it by that control (`&:has(> legend .raw-toggle)`). Call it after
/// the box's own `padding`, which it overrides.
@CSSBuilder
public func controlLegendInset(_ selectors: String...) -> [CSSOM.CSSRule] {
  selector(stringJoin(selectors, separator: ", ")) {
    paddingBlockEnd(calc(spacing16 + spacing20))
  }
}
