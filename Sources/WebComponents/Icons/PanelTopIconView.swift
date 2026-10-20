#if SERVER
  import CSSBuilder
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `panel-top` (ISC; THIRD_PARTY_NOTICES.md): a sheet with its
  /// top band ruled off, for a document's header (user, 2026-10-20: the
  /// testament's header in its XML pane). Lucide's own 24-grid geometry,
  /// fitted to the house box by IconStrokeFit: the long edge 1024,
  /// `iconStrokeWidth` thick, round caps and joins, the outer edges tight to
  /// the box.
  public struct PanelTopIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(size: CSS.Length, class: String = "") {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      let fit = IconStrokeFit(minX: 3, minY: 3, maxX: 21, maxY: 21)
      return svg {
        g {
          path().d(
            M(5, 3), H(19), a(2, 2, 0, false, true, 2, 2), V(19), a(2, 2, 0, false, true, -2, 2), H(5),
            a(2, 2, 0, false, true, -2, -2), V(5), a(2, 2, 0, false, true, 2, -2), Z())
          path().d(M(3, 9), h(18))
        }
        .transform(fit.transform)
        .strokeWidth(fit.strokeWidth)
      }
      .class(`class`.isEmpty ? "panel-top-icon-view" : "panel-top-icon-view \(`class`)")
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
