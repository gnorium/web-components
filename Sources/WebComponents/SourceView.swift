#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Source text, shown as source: monospaced, on the page's own ground, and
  /// coloured by the site's syntax tokens rather than by a highlight.js theme.
  ///
  /// The colouring itself happens on the client, and only for a block someone
  /// can actually see — see `SourceHydration`. A document of a few hundred
  /// thousand characters is not worth colouring until it is open.
  public struct SourceView: HTMLContent {
    let source: String
    let language: String

    public init(_ source: String, language: String = "xml") {
      self.source = source
      self.language = language
    }

    public func build() -> DOM.Node {
      pre {
        code { source }
          .class("source-view-code language-\(language)")
      }
      .class("source-view")
      .style {
        selector("&") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          lineHeight(lineHeightXSmall20)
          color(syntaxPlainText)
          backgroundColor(backgroundColorBase)
          whiteSpace(.preWrap)
          overflowWrap(.breakWord)
          margin(0)
          padding(0)
        }
        descendant(".source-view-code") {
          fontFamily(typographyFontMono)
          backgroundColor(.transparent)
          color(.inherit)
          padding(0)
        }
        // One palette for code across the site: the same tokens the session
        // trace colours a tool call's markup with.
        selector(".source-view .hljs-tag", ".source-view .hljs-name") {
          color(syntaxKeywords).important()
        }
        selector(".source-view .hljs-attr", ".source-view .hljs-attribute") {
          color(syntaxAttributes).important()
        }
        selector(".source-view .hljs-string") { color(syntaxStrings).important() }
        selector(".source-view .hljs-comment") { color(syntaxComments).important() }
        selector(".source-view .hljs-meta") { color(syntaxOtherDeclarations).important() }
        selector(".source-view .hljs-symbol", ".source-view .hljs-punctuation") {
          color(syntaxPlainText).important()
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// Colours the source blocks someone can see, when they can see them.
  ///
  /// A page may hold a thousand blocks — one per page of a transcription —
  /// behind switches, accordions and a viewer's pager. Colouring them all at
  /// load would spend a second of the main thread on markup nobody has asked
  /// for, so nothing happens until a block has a box on screen: at load, after
  /// any click that may have opened one, and whenever an object viewer turns to
  /// another canvas. A block already coloured is left alone.
  public final class SourceHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: SourceHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector(".source-view") != nil else { return }
      let hydration = SourceHydration()
      hydration.hydrate()
      instance = hydration
    }

    public init() {}

    public func hydrate() {
      Self.highlightVisible()
      _ = document.addEventListener(.click) { _ in
        _ = window.requestAnimationFrame { Self.highlightVisible() }
      }
      if let viewer = document.querySelector(".artifact-view") {
        _ = viewer.addEventListener("artifact-canvas-change") { _ in
          Self.highlightVisible()
        }
      }
    }

    public static func highlightVisible() {
      for block in document.querySelectorAll(".source-view-code") {
        guard !stringEquals(block.dataset["highlighted"] ?? "", "true") else { continue }
        guard let rect = block.getBoundingClientRect(), rect.height > 0 else { continue }
        block.setAttribute(data("highlighted"), "true")
        HighlightJS.highlightElement(elementID: block.id)
      }
    }
  }
#endif
