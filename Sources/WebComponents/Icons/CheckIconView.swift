import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Visual check-mark leaf. Available on SERVER + CLIENT for CheckIconFactory.
public struct CheckIconView: HTMLContent {
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
          M(325.02, 616.85), L(82.13, 373.95), l(-82.13, 82.13), L(325.02, 781.69), L(1024, 82.71),
          l(-82.13, -82.71), Z())
    }
    .class(
      stringIsEmpty(`class`) ? "check-icon-view" : "check-icon-view \(`class`)"
    )
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 781.69)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}

#if CLIENT
  import WebAPIs

  public enum CheckIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = CheckIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
