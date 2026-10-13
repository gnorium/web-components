#if SERVER
import CSSBuilder
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Two overlapping sheets: superimpose views without merging their content.
public struct LayersIconView: HTMLContent {
  let size: CSS.Length
  public init(size: CSS.Length) { self.size = size }
  public func build() -> DOM.Node {
    svg {
      path().addingAttribute("d", "M12 3 2 8l10 5 10-5-10-5ZM2 12l10 5 10-5M2 16l10 5 10-5")
    }
    .class("layers-icon-view").viewBox(0, 0, 24, 24).xmlns("http://www.w3.org/2000/svg")
    .addingAttribute("fill", "none").addingAttribute("stroke", "currentColor")
    .addingAttribute("stroke-width", "2").addingAttribute("stroke-linecap", "round")
    .addingAttribute("stroke-linejoin", "round").style { width(size) }
    .build()
  }
}
#endif
