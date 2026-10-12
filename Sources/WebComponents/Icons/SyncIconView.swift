#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// Two arrows chasing each other around a circle, as a sync icon is
  /// drawn (Material's `sync`). Codex has no sync icon, so it is drawn in
  /// the house style (user, 2026-10-12), as SwapIconView is: a 128/1024
  /// stroke, butt ends, mitered arrowheads of SwapIconView's geometry. Two
  /// arcs of 150° on one circle, each ending in an arrowhead along the
  /// turn, the arrangement turned so its outer edges touch the box on
  /// every side (tight: the circle's outer edge at 512, its radius 448).
  public struct SyncIconView: HTMLContent {
    let iconSize: CSS.Length
    let `class`: String

    public init(
      size: CSS.Length,
      class: String = ""
    ) {
      self.iconSize = size
      self.class = `class`
    }

    /// The glyph's arcs and arrowheads, which UnSyncIconView cuts.
    @SVGBuilder
    static var glyph: [DOM.Node] {
      path()
        .d(
          M(504.18, 64.06), A(448, 448, 0, false, true, 742.74, 896.02),
          M(1006.2, 961.7), L(742.74, 896.02), L(808.43, 632.55))
      path()
        .d(
          M(519.82, 959.94), A(448, 448, 0, false, true, 281.26, 127.98),
          M(17.8, 62.3), L(281.26, 127.98), L(215.57, 391.45))
    }

    public func build() -> DOM.Node {
      svg {
        Self.glyph
      }
      .class(`class`.isEmpty ? "sync-icon-view" : "sync-icon-view \(`class`)")
      .style { height(iconSize) }
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .fill(.none)
      .stroke(.currentColor)
      .strokeWidth(128)
      .strokeLinecap(.butt)
      .strokeLinejoin(.miter)
      .build()
    }
  }
#endif
