#if SERVER
  import CSSBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Lucide's `panel-top` (ISC; THIRD_PARTY_NOTICES.md): a sheet with its top
  /// band ruled off, for a document's header (user, 2026-10-20: the testament's
  /// header in its XML pane). Lucide's own geometry (lucide-static 1.60.0),
  /// carried flat into the house box: the long edge 1024, the house stroke
  /// (`iconStrokeWidth`), round caps and joins, tight to the box (user,
  /// 2026-10-26).
  public struct PanelTopIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(size: CSS.Length, class: String = "") {
      self.iconSize = size
      self.class = `class`
    }

    public func build() -> DOM.Node {
      svg {
        rect().x(46.55).y(46.55).width(930.91).height(930.91).rx(103.43)
        path().d("M46.55 356.85L977.45 356.85")
      }
      .class(stringIsEmpty(`class`) ? "panel-top-icon-view" : "panel-top-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(93.09)
      .strokeLinecap(.round)
      .strokeLinejoin(.round)
      .ariaHidden(true)
      .build()
    }
  }
#endif
