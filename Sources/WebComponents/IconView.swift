import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// A graphical representation of an idea. Can be used inside other components.
///
/// An icon beside text is as tall as that text's line (user, 2026-10-21;
/// was its font size): the icon size tokens are line heights—sizeIconSmall
/// the 26px line of 16px body text—and a control on the 22px line takes
/// lineHeightSmall22. It fills the line box, never grows it, and is
/// centered in it: a line's middle is the capitals' middle, so its flex row
/// aligns `center` (`flex-start` where the text wraps), with no
/// `centerOnCapitals` offset, which is only for a mark smaller than its line.
///
/// The exception is an icon that stands in for punctuation or a character—a
/// breadcrumb's chevron (BreadcrumbSeparatorView, BreadcrumbLabelView,
/// RecordLabelView), a diff label's `±` (DiffLabelView), a process badge's
/// `∴` or `∫` (WatchtowerProcessView), an inline arrow in "X → Y" (the
/// Graph's paths): it is the FONT size of its text (fontSizeMedium16 beside
/// 16px text), as a character would be (user, 2026-10-21, 2026-10-26).
public struct IconView: HTMLContent {
  let icon: [DOM.Node]
  let iconLabel: String?
  let size: CSS.Length
  let iconColor: CSS.Color?
  /// A slot as wide as it is tall, the glyph centered in it at its own
  /// tight shape: a list of icons of different widths (a column of links)
  /// starts every label at the same x.
  let square: Bool
  let `class`: String

  public init<T: HTMLContent>(
    icon: [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    square: Bool = false,
    class: String = ""
  ) {
    self.icon = icon.map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.square = square
    self.`class` = `class`
  }

  /// Convenience init for icon components
  public init<T: HTMLContent>(
    @HTMLBuilder icon: () -> [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    square: Bool = false,
    class: String = ""
  ) {
    self.icon = icon().map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.square = square
    self.`class` = `class`
  }

  /// Convenience init for icon components with size parameter passed to icon builder
  public init<T: HTMLContent>(
    @HTMLBuilder icon: (_ size: CSS.Length) -> [T],
    iconLabel: String? = nil,
    size: CSS.Length,
    iconColor: CSS.Color? = nil,
    square: Bool = false,
    class: String = ""
  ) {
    self.icon = icon(size).map { $0.build() }
    self.iconLabel = iconLabel
    self.size = size
    self.iconColor = iconColor
    self.square = square
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
      if square { width(size) }
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
