import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Filled circle leaf (●). Available on SERVER + CLIENT for DiscIconFactory.
public struct DiscIconView: HTMLContent {
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
        .r(10)
    }
    .class(
      stringIsEmpty(`class`) ? "disc-icon-view" : "disc-icon-view \(`class`)"
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

  public enum DiscIconFactory {
    public static func createElement(
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = DiscIconView(width: width, height: height, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
