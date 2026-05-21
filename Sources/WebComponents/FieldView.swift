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
    let labelContent: [Node]
    let descriptionContent: [Node]
    let inputContent: [Node]
    let helpTextContent: [Node]
    let messages: ValidationMessages
    let `class`: String
    let labelFontWeight: CSSFontWeight
    let labelFontSize: Length

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
      id: String,
      labelIcon: String? = nil,
      optional: Bool = false,
      optionalFlag: String = "(optional)",
      hideLabel: Bool = false,
      isFieldset: Bool = false,
      disabled: Bool = false,
      status: ValidationStatus = .default,
      messages: ValidationMessages = ValidationMessages(),
      labelFontWeight: CSSFontWeight = fontWeightBold,
      labelFontSize: Length = fontSizeMedium16,
      class: String = "",
      @HTMLBuilder label: () -> [Node],
      @HTMLBuilder description: () -> [Node] = { [] },
      @HTMLBuilder input: () -> [Node],
      @HTMLBuilder helpText: () -> [Node] = { [] }
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
    private func fieldViewCSS() -> [CSSRule] {
      display(.flex)
      flexDirection(.column)
      gap(spacing8)

      if disabled {
        opacity(opacityMedium)
      }
    }

    @CSSBuilder
    private func fieldInputWrapperCSS() -> [CSSRule] {
      display(.block)
    }

    @CSSBuilder
    private func fieldHelpTextCSS() -> [CSSRule] {
      display(.block)
      fontSize(fontSizeSmall14)
      lineHeight(lineHeightSmall22)
      color(disabled ? colorDisabled : colorSubtle)
    }

    @CSSBuilder
    private func fieldValidationMessageCSS() -> [CSSRule] {
      display(.flex)
      alignItems(.flexStart)
      gap(spacing4)
      fontSize(fontSizeSmall14)
      lineHeight(lineHeightSmall22)
    }

    @CSSBuilder
    private func fieldValidationIconCSS() -> [CSSRule] {
      display(.inlineFlex)
      alignItems(.center)
      justifyContent(.center)
      flexShrink(0)
      fontWeight(fontWeightBold)
    }

    @CSSBuilder
    private func fieldValidationTextCSS() -> [CSSRule] {
      flex(1)
    }

    public func build() -> Node {
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
        return div {
          LabelView(
            icon: labelIcon,
            optional: optional,
            optionalFlag: optionalFlag,
            visuallyHidden: hideLabel,
            isLegend: false,
            inputID: id,
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
