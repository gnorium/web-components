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
  public let width: Length
  public let height: Length
  public var `class`: String
  public var data: [TableView.AttributePair] = []
  public var style: [(@Sendable () -> [CSSRule])] = []

  public init(
    id: String,
    expanded: Bool = false,
    width: Length = px(20),
    height: Length = px(20),
    class: String = ""
  ) {
    self.id = id
    self.expanded = expanded
    self.width = width
    self.height = height
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

  public func style(@CSSBuilder _ rules: @escaping @Sendable () -> [CSSRule]) -> Self {
    var copy = self
    copy.style.append(rules)
    return copy
  }

  public func render() -> Node {
    var svgNode = svg {
      polygon()
        .points((2.5, 4.75), (10, 12.25), (17.5, 4.75), (19, 6.25), (10, 15.25), (1, 6.25))
        .fill(.currentColor)
    }
    .class(stringIsEmpty(`class`) ? "animated-chevron" : "animated-chevron \(`class`)")
    .id("\(id)-chevron")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")
    .data("expanded", expanded ? "true" : "false")
    .style {
      transition(.transform, ms(200), .ease)
      transform(rotate(expanded ? deg(0) : deg(-90)))
      transformOrigin(perc(50))
    }

    for pair in data {
      svgNode = svgNode.data(pair.key, pair.value)
    }

    for s in style {
      svgNode = svgNode.style(s)
    }

    return svgNode
  }
}

#if CLIENT
  import WebAPIs

  public enum AnimatedRightDownChevronFactory {
    public static func createElement(id: String, expanded: Bool = false) -> Element {
      let wrapper = document.createElement(.span)
      let view = AnimatedRightDownChevronView(id: id, expanded: expanded)
      wrapper.innerHTML = buildHTML { view.render() }
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
