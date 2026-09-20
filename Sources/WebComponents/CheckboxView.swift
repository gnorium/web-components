import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

private extension HTML.HTMLInputElement {
  func form(_ value: String?) -> Self {
    guard let value else { return self }
    return form(value)
  }
}

/// A Checkbox is a binary input that can appear by itself or in a multiselect group.
/// Checkboxes can be selected, unselected or in an indeterminate state.
public struct CheckboxView: HTMLContent {
  let id: String
  let name: String
  let value: String
  let form: String?
  let checked: Bool
  let disabled: Bool
  let indeterminate: Bool
  let inline: Bool
  let hideLabel: Bool
  let status: ValidationStatus
  let labelContent: [DOM.Node]
  let descriptionContent: [DOM.Node]
  let afterLabelContent: [DOM.Node]
  let `class`: String
  let labelFontWeight: CSS.FontWeight
  let labelFontSize: CSS.Length

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    value: String = "1",
    form: String? = nil,
    checked: Bool = false,
    disabled: Bool = false,
    indeterminate: Bool = false,
    inline: Bool = false,
    hideLabel: Bool = false,
    status: ValidationStatus = .default,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightNormal,
    labelFontSize: CSS.Length = fontSizeSmall14,
    @HTMLBuilder label: () -> [DOM.Node],
    @HTMLBuilder description: () -> [DOM.Node] = { [] },
    @HTMLBuilder afterLabel: () -> [DOM.Node] = { [] }
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.form = form
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
    self.afterLabelContent = afterLabel()
  }

  public init(
  id: String,
  name: String,
  value: Bool,
  form: String? = nil,
  checked: Bool = false,
  disabled: Bool = false,
  indeterminate: Bool = false,
  inline: Bool = false,
  hideLabel: Bool = false,
  status: ValidationStatus = .default,
  class: String = "",
  labelFontWeight: CSS.FontWeight = fontWeightNormal,
  labelFontSize: CSS.Length = fontSizeSmall14,
  @HTMLBuilder label: () -> [DOM.Node],
  @HTMLBuilder description: () -> [DOM.Node] = { [] },
  @HTMLBuilder afterLabel: () -> [DOM.Node] = { [] }
  ) {
    self.init(
      id: id,
      name: name,
      value: value ? "true" : "false",
      form: form,
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
      afterLabel: afterLabel
    )
  }

  public func build() -> DOM.Node {
    let hasDescription = !descriptionContent.isEmpty
    let hasAfterLabel = !afterLabelContent.isEmpty
    let descriptionID = hasDescription ? "\(id)-description" : nil

    return div {
      span {
        input()
          .type(.checkbox)
          .id(id)
          .name(name)
          .value(value)
          .form(form)
          .checked(checked)
          .disabled(disabled)
          .ariaDescribedby(descriptionID)
          .class("checkbox-input")
          .style {
            selector("&") {
              position(.absolute)
              top(0)
              left(0)
              width(perc(100))
              height(perc(100))
              margin(0)
              opacity(0)
              zIndex(zIndexAboveContent)
              cursor(.pointer)
            }
            pseudoClass(.disabled) { cursor(cursorNotAllowed) }
            pseudoClass(.checked) {
              nextSibling(".checkbox-icon") {
                pseudoElement(.before) {
                  opacity(1).important()
                  transform(translate(perc(-50), perc(-60)), rotate(deg(45)), scale(1)).important()
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
                pseudoElement(.before) {
                  borderRightColor(colorDisabled).important()
                  borderBottomColor(colorDisabled).important()
                }
              }
            }
            pseudoClass(.indeterminate, .disabled) {
              nextSibling(".checkbox-icon") {
                pseudoElement(.before) { backgroundColor(backgroundColorDisabledSubtle).important() }
              }
            }
            pseudoClass(.focus) {
              nextSibling(".checkbox-icon") {
                borderColor(borderColorInputBinaryFocus).important()
                boxShadow(px(0), px(0), px(8), boxShadowColorBlueFocus).important()
              }
            }
            pseudoClass(.enabled, .hover) {
              nextSibling(".checkbox-icon") { borderColor(borderColorInputBinary).important() }
            }
            pseudoClass(.enabled, .hover, .checked) {
              nextSibling(".checkbox-icon") {
                backgroundColor(backgroundColorInputBinaryChecked).important()
                borderColor(borderColorInputBinaryCheckedHover).important()
              }
            }
            pseudoClass(.enabled, .active) {
              nextSibling(".checkbox-icon") {
                backgroundColor(backgroundColorInputBinaryChecked).important()
                borderColor(borderColorInputBinary).important()
              }
            }
            pseudoClass(.enabled, .active, .checked) {
              nextSibling(".checkbox-icon") {
                backgroundColor(backgroundColorInputBinaryChecked).important()
                borderColor(borderColorInputBinaryCheckedActive).important()
              }
            }
          }

        span()
          .class("checkbox-icon")
          .data("status", status.rawValue)
          .data("disabled", disabled)
          .data("indeterminate", indeterminate)
          .style {
            selector("&") {
              display(.inlineBlock)
              position(.relative)
              pointerEvents(.none)
              width(minSizeInputBinary)
              height(minSizeInputBinary)
              borderRadius(borderRadiusMinimal)
              flexShrink(0)
              backgroundColor(backgroundColorBase)
              border(borderWidthBase, .solid, borderColorInputBinary)
            }
            selector("&[data-disabled='true']") {
              backgroundColor(backgroundColorDisabledSubtle)
              borderColor(borderColorDisabled)
            }
            selector("&[data-disabled='false'][data-status='error']") { borderColor(borderColorRed) }
            pseudoElement(.before) {
              content("\"\"")
              position(.absolute)
              top(perc(50))
              left(perc(50))
              pointerEvents(.none)
              opacity(0)
            }
            selector("&[data-indeterminate='true']::before") {
              width(px(10))
              height(px(2))
              backgroundColor(colorInvertedFixed)
              transform(translate(perc(-50), perc(-50)), scale(1))
            }
            selector("&[data-indeterminate='false']::before") {
              width(px(5))
              height(px(10))
              borderRight(px(2), .solid, colorInvertedFixed)
              borderBottom(px(2), .solid, colorInvertedFixed)
              transform(translate(perc(-50), perc(-60)), rotate(deg(45)), scale(1))
            }
          }
      }
      .class("checkbox-icon-wrapper")
      .style {
        selector("&") {
          display(.inlineFlex)
          position(.relative)
          verticalAlign(.middle)
        }
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

        if hasAfterLabel {
          div {
            afterLabelContent
          }
          .class("checkbox-after-label")
          .style {
            selector("&") { display(.block) }
          }
        }
      }
      .class("checkbox-label-wrapper")
    }
    .class(stringIsEmpty(`class`) ? "checkbox-view" : "checkbox-view \(`class`)")
    .data("inline", inline)
    .data("hide-label", hideLabel)
    .data("has-after-label", hasAfterLabel)
    .style {
      selector("&") {
        display(.flex)
        alignItems(.center)
        position(.relative)
      }
      selector("&[data-inline='true']") { display(.inlineFlex) }
      selector("&[data-inline='false']") {
        minHeight(minSizeInputBinary)
        marginBlockEnd(spacing8)
      }
      selector("&[data-hide-label='true'][data-has-after-label='false']") { justifyContent(.center) }
      selector("&:not([data-hide-label='true']), &[data-has-after-label='true']") { gap(spacing8) }
      selector("&[data-inline='true']:not([data-hide-label='true']), &[data-inline='true'][data-has-after-label='true']") {
        marginInlineEnd(spacing16)
      }
      selector("&[data-inline='true']:last-child") { marginInlineEnd(0).important() }
      selector("&[data-inline='false']:last-child") { marginBlockEnd(0).important() }
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
      form: String? = nil,
      checked: Bool = false,
      disabled: Bool = false,
      indeterminate: Bool = false,
      inline: Bool = false,
      hideLabel: Bool = false,
      status: CheckboxView.ValidationStatus = .default,
      class: String = "",
      labelFontWeight: CSS.FontWeight = fontWeightNormal,
      labelFontSize: CSS.Length = fontSizeSmall14,
      title: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = CheckboxView(
        id: id,
        name: name,
        value: value,
        form: form,
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
      wrapper.innerHTML = view.render()
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
