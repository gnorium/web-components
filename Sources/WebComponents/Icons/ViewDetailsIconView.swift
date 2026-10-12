import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct ViewDetailsIconView: HTMLContent {
  let `class`: String
  let iconSize: CSS.Length

  public init(
    class: String = "",
    size: CSS.Length
  ) {
    self.class = `class`
    self.iconSize = size
  }

  public func build() -> DOM.Node {
    let fit = IconStrokeFit(minX: 51.2, minY: 51.2, maxX: 972.8, maxY: 972.8)
    return svg {
      g {
        rect()
          .width(px(358.4))
          .height(px(358.4))
          .x(px(51.2))
          .y(px(51.2))
          .rx(px(51.2))

        rect()
          .width(px(358.4))
          .height(px(358.4))
          .x(px(51.2))
          .y(px(614.4))
          .rx(px(51.2))

        path()
          .d(
            M(614.4, 102.4), h(358.4), M(614.4, 358.4), h(358.4), M(614.4, 665.6), h(358.4),
            M(614.4, 921.6), h(358.4))
      }
      .transform(fit.transform)
      .strokeWidth(fit.strokeWidth)
    }
    .class(stringIsEmpty(`class`) ? "view-details-icon-view" : "view-details-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, fit.width, fit.height)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)

  }
}
