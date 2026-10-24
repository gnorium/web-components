import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// The footer of a paged list (user, 2026-10-24): the range at the start
/// ("1–100 of 1,000"), the pager at the end (`PaginationView`). One row; on
/// a narrow phone, the range over the pager, both centered. Every paged
/// table's footer and both thread sections' are this one component.
public struct PaginationFooterView: HTMLContent {
  public let info: String
  public let pagination: PaginationView?
  public let `class`: String

  /// - Parameters:
  ///   - info: The range text, already written.
  ///   - pagination: The pager, or nil when there is no other page to go to.
  ///   - class: Extra classes on the row.
  public init(info: String, pagination: PaginationView?, class: String = "") {
    self.info = info
    self.pagination = pagination
    self.class = `class`
  }

  public func build() -> DOM.Node {
    div {
      div { info }
        .class("pagination-info")
      if let pagination {
        pagination
      }
    }
    .class(stringIsEmpty(`class`) ? "table-pagination" : "table-pagination \(`class`)")
    .style {
      selector("&") {
        display(.flex)
        alignItems(.center)
        justifyContent(.spaceBetween)
        gap(spacing12)
        flexWrap(.wrap)
      }
      descendant(".pagination-info") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
      }
      descendant(".table-pagination-controls") {
        flexShrink(0)
        // PaginationView centers itself with `margin: 0 auto`. Here it is one
        // end of a space-between row, so the end margin has to be taken back
        // or the auto pair recenters it mid-row.
        marginInlineStart(.auto)
        marginInlineEnd(0)
      }
      // On a narrow phone the row would wrap unevenly: two lines instead,
      // the count over the pager, both centered. Wider, one row fits.
      media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
        selector("&") {
          flexDirection(.column).important()
          justifyContent(.center).important()
        }
        descendant(".pagination-info") {
          textAlign(.center).important()
        }
        descendant(".table-pagination-controls") {
          marginInline(.auto).important()
        }
      }
    }
  }
}
