import DOMBuilder
import WebTypes
import XCTest
@testable import WebComponents

final class EditorAndNavigationTests: XCTestCase {
  private func elements(in node: DOM.Node) -> [DOM.Element] {
    guard let element = node as? DOM.Element else { return [] }
    return [element] + element.children.flatMap { elements(in: $0) }
  }

  private func text(in node: DOM.Node) -> String {
    if let text = node as? DOM.Text { return text.content }
    return (node as? DOM.Element)?.children.map { text(in: $0) }.joined() ?? ""
  }

  func testTEIEditorKeepsEverySourceCharacter() throws {
    for attribute in ["xml:space='preserve'", "xml:space = \"preserve\"", "xml:space = 'preserve'"] {
      let source = "<p \(attribute)><hi>a</hi>  <hi>b</hi>\u{00A0}c\n</p>"
      let view = TEIView(
        teiXml: "<TEI><text><body><pb n=\"1\" facs=\"https://web-tests.invalid/iiif/1\"/>\(source)</body></text></TEI>",
        editable: true)
      let page = try XCTUnwrap(view.pages.first)
      let nodes = elements(in: view.build())
      let input = try XCTUnwrap(nodes.first { $0.tag == "textarea" })
      let code = try XCTUnwrap(nodes.first { node in
        node.tag == "code" && node.attributes.contains { $0.0 == "contenteditable" }
      })
      XCTAssertEqual(text(in: input), page.markup)
      XCTAssertEqual(text(in: code), page.markup)
      XCTAssertTrue(text(in: input).contains(source))
    }
  }

  func testPaginationChangesOnlyExactPageParameters() {
    XCTAssertEqual(
      PaginationURL.settingPage("2", in: "/records?per_page=25&page=1&filter=a&filter=b&sort=name#results"),
      "/records?per_page=25&page=2&filter=a&filter=b&sort=name#results")
    XCTAssertEqual(
      PaginationURL.settingPage("3", in: "/records?per_page=25&filter=page%3D1#page=1"),
      "/records?per_page=25&filter=page%3D1&page=3#page=1")
    XCTAssertEqual(PaginationURL.settingPage("2", in: "/records#results"), "/records?page=2#results")
    XCTAssertEqual(PaginationURL.settingPage("2", in: "/records?#results"), "/records?page=2#results")
    XCTAssertEqual(PaginationURL.settingPage("4", in: "/records?page=1&page=2"), "/records?page=4&page=4")
    XCTAssertEqual(PaginationURL.settingPage("4", in: "/records?page=&x=1"), "/records?page=4&x=1")
    XCTAssertEqual(PaginationURL.settingPage("2", in: "/café?filter=é&page=1#résultats"), "/café?filter=é&page=2#résultats")
  }

  func testSearchResultsAreInvalidatedBeforeNextResponse() {
    var search = ComboboxSearch()
    let apple = search.begin()
    XCTAssertTrue(search.receive(query: "apple", sequence: apple, currentQuery: "apple"))
    XCTAssertTrue(search.matches("apple"))
    let banana = search.begin()
    XCTAssertFalse(search.matches("apple"))
    XCTAssertFalse(search.matches("banana"))
    XCTAssertFalse(search.receive(query: "apple", sequence: apple, currentQuery: "banana"))
    XCTAssertFalse(search.receive(query: "banana", sequence: banana, currentQuery: "other"))
    XCTAssertTrue(search.receive(query: "banana", sequence: banana, currentQuery: "banana"))
    XCTAssertTrue(search.matches("banana"))
  }

  func testCurrentRemoteResultsRemainUnfilteredForDiacriticMatching() {
    var search = ComboboxSearch()
    let request = search.begin()
    // The server may return “café” for “cafe”. Ownership follows the query,
    // not a second client-side substring comparison of the display name.
    XCTAssertTrue(search.receive(query: "cafe", sequence: request, currentQuery: "cafe"))
    XCTAssertTrue(search.matches("cafe"))
    XCTAssertFalse(search.matches("tea"))
    _ = search.begin()
    XCTAssertFalse(search.matches("cafe"))
  }

  func testEditableTargetsKeepTheirTypingAndNavigationKeys() {
    for tag in ["INPUT", "TEXTAREA", "SELECT"] {
      XCTAssertTrue(KeyboardShortcuts.isEditable(tag: tag, contentEditableAncestors: []))
    }
    for attribute in ["", "true", "plaintext-only", "PLAINTEXT-ONLY"] {
      XCTAssertTrue(KeyboardShortcuts.isEditable(tag: "CODE", contentEditableAncestors: [attribute]))
      XCTAssertTrue(KeyboardShortcuts.isEditable(tag: "SPAN", contentEditableAncestors: ["inherit", attribute]))
    }
    XCTAssertFalse(KeyboardShortcuts.isEditable(tag: "SPAN", contentEditableAncestors: ["false", "true"]))
    XCTAssertTrue(KeyboardShortcuts.isEditable(tag: "SPAN", contentEditableAncestors: ["true", "false"]))
    XCTAssertFalse(KeyboardShortcuts.isEditable(tag: "DIV", contentEditableAncestors: []))
    for key in ["/", "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End", "PageUp", "PageDown"] {
      XCTAssertTrue(KeyboardShortcuts.editorOwns(key))
    }
    XCTAssertFalse(KeyboardShortcuts.editorOwns("Escape"))
  }
}
