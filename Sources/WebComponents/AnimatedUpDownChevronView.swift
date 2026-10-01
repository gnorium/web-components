import CSSBuilder
import CSSOMBuilder
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

/// An animated constant-width chevron SVG that morphs between collapsed (v down) and
/// expanded (^ up) states by updating the polyline `points` on animation frames.
/// The mid-animation shape is a horizontal stroke of the same weight.
/// Used for table sort indicators and group expand/collapse toggles.
///
public struct AnimatedUpDownChevronView: HTMLContent {
  public static let collapsedPoints: [(Double, Double)] = [
    (41.58, 41.58), (512, 512), (982.42, 41.58),
  ]
  public static let expandedPoints: [(Double, Double)] = [
    (41.58, 570.8), (512, 100.38), (982.42, 570.8),
  ]
  public static let midpointPoints: [(Double, Double)] = [
    (41.58, 306.19), (512, 306.19), (982.42, 306.19),
  ]

  public let id: String
  public let expanded: Bool
  public let size: CSS.Length
  public var `class`: String
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

  public func style(@CSSBuilder _ rules: @escaping @Sendable () -> [CSSOM.CSSRule]) -> Self {
    var copy = self
    copy.customStyleRules.append(rules)
    return copy
  }

  public func build() -> DOM.Node {
    // MARK: - Chevron Geometry (1024 x 612.38 viewBox)
    // The collapsed centerline is AnimatedRightDownChevronView's down chevron;
    // the expanded centerline is its exact vertical mirror about y = 306.19.
    // The box is tight to the union of all three shapes' ink (butt ends
    // and miter tips included), so they share one box and one center.

    return svg {
      if expanded {
        polyline().points(pointsToString(Self.expandedPoints))
      } else {
        polyline().points(pointsToString(Self.collapsedPoints))
      }
    }
    .class(
      stringIsEmpty(`class`) ? "animated-up-down-chevron-view" : "animated-up-down-chevron-view \(`class`)"
    )
    .id("\(id)-up-down-chevron")
    .style { width(size) }
    .viewBox(0, 0, 1024, 612.38)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeWidth(117.61)
    .strokeLinecap(.butt)
    .strokeLinejoin(.miter)
    .style {
      selector("&") {
        for sty in customStyleRules {
          sty()
        }
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT controller for an AnimatedUpDownChevronView DOM element.
  /// Handles SMIL animation morphing between collapsed and expanded states.
  public class AnimatedUpDownChevronInstance: @unchecked Sendable {
    private let svg: DOM.Element
    private var isExpanded = false
    private var animationGeneration = 0
    private var animationStartedAt: Double = 0
    private var animationFrom: [(Double, Double)] = AnimatedUpDownChevronView.collapsedPoints
    private var animationTo: [(Double, Double)] = AnimatedUpDownChevronView.collapsedPoints
    private let animationDurationMs = 200.0

    public init?(element: DOM.Element) {
      if element.classList.contains("animated-up-down-chevron-view") {
        self.svg = element
      } else if let found = element.querySelector(".animated-up-down-chevron-view") {
        self.svg = found
      } else {
        return nil
      }

      let current = svg.querySelector("polyline")?.getAttribute(.points) ?? ""
      isExpanded = stringEquals(current, pointsToString(AnimatedUpDownChevronView.expandedPoints))
    }

    public func morph(toExpanded: Bool) {
      guard toExpanded != isExpanded else { return }
      animationGeneration += 1
      animationStartedAt = window.performance.now()
      animationFrom = isExpanded
        ? AnimatedUpDownChevronView.expandedPoints
        : AnimatedUpDownChevronView.collapsedPoints
      animationTo = toExpanded
        ? AnimatedUpDownChevronView.expandedPoints
        : AnimatedUpDownChevronView.collapsedPoints
      isExpanded = toExpanded
      scheduleFrame(generation: animationGeneration)
    }

    public func setState(expanded: Bool, animated: Bool = true) {
      if animated {
        morph(toExpanded: expanded)
      } else {
        animationGeneration += 1
        isExpanded = expanded
        let targetPoints = expanded ? AnimatedUpDownChevronView.expandedPoints : AnimatedUpDownChevronView.collapsedPoints

        if let polyline = svg.querySelector("polyline") {
          polyline.setAttribute(.points, pointsToString(targetPoints))
        }
      }
    }

    private func scheduleFrame(generation: Int) {
      _ = window.requestAnimationFrame { [self] in
        advanceFrame(generation: generation)
      }
    }

    private func advanceFrame(generation: Int) {
      guard generation == animationGeneration,
        let polyline = svg.querySelector("polyline")
      else { return }

      let elapsed = window.performance.now() - animationStartedAt
      let progress = elapsed >= animationDurationMs ? 1.0 : elapsed / animationDurationMs
      let points: [(Double, Double)]
      if progress <= 0.5 {
        points = interpolate(animationFrom, AnimatedUpDownChevronView.midpointPoints, progress * 2)
      } else {
        points = interpolate(AnimatedUpDownChevronView.midpointPoints, animationTo, (progress - 0.5) * 2)
      }
      polyline.setAttribute(.points, pointsToString(points))

      if progress < 1 {
        scheduleFrame(generation: generation)
      } else {
        polyline.setAttribute(.points, pointsToString(animationTo))
      }
    }
  }

  private func interpolate(
    _ from: [(Double, Double)],
    _ to: [(Double, Double)],
    _ progress: Double
  ) -> [(Double, Double)] {
    zip(from, to).map { start, end in
      (start.0 + (end.0 - start.0) * progress, start.1 + (end.1 - start.1) * progress)
    }
  }

  /// CLIENT factory for creating AnimatedUpDownChevronView DOM elements dynamically.
  public enum AnimatedUpDownChevronFactory {
    /// Creates an animated chevron SVG element matching the server-rendered AnimatedUpDownChevronView.
    /// - Parameters:
    ///   - id: Base ID (element gets id="\(id)-up-down-chevron")
    ///   - expanded: Initial state (false = down v, true = up ^)
    /// - Returns: A wrapper element containing the SVG
    public static func createElement(id: String, expanded: Bool = false, size: CSS.Length) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = AnimatedUpDownChevronView(id: id, expanded: expanded, size: size)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }

    /// Obtains an instance controller for an existing chevron element.
    public static func from(element: DOM.Element) -> AnimatedUpDownChevronInstance? {
      return AnimatedUpDownChevronInstance(element: element)
    }

    /// Hydrates all chevrons within a container.
    public static func hydrateAll(in container: DOM.Element) {
      let chevrons = container.querySelectorAll(".animated-up-down-chevron-view")
      for chevron in chevrons {
        _ = AnimatedUpDownChevronInstance(element: chevron)
      }
    }
  }
#endif
