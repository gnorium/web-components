import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A full ring of 12 round dots (user, 2026-10-18): the pending mark of
/// calibration and of the objects before it (an overture). Drawn on
/// Lucide's 24 grid scaled to the house 1024 box—a circle of radius 9, the
/// stroke 2, round caps—as a dash of next to no length every twelfth of the
/// circumference, which the round cap makes a dot. Its static twin turning
/// is `RotatingDottedRingSectorView`.
public struct DottedRingView: HTMLContent {
  let iconSize: CSS.Length
  let `class`: String

  public init(
    size: CSS.Length,
    class: String = ""
  ) {
    self.iconSize = size
    self.class = `class`
  }

  /// Lucide's grid in the house box: a unit of the 24 grid.
  static let unit: Double = 1024 / 24
  /// The ring's radius: its dots' outer edge on the box's, as RingIconView's
  /// ring—the radius less half the stroke (a tight icon fills its box).
  static let radius: Double = 512 - iconStrokeWidth / 2
  /// A twelfth of the circumference: the step between two dots.
  static let step: Double = 2 * 3.141592653589793 * radius / 12
  /// A dash's length, `0.01` of the grid's units: a point the round cap
  /// swells to a dot.
  static let dash: Double = 0.01 * unit

  /// `stroke-dasharray`: a dot every `step`.
  static var dasharray: String {
    "\(doubleToString(dash)) \(doubleToString(step - dash))"
  }

  /// `stroke-dashoffset`: half a dash, so that a dot falling on the path's
  /// very end is drawn, not cut off.
  static var dashoffset: CSS.Length { px(dash / 2) }

  public func build() -> DOM.Node {
    svg {
      path()
        // From the top, clockwise, in two half circles (one arc cannot
        // close itself).
        .d(
          M(512, 512 - Self.radius),
          A(Self.radius, Self.radius, 0, true, true, 512, 512 + Self.radius),
          A(Self.radius, Self.radius, 0, true, true, 512, 512 - Self.radius))
        .fill(.none)
        .stroke(.currentColor)
        .strokeWidth(iconStrokeWidth)
        .strokeLinecap(.round)
        .strokeDasharray(Self.dasharray)
        .strokeDashoffset(Self.dashoffset)
    }
    .class(
      stringIsEmpty(`class`) ? "dotted-ring-view" : "dotted-ring-view \(`class`)"
    )
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
  }
}

#if CLIENT
  import WebAPIs

  public enum DottedRingFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = DottedRingView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
