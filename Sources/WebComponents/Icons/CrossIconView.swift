import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Visual cross / x-mark leaf. Use for close, failed, or clear — meaning is call-site.
/// Available on SERVER + CLIENT so CrossIconFactory can render without hand-built SVG replicas.
public struct CrossIconView: HTMLContent {
  let width: CSS.Length
  let height: CSS.Length
  let `class`: String

  public init(
    width: CSS.Length = px(20),
    height: CSS.Length = px(20),
    class: String = ""
  ) {
    self.width = width
    self.height = height
    self.class = `class`
  }

  public func build() -> DOM.Node {
    svg {
      path()
        .d(M(1.9943, 0), L(20, 18.0057), L(18.0057, 20), L(0, 2.0085), Z())

      path()
        .d(M(20, 1.9943), L(1.9943, 20), L(0, 18.0057), L(18.0057, 0), Z())
    }
    .class(
      stringIsEmpty(`class`) ? "cross-icon-view" : "cross-icon-view \(`class`)"
    )
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT factory — create CrossIconView DOM matching server-rendered markup.
  public enum CrossIconFactory {
    public static func createElement(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CrossIconView(width: width, height: height, class: `class`)
      wrapper.innerHTML = renderHTML { view.render() }
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
