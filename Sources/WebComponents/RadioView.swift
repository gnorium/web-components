import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A radio input with label and optional description that supports single selection from a group.
public struct RadioView: HTMLContent {
  let id: String
  let name: String
  let value: String
  let checked: Bool
  let inline: Bool
  let disabled: Bool
  let hideLabel: Bool
  let status: ValidationStatus
  let labelContent: [Node]
  let descriptionContent: [Node]
  let customInputContent: [Node]
  let `class`: String

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    value: String,
    checked: Bool = false,
    inline: Bool = false,
    disabled: Bool = false,
    hideLabel: Bool = false,
    status: ValidationStatus = .default,
    class: String = "",
    @HTMLBuilder label: () -> [Node],
    @HTMLBuilder description: () -> [Node] = { [] },
    @HTMLBuilder customInput: () -> [Node] = { [] }
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.hideLabel = hideLabel
    self.checked = checked
    self.inline = inline
    self.disabled = disabled
    self.status = status
    self.`class` = `class`
    self.labelContent = label()
    self.descriptionContent = description()
    self.customInputContent = customInput()
  }

  @CSSBuilder
  private func radioViewCSS(_ inline: Bool) -> [CSSRule] {
    if inline {
      display(.inlineFlex)
    } else {
      display(.flex)
    }
    alignItems(.center)
    position(.relative)
    minHeight(minSizeInteractivePointer)
    gap(spacing8)
  }

  @CSSBuilder
  private func radioInputCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSSRule] {
    position(.absolute)
    width(minSizeInputBinary)
    height(minSizeInputBinary)
    margin(0)
    opacity(0)
    cursor(disabled ? cursorBaseDisabled : cursorBaseHover)

    pseudoClass(.checked, not(.disabled)) {
      nextSibling(".radio-icon") {
        backgroundColor(backgroundColorInputBinaryChecked).important()
        borderColor(borderColorInputBinaryChecked).important()
        borderWidth(borderWidthInputRadioChecked).important()
      }
    }

    pseudoClass(.focus) {
      nextSibling(".radio-icon") {
        borderColor(borderColorInputBinaryFocus).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
    }

    pseudoClass(.hover, not(.disabled)) {
      nextSibling(".radio-icon") {
        borderColor(borderColorInputBinaryHover).important()
      }
    }
  }

  @CSSBuilder
  private func radioIconCSS(_ disabled: Bool, _ status: ValidationStatus) -> [CSSRule] {
    display(.inlineBlock)
    position(.relative)
    width(minSizeInputBinary)
    height(minSizeInputBinary)
    flexShrink(0)
    backgroundColor(disabled ? backgroundColorDisabled : backgroundColorBase)
    border(
      borderWidthBase, .solid,
      status == .error ? borderColorRed : (disabled ? borderColorDisabled : borderColorInputBinary))
    borderRadius(borderRadiusCircle)
    transition(.all, transitionDurationBase, transitionTimingFunctionSystem)
    cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
  }

  @CSSBuilder
  private func radioLabelWrapperCSS(_ disabled: Bool) -> [CSSRule] {
    display(.flex)
    flexDirection(.column)
    gap(spacing4)
    cursor(disabled ? cursorBaseDisabled : cursorBaseHover)
    userSelect(.none)
  }

  @CSSBuilder
  private func radioLabelTextCSS(_ disabled: Bool) -> [CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    lineHeight(lineHeightSmall22)
    fontWeight(fontWeightNormal)
    color(disabled ? colorDisabled : colorBase)
  }

  @CSSBuilder
  private func radioDescriptionCSS(_ disabled: Bool) -> [CSSRule] {
    fontSize(fontSizeSmall14)
    lineHeight(lineHeightSmall22)
    color(disabled ? colorDisabled : colorSubtle)
  }

  @CSSBuilder
  private func visuallyHiddenCSS() -> [CSSRule] {
    position(.absolute)
    width(px(1))
    height(px(1))
    margin(px(-1))
    padding(0)
    overflow(.hidden)
    clip(rect(0, 0, 0, 0))
    whiteSpace(.nowrap)
    borderWidth(0)
  }

  public func render() -> Node {
    let hasDescription = !descriptionContent.isEmpty
    let hasCustomInput = !customInputContent.isEmpty
    let descriptionID = hasDescription ? "\(id)-description" : nil

    var radioView = div {
      if hasCustomInput {
        customInputContent
      } else {
        input()
          .type(.radio)
          .id(id)
          .name(name)
          .value(value)
          .checked(checked)
          .disabled(disabled)
          .ariaDescribedby(descriptionID ?? "")
          .class("radio-input")
          .style {
            radioInputCSS(disabled, status)
          }
      }

      span {}
        .class("radio-icon")
        .ariaHidden(true)
        .style {
          radioIconCSS(disabled, status)
        }

      div {
        label {
          span {
            for item in labelContent { item }
          }
          .class("radio-label-text")
          .style {
            radioLabelTextCSS(disabled)
            if hideLabel {
              visuallyHiddenCSS()
            }
          }
        }
        .for(id)
        .class("radio-label")
        .style {
          if hideLabel {
            visuallyHiddenCSS()
          }
        }

        if hasDescription && !hideLabel {
          div {
            for item in descriptionContent { item }
          }
          .class("radio-description")
          .id(descriptionID ?? "")
          .style {
            radioDescriptionCSS(disabled)
          }
        }
      }
      .class("radio-label-wrapper")
      .style {
        radioLabelWrapperCSS(disabled)
        if hideLabel {
          visuallyHiddenCSS()
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "radio-view" : "radio-view \(`class`)")

    if status == .error {
      radioView = radioView.data("status", "error")
    }

    return radioView
      .style {
        radioViewCSS(inline)
      }

  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT factory for creating RadioView DOM elements dynamically.
  public enum RadioFactory {
    /// Creates a RadioView DOM element matching the server-rendered RadioView.
    public static func createElement(
      id: String,
      name: String,
      value: String,
      checked: Bool = false,
      inline: Bool = false,
      disabled: Bool = false,
      hideLabel: Bool = false,
      status: RadioView.ValidationStatus = .default,
      class: String = "",
      title: String = ""
    ) -> Element {
      let wrapper = document.createElement(.div)
      let view = RadioView(
        id: id,
        name: name,
        value: value,
        checked: checked,
        inline: inline,
        disabled: disabled,
        hideLabel: hideLabel,
        status: status,
        class: `class`,
        label: { title }
      )
      wrapper.innerHTML = buildHTML { view.render() }
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
