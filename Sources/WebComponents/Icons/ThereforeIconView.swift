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
/// triangle's (user, 2026-10-26).
/// Available on SERVER + CLIENT.
public struct ThereforeIconView: HTMLContent {
  let iconSize: CSS.Length
  let `class`: String

  public init(size: CSS.Length, class: String = "") {
    self.iconSize = size
    self.class = `class`
  }

  public func build() -> DOM.Node {
    // Radius 93.09: side 837.82, height 725.57, the glyph 911.75 tall.
    svg {
      circle().cx(512).cy(93.09).r(93.09)
      circle().cx(93.09).cy(818.66).r(93.09)
      circle().cx(930.91).cy(818.66).r(93.09)
    }
    .class(stringIsEmpty(`class`) ? "therefore-icon-view" : "therefore-icon-view \(`class`)")
    .style { width(iconSize) }
    .viewBox(0, 0, 1024, 911.75)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
