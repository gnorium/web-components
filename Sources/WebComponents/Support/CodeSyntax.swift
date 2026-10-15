#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import WebTypes
#endif

/// Code colored by its grammar, in one set of roles across languages (user,
/// 2026-10-12): XML (`XMLSyntax`), JSON (`JSONSyntax`) and Markdown
/// (`MarkdownSyntax`) each read their text in one pass into stretches of
/// these kinds, and a kind keeps its color whatever the language. The
/// stretches are painted by the CSS Custom Highlight API (`CodeEditorHydration`),
/// one `Highlight` a kind holding every block's ranges of it, so nothing is
/// written into the text.
///
/// Seven named hues, never the state colors (red, green, blue, yellow,
/// orange), plus gray for comments and the text's own color, as Xcode's
/// roles tell them apart. Xcode itself paints a whole XML tag, its marks and
/// attribute names with it, in one color and its values in a second; these
/// roles part names from attributes, and a prefix, a reference, an
/// instruction and CDATA from both.
public enum CodeSyntax {
  public enum Kind: Int, Sendable, CaseIterable {
    /// Plain: XML's `<`, `</`, `>`, `/>`. The text's own color.
    case tag
    /// The keyword role, magenta: an XML element's name; JSON's `true`,
    /// `false` and `null`; a Markdown heading, its `#` with it.
    case name
    /// The attribute role, cyan: an XML attribute's name; a JSON object's
    /// key.
    case attribute
    /// The string role, lime: an XML attribute's value and a JSON string,
    /// quotes with them.
    case value
    /// The character role, pink: an XML reference (`&amp;`, `&#x17F;`); a
    /// Markdown list, quote or rule mark.
    case entity
    /// Indigo: an XML namespace prefix with its colon (`xml:`, `tei:`); a
    /// JSON number; a Markdown link's or image's URL.
    case prefix
    /// The preprocessor role, violet: `<?xml … ?>`, `<!DOCTYPE …>`; a
    /// Markdown emphasis mark (`*`, `**`, `_`).
    case pi
    /// Mint, literal text: an XML CDATA section; Markdown code, inline or
    /// fenced.
    case cdata
    /// Gray: an XML or HTML comment.
    case comment

    /// The highlight's name: what a `::highlight()` rule colors.
    public var highlightName: String {
      switch self {
      case .tag: return "code-tag"
      case .name: return "code-name"
      case .attribute: return "code-attr"
      case .value: return "code-value"
      case .entity: return "code-entity"
      case .prefix: return "code-prefix"
      case .pi: return "code-pi"
      case .cdata: return "code-cdata"
      case .comment: return "code-comment"
      }
    }
  }

  public struct Token: Sendable, Equatable {
    public let kind: Kind
    /// Half-open, in UTF-16 code units.
    public let start: Int
    public let end: Int

    public init(kind: Kind, start: Int, end: Int) {
      self.kind = kind
      self.start = start
      self.end = end
    }
  }

  /// The grammars a text is read by.
  public enum Language: Sendable {
    case xml
    case json
    case markdown
  }

  /// The colored stretches of `text` in `language`, in order.
  public static func tokens(_ text: [UInt8], language: Language) -> [Token] {
    switch language {
    case .xml: return XMLSyntax.tokens(text)
    case .json: return JSONSyntax.tokens(text)
    case .markdown: return MarkdownSyntax.tokens(text)
    }
  }

  /// A text's bytes counted in UTF-16 code units as a read moves forward,
  /// as a DOM `Range` counts a text node: no table of every byte, since
  /// every stretch is found after the one before. Embedded Swift carries no
  /// Unicode tables, so it is counted by lead bytes.
  struct Units {
    private var bytes = 0
    private var units = 0

    /// The units before byte `index`, which is never behind the last asked.
    mutating func at(_ index: Int, in text: [UInt8]) -> Int {
      while bytes < index {
        let byte = text[bytes]
        if byte & 0xC0 != 0x80 { units += byte >= 0xF0 ? 2 : 1 }
        bytes += 1
      }
      return units
    }
  }

  #if SERVER
    /// Each role's `::highlight()` rule on the text under `scope` (a
    /// selector from the styled view, `&` its root): the role's syntax
    /// token, the same in every view and language. On the scope and on
    /// every element in it: a highlight is styled by the rule of the
    /// element whose text it covers, and WebKit carries no `::highlight()`
    /// down to a child—an editor's text, in its `.code-line` spans, read
    /// black in Safari (user, 2026-10-15).
    @CSSBuilder
    public static func highlightCSS(_ scope: String) -> [CSSOM.CSSRule] {
      selector("\(scope)::highlight(code-tag)", "\(scope) *::highlight(code-tag)") { color(syntaxPlainText) }
      selector("\(scope) [data-code-kind='code-tag']") { color(syntaxPlainText) }
      selector("\(scope)::highlight(code-name)", "\(scope) *::highlight(code-name)") { color(syntaxKeywords) }
      selector("\(scope) [data-code-kind='code-name']") { color(syntaxKeywords) }
      selector("\(scope)::highlight(code-attr)", "\(scope) *::highlight(code-attr)") { color(syntaxAttributes) }
      selector("\(scope) [data-code-kind='code-attr']") { color(syntaxAttributes) }
      selector("\(scope)::highlight(code-value)", "\(scope) *::highlight(code-value)") { color(syntaxStrings) }
      selector("\(scope) [data-code-kind='code-value']") { color(syntaxStrings) }
      selector("\(scope)::highlight(code-entity)", "\(scope) *::highlight(code-entity)") { color(syntaxCharacters) }
      selector("\(scope) [data-code-kind='code-entity']") { color(syntaxCharacters) }
      selector("\(scope)::highlight(code-prefix)", "\(scope) *::highlight(code-prefix)") { color(syntaxOtherTypeNames) }
      selector("\(scope) [data-code-kind='code-prefix']") { color(syntaxOtherTypeNames) }
      selector("\(scope)::highlight(code-pi)", "\(scope) *::highlight(code-pi)") { color(syntaxPreprocessorStatements) }
      selector("\(scope) [data-code-kind='code-pi']") { color(syntaxPreprocessorStatements) }
      selector("\(scope)::highlight(code-cdata)", "\(scope) *::highlight(code-cdata)") { color(syntaxOtherConstants) }
      selector("\(scope) [data-code-kind='code-cdata']") { color(syntaxOtherConstants) }
      selector("\(scope)::highlight(code-comment)", "\(scope) *::highlight(code-comment)") { color(syntaxComments) }
      selector("\(scope) [data-code-kind='code-comment']") { color(syntaxComments) }
    }
  #endif
}
