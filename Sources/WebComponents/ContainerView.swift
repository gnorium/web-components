#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A flexible layout wrapper that adapts across different breakpoints and screen sizes.
  public struct ContainerView: HTMLContent {
    let size: Size
    let content: [DOM.Node]
    let `class`: String

    public enum Size: String, Sendable {
      case medium
      case large
      case xLarge = "x-large"
      case full
    }

    public init(
      size: Size = .full,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.size = size
      self.`class` = `class`
      self.content = content()
    }

    public func build() -> DOM.Node {
      return div {
        content
      }
      .class(`class`.isEmpty ? "container-view" : "container-view \(`class`)")
      .data("size", size.rawValue)
      .style {
        selector("&") {
          width(perc(100))
          marginInline(.auto)
          boxSizing(.borderBox)
          display(.flex)
          flexDirection(.column)
          flex(1)
          minHeight(0)
          paddingInlineStart(clamp(spacing16, vw(5), spacing64))
          paddingInlineEnd(clamp(spacing16, vw(5), spacing64))
        }
        selector("&[data-size='medium']") { maxWidth(px(720)) }
        selector("&[data-size='large']") { maxWidth(px(960)) }
        selector("&[data-size='x-large']") { maxWidth(px(1280)) }
        selector("&[data-size='full']") { maxWidth(.none) }
      }
    }
  }
#endif
