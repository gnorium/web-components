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

  /// A DeepSeek tool result (deepseek-v4.1 chat_template.jinja, line 204):
  /// its JSON colored inside the tags; a result that is text stays Markdown.
  func testChatTemplateToolResult() {
    XCTAssertEqual(
      colored(#"<｜User｜><tool_result>{"ok": true, "tool": "zoom_image", "x": [1, null]}</tool_result>"#, .chatTemplate),
      [
        "tag:<", "name:｜User｜", "tag:>", "tag:<", "name:tool_result", "tag:>",
        "attr:\"ok\"", "name:true", "attr:\"tool\"", "value:\"zoom_image\"", "attr:\"x\"", "prefix:1", "name:null",
        "tag:</", "name:tool_result", "tag:>",
      ])
    XCTAssertEqual(
      colored("<tool_result>Page *5*, not found: true</tool_result>", .chatTemplate),
      ["tag:<", "name:tool_result", "tag:>", "pi:*", "pi:*", "tag:</", "name:tool_result", "tag:>"])
  }

  /// JSON across lines, a `<!--` and backticks in its strings never read
  /// as Markdown, and Markdown after it read as before.
  func testChatTemplateMultilineToolResult() {
    let sample = """
      <tool_result>{
        "note": "<!-- ``` -->",
        "n": -2.5e3
      }</tool_result>
      **done**
      """
    XCTAssertEqual(
      colored(sample, .chatTemplate),
      [
        "tag:<", "name:tool_result", "tag:>", "attr:\"note\"", "value:\"<!-- ``` -->\"", "attr:\"n\"",
        "prefix:-2.5e3", "tag:</", "name:tool_result", "tag:>", "pi:**", "pi:**",
      ])
  }

  /// DSML parameters (deepseek-v4.1 chat_template.jinja, line 227): a
  /// `string="false"` value is JSON and colored; a `string="true"` value
  /// is a raw string and stays plain, however JSON it looks.
  func testChatTemplateDSMLParameters() {
    let sample = """
      <｜DSML｜ parameter name="x" string="false">320</｜DSML｜ parameter>
      <｜DSML｜ parameter name="box" string="false">{"w": 2}</｜DSML｜ parameter>
      <｜DSML｜ parameter name="q" string="true">{"w": 2}</｜DSML｜ parameter>
      """
    let tag = ["tag:<", "name:｜DSML｜", "attr:parameter", "attr:name"]
    let close = ["tag:</", "name:｜DSML｜", "attr:parameter", "tag:>"]
    XCTAssertEqual(
      colored(sample, .chatTemplate),
      tag + ["value:\"x\"", "attr:string", "value:\"false\"", "tag:>", "prefix:320"] + close
        + tag + ["value:\"box\"", "attr:string", "value:\"false\"", "tag:>", "attr:\"w\"", "prefix:2"] + close
        + tag + ["value:\"q\"", "attr:string", "value:\"true\"", "tag:>"] + close)
  }

  /// Tool schemas (deepseek-v4.1 chat_template.jinja, lines 69–71): each
  /// line between the header and the closing instruction colored as JSON
  /// where it is one value; a line that is not stays Markdown, and a
  /// wrapper inside a schema's string is not read as one.
  func testChatTemplateToolSchemas() {
    let sample = """
      ### Available Tool Schemas

      {"name": "zoom_image", "description": "<tool_result>x</tool_result>"}
      not *json*
      {"name": "read_page"}

      You MUST strictly follow the above defined tool name and parameter schemas to invoke tool calls.
      {"after": 1}
      """
    XCTAssertEqual(
      colored(sample, .chatTemplate),
      [
        "name:### Available Tool Schemas",
        "attr:\"name\"", "value:\"zoom_image\"", "attr:\"description\"",
        "value:\"<tool_result>x</tool_result>\"",
        "pi:*", "pi:*",
        "attr:\"name\"", "value:\"read_page\"",
      ])
  }

  /// Outside a Raw, Markdown reads the same text as before: no JSON.
  func testMarkdownOutsideRawUnchanged() {
    let sample = #"<tool_result>{"ok": true}</tool_result>"#
    XCTAssertEqual(
      colored(sample, .markdown),
      ["tag:<", "name:tool_result", "tag:>", "tag:</", "name:tool_result", "tag:>"])
    XCTAssertEqual(
      CodeSyntax.tokens(Array("# A\n*b* `c`".utf8), language: .chatTemplate),
      CodeSyntax.tokens(Array("# A\n*b* `c`".utf8), language: .markdown))
  }

  /// JSON as RFC 8259 reads it: strict where the coloring forgives.
  func testJSONAccepts() {
    for valid in [#" {"a": [1, -0.5e+2, "\u00e9\n"], "b": {}} "#, "320", "null", #""s""#, "[]"] {
      XCTAssertTrue(JSONSyntax.accepts(Array(valid.utf8), from: 0, to: valid.utf8.count), valid)
    }
    for invalid in ["", "{a: 1}", "[1,]", "01", "1.", "tru", #""a"#, "{\"a\" 1}", "1 2", "Page 5"] {
      XCTAssertFalse(JSONSyntax.accepts(Array(invalid.utf8), from: 0, to: invalid.utf8.count), invalid)
    }
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
