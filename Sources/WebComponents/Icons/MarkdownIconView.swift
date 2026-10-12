#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Markdown mark (`M↓` in a rounded rectangle) by Dustin Curtis
  /// (dcurtis/markdown-mark, CC0; credited in THIRD_PARTY_NOTICES.md), the
  /// Raw switch of a Markdown source (user, 2026-10-12). Its outline
  /// variant redrawn in strokes on the house grid: a 128/1024 stroke with
  /// round caps and joins, the frame's outer edges tight to the box (1024
  /// × 704, near the mark's own 13:8), the frame's corners of radius 96 on
  /// its centerline. The original's filled M and arrow are stroked here,
  /// spaced 32 inside the frame and 64 apart, so the M keeps its V at
  /// this weight.
  public struct MarkdownIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(
      size: CSS.Length,
      class: String = ""
    ) {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .d(
            M(160, 64), H(864), A(96, 96, 0, false, true, 960, 160), V(544),
            A(96, 96, 0, false, true, 864, 640), H(160), A(96, 96, 0, false, true, 64, 544), V(160),
            A(96, 96, 0, false, true, 160, 64), Z())
        path()
          .d(M(224, 480), V(224), L(336, 364.8), L(448, 224), V(480))
        path()
          .d(M(720, 224), V(480), M(640, 400), L(720, 480), L(800, 400))
      }
      .class(`class`.isEmpty ? "markdown-icon-view" : "markdown-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, 1024, 704)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
