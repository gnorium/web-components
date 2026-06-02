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

  private static func sizeToLength(_ size: IconSize) -> CSS.Length {
    // Return concrete pixel values for SVGContent attributes (SVGContent doesn't support CSSContent variables)
    switch size {
    case .medium:
      return px(20)  // fontSizeMedium16 (16px) + 4px
    case .small:
      return px(16)  // fontSizeSmall14 (14px) + 2px
    case .xSmall:
      return px(12)
    }
  }

  @CSSBuilder
  private func iconViewCSS(_ size: IconSize, _ iconColor: CSS.Color?) -> [CSSOM.CSSRule] {
    display(.flex)
    alignItems(.center)
    justifyContent(.center)
    flexShrink(0)

    switch size {
    case .medium:
      width(sizeIconMedium)
      height(sizeIconMedium)
    case .small:
      width(sizeIconSmall)
      height(sizeIconSmall)
    case .xSmall:
      width(sizeIconXSmall)
      height(sizeIconXSmall)
    }

    if let iconColor = iconColor {
      color(iconColor)
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

    let baseElement = span {
      icon
    }
    .class(iconClasses)
    .ariaHidden(iconLabel == nil)
    .style {
      iconViewCSS(size, iconColor)
    }

    if let iconLabel = iconLabel {
      return baseElement.ariaLabel(iconLabel)
    } else {
      return baseElement
    }
  }
}
