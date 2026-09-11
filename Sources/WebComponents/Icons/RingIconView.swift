import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Hollow circle leaf (○). Available on SERVER + CLIENT for RingIconFactory.
public struct RingIconView: HTMLContent {
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
      circle()
        .cx(10)
        .cy(10)
        .r(8.75)
        .fill(.none)
        .stroke(.currentColor)
        .strokeWidth(2.5)
    }
    .class(
      stringIsEmpty(`class`) ? "ring-icon-view" : "ring-icon-view \(`class`)"
    )
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
  }
}

#if CLIENT
  import WebAPIs

  public enum RingIconFactory {
    public static func createElement(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = RingIconView(width: width, height: height, class: `class`)
      wrapper.innerHTML = renderHTML { view.render() }
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
