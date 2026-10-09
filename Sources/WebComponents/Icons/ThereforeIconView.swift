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
/// Built from the disc mark's geometry (no Codex icon holds it): the discs
/// span the grid's width, and the triangle stands centered in the box.
/// Available on SERVER + CLIENT.
public struct ThereforeIconView: HTMLContent {
  let iconSize: CSS.Length
  let `class`: String

  public init(size: CSS.Length, class: String = "") {
    self.iconSize = size
    self.class = `class`
  }

  public func build() -> DOM.Node {
    // Radius 160: side 704, height 610, the triangle 930 tall, centered
    // over 1024.
    svg {
      circle().cx(512).cy(207).r(160)
      circle().cx(160).cy(817).r(160)
      circle().cx(864).cy(817).r(160)
    }
    .class(stringIsEmpty(`class`) ? "therefore-icon-view" : "therefore-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 1024, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.currentColor)
  }
}
