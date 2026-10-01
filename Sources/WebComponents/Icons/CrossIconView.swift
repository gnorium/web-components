import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Visual cross / x-mark leaf. Use for close, failed, or clear—meaning is call-site.
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
        .d(M(102.11, 0), L(1024, 921.89), L(921.89, 1024), L(0, 102.84), Z())

      path()
        .d(M(1024, 102.11), L(102.11, 1024), L(0, 921.89), L(921.89, 0), Z())
    }
    .class(
      stringIsEmpty(`class`) ? "cross-icon-view" : "cross-icon-view \(`class`)"
    )
    .width(width)
    .height(height)
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT factory—create CrossIconView DOM matching server-rendered markup.
  public enum CrossIconFactory {
    public static func createElement(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CrossIconView(width: width, height: height, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
