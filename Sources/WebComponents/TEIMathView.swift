#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import MathMLBuilder
  import WebTypes
  import XMLUtilities

  /// A transcript's formula drawn as the browser draws MathML (MathML Core):
  /// the page's reading (``TEIView``, each symbol a word) and a diff's
  /// (``DiffView``, the formula whole) draw it alike.
  ///
  /// A mark that could not be read (TEI's `<gap>` in MathML's `<semantics>`,
  /// gnorium-python `bibliographic_explication/formulas.py`) is drawn as a gap in the
  /// text is, its reason in brackets, "[illegible]": a statement that there
  /// is no symbol, not one.
  public struct TEIMathView: HTMLContent {
    /// How a token element is drawn: attributes of its own, and its content.
    public struct Token {
      public let attributes: [(String, String)]
      public let content: [DOM.Node]

      public init(attributes: [(String, String)] = [], content: [DOM.Node]) {
        self.attributes = attributes
        self.content = content
      }
    }

    let formula: TEIMath
    let tokens: @Sendable ([TEILine.Run]) -> Token

    /// `tokens` draws a token's runs; by default, their text. An operator's
    /// text should stay the `<mo>`'s own text: MathML Core finds its spacing
    /// (a fence's none, a relation's thick space) by that text, and an
    /// element around it loses it ("sin ( x )").
    public init(_ formula: TEIMath, tokens: @escaping @Sendable ([TEILine.Run]) -> Token = TEIMathView.text) {
      self.formula = formula
      self.tokens = tokens
    }

    public static func text(_ runs: [TEILine.Run]) -> Token {
      Token(content: [DOM.Text(runs.map(\.text).joined())])
    }

    public func build() -> DOM.Node {
      func drawn(_ node: TEIMath.Node) -> DOM.Node {
        switch node {
        case .element(let name, let attributes, let children):
          return MathML.MathMLElement(name, attributes: attributes.map { ($0.name, $0.value) }) {
            for child in children { drawn(child) }
          }
        case .token(let name, let attributes, let runs):
          let token = tokens(runs)
          return MathML.MathMLElement(name, attributes: attributes.map { ($0.name, $0.value) } + token.attributes) {
            token.content
          }
        case .gap(let reason):
          return MathML.MathMLElement("mtext", attributes: [("class", "tei-math-gap")]) {
            "[\(reason.isEmpty ? "gap" : reason)]"
          }
        }
      }
      return span {
        MathML.MathMLElement("math", attributes: [("display", formula.display ? "block" : "inline")]) {
          for node in formula.content { drawn(node) }
        }
      }
      .class("tei-math-view")
      .data("display", formula.display ? "block" : "inline")
      .style {
        // A formula set on its own line scrolls within the page's width
        // rather than widening it.
        selector("&[data-display='block']") {
          display(.block)
          maxWidth(perc(100))
          overflowX(.auto)
        }
        // Not a symbol on the page: a statement that there is none, as a gap
        // in the text says it.
        descendant(".tei-math-gap") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          fontStyle(.italic)
          color(colorSubtle)
        }
      }
      .build()
    }
  }
#endif
