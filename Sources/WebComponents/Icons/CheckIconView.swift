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
        .d(
          M(6.3481, 14.4141), L(1.6041, 9.6701), L(0, 11.2742), L(6.3481, 17.6337), L(20, 3.9818),
          L(18.3959, 2.3663), Z())
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
