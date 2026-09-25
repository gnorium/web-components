import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Visual check-mark leaf. Available on SERVER + CLIENT for CheckIconFactory.
public struct CheckIconView: HTMLContent {
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
        .d(M(7, 14.17), L(2.83, 10), l(-1.41, 1.41), L(7, 17), L(19, 5), l(-1.41, -1.42), Z())
    }
    .class(
      stringIsEmpty(`class`) ? "check-icon-view" : "check-icon-view \(`class`)"
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

  public enum CheckIconFactory {
    public static func createElement(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CheckIconView(width: width, height: height, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
