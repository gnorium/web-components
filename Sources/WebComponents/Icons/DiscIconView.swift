import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Filled circle leaf (●). Available on SERVER + CLIENT for DiscIconFactory.
public struct DiscIconView: HTMLContent {
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
      circle()
        .cx(512)
        .cy(512)
        .r(512)
    }
    .class(
      stringIsEmpty(`class`) ? "disc-icon-view" : "disc-icon-view \(`class`)"
    )
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

#if CLIENT
  import WebAPIs

  public enum DiscIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = DiscIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
