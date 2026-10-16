import CSSOMBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// Code colored by its grammar's roles (user, 2026-10-12), one set across
/// XML, JSON and Markdown: each stretch named by its highlight.
final class CodeSyntaxTests: XCTestCase {
  private func colored(_ text: String, _ language: CodeSyntax.Language = .xml) -> [String] {
    let units = Array(text.utf16)
    return CodeSyntax.tokens(Array(text.utf8), language: language).map {
      "\($0.kind.highlightName.dropFirst(5)):" + String(decoding: units[$0.start..<$0.end], as: UTF16.self)
    }
  }

  func testATagAndItsText() {
    XCTAssertEqual(
      colored(#"<w xml:id="w1" lemma="a&amp;b">x &#x17F; y</w><lb/>"#),
      [
        "tag:<", "name:w", "prefix:xml:", "attr:id", "value:\"w1\"", "attr:lemma", "value:\"a", "entity:&amp;",
        "value:b\"", "tag:>", "entity:&#x17F;", "tag:</", "name:w", "tag:>", "tag:<", "name:lb", "tag:/>",
      ])
  }

  /// Every XML role on one sample: a PI, a DOCTYPE, a comment, a prefixed
  /// element and attribute, a value with an entity, text with a character
  /// reference, and CDATA.
  func testEveryXMLRole() {
    let sample = """
      <?xml version="1.0"?>
      <!DOCTYPE TEI>
      <!-- page 5 -->
      <tei:p xml:lang="en" n="R&amp;D">Skeat&#x2019;s <![CDATA[<raw>]]></tei:p>
      """
    XCTAssertEqual(
      colored(sample),
      [
        "pi:<?xml version=\"1.0\"?>", "pi:<!DOCTYPE TEI>", "comment:<!-- page 5 -->",
        "tag:<", "prefix:tei:", "name:p", "prefix:xml:", "attr:lang", "value:\"en\"", "attr:n", "value:\"R",
        "entity:&amp;", "value:D\"", "tag:>", "entity:&#x2019;", "cdata:<![CDATA[<raw>]]>",
        "tag:</", "prefix:tei:", "name:p", "tag:>",
      ])
    XCTAssertEqual(
      Set(CodeSyntax.tokens(Array(sample.utf8), language: .xml).map(\.kind)), Set(CodeSyntax.Kind.allCases))
  }

  func testCommentsInstructionsAndCDATA() {
    XCTAssertEqual(
      colored("<?xml version=\"1.0\"?><!-- a <b> --><![CDATA[<c>]]>R & D"),
      ["pi:<?xml version=\"1.0\"?>", "comment:<!-- a <b> -->", "cdata:<![CDATA[<c>]]>"])
  }

  /// Counted in UTF-16 code units, as a DOM `Range` counts: a character
  /// outside the Basic Multilingual Plane is two.
  func testUnitsPastAnAstralCharacter() {
    XCTAssertEqual(colored("<a>𝔊</a>"), ["tag:<", "name:a", "tag:>", "tag:</", "name:a", "tag:>"])
    let tokens = CodeSyntax.tokens(Array("<a>𝔊</a>".utf8), language: .xml)
    XCTAssertEqual(tokens[3].start, 5)
  }

  func testJSON() {
    XCTAssertEqual(
      colored(#"read_page {"page": 5, "lines": [1.5e2, -3], "ok": true, "next": null, "q": "a\"b"}"#, .json),
      [
        "attr:\"page\"", "prefix:5", "attr:\"lines\"", "prefix:1.5e2", "prefix:-3", "attr:\"ok\"", "name:true",
        "attr:\"next\"", "name:null", "attr:\"q\"", "value:\"a\\\"b\"",
      ])
  }

  func testMarkdown() {
    let sample = """
      # Skeat, page 5
      Some *emphasis*, **strong** and `code`; a snake_case name, 2 * 3.
      - a [link](https://gnorium.com/x) and ![image](a.png)
      1. first
      > quoted
      ---
      <!-- note -->
      ```xml
      <p n="1">a&amp;b</p>
      ```
      ```json
      {"a": 1}
      ```
      ```
      plain fence
      ```
      """
    XCTAssertEqual(
      colored(sample, .markdown),
      [
        "name:# Skeat, page 5", "pi:*", "pi:*", "pi:**", "pi:**", "cdata:`code`",
        "entity:-", "prefix:https://gnorium.com/x", "prefix:a.png",
        "entity:1.", "entity:>", "entity:---", "comment:<!-- note -->",
        "cdata:```xml", "tag:<", "name:p", "attr:n", "value:\"1\"", "tag:>", "entity:&amp;", "tag:</", "name:p",
        "tag:>", "cdata:```",
        "cdata:```json", "attr:\"a\"", "prefix:1", "cdata:```",
        "cdata:```", "cdata:plain fence", "cdata:```",
      ])
  }

  /// A chat template's text (user, 2026-10-16): its tokens read as tags,
  /// Markdown's own marks as before, and `<` before no name stays text.
  func testMarkdownTagsAndChatTemplateTokens() {
    let sample = """
      <|im_start|>user
      Zoom *here*, if x < y and a<3.<|im_end|>
      <tool_call>
      <function=zoom_image>
      <｜DSML｜ invoke name="zoom">
      """
    XCTAssertEqual(
      colored(sample, .markdown),
      [
        "tag:<", "name:|im_start|", "tag:>", "pi:*", "pi:*", "tag:<", "name:|im_end|", "tag:>",
        "tag:<", "name:tool_call", "tag:>", "tag:<", "name:function=zoom_image", "tag:>",
        "tag:<", "name:｜DSML｜", "attr:invoke", "attr:name", "value:\"zoom\"", "tag:>",
      ])
  }
}

/// Each role's highlight is styled on the scope and on every element in it
/// (user, 2026-10-15): WebKit styles a highlight by the rule of the element
/// whose text it covers and carries no `::highlight()` down to a child, so
/// an editor's text, in its `.code-line` spans, read black in Safari.
final class CodeSyntaxHighlightRuleTests: XCTestCase {
  func testEachRoleIsStyledOnTheScopeAndItsDescendants() {
    let selectors = CodeSyntax.highlightCSS("& .code-code").compactMap { ($0 as? CSSOM.CSSStyleRule)?.selectorText }
    for kind in CodeSyntax.Kind.allCases {
      let rule = selectors.first { $0.contains("::highlight(\(kind.highlightName))") }
      XCTAssertNotNil(rule, kind.highlightName)
      XCTAssertTrue(rule?.contains("& .code-code *::highlight(\(kind.highlightName))") == true, rule ?? "")
    }
  }
}
