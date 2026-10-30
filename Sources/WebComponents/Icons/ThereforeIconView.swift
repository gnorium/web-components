import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Therefore (∴): three equal discs at the vertices of an upright
/// equilateral triangle, the sign of a conclusion drawn from premises.
/// No Lucide icon holds it: each disc is Lucide's dot (a circle of r 1 at
/// stroke 2: radius 2 of its 24, the stroke width, 1024×2/22), and the
/// glyph is tight, its discs spanning the 1024 width, its height the
/// triangle's (user, 2026-10-26). `weight` thickens the discs beside
/// semibold type (`IconWeight`, user 2026-10-30), the glyph still tight.
/// Available on SERVER + CLIENT.
public struct ThereforeIconView: HTMLContent {
  let iconSize: CSS.Length
  let weight: IconWeight
  let `class`: String

  public init(size: CSS.Length, weight: IconWeight = .regular, class: String = "") {
    self.iconSize = size
    self.weight = weight
    self.class = `class`
  }

  public func build() -> DOM.Node {
    // Regular, radius 93.09: side 837.82, height 725.57, the glyph 911.75 tall.
    let radius = 1024 * weight.share
    let side = 1024 - 2 * radius
    let foot = radius + side * 0.8660254037844386
    return svg {
      circle().cx(512).cy(radius).r(radius)
      circle().cx(radius).cy(foot).r(radius)
      circle().cx(1024 - radius).cy(foot).r(radius)
    }
    .class(stringIsEmpty(`class`) ? "therefore-icon-view" : "therefore-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, foot + radius)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
