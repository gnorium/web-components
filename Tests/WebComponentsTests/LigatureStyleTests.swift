import CSSBuilder
import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// Ligatures only where the print has them (user, 2026-10-31): every TEI view and every rendered diff turns
/// the face's automatic ligatures off; only a marked ligature is drawn joined.
final class LigatureStyleTests: XCTestCase {
  private func css(_ build: () -> DOM.Node) -> String {
    HTMLGlobalStyle.collecting { _ = build() }.currentStyleSheets().map(\.css).joined(separator: "\n")
  }

  func testTheFaceSLigaturesAreOffAndAMarkedOneIsOn() {
    let tei = css { TEIView(teiXml: ##"<TEI><text><body><p>a <g ref="#ct">ct</g> fi</p></body></text></TEI>"##).build() }
    XCTAssertTrue(tei.contains("font-variant-ligatures:none") || tei.contains("font-variant-ligatures: none"), tei)
    XCTAssertTrue(tei.contains("common-ligatures discretionary-ligatures"))
    XCTAssertFalse(tei.contains("data-service-id]:not"))
  }
}
