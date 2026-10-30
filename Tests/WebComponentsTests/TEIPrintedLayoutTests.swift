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

  /// A figure the page sets by its zone (user, 2026-10-30: a board's crest, on a page with no body type) is
  /// drawn at its setting as a figure the page places is: its size, its place across and its place down.
  func testAFigureSetByItsZoneIsDrawnAtItsPlace() throws {
    let a = "https://web-tests.invalid/iiif/1/full/max/0/default.jpg"
    let document = #"<TEI xmlns="http://www.tei-c.org/ns/1.0"><teiHeader><encodingDesc><tagsDecl>"#
      + #"<rendition xml:id="text-block" scheme="css" selector="text">font-size:20px;inline-size:44em;block-size:55.9em;margin:3em</rendition>"#
      + "</tagsDecl></encodingDesc></teiHeader>"
      + #"<facsimile><surface n="1" ulx="0" uly="0" lrx="1000" lry="1000"><graphic url="\#(a)" width="1000px" height="1300px"/>"#
      + #"<zone xml:id="textblock" type="textblock" points="420,240 620,240 620,440 420,440"/><zone type="leaf" points="100,80 900,80 900,920 100,920"/>"#
      + #"<zone xml:id="z1" ulx="500" uly="300" lrx="580" lry="400"/></surface></facsimile>"#
      + ##"<text><body><pb n="1" facs="\##(a)"/><figure facs="#z1"><graphic url="/calibration-figures/z1.svg?image=x" mimeType="image/svg+xml"/></figure></body></text></TEI>"##
    let nodes = elements(in: TEIView(teiXml: document).build())
    let figure = try XCTUnwrap(classed("tei-figure", in: nodes).first)
    XCTAssertEqual(attribute("data-placed", of: figure), "true")
    XCTAssertEqual(
      attribute("style", of: figure),
      "inline-size:5em;block-size:8.125em;margin-inline-start:22em;margin-block-start:14.875em;")
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
      #"<p>A<lb/></p><milestone unit="section" rend="rule" style="inline-size:10em"/><note type="binding" subtype="edition" style="border-style:solid;padding:1em"><p>Gift<lb/></p></note><note place="foot" rend="align(justify)" style="column-gap:2em"><cb/>One<lb/>two<lb/><cb/>Three<lb/></note>"#)
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
    // The page's own pair (its <pb>'s renditions) is the theme's: its lines carry no color; another ink is
    // drawn as encoded.
    let inverted = view(
      ##"<ab><lb/>White type</ab><ab rend="color(yellow)"><lb/>Gilt</ab>"##)
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
      <facsimile><surface n="1" ulx="0" uly="0" lrx="1000" lry="1000">\
      <graphic url="https://web-tests.invalid/iiif/1"/>\
      <zone xml:id="z-L1" ulx="120" uly="80" lrx="320" lry="110"/></surface></facsimile>\
      <text><body><pb n="1" facs="https://web-tests.invalid/iiif/1"/>\
      <lb facs="#z-L1"/><note type="provenance">69304</note>\
      <note place="top margin-left" style="margin-block-end:2em"><p>Ref PE 1580<lb/></p></note>\
      <p>Main text<lb/></p>\
      <note place="margin-left" style="margin-inline-end:1em"><p>Gloss<lb/></p></note>\
      <note type="binding" subtype="issue" place="bottom"><p>Stamp<lb/></p></note></body></text></TEI>
      """
    let nodes = elements(in: TEIView(teiXml: document).build())
    let page = try XCTUnwrap(classed("tei-page", in: nodes).first)
    XCTAssertEqual(attribute("data-element-zones", of: page), "1:120 80 200 30")
    let layer = try XCTUnwrap(nodes.first { attribute("data-layer", of: $0) == "rendering" })
    XCTAssertEqual(attribute("data-framed", of: layer), "true")
    XCTAssertEqual(
      attribute("style", of: layer),
      "--tei-frame-measure: 44; --tei-frame-height: 55.9; --tei-frame-head: 3; --tei-frame-foot: 3; --tei-frame-left: 3; --tei-frame-right: 3; --tei-page-width: 0; --tei-page-height: 0")
    let frame = try XCTUnwrap(classed("tei-text-block", in: nodes).first)
    XCTAssertEqual(text(of: frame).trimmingCharacters(in: .whitespacesAndNewlines), "Main text")
    let margins = classed("tei-margin", in: nodes)
    XCTAssertEqual(margins.compactMap { attribute("data-place", of: $0) }, ["top-left", "margin-left", "bottom"])
    XCTAssertEqual(margins.map { text(of: $0).trimmingCharacters(in: .whitespacesAndNewlines) }, ["Ref PE 1580", "Gloss", "Stamp"])
  }

  /// A blank leaf in its work's frame is the empty page it is (user,
  /// 2026-10-29): its `<gap reason="blank"/>` stays in its TEI, and the
  /// trace draws no mark, at no place, on a page of its measured size.
  func testABlankLeafIsAnEmptyPage() throws {
    let document = """
      <TEI><teiHeader><encodingDesc><tagsDecl><rendition xml:id="text-block" scheme="css" selector="text">\
      font-size:20px;inline-size:44em;block-size:55.9em;margin:3em</rendition></tagsDecl></encodingDesc></teiHeader>\
      <text><body><pb n="Front flyleaf" facs="https://web-tests.invalid/iiif/1"/>\
      <gap reason="blank" style="margin-inline-start:7em"/></body></text></TEI>
      """
    let nodes = elements(in: TEIView(teiXml: document).build())
    let layer = try XCTUnwrap(nodes.first { attribute("data-layer", of: $0) == "rendering" })
    XCTAssertEqual(attribute("data-framed", of: layer), "true")
    XCTAssertEqual(text(of: layer).trimmingCharacters(in: .whitespacesAndNewlines), "")
    XCTAssertTrue(classed("tei-line-gap", in: nodes).isEmpty)
    // A page with no frame still says what it is.
    let unframed = view(#"<gap reason="blank"/>"#)
    XCTAssertEqual(classed("tei-line-gap", in: unframed).map { text(of: $0) }, ["[blank]"])
  }

  /// Lines the print sets on one row (gnorium-python `base_tei._rows`) are one row, each at its own place
  /// on it: a catchword on its signature's row, never stacked under it (Hamlet Q1), each piece over the
  /// whole row's measure; a turnover on the row of the line beside it.
  func testLinesSetOnOneRowAreOneRowEachAtItsPlace() throws {
    let nodes = view(
      ##"<ab><lb facs="#z-L21"/>But who must lie in it?<seg facs="#z-L22" rend="align(left)" style="margin-inline-start:24.25rem">(sir.</seg><lb facs="#z-L23"/>If I should say</ab><lb facs="#z-L38"/><fw type="sig" rend="align(left)" style="margin-inline-start:18rem">C</fw><fw type="catch" facs="#z-L39" rend="align(left)" style="margin-inline-start:23.75rem">Ham.</fw>"##)
    let furniture = try XCTUnwrap(classed("tei-forme-row", in: nodes).first)
    XCTAssertEqual(text(of: furniture), "CHam.")
    let pieces = classed("tei-forme-row-start", in: elements(in: furniture))
    XCTAssertEqual(pieces.count, 2)
    XCTAssertEqual(
      classed("tei-line-forme", in: elements(in: furniture)).compactMap { attribute("style", of: $0) },
      ["margin-inline-start:18em;", "margin-inline-start:23.75em;"])
    let row = try XCTUnwrap(classed("tei-row", in: nodes).first)
    let lines = classed("tei-line", in: elements(in: row))
    XCTAssertEqual(lines.map { text(of: $0) }, ["But who must lie in it?", "(sir."])
    XCTAssertEqual(attribute("style", of: lines[1]), "margin-inline-start:24.25rem;")
    XCTAssertFalse(text(of: row).contains("If I should say"))
  }
}
