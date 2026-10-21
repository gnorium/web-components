import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `pause` (ISC; THIRD_PARTY_NOTICES.md), to hold a replay where
/// it stands (user, 2026-10-21). Lucide's own 24-grid geometry (tag
/// 1.60.0), fitted to the house box by IconStrokeFit: the long edge 1024,
/// `iconStrokeWidth` thick, round caps and joins, the outer edges tight to
/// the box. SERVER + CLIENT for PauseIconFactory: the replay's Pause/Play
/// swaps it.
public struct PauseIconView: HTMLContent {
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
    let fit = IconStrokeFit(minX: 5, minY: 3, maxX: 19, maxY: 21)
    return svg {
      g {
        rect()
          .width(px(5))
          .height(px(18))
          .x(px(14))
          .y(px(3))
          .rx(px(1))

        rect()
          .width(px(5))
          .height(px(18))
          .x(px(5))
          .y(px(3))
          .rx(px(1))
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "pause-icon-view" : "pause-icon-view \(`class`)")
    .style { height(iconSize) }
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

#if CLIENT
  import WebAPIs

  public enum PauseIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = PauseIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
