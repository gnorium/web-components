import DOMBuilder
import WebTypes
import XCTest
import XMLUtilities
@testable import WebComponents

/// The printed page's furniture as TEI encodes it (user, 2026-10-13): a
/// contents leader, a printed rule, a framed block, footnote columns.
final class TEIPrintedLayoutTests: XCTestCase {
  private func elements(in node: DOM.Node) -> [DOM.Element] {
    guard let element = node as? DOM.Element else { return [] }
    return [element] + element.children.flatMap { elements(in: $0) }
  }

  private func attribute(_ name: String, of element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func text(of node: DOM.Node) -> String {
    if let text = node as? DOM.Text { return text.content }
    return (node as? DOM.Element)?.children.map { text(of: $0) }.joined() ?? ""
  }

  private func classed(_ name: String, in nodes: [DOM.Element]) -> [DOM.Element] {
    nodes.filter { (attribute("class", of: $0) ?? "").split(separator: " ").contains { $0 == name } }
  }

  private func view(_ body: String) -> [DOM.Element] {
    elements(
      in: TEIView(teiXml: #"<TEI><text><body><pb n="1" facs="https://web-tests.invalid/iiif/1"/>\#(body)</body></text></TEI>"#)
        .build())
  }

  func testContentsTitleDotsAreALeader() throws {
    let nodes = view(
      #"<table type="contents"><row><cell><p>Preface <pc style="letter-spacing:1.2em">.\#u{2002}.\#u{2002}.\#u{2002}.</pc><lb/></p></cell><cell><p>vii<lb/></p></cell></row></table>"#)
    let leader = try XCTUnwrap(classed("tei-leader", in: nodes).first)
    // Its dots at their printed pitch: the run's own setting.
    XCTAssertTrue(elements(in: leader).contains { attribute("style", of: $0) == "letter-spacing:1.2em;" })
    // Exactly the printed dots, as the TEI has them, and nothing drawn besides.
    XCTAssertEqual(text(of: leader).filter { $0 == "." }.count, 4)
    XCTAssertNil(attribute("data-leader", of: leader))
    // The page reference's cell draws no leader.
    XCTAssertEqual(classed("tei-line-leadered", in: nodes).count, 1)
  }

  func testRuleFrameAndFootnoteColumns() throws {
    let nodes = view(
      #"<p>A<lb/></p><milestone unit="section" rend="rule" style="inline-size:10em"/><note type="provenance" style="border-style:solid;padding:1em"><p>Gift<lb/></p></note><note place="foot" rend="align(justify)" style="column-gap:2em"><cb/>One<lb/>two<lb/><cb/>Three<lb/></note>"#)
    let rule = try XCTUnwrap(classed("tei-rule", in: nodes).first)
    XCTAssertEqual(attribute("style", of: rule), "inline-size:10em;")
    let frame = try XCTUnwrap(classed("tei-frame", in: nodes).first)
    XCTAssertEqual(attribute("style", of: frame), "border-style:solid;padding:1em;")
    let columns = try XCTUnwrap(classed("tei-columns", in: nodes).first)
    XCTAssertEqual(attribute("style", of: columns), "column-gap:2em;")
    let notes = classed("tei-line-note", in: nodes)
    XCTAssertEqual(notes.compactMap { attribute("data-rend", of: $0) }.last, "align(justify) css:column-gap=2em")
  }

  func testAParagraphRunOnToTheNextPageNamesItsPart() throws {
    let nodes = view(
      #"<p rend="align(justify)">Whole<lb/>here.<lb/></p><p rend="align(justify)" part="I">Runs<lb/>on<lb/></p>"#)
    let blocks = classed("tei-block", in: nodes)
    XCTAssertEqual(blocks.compactMap { attribute("data-part", of: $0) }, ["", "I"])
  }
}
