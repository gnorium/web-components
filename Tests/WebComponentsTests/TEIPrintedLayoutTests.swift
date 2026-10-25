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

  /// A run on a ground of its own (user, 2026-10-25: a shaded box, gnorium-python `base_tei.fills`) is a
  /// frame drawing that ground as encoded, in every theme; the page's ground is never drawn, and an ink is
  /// its name's color with no theme's fallback.
  func testAFilledRunDrawsItsGroundAsEncoded() throws {
    let nodes = view(
      #"<ab style="background-color:#d7e4f3;padding:1em"><lb/>Boxed<lb/>lines</ab><ab><lb/>After</ab>"#)
    let frame = try XCTUnwrap(classed("tei-frame", in: nodes).first)
    XCTAssertEqual(attribute("style", of: frame), "background-color:#d7e4f3;padding:1em;")
    XCTAssertEqual(classed("tei-frame", in: nodes).count, 1)
    XCTAssertTrue(text(of: frame).contains("Boxed") && !text(of: frame).contains("After"))
    // The default ink of either pair carries no color: the theme's text color; gilt is drawn as encoded.
    let inverted = view(#"<ab><lb/>White type</ab><ab rend="color(yellow)"><lb/>Gilt</ab>"#)
    let inked = inverted.filter { (attribute("data-rend", of: $0) ?? "").contains("color(") }
    XCTAssertFalse(inked.isEmpty)
    XCTAssertTrue(inked.allSatisfy { text(of: $0).contains("Gilt") && !text(of: $0).contains("White") })
    XCTAssertEqual(TEIView.inks.count, TEIRenderer.inks.count)
    XCTAssertEqual(Set(TEIView.inks.map(\.name)), Set(TEIRenderer.inks))
  }

  func testAParagraphRunOnToTheNextPageNamesItsPart() throws {
    let nodes = view(
      #"<p rend="align(justify)">Whole<lb/>here.<lb/></p><p rend="align(justify)" part="I">Runs<lb/>on<lb/></p>"#)
    let blocks = classed("tei-block", in: nodes)
    XCTAssertEqual(blocks.compactMap { attribute("data-part", of: $0) }, ["", "I"])
  }

  /// A footnote's indent is its first line's only: the block a column
  /// break falls inside runs on into the next column (user, 2026-10-13).
  func testAColumnBreakInsideABlockRunsItOn() throws {
    let nodes = view(#"<note place="foot" style="text-indent:1em;column-gap:2em"><cb/>One<lb/>two<lb/><cb/>three<lb/></note>"#)
    let blocks = classed("tei-block", in: nodes)
    XCTAssertEqual(blocks.compactMap { attribute("data-part", of: $0) }, ["I", "F"])
  }

  /// A horizontal `<space/>` is a gap in its line as wide as it says, a
  /// decimal too; the page still renders (user, 2026-10-13).
  func testHorizontalSpaceIsAGapThatWide() throws {
    let nodes = view(
      #"<p>a<space dim="horizontal" quantity="1.5"/>b<space quantity="0.68" unit="em"/>c<lb/></p>"#)
    let gaps = classed("tei-run-space", in: nodes)
    XCTAssertEqual(
      gaps.compactMap { attribute("style", of: $0) },
      ["inline-size: calc(1.5 * var(--tei-space-char, 1ch));", "inline-size: 0.68em;"])
    XCTAssertEqual(gaps.map { text(of: $0) }, [" ", " "])
    let layer = try XCTUnwrap(nodes.first { attribute("data-layer", of: $0) == "rendering" })
    XCTAssertEqual(text(of: layer).filter { !$0.isWhitespace }, "abc")
  }

  /// A space's character is as wide as the header declares the print's quads (the tuning's fitted width,
  /// gnorium-python `scale.space_rendition`): the page's layer carries it; with none declared, a `ch`.
  func testASpacesCharacterIsTheWidthTheHeaderDeclares() throws {
    // As a header's declarations are read (`TEIRendition.declarations`).
    let declared = TEIRendition.declarations(
      of: #"<TEI><teiHeader><encodingDesc><tagsDecl><rendition xml:id="space-char" scheme="css">inline-size:0.4452em</rendition></tagsDecl></encodingDesc></teiHeader></TEI>"#)
    XCTAssertEqual(TEIView.spaceCharacter(in: declared), "0.4452em")
    XCTAssertNil(TEIView.spaceCharacter(in: [:]))
    XCTAssertNil(TEIView.spaceCharacter(in: ["space-char": "css:inline-size=12px"]))
    XCTAssertEqual(TEIView.pageTextStyle(frame: nil, renditions: declared), "--tei-space-char: 0.4452em")
    XCTAssertEqual(TEIView.pageTextStyle(frame: nil, renditions: [:]), "")
  }

  /// A page in its work's frame (user, 2026-10-14): its main text in the
  /// frame, its marginalia outside it on their sides, the page's frame,
  /// margin and size in the body type's em on the page's layer.
  func testMarginaliaAreSetOutsideTheFrameOnTheirSides() throws {
    let document = """
      <TEI><teiHeader><encodingDesc><tagsDecl><rendition xml:id="text-block" scheme="css" selector="text">\
      font-size:20px;inline-size:44em;block-size:55.9em;margin:3em</rendition></tagsDecl></encodingDesc></teiHeader>\
      <text><body><pb n="1" facs="https://web-tests.invalid/iiif/1"/>\
      <note type="provenance" place="top margin-left" style="margin-block-end:2em"><p>Ref PE 1580<lb/></p></note>\
      <p>Main text<lb/></p>\
      <note place="margin-left" style="margin-inline-end:1em"><p>Gloss<lb/></p></note>\
      <note type="provenance" place="bottom"><p>Stamp<lb/></p></note></body></text></TEI>
      """
    let nodes = elements(in: TEIView(teiXml: document).build())
    let layer = try XCTUnwrap(nodes.first { attribute("data-layer", of: $0) == "rendering" })
    XCTAssertEqual(attribute("data-framed", of: layer), "true")
    XCTAssertEqual(
      attribute("style", of: layer),
      "--tei-frame-measure: 44; --tei-frame-height: 55.9; --tei-frame-margin: 3; --tei-page-width: 0; --tei-page-height: 0")
    let frame = try XCTUnwrap(classed("tei-text-block", in: nodes).first)
    XCTAssertEqual(text(of: frame).trimmingCharacters(in: .whitespacesAndNewlines), "Main text")
    let margins = classed("tei-margin", in: nodes)
    XCTAssertEqual(margins.compactMap { attribute("data-place", of: $0) }, ["top-left", "margin-left", "bottom"])
    XCTAssertEqual(margins.map { text(of: $0).trimmingCharacters(in: .whitespacesAndNewlines) }, ["Ref PE 1580", "Gloss", "Stamp"])
  }
}
