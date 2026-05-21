#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// A graphical representation of an idea. Can be used inside other components.
  public struct IconView: HTMLContent {
    let icon: [Node]
    let iconLabel: String?
    let size: IconSize
    let iconColor: CSSColor?
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
      iconColor: CSSColor? = nil,
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
      iconColor: CSSColor? = nil,
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
      @HTMLBuilder icon: (_ size: Length) -> [T],
      iconLabel: String? = nil,
      size: IconSize = .medium,
      iconColor: CSSColor? = nil,
      class: String = ""
    ) {
      let actualSize = Self.sizeToLength(size)
      self.icon = icon(actualSize).map { $0.build() }
      self.iconLabel = iconLabel
      self.size = size
      self.iconColor = iconColor
      self.`class` = `class`
    }

    private static func sizeToLength(_ size: IconSize) -> Length {
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
    private func iconViewCSS(_ size: IconSize, _ iconColor: CSSColor?) -> [CSSRule] {
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

    public func build() -> Node {
      let iconClasses = {
        var classes = "icon-view"
        classes += " icon-\(size.rawValue)"
        if !`class`.isEmpty {
          classes += " \(`class`)"
        }
        return classes
      }()

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
#endif
