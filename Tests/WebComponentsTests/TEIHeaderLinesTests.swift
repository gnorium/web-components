import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
import XMLUtilities

@testable import WebComponents

/// A document's header in its pages' XML (user, 2026-10-20): each page's code
/// headed by the document's `<teiHeader>` lines, read-only and hidden until
/// the viewer's Header switch; the page's code itself (read or edited) never
/// holds a header; the page's numbers counted on after the header's.
final class TEIHeaderLinesTests: XCTestCase {
  static let header = """
    <teiHeader><encodingDesc><tagsDecl>
    <rendition xml:id="size-1" scheme="css">font-size:0.8251rem</rendition>
    </tagsDecl></encodingDesc></teiHeader>
    """
  static let document =
    "<TEI xmlns=\"http://www.tei-c.org/ns/1.0\">\(header)<text><body><pb n=\"1\" facs=\"https://example.org/iiif/p1/full/1300,/0/default.jpg\"/><p>One.</p></body></text></TEI>"

  private func html(editable: Bool, header: String?) -> String {
    TEIView(teiXml: Self.document, editable: editable, header: header).build().render()
  }

  private func raw(_ out: String) throws -> String {
    let start = try XCTUnwrap(out.range(of: "class=\"tei-page-raw\""))
    return String(out[start.lowerBound...])
  }

  func testTheHeaderHeadsEachPagesCodeReadOnly() throws {
    for editable in [false, true] {
      let code = try raw(html(editable: editable, header: Self.header))
      let head = try XCTUnwrap(code.range(of: "class=\"tei-page-header\""))
      // The header's lines first, a read-only block; the page's code after.
      XCTAssertTrue(code[head.upperBound...].contains("teiHeader"))
      XCTAssertFalse(code[head.lowerBound..<(code.range(of: editable ? "tei-page-edit" : "</div><pre")?.lowerBound ?? code.endIndex)].contains("contenteditable"))
      XCTAssertTrue(code.contains("--header-lines: 3"), "the page's numbers start after the header's three lines")
    }
  }

  func testThePagesCodeNeverHoldsTheHeader() throws {
    for editable in [false, true] {
      let code = try raw(html(editable: editable, header: nil))
      XCTAssertFalse(code.contains("tei-page-header"))
      XCTAssertFalse(code.contains("teiHeader"), "the page's own code holds a header (editable: \(editable))")
    }
  }

  func testTheHeaderToggleIsTitledAndNamed() {
    let out = HeaderToggleButtonView(disabled: true, class: "artifact-header-toggle").build().render()
    XCTAssertTrue(out.contains("title=\"Header\""))
    XCTAssertTrue(out.contains("aria-label=\"Show the header\""))
    XCTAssertTrue(out.contains("disabled"))
    XCTAssertTrue(out.contains("panel-top-icon-view"))
  }
}
