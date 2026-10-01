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
  let size: IconSize
  let iconColor: CSS.Color?
  let `class`: String

  public enum IconSize: String, Sendable {
    case medium
    case small
    case xSmall = "x-small"
  }

  public init<T: HTMLContent>(
    icon: [T],
    iconLabel: String? = nil,
    size: IconSize = .medium,
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
    size: IconSize = .medium,
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
    size: IconSize = .medium,
    iconColor: CSS.Color? = nil,
    class: String = ""
  ) {
    let actualSize = Self.sizeToLength(size)
    self.icon = icon(actualSize).map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.`class` = `class`
  }

  /// The icon's length for its size. Icons are drawn tight, so their box
  /// follows the glyph: the length sets the glyph's longer edge (its height,
  /// or its width when wider than tall), set inline so the token resolves,
  /// and the other edge follows the view box. The size is the size of the
  /// text the icon sits with: `.small` beside 16px text, `.xSmall` beside
  /// 14px or smaller, `.medium` for larger standalone controls.
  private static func sizeToLength(_ size: IconSize) -> CSS.Length {
    switch size {
    case .medium:
      return sizeIconMedium
    case .small:
      return sizeIconSmall
    case .xSmall:
      return sizeIconXSmall
    }
  }

  public func build() -> DOM.Node {
    // Embedded-safe: no String += concatenation or rawValue interpolation.
    let sizeClass: String
    switch size {
    case .medium: sizeClass = "icon-medium"
    case .small: sizeClass = "icon-small"
    case .xSmall: sizeClass = "icon-x-small"
    }
    var classParts = ["icon-view", sizeClass]
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
    .data("size", size.rawValue)
    .data("color", iconColorValue)
    .style {
      selector("&") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
      }
      selector("&[data-size='medium']") { height(sizeIconMedium) }
      selector("&[data-size='small']") { height(sizeIconSmall) }
      selector("&[data-size='x-small']") { height(sizeIconXSmall) }
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
