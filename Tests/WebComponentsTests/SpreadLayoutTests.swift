import DOMBuilder
import WebTypes
import XCTest
import XMLUtilities
@testable import WebComponents

/// A canvas photographed as an opening, a `<pb/>` for each side, is set as
/// a spread: each page its own column (user, 2026-10-12).
final class SpreadLayoutTests: XCTestCase {
  private func elements(in node: DOM.Node) -> [DOM.Element] {
    guard let element = node as? DOM.Element else { return [] }
    return [element] + element.children.flatMap { elements(in: $0) }
  }

  private func text(in node: DOM.Node) -> String {
    if let text = node as? DOM.Text { return text.content }
    return (node as? DOM.Element)?.children.map { text(in: $0) }.joined() ?? ""
  }

  private func attribute(_ name: String, of element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func classed(_ name: String, in nodes: [DOM.Element]) -> [DOM.Element] {
    nodes.filter { (attribute("class", of: $0) ?? "").split(separator: " ").contains { $0 == name } }
  }

  private func view(_ body: String, direction: String? = nil) -> [DOM.Element] {
    elements(
      in: TEIView(
        teiXml: #"<TEI><text><body><pb n="A1 verso" facs="https://web-tests.invalid/iiif/1"/>\#(body)</body></text></TEI>"#,
        direction: direction
      ).build())
  }

  func testTwoPagesOnOneCanvasAreTwoColumnsInReadingOrder() throws {
    let nodes = view(#"<p>Leftward<lb/></p><pb n="A2 recto"/><p>Rightward<lb/></p>"#, direction: "ltr")
    let rendering = try XCTUnwrap(nodes.first { attribute("data-layer", of: $0) == "rendering" })
    let spreads = classed("tei-spread", in: elements(in: rendering))
    XCTAssertEqual(spreads.count, 1)
    let spread = try XCTUnwrap(spreads.first)
    XCTAssertEqual(attribute("dir", of: spread), "ltr")
    let pages = classed("tei-spread-page", in: elements(in: spread))
    XCTAssertEqual(pages.count, 2)
    // Each page headed by its own label: the first by the canvas's, whose
    // page break is the document's.
    XCTAssertEqual(classed("tei-line-mark", in: elements(in: pages[0])).map { text(in: $0) }, ["A1 verso"])
    XCTAssertEqual(classed("tei-line-mark", in: elements(in: pages[1])).map { text(in: $0) }, ["A2 recto"])
    XCTAssertTrue(text(in: pages[0]).contains("Leftward"))
    XCTAssertFalse(text(in: pages[0]).contains("Rightward"))
    XCTAssertTrue(text(in: pages[1]).contains("Rightward"))
  }

  /// The spread runs in the direction the document's data gives, never
  /// one read off its letters: none given, none set.
  func testASpreadRunsInTheDirectionGiven() throws {
    let body = #"<p>שמאל<lb/></p><pb n="A2 recto"/><p>ימין<lb/></p>"#
    let rightToLeft = try XCTUnwrap(classed("tei-spread", in: view(body, direction: "rtl")).first)
    XCTAssertEqual(attribute("dir", of: rightToLeft), "rtl")
    let unsaid = try XCTUnwrap(classed("tei-spread", in: view(body)).first)
    XCTAssertNil(attribute("dir", of: unsaid))
  }

  func testOnePageOnACanvasIsNoSpread() {
    let nodes = view("<p>Alone<lb/></p>")
    XCTAssertTrue(classed("tei-spread", in: nodes).isEmpty)
    XCTAssertTrue(classed("tei-spread-page", in: nodes).isEmpty)
    XCTAssertTrue(classed("tei-line-mark", in: nodes).isEmpty)
  }

  func testPagesSplitAtEachPageBreakAfterTheirLines() {
    let line = { (text: String) in TEILine(kind: .text, text: text) }
    let mark = { (text: String) in TEILine(kind: .mark, text: text) }
    // A page break that opens the canvas's lines heads its first page.
    XCTAssertEqual(
      TEIView.spreadPages(of: [mark("1"), line("a"), mark("2"), line("b"), mark("3")]).map { $0.map(\.text) },
      [["1", "a"], ["2", "b"], ["3"]])
    XCTAssertEqual(TEIView.spreadPages(of: [line("a")]).map { $0.map(\.text) }, [["a"]])
  }
}
