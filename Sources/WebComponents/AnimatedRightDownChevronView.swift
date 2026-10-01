import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// An animated chevron SVG that rotates between collapsed (> right) and
/// expanded (v down) states via CSS `transform: rotate()` transition.
public struct AnimatedRightDownChevronView: HTMLContent {
  public let id: String
  public let expanded: Bool
  public let size: CSS.Length
  public var `class`: String
  public var data: [TableView.AttributePair] = []
  public var customStyleRules: [(@Sendable () -> [CSSOM.CSSRule])] = []

  public init(
    id: String,
    expanded: Bool = false,
    size: CSS.Length,
    class: String = ""
  ) {
    self.id = id
    self.expanded = expanded
    self.size = size
    self.class = `class`
  }

  // MARK: - Modifiers

  public func `class`(_ value: String) -> Self {
    var copy = self
    copy.class = value
    return copy
  }

  public func data(_ key: String, _ value: String) -> Self {
    var copy = self
    copy.data.append(TableView.AttributePair(key, value))
    return copy
  }

  public func style(@CSSBuilder _ rules: @escaping @Sendable () -> [CSSOM.CSSRule]) -> Self {
    var copy = self
    copy.customStyleRules.append(rules)
    return copy
  }

  public func build() -> DOM.Node {
    var svgNode = svg {
      polyline()
        .points("41.58,247.39 512,717.81 982.42,247.39")
    }
    .class(stringIsEmpty(`class`) ? "animated-right-down-chevron-view" : "animated-right-down-chevron-view \(`class`)")
    .id("\(id)-chevron")
    .style { height(size) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeWidth(117.61)
    .strokeLinecap(.butt)
    .strokeLinejoin(.miter)
    .data("expanded", expanded ? "true" : "false")
    .style {
      selector("&") {
        transition(.transform, ms(200), .ease)
        transformOrigin(perc(50))
      }
      selector("&[data-expanded='true']") { transform(rotate(deg(0))) }
      selector("&[data-expanded='false']") { transform(rotate(deg(-90))) }

      for sty in customStyleRules {
        sty()
      }
    }

    for pair in data {
      svgNode = svgNode.data(pair.key, pair.value)
    }

    return svgNode
  }
}

#if CLIENT
  import WebAPIs

  public enum AnimatedRightDownChevronFactory {
    public static func createElement(id: String, expanded: Bool = false, size: CSS.Length) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = AnimatedRightDownChevronView(id: id, expanded: expanded, size: size)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
