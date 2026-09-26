import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A multi-line text input that allows manual resizing if needed.
public struct TextAreaView: HTMLContent {
  let id: String
  let name: String
  let placeholder: String
  let value: String
  let status: ValidationStatus
  let disabled: Bool
  let readonly: Bool
  let required: Bool
  let rows: Int
  let autosize: Bool
  let startIcon: String?
  let endIcon: String?
  let labelText: String
  let tooltip: String?
  let fullWidth: Bool
  /// The id of the form this submits with, when it sits outside that form.
  let form: String?
  let `class`: String
  /// Whether the label carries the lighter "(optional)" aside after its
  /// text, as LabelView draws it: not part of the label text.
  let optional: Bool
  let optionalFlag: String

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    placeholder: String = "",
    value: String = "",
    status: ValidationStatus = .default,
    disabled: Bool = false,
    readonly: Bool = false,
    required: Bool = false,
    rows: Int = 4,
    autosize: Bool = false,
    startIcon: String? = nil,
    endIcon: String? = nil,
    label: String = "",
    optional: Bool = false,
    optionalFlag: String = "(optional)",
    tooltip: String? = nil,
    fullWidth: Bool = true,
    form: String? = nil,
    class: String = ""
  ) {
    self.id = id
    self.name = name
    self.placeholder = placeholder
    self.value = value
    self.status = status
    self.disabled = disabled
    self.readonly = readonly
    self.required = required
    self.rows = rows
    self.autosize = autosize
    self.startIcon = startIcon
    self.endIcon = endIcon
    self.labelText = label
    self.tooltip = tooltip
    self.fullWidth = fullWidth
    self.form = form
    self.`class` = `class`
    self.optional = optional
    self.optionalFlag = optionalFlag
  }

  public func build() -> DOM.Node {
    var textAreaInput = textarea(value)
      .id(id)
      .name(name)
      .placeholder(placeholder)
      .disabled(disabled)
      .readonly(readonly)
      .required(required)
      .rows(rows)
      .class("text-area-input")

    if autosize {
      textAreaInput = textAreaInput.data("autosize", "true")
    }
    if let form {
      textAreaInput = textAreaInput.form(form)
    }

    var hasStartIcon = false
    var hasEndIcon = false
    if let _ = startIcon { hasStartIcon = true }
    if let _ = endIcon { hasEndIcon = true }
    let stateClass = "\(fullWidth ? "text-area-full-width " : "")\(disabled ? "text-area-disabled " : "")\(readonly ? "text-area-read-only " : "")\(status == .error ? "text-area-error " : "")\(autosize ? "text-area-autosize " : "")\(hasStartIcon ? "text-area-has-start-icon " : "")\(hasEndIcon ? "text-area-has-end-icon" : "")"
    let textAreaClass = stringIsEmpty(`class`)
      ? "text-area-view \(stateClass)"
      : "text-area-view \(stateClass) \(`class`)"

    var container = div {
      if let icon = startIcon {
        span { icon }
          .class("text-area-start-icon")
          .ariaHidden(true)
      }
      textAreaInput
      if let icon = endIcon {
        span { icon }
          .class("text-area-end-icon")
          .ariaHidden(true)
      }
    }
    .class(textAreaClass)

    if status == .error {
      container = container.data("status", "error")
    }

    let styledContainer = container.style {
      selector("&") {
        position(.relative)
        display(.inlineBlock)
      }
      selector("&.text-area-full-width") { width(perc(100)) }
      selector("&.text-area-has-start-icon", "&.text-area-has-end-icon") {
        display(.flex)
        alignItems(.flexStart)
        gap(spacing8)
      }
      descendant(".text-area-input") {
        width(perc(100))
        padding(spacing8, px(15))
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        outline(.none)
        cursor(cursorText)
        resize(.vertical)
        overflowY(.auto)
      }
      selector("&.text-area-disabled .text-area-input") {
        color(colorDisabled)
        customProperty("-webkit-text-fill-color", colorDisabled)
        backgroundColor(backgroundColorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
        resize(.none)
      }
      selector("&.text-area-read-only .text-area-input") {
        backgroundColor(backgroundColorNeutralSubtle)
      }
      selector("&.text-area-error .text-area-input") { borderColor(borderColorRed) }
      selector("&.text-area-autosize .text-area-input") {
        resize(.none)
        fieldSizing(.content)
        minHeight(em(2.5))
        maxHeight(rem(18))
      }
      selector("&.text-area-autosize.text-area-disabled .text-area-input") {
        overflowY(.hidden)
      }
      selector("&.text-area-has-start-icon .text-area-input") {
        paddingInlineStart(calc(px(15) + sizeIconMedium + spacing8)).important()
      }
      selector("&.text-area-has-end-icon .text-area-input") {
        paddingInlineEnd(calc(px(15) + sizeIconMedium + spacing8)).important()
      }
      // The same rule as TextInputView's: colour only. An opacity on top of
      // the colour made a textarea's placeholder read as a different grey
      // from the input beside it, and WebKit ignored the colour altogether.
      selector("& .text-area-input::placeholder") {
        color(colorPlaceholder).important()
        customProperty("-webkit-text-fill-color", colorPlaceholder).important()
      }
      selector("& .text-area-input:disabled::placeholder") {
        color(colorDisabled).important()
        customProperty("-webkit-text-fill-color", colorDisabled).important()
      }
      selector("&:not(.text-area-disabled):not(.text-area-read-only) .text-area-input:focus") {
        borderColor(borderColorBlueFocus).important()
        outline(.none).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      // No hover state: a field's border says where the field is, and focus
      // says where the keyboard is. A third state between them only makes the
      // field under the pointer look like the field being typed in. The search
      // bar has none either.
      selector("& .text-area-start-icon", "& .text-area-end-icon") {
        position(.absolute)
        top(spacing12)
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(sizeIconMedium)
        height(sizeIconMedium)
        color(colorSubtle)
        pointerEvents(.none)
      }
      descendant(".text-area-start-icon") { left(px(15)) }
      descendant(".text-area-end-icon") { right(px(15)) }
    }

    if stringIsEmpty(labelText) { return styledContainer }

    return div {
      label {
        span { labelText }
          .class("text-area-label")
        if optional {
          span { optionalFlag }
            .class("text-area-optional-flag")
            .data("optional-flag", true)
        }
        if let tooltip = tooltip {
          TooltipView(tooltip: tooltip, placement: .bottom) {
            IconView { InfoIconView() }
          }
        }
      }
      .class("text-area-label-row")
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
          fontSize(fontSizeSmall14)
          fontWeight(600)
          color(colorBase)
          marginBlockEnd(spacing4)
          fontFamily(typographyFontSans)
        }
        // An aside affixed to the label, not label text: LabelView's
        // `.label-optional-flag`.
        descendant(".text-area-optional-flag") {
          fontWeight(fontWeightNormal)
          color(colorSubtle)
        }
      }
      styledContainer
    }
  }
}

#if CLIENT
  import WebAPIs

  public class TextAreaHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TextAreaHydration?
    public init() {
      // A right-click should land the paste that follows it; Safari does not
      // focus on the click, so focus when the context menu opens.
      for area in document.querySelectorAll(".text-area-input") {
        _ = area.addEventListener(.contextmenu) { _ in
          area.focus()
        }
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".text-area-view") != nil else { return }
      instance = TextAreaHydration()
    }

  }
#endif
