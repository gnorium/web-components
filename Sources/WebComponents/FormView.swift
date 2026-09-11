#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// Generic form view component for creating and editing records.
  /// Auto-generates form fields based on configuration.
  public struct FormView: HTMLContent {
    /// Form field configuration
    public struct Field: Sendable {
      public let name: String
      public let label: String
      public let type: FieldType
      public let value: String
      public let required: Bool
      public let placeholder: String?
      public let helpText: String?
      public let options: [(value: String, label: String)]?
      public let readOnly: Bool
      public let rows: Int

      public enum FieldType: String, Sendable {
        case text
        case textarea
        case email
        case url
        case password
        case number
        case date
        case datetime
        case checkbox
        case select
        case hidden
      }

      public init(
        name: String,
        label: String,
        type: FieldType = .text,
        value: String = "",
        required: Bool = false,
        placeholder: String? = nil,
        helpText: String? = nil,
        options: [(value: String, label: String)]? = nil,
        readOnly: Bool = false,
        rows: Int = 5
      ) {
        self.name = name
        self.label = label
        self.type = type
        self.value = value
        self.required = required
        self.placeholder = placeholder
        self.helpText = helpText
        self.options = options
        self.readOnly = readOnly
        self.rows = rows
      }
    }

    let title: String
    let formAction: String
    let fields: [Field]
    let submitLabel: String
    let cancelUrl: String?
    let cancelLabel: String

    public init(
      title: String,
      action: String,
      fields: [Field],
      submitLabel: String = "Save",
      cancelUrl: String? = nil,
      cancelLabel: String = "Cancel"
    ) {
      self.title = title
      self.formAction = action
      self.fields = fields
      self.submitLabel = submitLabel
      self.cancelUrl = cancelUrl
      self.cancelLabel = cancelLabel
    }

    public func build() -> DOM.Node {
      div {
        // Header
        h1 { title }
          .class("form-view-title")

        // Form
        form {
          for field in fields {
            renderField(field)
          }

          // Actions
          div {
            button { submitLabel }
              .type(.submit)
              .class("form-view-submit")

            if let url = cancelUrl {
              a { cancelLabel }
                .href(url)
                .class("form-view-cancel")
            }
          }
          .class("form-actions")
        }
        .action(formAction)
        .method(.post)
        .class("form-view-form")
      }
      .class("form-view")
      .style {
        selector("&") {
          maxWidth(px(800))
          margin(0, .auto)
          padding(spacing48, spacing24)
          display(.flex)
          flexDirection(.column)
          gap(spacing32)
        }
        descendant(".form-view-title") {
          fontFamily(typographyFontSans)
          fontSize(px(32))
          fontWeight(.normal)
          color(colorBase)
          margin(0)
        }
        descendant(".form-view-form") {
          display(.flex)
          flexDirection(.column)
          gap(spacing24)
        }
        descendant(".form-actions") {
          display(.flex)
          gap(spacing16)
        }
        descendant(".form-view-submit") {
          padding(spacing12, spacing24)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          fontWeight(500)
          color(colorInverted)
          backgroundColor(backgroundColorBlue)
          border(.none)
          borderRadius(borderRadiusBase)
          cursor(.pointer)
          transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
        }
        descendant(".form-view-submit:hover") { backgroundColor(backgroundColorBlueHover) }
        descendant(".form-view-cancel") {
          padding(spacing12, spacing24)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          color(colorBase)
          backgroundColor(backgroundColorInteractive)
          border(borderWidthBase, borderStyleBase, borderColorBase)
          borderRadius(borderRadiusBase)
          textDecoration(.none)
          transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
        }
        descendant(".form-view-cancel:hover") { backgroundColor(backgroundColorInteractiveSubtleHover) }
        descendant(".form-field") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
        }
        descendant(".form-view-checkbox-label") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          fontSize(fontSizeMedium16)
          color(colorBase)
          cursor(.pointer)
        }
        descendant(".form-view-label") {
          fontSize(fontSizeSmall14)
          fontWeight(500)
          color(colorBase)
        }
        descendant(".form-view-help-text") {
          fontSize(fontSizeSmall14)
          color(colorSubtle)
        }
        selector(".form-field input:not([type='checkbox'])", ".form-field textarea", ".form-field select") {
          width(perc(100))
          padding(spacing12, spacing16)
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          color(colorBase)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, borderStyleBase, borderColorBase)
          borderRadius(borderRadiusBase)
        }
        selector(".form-field input:not([type='checkbox']):focus", ".form-field textarea:focus", ".form-field select:focus") {
          borderColor(borderColorBlueFocus)
          outline(.none)
          boxShadow(.inset, 0, 0, 0, px(1), borderColorBlueFocus)
        }
        selector(".form-field input:not([type='checkbox']):disabled", ".form-field textarea:disabled", ".form-field select:disabled") {
          backgroundColor(backgroundColorDisabledSubtle)
          color(colorDisabled)
          cursor(.notAllowed)
        }
      }
    }

    @HTMLBuilder
    private func renderField(_ field: Field) -> [DOM.Node] {
      if field.type == .hidden {
        input()
          .type(.hidden)
          .name(field.name)
          .value(field.value)
      } else if field.type == .checkbox {
        div {
          label {
            input()
              .type(.checkbox)
              .name(field.name)
              .value("true")
              .checked(field.value == "true")

            span { field.label }
          }
          .class("form-view-checkbox-label")

          if let help = field.helpText {
            p { help }
              .class("form-view-help-text")
          }
        }
        .class("form-field")
      } else {
        div {
          label { field.label + (field.required ? "" : " (optional)") }
            .for(field.name)
            .class("form-view-label")

          fieldInput(field)

          if let help = field.helpText {
            p { help }
              .class("form-view-help-text")
          }
        }
        .class("form-field")
      }
    }

    @HTMLBuilder
    private func fieldInput(_ field: Field) -> [DOM.Node] {
      switch field.type {
      case .textarea:
        textarea(field.value)
          .name(field.name)
          .id(field.name)
          .required(field.required)
          .disabled(field.readOnly)
          .rows(field.rows)
          .placeholder(field.placeholder ?? "")

      case .select:
        select {
          for opt in field.options ?? [] {
            option { opt.label }
              .value(opt.value)
              .selected(opt.value == field.value)
          }
        }
        .name(field.name)
        .id(field.name)
        .required(field.required)
        .disabled(field.readOnly)

      case .email:
        input()
          .type(.email)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)
          .placeholder(field.placeholder ?? "")

      case .url:
        input()
          .type(.url)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)
          .placeholder(field.placeholder ?? "")

      case .password:
        input()
          .type(.password)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .placeholder(field.placeholder ?? "")

      case .number:
        input()
          .type(.number)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)
          .placeholder(field.placeholder ?? "")

      case .date:
        input()
          .type(.date)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)

      case .datetime:
        input()
          .type(.datetimeLocal)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)

      default:
        input()
          .type(.text)
          .name(field.name)
          .id(field.name)
          .value(field.value)
          .required(field.required)
          .disabled(field.readOnly)
          .placeholder(field.placeholder ?? "")
      }
    }
  }
#endif
