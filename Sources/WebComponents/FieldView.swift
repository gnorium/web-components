#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A form field with a label, an input or control, and an optional validation message.
  /// Provides features for building accessible form fields to collect user input.
  public struct FieldView: HTMLContent {
    let id: String
    let labelIcon: String?
    let optional: Bool
    let optionalFlag: String
    let hideLabel: Bool
    let isFieldset: Bool
    let disabled: Bool
    let status: ValidationStatus
    let labelContent: [DOM.Node]
    let descriptionContent: [DOM.Node]
    let inputContent: [DOM.Node]
    let helpTextContent: [DOM.Node]
    let messages: ValidationMessages
    let `class`: String
    let labelFontWeight: CSS.FontWeight
    let labelFontSize: CSS.Length

    public enum ValidationStatus: String, Sendable {
      case `default`
      case error
      case warning
      case success
    }

    public struct ValidationMessages: Sendable {
      let error: String?
      let warning: String?
      let success: String?

      public init(error: String? = nil, warning: String? = nil, success: String? = nil) {
        self.error = error
        self.warning = warning
        self.success = success
      }
    }

    public init(
      id: String = "",
      labelIcon: String? = nil,
      optional: Bool = false,
      optionalFlag: String = "(optional)",
      hideLabel: Bool = false,
      isFieldset: Bool = false,
      disabled: Bool = false,
      status: ValidationStatus = .default,
      messages: ValidationMessages = ValidationMessages(),
      labelFontWeight: CSS.FontWeight = fontWeightBold,
      labelFontSize: CSS.Length = fontSizeMedium16,
      class: String = "",
      @HTMLBuilder label: () -> [DOM.Node],
      @HTMLBuilder description: () -> [DOM.Node] = { [] },
      @HTMLBuilder input: () -> [DOM.Node],
      @HTMLBuilder helpText: () -> [DOM.Node] = { [] }
    ) {
      self.id = id
      self.labelIcon = labelIcon
      self.optional = optional
      self.optionalFlag = optionalFlag
      self.hideLabel = hideLabel
      self.isFieldset = isFieldset
      self.disabled = disabled
      self.status = status
      self.messages = messages
      self.labelFontWeight = labelFontWeight
      self.labelFontSize = labelFontSize
      self.`class` = `class`
      self.labelContent = label()
      self.descriptionContent = description()
      self.inputContent = input()
      self.helpTextContent = helpText()
    }

    @CSSBuilder
    private func fieldViewCSS() -> [CSSOM.CSSRule] {
      display(.flex)
      flexDirection(.column)
      gap(spacing8)

      if disabled {
        opacity(opacityMedium)
      }
    }

    @CSSBuilder
    private func fieldInputWrapperCSS() -> [CSSOM.CSSRule] {
      display(.block)
    }

    @CSSBuilder
    private func fieldHelpTextCSS() -> [CSSOM.CSSRule] {
      display(.block)
      fontSize(fontSizeSmall14)
      lineHeight(lineHeightSmall22)
      color(disabled ? colorDisabled : colorSubtle)
    }

    @CSSBuilder
    private func fieldValidationMessageCSS() -> [CSSOM.CSSRule] {
      display(.flex)
      alignItems(.flexStart)
      gap(spacing4)
      fontSize(fontSizeSmall14)
      lineHeight(lineHeightSmall22)
    }

    @CSSBuilder
    private func fieldValidationIconCSS() -> [CSSOM.CSSRule] {
      display(.inlineFlex)
      alignItems(.center)
      justifyContent(.center)
      flexShrink(0)
      fontWeight(fontWeightBold)
    }

    @CSSBuilder
    private func fieldValidationTextCSS() -> [CSSOM.CSSRule] {
      flex(1)
    }

    public func build() -> DOM.Node {
      let hasDescription = !descriptionContent.isEmpty
      let hasHelpText = !helpTextContent.isEmpty
      let descriptionID = hasDescription ? "\(id)-description" : nil
      let helpTextID = hasHelpText ? "\(id)-help-text" : nil

      if isFieldset {
        return fieldset {
          LabelView(
            icon: labelIcon,
            optional: optional,
            optionalFlag: optionalFlag,
            visuallyHidden: hideLabel,
            isLegend: true,
            descriptionID: descriptionID,
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

          div {
            inputContent
          }
          .class("field-input-wrapper")
          .style {
            fieldInputWrapperCSS()
          }

          if hasHelpText {
            div { helpTextContent }
              .class("field-help-text")
              .id(helpTextID ?? "")
              .style {
                fieldHelpTextCSS()
              }
          }

          if status == .error, let errorMsg = messages.error {
            div {
              span { "⚠" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { errorMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorRed)
            }
          }

          if status == .warning, let warningMsg = messages.warning {
            div {
              span { "⚠" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { warningMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorOrange)
            }
          }

          if status == .success, let successMsg = messages.success {
            div {
              span { "✓" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { successMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorGreen)
            }
          }
        }
        .class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
        .disabled(disabled)
        .style {
          margin(0)
          padding(0)
          border(.none)
          minWidth(0)
          fieldViewCSS()
        }

      } else {
        return label {
          LabelView(
            icon: labelIcon,
            optional: optional,
            optionalFlag: optionalFlag,
            visuallyHidden: hideLabel,
            isLegend: false,
            descriptionID: descriptionID,
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

          div {
            inputContent
          }
          .class("field-input-wrapper")
          .style {
            fieldInputWrapperCSS()
          }

          if hasHelpText {
            div { helpTextContent }
              .class("field-help-text")
              .id(helpTextID ?? "")
              .style {
                fieldHelpTextCSS()
              }
          }

          if status == .error, let errorMsg = messages.error {
            div {
              span { "⚠" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { errorMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorRed)
            }
          }

          if status == .warning, let warningMsg = messages.warning {
            div {
              span { "⚠" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { warningMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorOrange)
            }
          }

          if status == .success, let successMsg = messages.success {
            div {
              span { "✓" }
                .class("field-validation-icon")
                .ariaHidden(true)
                .style {
                  fieldValidationIconCSS()
                }

              span { successMsg }
                .class("field-validation-text")
                .style {
                  fieldValidationTextCSS()
                }
            }
            .class("field-validation-message")
            .style {
              fieldValidationMessageCSS()
              color(colorGreen)
            }
          }
        }
        .class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
        .style {
          fieldViewCSS()
        }

      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import WebAPIs
  import WebTypes

  public class FieldViewHydration: @unchecked Sendable {
    public init() {
      let labels = document.querySelectorAll("label.field-view")
      for label in labels {
        _ = label.addEventListener(.click) { event in
          guard let target = event.target else { return }
          if target.closest(".label-view") != nil {
            event.preventDefault()
          }
        }
      }
    }
  }
#endif
