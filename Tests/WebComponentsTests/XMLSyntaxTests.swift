import XCTest
@testable import WebComponents

/// XML colored by its grammar (user, 2026-10-11): marks, names (prefixed
/// whole), attribute names and values, references in text and in values,
/// comments, PIs, CDATA; text between tags plain.
final class XMLSyntaxTests: XCTestCase {
  private func colored(_ text: String) -> [String] {
    let units = Array(text.utf16)
    return XMLSyntax.tokens(Array(text.utf8)).map {
      "\($0.kind.highlightName.dropFirst(5)):" + String(decoding: units[$0.start..<$0.end], as: UTF16.self)
    }
  }

  func testATagAndItsText() {
    XCTAssertEqual(
      colored(#"<w xml:id="w1" lemma="a&amp;b">x &#x17F; y</w><lb/>"#),
      [
        "tag:<", "name:w", "attr:xml:id", "string:\"w1\"", "attr:lemma", "string:\"a", "entity:&amp;", "string:b\"",
        "tag:>", "entity:&#x17F;", "tag:</", "name:w", "tag:>", "tag:<", "name:lb", "tag:/>",
      ])
  }

  func testCommentsInstructionsAndCDATA() {
    XCTAssertEqual(
      colored("<?xml version=\"1.0\"?><!-- a <b> --><![CDATA[<c>]]>R & D"),
      ["meta:<?xml version=\"1.0\"?>", "comment:<!-- a <b> -->", "cdata:<![CDATA[<c>]]>"])
  }
}
