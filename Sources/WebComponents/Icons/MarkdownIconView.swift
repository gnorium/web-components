#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// The Markdown mark (`M↓` in a rounded rectangle) by Dustin Curtis
  /// (dcurtis/markdown-mark, CC0; credited in THIRD_PARTY_NOTICES.md), the
  /// Raw switch of a Markdown source (user, 2026-10-12). Its outline
  /// variant redrawn in strokes on the mark's own 208 × 128 grid: the
  /// frame's centerline 5–203 × 5–123 with corners of radius 14, the
  /// filled M and arrow of the original as strokes along their middles
  /// (the M's legs at 40 and 100, its V down to 69.5; the arrow's shaft at
  /// 155, its head 24 wide on each side, its tip at 89). Fitted to the
  /// house box by IconStrokeFit: the long edge 1024, `iconStrokeWidth`
  /// thick, round caps and joins, the frame's outer edges tight to the box.
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
      let fit = IconStrokeFit(minX: 5, minY: 5, maxX: 203, maxY: 123)
      return svg {
        g {
          path()
            .d(
              M(19, 5), H(189), A(14, 14, 0, false, true, 203, 19), V(109),
              A(14, 14, 0, false, true, 189, 123), H(19), A(14, 14, 0, false, true, 5, 109), V(19),
              A(14, 14, 0, false, true, 19, 5), Z())
          path().d(M(40, 89), V(39), L(70, 69.5), L(100, 39), V(89))
          path().d(M(155, 39), V(89), M(131, 65), L(155, 89), L(179, 65))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "markdown-icon-view" : "markdown-icon-view \(`class`)")
      .style { width(iconSize) }
      .viewBox(0, 0, fit.width, fit.height)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
