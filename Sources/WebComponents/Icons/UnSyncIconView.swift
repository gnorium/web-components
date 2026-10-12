#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// SyncIconView struck through, as Codex strikes its "un-" icons
  /// (unLink, unBlock): a slash of the same 128/1024 weight from the top
  /// left corner to the bottom right, its ends cut square to it at the
  /// box's edges, and the glyph cut away for a gap of the slash's half
  /// weight on each side of it. Codex has no sync icon (user, 2026-10-12).
  public struct UnSyncIconView: HTMLContent {
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
        defs {
          // What is kept of the glyph: either side of the slash and its
          // gaps (|x − y| ≥ 128√2, the slash's 64 and a 64 gap, at 45°),
          // out past the box so nothing at its edge is clipped.
          clipPath {
            polygon().points((53.02, -128), (1152, -128), (1152, 970.98))
            polygon().points((-128, 53.02), (-128, 1152), (970.98, 1152))
          }
          .id("un-sync-icon-cut")
        }
        g {
          SyncIconView.glyph
        }
        .clipPath("url(#un-sync-icon-cut)")
        // The slash: |x − y| ≤ 64√2, its ends at the box's edges.
        polygon()
          .points((90.51, 0), (0, 90.51), (933.49, 1024), (1024, 933.49))
          .fill(.currentColor)
          .stroke(.none)
      }
      .class(`class`.isEmpty ? "un-sync-icon-view" : "un-sync-icon-view \(`class`)")
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
