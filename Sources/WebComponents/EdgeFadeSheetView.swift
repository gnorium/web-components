#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Where a faded value opened as a sheet is shown whole (`fadeOverflow`,
  /// `data-edge-fade="sheet"`; user, 2026-10-08): a `DialogSheetView` over
  /// the nearest `data-sheet-host` around the value, or the screen, the value
  /// as its title, wrapped at its spaces as prose is. A tight box—a reader's
  /// header—wrapping its value in place made a column a word wide and pushed
  /// what it headed out of sight.
  ///
  /// A view that has values to open so draws one, in its host
  /// (`ArtifactView`); `EdgeFadeHydration` fills it with the value as the box
  /// holds it, ids and fades aside, its links working.
  public struct EdgeFadeSheetView: HTMLContent {
    public init() {}

    public func build() -> DOM.Node {
      div {
        DialogSheetView(class: "edge-fade-sheet", ariaLabel: "—")
      }
      .class("edge-fade-sheet-view")
      .style {
        selector("&") {
          display(.contents)
        }
        // The value as prose: broken at its spaces, hyphenated where its
        // language allows, a word cut only where it is wider than the line
        // (a URL).
        descendant(".dialog-sheet-title") {
          alignSelf(.center)
          whiteSpace(.normal)
          overflowWrap(.breakWord)
          hyphens(.auto)
        }
      }
      .build()
    }
  }
#endif
