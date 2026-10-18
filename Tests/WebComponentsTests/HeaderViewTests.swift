import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

final class HeaderViewTests: XCTestCase {
  static let header = """
    <teiHeader><fileDesc><titleStmt><title>Skeat</title></titleStmt></fileDesc>
    <encodingDesc><tagsDecl>
    <rendition xml:id="size-1" scheme="css">font-size:0.8251rem</rendition>
    <rendition xml:id="size-2" scheme="css">font-size:1.0029rem</rendition>
    </tagsDecl></encodingDesc></teiHeader>
    """

  private func html(_ header: String) -> String { HeaderView(teiHeader: header).build().render() }

  func testRenderedLayerHoldsLabelledEntriesAndNoHeading() {
    let out = html(Self.header)
    XCTAssertTrue(out.contains("class=\"header-view\""))
    XCTAssertTrue(out.contains("data-header-layer=\"rendered\""))
    XCTAssertTrue(out.contains("header-entry-label"))
    XCTAssertTrue(out.contains(">Title<"))
    XCTAssertTrue(out.contains(">Skeat<"))
    XCTAssertTrue(out.contains(">Scale<"))
    XCTAssertTrue(out.contains("<caption>Size</caption>"))
    XCTAssertTrue(out.contains(">size-1<"))
    XCTAssertTrue(out.contains(">0.8251<"))
    XCTAssertFalse(out.contains("<h1"))
    XCTAssertFalse(out.contains("<h2"))
    XCTAssertFalse(out.contains("<h3"))
  }

  func testBoxIsReadOnlyGrayAndBorderedByTokens() throws {
    var node: DOM.Node?
    let sheets = HTMLGlobalStyle.collecting { node = HeaderView(teiHeader: Self.header).build() }.currentStyleSheets()
    XCTAssertNotNil(node)
    let css = sheets.filter { $0.owner.hasPrefix("header-") }.map(\.css).joined(separator: "\n")
    XCTAssertFalse(css.isEmpty)
    XCTAssertTrue(css.contains("--background-color-neutral-subtle"))
    XCTAssertTrue(css.contains("--border-color-subtle"))
    XCTAssertFalse(css.contains("text-overflow"))
    XCTAssertFalse(css.contains("box-shadow"))
  }

  func testXMLSwitchSitsInTheBottomLeftLegend() {
    let out = html(Self.header)
    XCTAssertTrue(out.contains("<legend class=\"header-legend\""))
    XCTAssertTrue(out.contains("header-xml-toggle"))
    XCTAssertTrue(out.contains("data-raw=\"false\""))
  }

  func testRawLayerIsNumberedFromOneWithoutAPrefix() {
    let out = html(Self.header)
    XCTAssertTrue(out.contains("data-header-layer=\"raw\""))
    XCTAssertTrue(out.contains("code-gutter"))
    XCTAssertTrue(out.contains(">1\n2\n3"))
    XCTAssertFalse(out.contains("H1"))
  }

  func testAnEmptyHeaderShowsAnEmDash() {
    let out = html("<teiHeader/>")
    XCTAssertTrue(out.contains(">Title<"))
    XCTAssertTrue(out.contains("header-entry-value\">—<"))
  }
}
