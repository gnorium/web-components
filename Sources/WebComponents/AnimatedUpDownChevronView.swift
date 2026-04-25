import CSSBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

private func pointsToString(_ points: [(Double, Double)]) -> String {
  var result = ""
  for i in 0..<points.count {
    if i > 0 { result = "\(result) " }
    let p = points[i]
    result = "\(result)\(doubleToString(p.0)),\(doubleToString(p.1))"
  }
  return result
}

/// An animated filled chevron SVG that morphs between collapsed (v down) and
/// expanded (^ up) states via SMIL `<animate>` on the polygon `points` attribute.
/// Used for table sort indicators and group expand/collapse toggles.
///
/// To trigger the animation from JS/CLIENT:
/// ```js
/// let el = document.querySelector('#my-id-up-down-chevron animate');
/// el.beginElement();
/// setTimeout(() => {
///   let from = el.getAttribute('from'), to = el.getAttribute('to');
///   el.parentElement.setAttribute('points', to);
///   el.setAttribute('from', to);
///   el.setAttribute('to', from);
/// }, 210);
/// ```
public struct AnimatedUpDownChevronView: HTMLContent {
  public static let collapsedPoints: [(Double, Double)] = [
    (2.5, 4.75), (10, 12.25), (17.5, 4.75), (19, 6.25), (10, 15.25), (1, 6.25),
  ]
  public static let expandedPoints: [(Double, Double)] = [
    (2.5, 15.25), (10, 7.75), (17.5, 15.25), (19, 13.75), (10, 4.75), (1, 13.75),
  ]

  let id: String
  let expanded: Bool
  let width: Length
  let height: Length
  let `class`: String

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

  public func render() -> Node {
    // MARK: - Chevron Geometry (20x20 viewBox)
    // Collapsed (v down): (2.5, 4.75) (10, 12.25) (17.5, 4.75) (19, 6.25) (10, 15.25) (1, 6.25)
    // Expanded (^ up):   (2.5, 15.25) (10, 7.75) (17.5, 15.25) (19, 13.75) (10, 4.75) (1, 13.75)

    return svg {
      if expanded {
        polygon {
          animate()
            .attributeName(.points)
            .from(pointsToString(Self.expandedPoints))
            .to(pointsToString(Self.collapsedPoints))
            .dur(ms(200))
            .fill(.freeze)
            .begin(.indefinite)
        }
        .points(pointsToString(Self.expandedPoints))
        .fill(.currentColor)
      } else {
        polygon {
          animate()
            .attributeName(.points)
            .from(pointsToString(Self.collapsedPoints))
            .to(pointsToString(Self.expandedPoints))
            .dur(ms(200))
            .fill(.freeze)
            .begin(.indefinite)
        }
        .points(pointsToString(Self.collapsedPoints))
        .fill(.currentColor)
      }
    }
    .class(
      stringIsEmpty(`class`) ? "animated-up-down-chevron-view" : "animated-up-down-chevron-view \(`class`)"
    )
    .id("\(id)-up-down-chevron")
    .width(width)
    .height(height)
    .viewBox(0, 0, 20, 20)
    .xmlns("http://www.w3.org/2000/svg")

  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT controller for an AnimatedUpDownChevronView DOM element.
  /// Handles SMIL animation morphing between collapsed and expanded states.
  public class AnimatedUpDownChevronInstance: @unchecked Sendable {
    private let svg: Element

    public init?(element: Element) {
      if element.classList.contains("animated-up-down-chevron-view") {
        self.svg = element
      } else if let found = element.querySelector(".animated-up-down-chevron-view") {
        self.svg = found
      } else {
        return nil
      }

      self.ensureAnimateElements()
    }

    /// Re-creates server-rendered <animate> elements so beginElement() works reliably in WASM.
    private func ensureAnimateElements() {
      let polygons = svg.querySelectorAll("polygon")
      for polygon in polygons {
        if let animateEl = polygon.querySelector("animate") {
          let from = animateEl.getAttribute(.from) ?? ""
          let to = animateEl.getAttribute(.to) ?? ""
          polygon.innerHTML = buildHTML {
            animate()
              .attributeName(.points)
              .from(from)
              .to(to)
              .dur(ms(200))
              .fill(.freeze)
              .begin(.indefinite)
          }
        }
      }
    }

    public func morph(toExpanded: Bool) {
      let animateElements = svg.querySelectorAll("animate")
      for animateEl in animateElements {
        // Start the animation
        animateEl.beginElement()

        // After animation completes, update attributes for the next cycle
        window.setTimeout(210) {
          if let polygon = animateEl.parentElement {
            let from = animateEl.getAttribute(.from) ?? ""
            let to = animateEl.getAttribute(.to) ?? ""
            
            polygon.setAttribute(.points, to)
            polygon.innerHTML = buildHTML {
              animate()
                .attributeName(.points)
                .from(to)
                .to(from)
                .dur(ms(200))
                .fill(.freeze)
                .begin(.indefinite)
            }
          }
        }
      }
    }

    public func setState(expanded: Bool, animated: Bool = true) {
      if animated {
        morph(toExpanded: expanded)
      } else {
        let targetPoints = expanded ? AnimatedUpDownChevronView.expandedPoints : AnimatedUpDownChevronView.collapsedPoints
        let nextFrom = expanded ? AnimatedUpDownChevronView.expandedPoints : AnimatedUpDownChevronView.collapsedPoints
        let nextTo = expanded ? AnimatedUpDownChevronView.collapsedPoints : AnimatedUpDownChevronView.expandedPoints

        if let polygon = svg.querySelector("polygon") {
          polygon.setAttribute(.points, pointsToString(targetPoints))
          polygon.innerHTML = buildHTML {
            animate()
              .attributeName(.points)
              .from(pointsToString(nextFrom))
              .to(pointsToString(nextTo))
              .dur(ms(200))
              .fill(.freeze)
              .begin(.indefinite)
          }
        }
      }
    }
  }

  /// CLIENT factory for creating AnimatedUpDownChevronView DOM elements dynamically.
  public enum AnimatedUpDownChevronFactory {
    /// Creates an animated chevron SVG element matching the server-rendered AnimatedUpDownChevronView.
    /// - Parameters:
    ///   - id: Base ID (element gets id="\(id)-up-down-chevron")
    ///   - expanded: Initial state (false = down v, true = up ^)
    /// - Returns: A wrapper element containing the SVG
    public static func createElement(id: String, expanded: Bool = false) -> Element {
      let wrapper = document.createElement(.span)
      let view = AnimatedUpDownChevronView(id: id, expanded: expanded)
      wrapper.innerHTML = buildHTML { view.render() }
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }

    /// Obtains an instance controller for an existing chevron element.
    public static func from(element: Element) -> AnimatedUpDownChevronInstance? {
      return AnimatedUpDownChevronInstance(element: element)
    }

    /// Hydrates all chevrons within a container.
    public static func hydrateAll(in container: Element) {
      let chevrons = container.querySelectorAll(".animated-up-down-chevron-view")
      for chevron in chevrons {
        _ = AnimatedUpDownChevronInstance(element: chevron)
      }
    }
  }
#endif
