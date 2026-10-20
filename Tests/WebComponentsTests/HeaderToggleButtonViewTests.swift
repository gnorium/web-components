import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
import XMLUtilities

@testable import WebComponents

/// A document's header is its viewer's Header pane's alone (user,
/// 2026-10-21): a page's XML, read or edited, never holds it, nor draws it
/// over its code; the switch that shows it is titled and named, and enabled
/// unless its host says otherwise.
final class HeaderToggleButtonViewTests: XCTestCase {
  static let header = """
    <teiHeader><encodingDesc><tagsDecl>
    <rendition xml:id="size-1" scheme="css">font-size:0.8251rem</rendition>
    </tagsDecl></encodingDesc></teiHeader>
    """
  static let document =
    "<TEI xmlns=\"http://www.tei-c.org/ns/1.0\">\(header)<text><body><pb n=\"1\" facs=\"https://example.org/iiif/p1/full/1300,/0/default.jpg\"/><p>One.</p></body></text></TEI>"

  private func raw(_ out: String) throws -> String {
    let start = try XCTUnwrap(out.range(of: "class=\"tei-page-raw\""))
    return String(out[start.lowerBound...])
  }

  func testAPagesXMLNeverHoldsTheHeader() throws {
    for editable in [false, true] {
      let code = try raw(TEIView(teiXml: Self.document, editable: editable).build().render())
      XCTAssertFalse(code.contains("tei-page-header"), "a header drawn over the page's code (editable: \(editable))")
      XCTAssertFalse(code.contains("teiHeader"), "the page's own code holds a header (editable: \(editable))")
      XCTAssertFalse(code.contains("--header-lines"), "the page's numbers start after a header (editable: \(editable))")
    }
  }

  func testTheHeaderToggleIsTitledAndNamed() {
    let out = HeaderToggleButtonView(class: "artifact-header-toggle").build().render()
    XCTAssertTrue(out.contains("title=\"Header\""))
    XCTAssertTrue(out.contains("aria-label=\"Show the header\""))
    XCTAssertNil(
      out.range(of: #"<button[^>]*\sdisabled"#, options: .regularExpression), "the switch is drawn disabled")
    XCTAssertTrue(out.contains("panel-top-icon-view"))
    XCTAssertTrue(out.contains("artifact-header-toggle"))
  }
}
