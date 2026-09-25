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
    /// Guidance that belongs to the field but not under it. Help text
    /// pushes every later field down the page to say something a reader
    /// needs once; a tooltip is there when it is wanted and gone when it
    /// is not. Same affordance DropdownView already offers.
    let tooltip: String?
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
      labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
      labelFontSize: CSS.Length = fontSizeMedium16,
      tooltip: String? = nil,
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
      self.tooltip = tooltip
      self.labelFontSize = labelFontSize
      self.`class` = `class`
      self.labelContent = label()
      self.descriptionContent = description()
      self.inputContent = input()
      self.helpTextContent = helpText()
    }

    public func build() -> DOM.Node {
      let hasDescription = !descriptionContent.isEmpty
      let hasHelpText = !helpTextContent.isEmpty
      let descriptionID = hasDescription ? "\(id)-description" : nil
      let helpTextID = hasHelpText ? "\(id)-help-text" : nil
      // A form that validates itself draws messages on the client.
      FieldValidationMessageView.preloadStyleSheet()

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
            labelFontSize: labelFontSize,
            tooltip: tooltip
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

          if hasHelpText {
            div { helpTextContent }
              .class("field-help-text")
              .id(helpTextID ?? "")
              .data("disabled", disabled)
          }

          if status == .error, let errorMsg = messages.error {
            FieldValidationMessageView(status: .error, message: errorMsg)
          }

          if status == .warning, let warningMsg = messages.warning {
            FieldValidationMessageView(status: .warning, message: warningMsg)
          }

          if status == .success, let successMsg = messages.success {
            FieldValidationMessageView(status: .success, message: successMsg)
          }
        }
        .class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
        .disabled(disabled)
        .data("disabled", disabled)
        .style {
          selector("&") {
            display(.flex)
            flexDirection(.column)
            gap(spacing8)
            margin(0)
            padding(0)
            border(.none)
            minWidth(0)
          }
          selector("&[data-disabled='true']") { opacity(opacityMedium) }
          descendant(".field-input-wrapper") { display(.block) }
          descendant(".field-help-text") {
            display(.block)
            fontSize(fontSizeSmall14)
            lineHeight(lineHeightSmall22)
            color(colorSubtle)
          }
          selector("& .field-help-text[data-disabled='true']") { color(colorDisabled) }
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
            labelFontSize: labelFontSize,
            tooltip: tooltip
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

          if hasHelpText {
            div { helpTextContent }
              .class("field-help-text")
              .id(helpTextID ?? "")
              .data("disabled", disabled)
          }

          if status == .error, let errorMsg = messages.error {
            FieldValidationMessageView(status: .error, message: errorMsg)
          }

          if status == .warning, let warningMsg = messages.warning {
            FieldValidationMessageView(status: .warning, message: warningMsg)
          }

          if status == .success, let successMsg = messages.success {
            FieldValidationMessageView(status: .success, message: successMsg)
          }
        }
        .class(`class`.isEmpty ? "field-view" : "field-view \(`class`)")
        .data("disabled", disabled)
        .style {
          selector("&") {
            display(.flex)
            flexDirection(.column)
            gap(spacing8)
          }
          selector("&[data-disabled='true']") { opacity(opacityMedium) }
          descendant(".field-input-wrapper") { display(.block) }
          descendant(".field-help-text") {
            display(.block)
            fontSize(fontSizeSmall14)
            lineHeight(lineHeightSmall22)
            color(colorSubtle)
          }
          selector("& .field-help-text[data-disabled='true']") { color(colorDisabled) }
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
    public static nonisolated(unsafe) var instance: FieldViewHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector("label.field-view") != nil else { return }
      instance = FieldViewHydration()
    }

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
