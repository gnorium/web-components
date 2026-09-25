import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
#if SERVER
  import Foundation
  import SVGBuilder
#endif
import HTMLBuilder
import WebTypes

/// InfoChip — a non-interactive indicator that provides information and/or conveys a status.
public struct InfoChipView: HTMLContent {
  let chipColor: InfoChipColor
  let weight: Weight
  let size: Size
  let icon: String?
  /// A status is not always an announcement: a chip that states a fact
  /// rather than raising an alarm reads better at normal weight.
  let labelFontWeight: CSS.FontWeight
  let iconContent: [DOM.Node]
  let content: [DOM.Node]
  let `class`: String

  /// Apple HIG color for the chip
  public enum InfoChipColor: String, Sendable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray

    // Legacy aliases
    public static let notice = InfoChipColor.gray
    public static let warning = InfoChipColor.orange
    public static let error = InfoChipColor.red
    public static let success = InfoChipColor.green
  }

  /// Visual weight of the chip
  public enum Weight: String, Sendable {
    /// Light background, colored text, border (default)
    case subtle
    /// Filled background, inverted text, no border
    case solid
  }

  /// Physical size of the chip
  public enum Size: String, Sendable {
    /// Standard status chip: 40px control height.
    case medium
    /// Header / primary status — 44px tall, ``fontSizeXLarge20``
    case large
  }

  public init(
    chipColor: InfoChipColor = .gray,
    weight: Weight = .subtle,
    size: Size = .medium,
    icon: String? = nil,
    labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
    class: String = "",
    @HTMLBuilder iconContent: () -> [DOM.Node] = { [] },
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.chipColor = chipColor
    self.weight = weight
    self.size = size
    self.icon = icon
    self.labelFontWeight = labelFontWeight
    self.iconContent = iconContent()
    self.content = content()
    self.`class` = `class`
  }

  /// Legacy init
  public init(
    color: InfoChipColor,
    weight: Weight = .subtle,
    size: Size = .medium,
    icon: String? = nil,
    class: String = "",
    @HTMLBuilder iconContent: () -> [DOM.Node] = { [] },
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.chipColor = color
    self.weight = weight
    self.size = size
    self.icon = icon
    self.labelFontWeight = fontWeightSemiBold
    self.iconContent = iconContent()
    self.content = content()
    self.`class` = `class`
  }

  /// Legacy init
  public init(
    status: InfoChipColor,
    weight: Weight = .subtle,
    size: Size = .medium,
    icon: String? = nil,
    class: String = "",
    @HTMLBuilder iconContent: () -> [DOM.Node] = { [] },
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.chipColor = status
    self.weight = weight
    self.size = size
    self.icon = icon
    self.labelFontWeight = fontWeightSemiBold
    self.iconContent = iconContent()
    self.content = content()
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    let iconLength: CSS.Length = size == .large ? sizeIconMedium : sizeIconSmall

    let hasIconContent = !iconContent.isEmpty
    let suppressIcon = icon.map { stringIsEmpty($0) } ?? false

    let shouldShowIcon: Bool = {
      if suppressIcon { return false }
      if hasIconContent { return true }
      if let icon = icon { return !stringIsEmpty(icon) }
      return chipColor != .gray
    }()

    let sizeClass = size == .medium ? "" : " info-chip-\(size.rawValue)"

    return span {
      if shouldShowIcon {
        span {
          if hasIconContent {
            iconContent
          } else {
            #if SERVER
              resolvedIconNodes(iconLength: iconLength)
            #else
              icon ?? fallbackIconGlyph()
            #endif
          }
        }
        .class("info-chip-icon")
        .ariaHidden(true)
      }

      if !content.isEmpty {
        span {
          content
        }
        .class("info-chip-text")
      }
    }
    .class(
      stringIsEmpty(`class`)
        ? "info-chip-view info-chip-\(chipColor.rawValue) info-chip-\(weight.rawValue)\(sizeClass)"
        : "info-chip-view info-chip-\(chipColor.rawValue) info-chip-\(weight.rawValue)\(sizeClass) \(`class`)"
    )
    .data("label-font-weight", labelFontWeight.value)
    .style {
      selector("&") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        gap(spacing8)
        height(size40)
        maxHeight(size40)
        minHeight(size40)
        padding(0, spacing8)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        lineHeight(lineHeightXSmall20)
        borderRadius(borderRadiusPill)
        whiteSpace(.nowrap)
        textOverflow(.ellipsis)
        overflow(.hidden)
        boxSizing(.borderBox)
      }
      // The component stylesheet is shared by every chip instance.  Put the
      // requested label weight on the element, then select it here; baking the
      // first instance's value into `.info-chip-view` made every later chip
      // inherit whichever weight happened to render first.
      selector("&[data-label-font-weight='\(fontWeightSemiBold.value)']") {
        fontWeight(fontWeightSemiBold)
      }
      selector("&[data-label-font-weight='\(fontWeightBold.value)']") {
        fontWeight(fontWeightBold)
      }
      selector("&.info-chip-large") {
        height(size44)
        maxHeight(size44)
        minHeight(size44)
        // Match the evidence/hallmark header mark: 44×44 optical block, pill ends.
        padding(0, spacing12)
        gap(spacing8)
        fontSize(fontSizeXLarge20)
        lineHeight(lineHeightXLarge30)
      }
      selector("&.info-chip-subtle") {
        border(borderWidthBase, .solid, .currentColor)
      }
      selector("&.info-chip-solid") {
        color(colorInvertedFixed)
      }
      selector("&.info-chip-red.info-chip-subtle") {
        color(colorRed)
        backgroundColor(backgroundColorRedSubtle)
      }
      selector("&.info-chip-orange.info-chip-subtle") {
        color(colorOrange)
        backgroundColor(backgroundColorOrangeSubtle)
      }
      selector("&.info-chip-yellow.info-chip-subtle") {
        color(colorYellow)
        backgroundColor(backgroundColorYellowSubtle)
      }
      selector("&.info-chip-green.info-chip-subtle") {
        color(colorGreen)
        backgroundColor(backgroundColorGreenSubtle)
      }
      selector("&.info-chip-mint.info-chip-subtle") {
        color(colorMint)
        backgroundColor(backgroundColorMintSubtle)
      }
      selector("&.info-chip-teal.info-chip-subtle") {
        color(colorTeal)
        backgroundColor(backgroundColorTealSubtle)
      }
      selector("&.info-chip-cyan.info-chip-subtle") {
        color(colorCyan)
        backgroundColor(backgroundColorCyanSubtle)
      }
      selector("&.info-chip-blue.info-chip-subtle") {
        color(colorBlue)
        backgroundColor(backgroundColorBlueSubtle)
      }
      selector("&.info-chip-indigo.info-chip-subtle") {
        color(colorIndigo)
        backgroundColor(backgroundColorIndigoSubtle)
      }
      selector("&.info-chip-purple.info-chip-subtle") {
        color(colorPurple)
        backgroundColor(backgroundColorPurpleSubtle)
      }
      selector("&.info-chip-pink.info-chip-subtle") {
        color(colorPink)
        backgroundColor(backgroundColorPinkSubtle)
      }
      selector("&.info-chip-brown.info-chip-subtle") {
        color(colorBrown)
        backgroundColor(backgroundColorBrownSubtle)
      }
      selector("&.info-chip-gray.info-chip-subtle") {
        color(colorGray)
        backgroundColor(backgroundColorGraySubtle)
      }
      selector("&.info-chip-red.info-chip-solid") { backgroundColor(colorRed) }
      selector("&.info-chip-orange.info-chip-solid") { backgroundColor(colorOrange) }
      selector("&.info-chip-yellow.info-chip-solid") { backgroundColor(colorYellow) }
      selector("&.info-chip-green.info-chip-solid") { backgroundColor(colorGreen) }
      selector("&.info-chip-mint.info-chip-solid") { backgroundColor(colorMint) }
      selector("&.info-chip-teal.info-chip-solid") { backgroundColor(colorTeal) }
      selector("&.info-chip-cyan.info-chip-solid") { backgroundColor(colorCyan) }
      selector("&.info-chip-blue.info-chip-solid") { backgroundColor(colorBlue) }
      selector("&.info-chip-indigo.info-chip-solid") { backgroundColor(colorIndigo) }
      selector("&.info-chip-purple.info-chip-solid") { backgroundColor(colorPurple) }
      selector("&.info-chip-pink.info-chip-solid") { backgroundColor(colorPink) }
      selector("&.info-chip-brown.info-chip-solid") { backgroundColor(colorBrown) }
      selector("&.info-chip-gray.info-chip-solid") { backgroundColor(colorGray) }
      descendant(".info-chip-icon") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(sizeIconSmall)
        height(sizeIconSmall)
        flexShrink(0)
        fontSize(fontSizeSmall14)
        lineHeight(1)
      }
      descendant(".info-chip-icon > svg") {
        width(perc(100))
        height(perc(100))
        display(.block)
      }
      descendant(".info-chip-icon > .rotating-sector-view") {
        width(perc(100))
        height(perc(100))
      }
      selector("&.info-chip-large .info-chip-icon") {
        width(sizeIconMedium)
        height(sizeIconMedium)
        fontSize(fontSizeXLarge20)
      }
      descendant(".info-chip-text") {
        flex(1)
        minWidth(0)
        textOverflow(.ellipsis)
        overflow(.hidden)
        whiteSpace(.nowrap)
      }
    }
  }

  private func fallbackIconGlyph() -> String {
    switch chipColor {
    case .gray: return "ℹ"
    case .orange: return "⚠"
    case .red: return "✗"
    case .mint: return "●"
    case .green: return "✓"
    case .yellow, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown: return "●"
    }
  }

  #if SERVER
    @HTMLBuilder
    private func resolvedIconNodes(iconLength: CSS.Length) -> [DOM.Node] {
      if let icon = icon {
        switch icon {
        case "○":
          RingIconView(width: iconLength, height: iconLength)
        case "●":
          DiscIconView(width: iconLength, height: iconLength)
        case "✓":
          CheckIconView(width: iconLength, height: iconLength)
        case "✗":
          CrossIconView(width: iconLength, height: iconLength)
        default:
          span { icon }
        }
      } else {
        switch chipColor {
        case .green:
          CheckIconView(width: iconLength, height: iconLength)
        case .red:
          CrossIconView(width: iconLength, height: iconLength)
        case .orange:
          span { "⚠" }
        case .gray:
          InfoIconView(width: iconLength, height: iconLength)
        case .mint, .yellow, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown:
          DiscIconView(width: iconLength, height: iconLength)
        }
      }
    }
  #endif
}
