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

  @CSSBuilder
  private func labelViewCSS() -> [CSSOM.CSSRule] {
    display(.flex)
    flexDirection(.column)
    gap(spacing4)
  }

  @CSSBuilder
  private func visuallyHiddenCSS() -> [CSSOM.CSSRule] {
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

  @CSSBuilder
  private func labelTextCSS() -> [CSSOM.CSSRule] {
    display(.flex)
    alignItems(.center)
    gap(spacing4)
    fontFamily(typographyFontSans)
    fontSize(labelFontSize)
    fontWeight(labelFontWeight)
    lineHeight(lineHeightMedium26)
    color(disabled ? colorDisabled : colorBase)
  }

  @CSSBuilder
  private func labelIconCSS() -> [CSSOM.CSSRule] {
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(minSizeIconMedium)
    height(minSizeIconMedium)
    color(disabled ? colorDisabled : colorSubtle)
    flexShrink(0)
  }

  @CSSBuilder
  private func labelOptionalFlagCSS() -> [CSSOM.CSSRule] {
    color(disabled ? colorDisabled : colorSubtle)
    fontWeight(fontWeightNormal)
  }

  @CSSBuilder
  private func labelDescriptionCSS() -> [CSSOM.CSSRule] {
    display(.block)
    fontSize(fontSizeSmall14)
    lineHeight(lineHeightSmall22)
    color(disabled ? colorDisabled : colorSubtle)
    fontWeight(fontWeightNormal)
  }

  public func build() -> DOM.Node {
    let hasDescription = !descriptionContent.isEmpty

    if isLegend {
      return legend {
        span {
          if let iconValue = icon {
            span { iconValue }
              .class("label-icon")
              .ariaHidden(true)
              .style {
                labelIconCSS()
              }
          }

          labelContent

          if optional {
            span { " \(optionalFlag)" }
              .class("label-optional-flag")
              .style {
                labelOptionalFlagCSS()
              }
          }
        }
        .class("label-text")
        .style {
          labelTextCSS()
        }

        if hasDescription {
          span { descriptionContent }
            .class("label-description")
            .id(descriptionID ?? "")
            .style {
              labelDescriptionCSS()
            }
        }
      }
      .class(
        stringIsEmpty(`class`) ? (visuallyHidden ? "label-view visually-hidden" : "label-view") : (visuallyHidden ? "label-view visually-hidden \(`class`)" : "label-view \(`class`)")
      )
      .style {
        labelViewCSS()

        if visuallyHidden {
          visuallyHiddenCSS()
        }
      }

    } else {
      return div {
        if let forID = inputID {
          label {
            if let iconValue = icon {
              span { iconValue }
                .class("label-icon")
                .ariaHidden(true)
                .style {
                  labelIconCSS()
                }
            }

            labelContent

            if optional {
              span { " \(optionalFlag)" }
                .class("label-optional-flag")
                .style {
                  labelOptionalFlagCSS()
                }
            }
          }
          .for(forID)
          .class("label-text")
          .style {
            labelTextCSS()
          }
        } else {
          span {
            if let iconValue = icon {
              span { iconValue }
                .class("label-icon")
                .ariaHidden(true)
                .style {
                  labelIconCSS()
                }
            }

            labelContent

            if optional {
              span { " \(optionalFlag)" }
                .class("label-optional-flag")
                .style {
                  labelOptionalFlagCSS()
                }
            }
          }
          .class("label-text")
          .style {
            labelTextCSS()
          }
        }

        if hasDescription {
          span { descriptionContent }
            .class("label-description")
            .id(descriptionID ?? "")
            .style {
              labelDescriptionCSS()
            }
        }
      }
      .class(
        stringIsEmpty(`class`) ? (visuallyHidden ? "label-view visually-hidden" : "label-view") : (visuallyHidden ? "label-view visually-hidden \(`class`)" : "label-view \(`class`)")
      )
      .style {
        labelViewCSS()

        if visuallyHidden {
          visuallyHiddenCSS()
        }
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
      wrapper.innerHTML = renderHTML { view.render() }
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
