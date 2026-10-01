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

  /// An icon beside text is that text's font size minus 4px: icons are
  /// tight (their ink fills the 1024 grid box), so at the full font size
  /// one looks larger than the letters, whose capitals are about 0.7em;
  /// minus 4 lands near the cap height. 12px text takes size8, 14 size10,
  /// 16 sizeIconXSmall, 18 size14, 20 sizeIconSmall, 24 sizeIconMedium,
  /// 28 size24; any other size, its font size less 4px.
  public static func size(beside fontSize: CSS.Length) -> CSS.Length {
    if stringEquals(fontSize.value, fontSizeXSmall12.value) { return size8 }
    if stringEquals(fontSize.value, fontSizeSmall14.value) { return size10 }
    if stringEquals(fontSize.value, fontSizeMedium16.value) { return sizeIconXSmall }
    if stringEquals(fontSize.value, fontSizeLarge18.value) { return size14 }
    if stringEquals(fontSize.value, fontSizeXLarge20.value) { return sizeIconSmall }
    if stringEquals(fontSize.value, fontSizeXXLarge24.value) { return sizeIconMedium }
    if stringEquals(fontSize.value, fontSizeXXXLarge28.value) { return size24 }
    return fontSize - px(4)
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
