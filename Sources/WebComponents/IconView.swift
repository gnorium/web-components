import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A graphical representation of an idea. Can be used inside other components.
public struct IconView: HTMLContent {
  let icon: [DOM.Node]
  let iconLabel: String?
  let size: CSS.Length
  let iconColor: CSS.Color?
  let `class`: String

  /// An icon beside text is that text's font size (user, 2026-10-10): 16px
  /// beside 16px text, 18 beside 18—a label's icon, a legend's, a status
  /// mark. Rows center it on the label's capitals and digits (the label's
  /// `text-box: trim-both cap alphabetic`), never by a nudge.
  public static func size(beside fontSize: CSS.Length) -> CSS.Length {
    fontSize
  }

  public init<T: HTMLContent>(
    icon: [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    class: String = ""
  ) {
    self.icon = icon.map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.`class` = `class`
  }

  /// Convenience init for icon components
  public init<T: HTMLContent>(
    @HTMLBuilder icon: () -> [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    class: String = ""
  ) {
    self.icon = icon().map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.`class` = `class`
  }

  /// Convenience init for icon components with size parameter passed to icon builder
  public init<T: HTMLContent>(
    @HTMLBuilder icon: (_ size: CSS.Length) -> [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    class: String = ""
  ) {
    self.icon = icon(size).map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    // Embedded-safe: no String += concatenation or rawValue interpolation.
    var classParts = ["icon-view"]
    if !stringIsEmpty(`class`) {
      classParts.append(`class`)
    }
    let iconClasses = stringJoin(classParts, separator: " ")
    let iconColorValue = iconColor?.value ?? ""

    let isHidden: Bool
    if let _ = iconLabel { isHidden = false } else { isHidden = true }

    let baseElement = span {
      icon
    }
    .class(iconClasses)
    .ariaHidden(isHidden)
    .data("color", iconColorValue)
    .style {
      // The icon's box is as tall as its size, set inline so every size
      // token resolves; its width follows the icon.
      height(size)
      selector("&") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
      }
      if let iconColor {
        selector("&[data-color='\(iconColorValue)']") { color(iconColor) }
      }
    }

    if let iconLabel = iconLabel {
      return baseElement.ariaLabel(iconLabel)
    } else {
      return baseElement
    }
  }
}
