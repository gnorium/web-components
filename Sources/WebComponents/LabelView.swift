import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A Label provides a descriptive title for an input or form field.
/// Every input or form field must have an associated label for accessibility.
public struct LabelView: HTMLContent {
  let icon: String?
  let optional: Bool
  let optionalFlag: String
  let visuallyHidden: Bool
  let isLegend: Bool
  let inputID: String?
  let descriptionID: String?
  let disabled: Bool
  let labelContent: [DOM.Node]
  let descriptionContent: [DOM.Node]
  let `class`: String
  let labelFontWeight: CSS.FontWeight
  let labelFontSize: CSS.Length

  public init(
    icon: String? = nil,
    optional: Bool = false,
    optionalFlag: String = "(optional)",
    visuallyHidden: Bool = false,
    isLegend: Bool = false,
    inputID: String? = nil,
    descriptionID: String? = nil,
    disabled: Bool = false,
    labelFontWeight: CSS.FontWeight = fontWeightBold,
    labelFontSize: CSS.Length = fontSizeMedium16,
    class: String = "",
    @HTMLBuilder label: () -> [DOM.Node],
    @HTMLBuilder description: () -> [DOM.Node] = { [] }
  ) {
    self.icon = icon
    self.optional = optional
    self.optionalFlag = optionalFlag
    self.visuallyHidden = visuallyHidden
    self.isLegend = isLegend
    self.inputID = inputID
    self.descriptionID = descriptionID
    self.disabled = disabled
    self.labelFontWeight = labelFontWeight
    self.labelFontSize = labelFontSize
    self.`class` = `class`
    self.labelContent = label()
    self.descriptionContent = description()
  }

  public func build() -> DOM.Node {
    let hasDescription = !descriptionContent.isEmpty
    let rootClass = stringIsEmpty(`class`)
      ? (visuallyHidden ? "label-view visually-hidden" : "label-view")
      : (visuallyHidden ? "label-view visually-hidden \(`class`)" : "label-view \(`class`)")
    let root: HTML.HTMLElement

    if isLegend {
      root = legend {
        span {
          if let iconValue = icon {
            span { iconValue }
              .class("label-icon")
              .ariaHidden(true)
          }

          labelContent

          if optional {
            span { " \(optionalFlag)" }
              .class("label-optional-flag")
          }
        }
        .class("label-text")

        if hasDescription {
          span { descriptionContent }
            .class("label-description")
            .id(descriptionID ?? "")
        }
      }
    } else {
      root = div {
        if let forID = inputID {
          label {
            if let iconValue = icon {
              span { iconValue }
                .class("label-icon")
                .ariaHidden(true)
            }

            labelContent

            if optional {
              span { " \(optionalFlag)" }
                .class("label-optional-flag")
            }
          }
          .for(forID)
          .class("label-text")
        } else {
          span {
            if let iconValue = icon {
              span { iconValue }
                .class("label-icon")
                .ariaHidden(true)
            }

            labelContent

            if optional {
              span { " \(optionalFlag)" }
                .class("label-optional-flag")
            }
          }
          .class("label-text")
        }

        if hasDescription {
          span { descriptionContent }
            .class("label-description")
            .id(descriptionID ?? "")
        }
      }
    }

    // Each configuration its own selector: the stylesheet keeps one rule per
    // selector, so rules that differed by parameter under one shared
    // selector let whichever label was built last set every label's size,
    // weight and colour.
    return root
      .class(rootClass)
      .data("label-size", labelFontSize.value)
      .data("label-weight", labelFontWeight.value)
      .data("disabled", disabled)
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
        }
        selector("&.visually-hidden") {
          position(.absolute)
          width(px(1))
          height(px(1))
          margin(px(-1))
          padding(0)
          overflow(.hidden)
          clip(rect(px(0), px(0), px(0), px(0)))
          whiteSpace(.nowrap)
          borderWidth(0)
        }
        descendant(".label-text") {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
          fontFamily(typographyFontSans)
          lineHeight(lineHeightMedium26)
          color(colorBase)
        }
        // Its own text only, not a label nested inside it.
        selector("&[data-label-size='\(labelFontSize.value)'] > .label-text") {
          fontSize(labelFontSize)
        }
        selector("&[data-label-weight='\(labelFontWeight.value)'] > .label-text") {
          fontWeight(labelFontWeight)
        }
        descendant(".label-icon") {
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
          width(minSizeIconMedium)
          height(minSizeIconMedium)
          color(colorSubtle)
          flexShrink(0)
        }
        descendant(".label-optional-flag") {
          color(colorSubtle)
          fontWeight(fontWeightNormal)
        }
        descendant(".label-description") {
          display(.block)
          fontSize(fontSizeSmall14)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          fontWeight(fontWeightNormal)
        }
        selector(
          "&[data-disabled='true'] > .label-text",
          "&[data-disabled='true'] > .label-text > .label-icon",
          "&[data-disabled='true'] > .label-text > .label-optional-flag",
          "&[data-disabled='true'] > .label-description"
        ) {
          color(colorDisabled)
        }
      }
  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT factory for creating LabelView DOM elements dynamically.
  public enum LabelFactory {
    /// Creates a LabelView DOM element matching the server-rendered LabelView.
    public static func createElement(
      icon: String? = nil,
      optional: Bool = false,
      optionalFlag: String = "(optional)",
      visuallyHidden: Bool = false,
      isLegend: Bool = false,
      inputID: String? = nil,
      descriptionID: String? = nil,
      disabled: Bool = false,
      labelFontWeight: CSS.FontWeight = fontWeightBold,
      labelFontSize: CSS.Length = fontSizeMedium16,
      class: String = "",
      title: String = "",
      description: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = LabelView(
        icon: icon,
        optional: optional,
        optionalFlag: optionalFlag,
        visuallyHidden: visuallyHidden,
        isLegend: isLegend,
        inputID: inputID,
        descriptionID: descriptionID,
        disabled: disabled,
        labelFontWeight: labelFontWeight,
        labelFontSize: labelFontSize,
        class: `class`,
        label: { title },
        description: { description }
      )
      wrapper.innerHTML = view.render()
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
