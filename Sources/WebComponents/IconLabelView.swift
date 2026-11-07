import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A label with its icon beside it, the icon leading and as tall as the
/// label's font size (the tight-icons rule: an icon beside a label takes
/// that label's size). The icon wears the label's own color, so it is as
/// quiet as the words. Inline, so it sits in a heading, a link or a
/// sentence alike; the caller sets the font.
public struct IconLabelView: HTMLContent {
  let mark: DOM.Node
  let text: String
  let `class`: String

  /// A mark already drawn at the label's font size.
  public init(_ text: String, mark: DOM.Node, class: String = "") {
    self.mark = mark
    self.text = text
    self.`class` = `class`
  }

  /// `icon` draws the mark at the size it is handed, which is `size`.
  public init<T: HTMLContent>(
    _ text: String, size: CSS.Length, class: String = "", @HTMLBuilder icon: (_ size: CSS.Length) -> [T]
  ) {
    self.mark = IconView(icon: icon, size: size).build()
    self.text = text
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    span {
      mark
      span { text }
        .class("icon-label-text")
    }
    .class(stringIsEmpty(`class`) ? "icon-label-view" : "icon-label-view \(`class`)")
    .style {
      selector("&") {
        display(.inlineFlex)
        alignItems(.center)
        gap(spacing8)
        // Top, not baseline: an inline flex box's baseline is its first
        // item's, the icon's bottom edge, which raised the box above the
        // text's baseline and grew its line by the font's descent—a
        // heading holding one stood taller than its neighbors' and its
        // label sat above center (an accordion's Pedigree header). Its line
        // height is its parent's, so top keeps it on the line.
        verticalAlign(.top)
      }
    }
    .build()
  }
}
