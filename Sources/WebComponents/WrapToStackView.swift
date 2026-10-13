import HTMLBuilder

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes
#endif

// A row of children that may not fit on one line—a button group, a page's
// links, a from → to header—is marked `data-wrap-stacked="true"` while its
// children, side by side with the row's column gap between them, are wider
// than the room the row has, and `"false"` while they fit. Each row answers
// in its own CSS: a button group stretches its buttons into a column, the
// home links stack centered, a comparison header stacks with its arrow
// turned down. Both SERVER and CLIENT: the mark is rendered with the row,
// and `WrapToStackViewHydration` keeps it current.
//
// The measure is the children's summed widths against the row's own width,
// not whether they have already wrapped (their `offsetTop`s): it says the
// same however the row is laid out at that moment. A stacked row's CSS may
// change its children's widths (a stretched button is the row's full width),
// so the row is measured with the mark set `"false"` first, as it lays out
// unstacked, and only then marked: the mark is never sticky.
//
// Without the hydration (the server render, no script) the mark stays
// `"false"`: a row that may not fit should wrap (`flex-wrap: wrap`) in its
// unstacked style, so it never runs off the page.
// No vertical writing mode is handled yet: the measure is the inline axis of
// horizontal text.

extension HTMLElementBuildable {
  /// Mark this row `data-wrap-stacked` while its children don't fit on one line
  /// (`WrapToStackViewHydration`); style its stacked layout under
  /// `&[data-wrap-stacked='true']`.
  public func wrapToStackView() -> Self {
    data("wrap-stacked", false)
  }
}

#if CLIENT
  /// The widths compared are fractional; a row whose children fit within half
  /// a pixel of it fits.
  private let wrapToStackViewSubpixelTolerance = 0.5

  /// Keeps each `data-wrap-stacked` row marked `"true"` while its children, with
  /// the row's column gap between them, are wider than the row, and
  /// `"false"` while they fit; re-measured whenever the row or any child
  /// resizes.
  public enum WrapToStackViewHydration {
    public static func hydrateIfPresent() {
      for row in document.querySelectorAll("[data-wrap-stacked]") {
        let children = row.querySelectorAll(":scope > *")
        let measure: @Sendable () -> Void = {
          row.setAttribute(data("wrap-stacked"), "false")
          let gap = parseDouble(stringRemoveSuffix(window.getComputedStyle(row).getPropertyValue("column-gap"), "px")) ?? 0
          var required = gap * Double(max(0, children.count - 1))
          for child in children { required += child.getBoundingClientRect()?.width ?? 0 }
          row.setAttribute(data("wrap-stacked"), required > row.clientWidth + wrapToStackViewSubpixelTolerance ? "true" : "false")
        }
        row.observeResize { _, _ in measure() }
        for child in children { child.observeResize { _, _ in measure() } }
        measure()
      }
    }
  }
#endif
