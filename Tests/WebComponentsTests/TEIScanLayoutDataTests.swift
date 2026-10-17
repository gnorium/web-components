import DOMBuilder
import WebTypes
import XCTest
import XMLUtilities

@testable import WebComponents

/// What a page hands the reader's overlay (user, 2026-10-17): its scan's
/// measured layout, a line's baseline after its corners where it has one, and
/// the work's em on its scan. Shaped on prod madrigal dd5cc0b2's canvas 3 (the
/// Etymological Dictionary's title page, a bookplate above its title), saved
/// before baselines were kept, and a line saved since.
final class TEIScanLayoutDataTests: XCTestCase {
  static let service = "https://web-tests.invalid/iiif/3"
  static let layout =
    #"<zone type="block" subtype="main" points="141.21,385.12 897.24,386.72 897.16,408.67 141.13,407.07"/>"#
    + #"<zone type="line" points="141.21,385.12 897.24,386.72 897.16,408.67 141.13,407.07"/>"#
    + #"<zone xml:id="p3-wz21" type="word" points="141.21,385.12 200.43,385.24 200.35,407.19 141.13,407.07"/>"#
    + #"<zone type="block" subtype="marginalia" points="282.16,60.9 663.73,61.71 663.34,162.74 281.78,161.93"/>"#
    + #"<zone type="line" points="395.99,61.14 548.48,61.46 548.43,73.1 395.95,72.78"/>"#
    + #"<zone type="line" points="282.05,89.99 663.61,90.8 663.53,113.28 281.97,112.47"><path type="baseline" points="282.05,110 663.61,110.8"/></zone>"#

  static let document =
    #"<TEI><teiHeader><encodingDesc><tagsDecl><rendition xml:id="text-block" scheme="css" selector="text">font-size:40.40px;inline-size:61.07em;block-size:83.54em;margin:4.37em;max-inline-size:61.45em</rendition><rendition xml:id="size-1" scheme="css">font-size:0.9578rem</rendition><rendition xml:id="size-2" scheme="css">font-size:2.0365rem</rendition><rendition xml:id="leading-1" scheme="css">line-height:1.6337rem</rendition></tagsDecl></encodingDesc></teiHeader><facsimile><surface n="3" ulx="0" uly="0" lrx="1000" lry="1000"><graphic url="\#(service)/full/max/0/default.jpg" width="2820px" height="3781px"/><zone xml:id="p3-textblock" type="textblock" points="141.21,385.12 897.24,386.72 896.67,536.41 140.64,534.81" style="font-size:109.89px"/>"#
    + layout
    + #"</surface></facsimile><text><body><pb n="3" facs="\#(service)/full/max/0/default.jpg"/><p>AN ETYMOLOGICAL DICTIONARY<lb/></p></body></text></TEI>"#

  private func elements(in node: DOM.Node) -> [DOM.Element] {
    guard let element = node as? DOM.Element else { return [] }
    return [element] + element.children.flatMap { elements(in: $0) }
  }

  private func attribute(_ name: String, of element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func page() throws -> DOM.Element {
    try XCTUnwrap(elements(in: TEIView(teiXml: Self.document).build()).first { attribute("data-page-index", of: $0) != nil })
  }

  /// A zone is its type, subtype, id and corners (11 fields); a line saved
  /// with its baseline has its two ends after them (15). A page saved before
  /// baselines were kept has no 15-field zone, and its 11-field ones are
  /// what they always were.
  func testOldLinesKeepElevenFieldsAndABaselinedLineFifteen() throws {
    let zones = (attribute("data-scan-layout", of: try page()) ?? "").split(separator: ";").map {
      $0.split(separator: " ").map(String.init)
    }
    XCTAssertEqual(zones.map(\.count), [11, 11, 11, 11, 11, 15])
    XCTAssertEqual(zones.map { $0[0] }, ["block", "line", "word", "block", "line", "line"])
    XCTAssertEqual(zones[3][1], "marginalia")
    XCTAssertEqual(zones[1], ["line", "-", "-", "141.21", "385.12", "897.24", "386.72", "897.16", "408.67", "141.13", "407.07"])
    XCTAssertEqual(Array(zones[5][11...]), ["282.05", "110", "663.61", "110.8"])
  }

  /// The book's em on the scan: the scans' width in em its frame declares
  /// (61.45), whatever the scan's pixels, in the 0–1000 space across it—
  /// 45.89 of the scan's 2820 pixels.
  func testTheBooksEmOnTheScanIsItsWidthOverTheFramesDeclaredWidth() throws {
    let em = try XCTUnwrap(Double(attribute("data-scan-em", of: try page()) ?? ""))
    XCTAssertEqual(em, 16.2734, accuracy: 1e-9)
    XCTAssertEqual(em / 1000 * 2820, 45.89, accuracy: 0.01)
  }
}
