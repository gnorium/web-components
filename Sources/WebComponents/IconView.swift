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

  /// An icon's size is the font size of the text it sits with: the icon
  /// token where one matches (sizeIconXSmall 12, sizeIconSmall 16,
  /// sizeIconMedium 20), otherwise that font-size token itself
  /// (fontSizeSmall14, fontSizeLarge18, ...).
  public static func size(matching fontSize: CSS.Length) -> CSS.Length {
    if stringEquals(fontSize.value, fontSizeXSmall12.value) { return sizeIconXSmall }
    if stringEquals(fontSize.value, fontSizeMedium16.value) { return sizeIconSmall }
    if stringEquals(fontSize.value, fontSizeXLarge20.value) { return sizeIconMedium }
    return fontSize
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
