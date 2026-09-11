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
  let labelContent: [DOM.Node]
  let descriptionContent: [DOM.Node]
  let customInputContent: [DOM.Node]
  var `class`: String

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
    @HTMLBuilder label: () -> [DOM.Node],
    @HTMLBuilder description: () -> [DOM.Node] = { [] },
    @HTMLBuilder customInput: () -> [DOM.Node] = { [] }
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

  public func `class`(_ value: String) -> Self {
    var copy = self
    copy.class = value
    return copy
  }

  public func build() -> DOM.Node {
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
      }

      span {}
        .class("radio-icon")
        .ariaHidden(true)
        .data("disabled", disabled)
        .data("status", status.rawValue)

      div {
        label {
          span {
            for item in labelContent { item }
          }
          .class(hideLabel ? "radio-label-text visually-hidden" : "radio-label-text")
          .data("disabled", disabled)
        }
        .for(id)
        .class(hideLabel ? "radio-label visually-hidden" : "radio-label")

        if hasDescription && !hideLabel {
          div {
            for item in descriptionContent { item }
          }
          .class("radio-description")
          .id(descriptionID ?? "")
          .data("disabled", disabled)
        }
      }
      .class(hideLabel ? "radio-label-wrapper visually-hidden" : "radio-label-wrapper")
      .data("disabled", disabled)
    }
    .class(stringIsEmpty(`class`) ? "radio-view" : "radio-view \(`class`)")
    .data("inline", inline)
    .data("hide-label", hideLabel)

    if status == .error {
      radioView = radioView.data("status", "error")
    }

    return radioView
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          position(.relative)
        }
        selector("&[data-inline='true']") {
          display(.inlineFlex)
        }
        selector("&[data-hide-label='true']") {
          width(minSizeInputBinary)
          height(minSizeInputBinary)
          justifyContent(.center)
        }
        selector("&[data-hide-label='false']") {
          minHeight(minSizeInteractivePointer)
          gap(spacing8)
        }
        descendant(".radio-input") {
          position(.absolute)
          top(0)
          left(0)
          width(perc(100))
          height(perc(100))
          margin(0)
          opacity(0)
          zIndex(zIndexAboveContent)
          cursor(cursorBaseHover)
          pseudoClass(.disabled) {
            cursor(cursorNotAllowed)
          }
          pseudoClass(.checked, .enabled) {
            nextSibling(".radio-icon") {
              backgroundColor(backgroundColorBase).important()
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
          pseudoClass(.hover, .not(.checked), .enabled) {
            nextSibling(".radio-icon") {
              borderColor(borderColorInputBinaryHover).important()
            }
          }
          pseudoClass(.hover, .checked, .enabled) {
            nextSibling(".radio-icon") {
              borderColor(borderColorInputBinaryCheckedHover).important()
            }
          }
          pseudoClass(.active, .checked, .enabled) {
            nextSibling(".radio-icon") {
              borderColor(borderColorInputBinaryCheckedActive).important()
            }
          }
        }
        descendant(".radio-icon") {
          display(.inlineBlock)
          position(.relative)
          width(minSizeInputBinary)
          height(minSizeInputBinary)
          flexShrink(0)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorInputBinary)
          borderRadius(borderRadiusCircle)
          transition(.all, transitionDurationBase, transitionTimingFunctionSystem)
          cursor(cursorBaseHover)
        }
        selector("& .radio-icon[data-disabled='true']") {
          backgroundColor(backgroundColorDisabled)
          borderColor(borderColorDisabled)
          cursor(cursorNotAllowed)
        }
        selector("& .radio-icon[data-disabled='false'][data-status='error']") {
          borderColor(borderColorRed)
        }
        descendant(".radio-label-wrapper") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          cursor(cursorBaseHover)
          userSelect(.none)
        }
        selector("& .radio-label-wrapper[data-disabled='true']") {
          cursor(cursorNotAllowed)
        }
        descendant(".radio-label-text") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          fontWeight(fontWeightNormal)
          color(colorBase)
        }
        selector("& .radio-label-text[data-disabled='true']") {
          color(colorDisabled)
        }
        descendant(".radio-description") {
          fontSize(fontSizeSmall14)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
        }
        selector("& .radio-description[data-disabled='true']") {
          color(colorDisabled)
        }
        descendant(".visually-hidden") {
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
    ) -> DOM.Element {
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
      wrapper.innerHTML = view.render()
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
