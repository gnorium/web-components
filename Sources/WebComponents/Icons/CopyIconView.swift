import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Overlapping-rectangles copy glyph. Available on SERVER + CLIENT for CopyIconFactory.
public struct CopyIconView: HTMLContent {
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
          M(113.78, 113.78), h(455.11), v(113.78), h(113.78), V(113.78),
          c(0, -62.58, -50.92, -113.78, -113.78, -113.78), H(113.78),
          c(-62.58, 0, -113.78, 50.92, -113.78, 113.78), v(455.11),
          c(0, 62.58, 50.92, 113.78, 113.78, 113.78), h(113.78), v(-113.78), H(113.78), Z())
      path()
        .d(
          M(455.11, 455.11), h(455.11), v(455.11), H(455.11), Z(), m(0, -113.78),
          c(-62.58, 0, -113.78, 50.92, -113.78, 113.78), v(455.11),
          c(0, 62.58, 50.92, 113.78, 113.78, 113.78), h(455.11),
          c(62.58, 0, 113.78, -50.92, 113.78, -113.78), V(455.11),
          c(0, -62.58, -50.92, -113.78, -113.78, -113.78), Z())
    }
    .class(
      stringIsEmpty(`class`) ? "copy-icon-view" : "copy-icon-view \(`class`)"
    )
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

#if CLIENT
  import WebAPIs

  public enum CopyIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CopyIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
