import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A Checkbox is a binary input that can appear by itself or in a multiselect group.
/// Checkboxes can be selected, unselected or in an indeterminate state.
public struct CheckboxView: HTMLContent {
  let id: String
  let name: String
  let value: String
  let checked: Bool
  let disabled: Bool
  let indeterminate: Bool
  let inline: Bool
  let hideLabel: Bool
  let status: ValidationStatus
  let labelContent: [Node]
  let descriptionContent: [Node]
  let customInputContent: [Node]
  let `class`: String
  let labelFontWeight: CSSFontWeight
  let labelFontSize: Length

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    value: String = "1",
    checked: Bool = false,
    disabled: Bool = false,
    indeterminate: Bool = false,
    inline: Bool = false,
    hideLabel: Bool = false,
    status: ValidationStatus = .default,
    class: String = "",
    labelFontWeight: CSSFontWeight = fontWeightNormal,
    labelFontSize: Length = fontSizeSmall14,
    @HTMLBuilder label: () -> [Node],
    @HTMLBuilder description: () -> [Node] = { [] },
    @HTMLBuilder customInput: () -> [Node] = { [] }
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.checked = checked
    self.disabled = disabled
    self.indeterminate = indeterminate
    self.inline = inline
    self.hideLabel = hideLabel
    self.status = status
    self.`class` = `class`
    self.labelFontWeight = labelFontWeight
    self.labelFontSize = labelFontSize
    self.labelContent = label()
    self.descriptionContent = description()
    self.customInputContent = customInput()
  }

  public init(
    id: String,
    name: String,
    value: Bool,
    checked: Bool = false,
    disabled: Bool = false,
    indeterminate: Bool = false,
    inline: Bool = false,
    hideLabel: Bool = false,
    status: ValidationStatus = .default,
    class: String = "",
    labelFontWeight: CSSFontWeight = fontWeightNormal,
    labelFontSize: Length = fontSizeSmall14,
    @HTMLBuilder label: () -> [Node],
    @HTMLBuilder description: () -> [Node] = { [] },
    @HTMLBuilder customInput: () -> [Node] = { [] }
  ) {
    self.init(
      id: id,
      name: name,
      value: value ? "true" : "false",
      checked: checked,
      disabled: disabled,
      indeterminate: indeterminate,
      inline: inline,
      hideLabel: hideLabel,
      status: status,
      class: `class`,
      labelFontWeight: labelFontWeight,
      labelFontSize: labelFontSize,
      label: label,
      description: description,
      customInput: customInput
    )
  }

  @CSSBuilder
  private func checkboxViewCSS(_ inline: Bool) -> [CSSRule] {
    if inline {
      display(.inlineFlex)
    } else {
      display(.flex)
    }
    alignItems(.center)
    position(.relative)
    if !inline {
      minHeight(minSizeInputBinary)
    }
    gap(spacing8)

    if inline {
      marginInlineEnd(spacing16)

      pseudoClass(.lastChild) {
        marginInlineEnd(0).important()
      }
    } else {
      marginBlockEnd(spacing8)

      pseudoClass(.lastChild) {
        marginBlockEnd(0).important()
      }
    }
  }

  @CSSBuilder
  private func checkboxIconWrapperCSS() -> [CSSRule] {
    display(.inlineFlex)
    position(.relative)
    verticalAlign(.middle)
  }

  @CSSBuilder
  private func checkboxInputCSS(_ disabled: Bool) -> [CSSRule] {
    position(.absolute)
    width(perc(100))
    height(perc(100))
    margin(0)
    opacity(0)
    zIndex(zIndexAboveContent)
    cursor(disabled ? cursorBaseDisabled : .pointer)

    // Checkmark visibility
    pseudoClass(.checked) {
      nextSibling(".checkbox-icon") {
        pseudoElement(.before) {
          opacity(1).important()
          transform(translate(perc(-50), perc(-60)), rotate(deg(45)), scale(1))
            .important()
        }
      }
    }

    pseudoClass(.indeterminate) {
      nextSibling(".checkbox-icon") {
        pseudoElement(.before) {
          opacity(1).important()
          transform(translate(perc(-50), perc(-50)), scale(1)).important()
        }
      }
    }

    pseudoClass(.checked) {
      nextSibling(".checkbox-icon") {
        backgroundColor(backgroundColorInputBinaryChecked).important()
        borderColor(borderColorInputBinaryChecked).important()
      }
    }

    pseudoClass(.checked, .disabled) {
      nextSibling(".checkbox-icon") {
        backgroundColor(backgroundColorDisabledSubtle).important()
        borderColor(borderColorDisabled).important()
      }
    }

    pseudoClass(.focus) {
      nextSibling(".checkbox-icon") {
        borderColor(borderColorBlueFocus).important()
        boxShadow(px(0), px(0), px(8), boxShadowColorBlueFocus).important()
      }
    }

    pseudoClass(.enabled, .hover) {
      nextSibling(".checkbox-icon") {
        borderColor(borderColorInputBinaryHover).important()
      }
    }

    pseudoClass(.enabled, .hover, .checked) {
      nextSibling(".checkbox-icon") {
        backgroundColor(backgroundColorInputBinaryChecked).important()
        borderColor(borderColorInputBinaryHover).important()
      }
    }

    pseudoClass(.enabled, .active) {
      nextSibling(".checkbox-icon") {
        backgroundColor(backgroundColorInputBinaryChecked).important()
        borderColor(borderColorInputBinaryActive).important()
      }
    }

    pseudoClass(.enabled, .active, .checked) {
      nextSibling(".checkbox-icon") {
        backgroundColor(backgroundColorInputBinaryChecked).important()
        borderColor(borderColorInputBinaryActive).important()
      }
    }
  }

  @CSSBuilder
  private func checkboxIconCSS(
    _ status: ValidationStatus, _ disabled: Bool, _ checked: Bool, _ indeterminate: Bool
  ) -> [CSSRule] {
    display(.inlineBlock)
    position(.relative)
    pointerEvents(.none)
    width(minSizeInputBinary)
    height(minSizeInputBinary)
    if disabled {
      backgroundColor(backgroundColorDisabledSubtle)
    } else {
      backgroundColor(backgroundColorBase)
    }
    if disabled {
      border(borderWidthBase, .solid, borderColorDisabled)
    } else if status == .error {
      border(borderWidthBase, .solid, borderColorRed)
    } else {
      border(borderWidthBase, .solid, borderColorInputBinary)
    }
    borderRadius(borderRadiusMinimal)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
    flexShrink(0)

    pseudoElement(.before) {
      content("\"\"")
      position(.absolute)
      top(perc(50))
      left(perc(50))
      pointerEvents(.none)
      transition(.all, s(0.2), .easeInOut)
      opacity(disabled && checked ? 1 : 0)  // Shown when input is checked/indeterminate
      transform(translate(perc(-50), (indeterminate ? perc(-50) : perc(-60))), scale(0.5))

      if indeterminate {
        width(px(10))
        height(px(2))
        backgroundColor(disabled ? colorSubtle : colorInvertedFixed)
      } else {
        width(px(5))
        height(px(10))
        borderRight(px(2), .solid, disabled ? colorSubtle : colorInvertedFixed)
        borderBottom(px(2), .solid, disabled ? colorSubtle : colorInvertedFixed)
        // Standard checkmark: rotate L-shape 45 degrees clockwise
        transform(translate(perc(-50), perc(-60)), rotate(deg(45)), scale(0.5))
      }
    }

    // Animation handled by input + .checkbox-icon:checked::before
  }

  @CSSBuilder
  private func checkboxLabelWrapperCSS() -> [CSSRule] {
    flex(1)
  }

  @CSSBuilder
  private func checkboxCustomInputCSS() -> [CSSRule] {
    display(.block)
  }

  public func render() -> Node {
    let hasDescription = !descriptionContent.isEmpty
    let hasCustomInput = !customInputContent.isEmpty
    let descriptionID = hasDescription ? "\(id)-description" : nil

    return div {
      span {
        input()
          .type(.checkbox)
          .id(id)
          .name(name)
          .value(value)
          .checked(checked)
          .disabled(disabled)
          .ariaDescribedby(descriptionID)
          .class("checkbox-input")
          .style {
            checkboxInputCSS(disabled)
          }

        span()
          .class("checkbox-icon")
          .style {
            checkboxIconCSS(status, disabled, checked, indeterminate)
          }
      }
      .class("checkbox-icon-wrapper")
      .style {
        checkboxIconWrapperCSS()
      }

      div {
        LabelView(
          visuallyHidden: hideLabel,
          inputID: id,
          descriptionID: hasDescription ? descriptionID : nil,
          disabled: disabled,
          labelFontWeight: labelFontWeight,
          labelFontSize: labelFontSize
        ) {
          labelContent
        } description: {
          if hasDescription {
            descriptionContent
          }
        }

        if hasCustomInput {
          div {
            customInputContent
          }
          .class("checkbox-custom-input")
          .style {
            checkboxCustomInputCSS()
          }
        }
      }
      .class("checkbox-label-wrapper")
      .style {
        checkboxLabelWrapperCSS()
      }
    }
    .class(stringIsEmpty(`class`) ? "checkbox-view" : "checkbox-view \(`class`)")
    .style {
      checkboxViewCSS(inline)
    }
  }
}

#if CLIENT
  import WebAPIs

  /// CLIENT factory for creating CheckboxView DOM elements dynamically.
  public enum CheckboxFactory {
    /// Creates a CheckboxView DOM element matching the server-rendered CheckboxView.
    public static func createElement(
      id: String,
      name: String,
      value: String = "1",
      checked: Bool = false,
      disabled: Bool = false,
      indeterminate: Bool = false,
      inline: Bool = false,
      hideLabel: Bool = false,
      status: CheckboxView.ValidationStatus = .default,
      class: String = "",
      labelFontWeight: CSSFontWeight = fontWeightNormal,
      labelFontSize: Length = fontSizeSmall14,
      title: String = ""
    ) -> Element {
      let wrapper = document.createElement(.div)
      let view = CheckboxView(
        id: id,
        name: name,
        value: value,
        checked: checked,
        disabled: disabled,
        indeterminate: indeterminate,
        inline: inline,
        hideLabel: hideLabel,
        status: status,
        class: `class`,
        labelFontWeight: labelFontWeight,
        labelFontSize: labelFontSize,
        label: { title }
      )
      wrapper.innerHTML = buildHTML { view.render() }
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
