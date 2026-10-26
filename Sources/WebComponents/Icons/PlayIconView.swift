import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `play` (ISC; THIRD_PARTY_NOTICES.md): Lucide's `play` (ISC;
/// THIRD_PARTY_NOTICES.md), to play a replay on (user, 2026-10-21). Lucide's
/// own geometry (lucide-static 1.60.0), carried flat into the house box: the
/// long edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins,
/// tight to the box (user, 2026-10-26). SERVER + CLIENT for PlayIconFactory:
/// the replay's Pause/Play swaps it.
public struct PlayIconView: HTMLContent {
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
      path().d("M46.55 150A103.43 103.43 0 0 1 202.1 60.64L822.51 422.54A103.43 103.43 0 0 1 822.67 601.36L202.1 963.36A103.43 103.43 0 0 1 46.55 874Z")
    }
    .class(stringIsEmpty(`class`) ? "play-icon-view" : "play-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 920.58, 1024)
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

#if CLIENT
  import WebAPIs

  public enum PlayIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = PlayIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
