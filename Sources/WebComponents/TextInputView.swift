import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A form element that lets users input and edit a single-line text value.
public struct TextInputView: HTMLContent {
  let id: String
  let name: String
  let placeholder: String
  let value: String
  let type: InputType
  let status: ValidationStatus
  let disabled: Bool
  let readonly: Bool
  let required: Bool
  let clearable: Bool
  let startIcon: String?
  let endIcon: String?
  let inputFontSize: CSS.Length
  let labelText: String
  let tooltip: String?
  let fullWidth: Bool
  let `class`: String
  let min: Int?
  let max: Int?

  public enum InputType: String, Sendable {
    case text
    case search
    case number
    case email
    case password
    case tel
    case url
    case week
    case month
    case date
    case datetimeLocal = "datetime-local"
    case time
  }

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    placeholder: String = "",
    value: String = "",
    type: InputType = .text,
    status: ValidationStatus = .default,
    disabled: Bool = false,
    readonly: Bool = false,
    required: Bool = false,
    clearable: Bool = false,
    startIcon: String? = nil,
    endIcon: String? = nil,
    inputFontSize: CSS.Length = fontSizeMedium16,
    label: String = "",
    tooltip: String? = nil,
    fullWidth: Bool = true,
    class: String = "",
    min: Int? = nil,
    max: Int? = nil
  ) {
    self.id = id
    self.name = name
    self.placeholder = placeholder
    self.value = value
    self.type = type
    self.status = status
    self.disabled = disabled
    self.readonly = readonly
    self.required = required
    self.clearable = clearable
    self.startIcon = startIcon
    self.endIcon = endIcon
    self.inputFontSize = inputFontSize
    self.labelText = label
    self.tooltip = tooltip
    self.fullWidth = fullWidth
    self.`class` = `class`
    self.min = min
    self.max = max
  }

  @CSSBuilder
  private func textInputViewCSS() -> [CSSOM.CSSRule] {
    position(.relative)
    display(.inlineBlock)
    if fullWidth {
      width(perc(100))
    }
  }

  @CSSBuilder
  private func textInputInputCSS(
    _ disabled: Bool, _ readonly: Bool, _ status: ValidationStatus, _ hasStartIcon: Bool,
    _ hasEndIcon: Bool, _ clearable: Bool
  ) -> [CSSOM.CSSRule] {
    let isError = status == .error
    width(perc(100))
    minHeight(minSizeInteractivePointer)
    padding(spacing8, px(15))
    fontFamily(typographyFontSans)
    fontSize(inputFontSize)
    color(disabled ? colorDisabled : colorBase)
    backgroundColor(disabled ? backgroundColorDisabled : (readonly ? backgroundColorNeutralSubtle : backgroundColorBase))
    border(borderWidthBase, .solid, isError ? borderColorRed : (disabled ? borderColorDisabled : borderColorBase))
    borderRadius(borderRadiusBase)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
    outline(.none)
    cursor(disabled ? cursorNotAllowed : cursorText)
    boxSizing(.borderBox)

    if hasStartIcon {
      paddingInlineStart(calc(px(15) + sizeIconMedium + spacing8)).important()
    }

    if hasEndIcon || clearable {
      paddingInlineEnd(calc(px(15) + sizeIconMedium + spacing8)).important()
    }

    pseudoElement(.placeholder) {
      color(colorPlaceholder).important()
    }

    pseudoClass(.focus, not(.disabled), not(.readOnly)) {
      borderColor(borderColorBlueFocus).important()
      outline(.none).important()
      boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
    }

    pseudoClass(.hover, .focus, not(.disabled), not(.readOnly)) {
      borderColor(borderColorBlue).important()
    }
  }

  @CSSBuilder
  private func textInputIconCSS(_ isStartIcon: Bool) -> [CSSOM.CSSRule] {
    position(.absolute)
    top(perc(50))
    transform(translateY(perc(-50)))
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(sizeIconMedium)
    height(sizeIconMedium)
    color(colorSubtle)
    pointerEvents(.none)

    if isStartIcon {
      left(px(15))
    } else {
      right(px(15))
    }
  }

  @CSSBuilder
  private func textInputClearButtonCSS(_ disabled: Bool) -> [CSSOM.CSSRule] {
    position(.absolute)
    top(perc(50))
    right(px(15))
    transform(translateY(perc(-50)))
    display(.none)
    alignItems(.center)
    justifyContent(.center)
    width(sizeIconMedium)
    height(sizeIconMedium)
    padding(0)
    backgroundColor(.transparent)
    border(.none)
    borderRadius(borderRadiusCircle)
    color(colorSubtle)
    cursor(disabled ? cursorNotAllowed : cursorBase)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)

    pseudoClass(.hover, not(.disabled)) {
      backgroundColor(backgroundColorInteractiveSubtleHover).important()
      color(colorBase).important()
    }

    pseudoClass(.active, not(.disabled)) {
      backgroundColor(backgroundColorInteractiveSubtleActive).important()
    }

    pseudoClass(.focus) {
      outline(px(2), .solid, borderColorBlueFocus).important()
      outlineOffset(px(-2)).important()
    }

    if disabled {
      opacity(opacityMedium).important()
    }
  }

  public func build() -> DOM.Node {
    let hasStartIcon = if let _ = startIcon { true } else { false }
    let hasEndIcon = if let _ = endIcon { true } else { false }
    let htmlInputType = getHTMLInputType(type)

    // Build input element before the div block
    var inputEl = input()
      .type(htmlInputType)
      .id(id)
      .name(name)
      .placeholder(placeholder)
      .value(value)
      .disabled(disabled)
      .readonly(readonly)
      .required(required)
      .class("text-input-input")

    if let minValue = min {
      inputEl = inputEl.min(minValue)
    }
    if let maxValue = max {
      inputEl = inputEl.max(maxValue)
    }

    let styledInput = inputEl.style {
      textInputInputCSS(disabled, readonly, status, hasStartIcon, hasEndIcon, clearable)
    }

    var container = div {
      if let icon = startIcon {
        span { icon }
          .class("text-input-start-icon")
          .ariaHidden(true)
          .style {
            textInputIconCSS(true)
          }
      }

      styledInput

      if clearable {
        button {
          span { "×" }
            .ariaHidden(true)
        }
        .type(.button)
        .class("text-input-clear-button")
        .ariaLabel("Clear")
        .tabindex(-1)
        .style {
          textInputClearButtonCSS(disabled)
        }
      }

      if let icon = endIcon {
        span { icon }
          .class("text-input-end-icon")
          .ariaHidden(true)
          .style {
            textInputIconCSS(false)
          }
      }
    }
    .class(stringIsEmpty(`class`) ? "text-input-view" : "text-input-view \(`class`)")

    if status == .error {
      container = container.data("status", "error")
    }

    if clearable {
      container = container.data("clearable", "true")
    }

    let wrapper = container.style {
      textInputViewCSS()
    }

    if stringIsEmpty(labelText) {
      return wrapper
    }

    return div {
      label {
        span { labelText }
        .class("text-input-label")
        if let tooltip = tooltip {
          TooltipView(tooltip: tooltip, placement: .bottom) {
            IconView {
              InfoIconView()
            }
          }
        }
      }
      .style {
        display(.flex)
        alignItems(.center)
        gap(spacing4)
        fontSize(fontSizeSmall14)
        fontWeight(600)
        color(colorBase)
        marginBlockEnd(spacing4)
        fontFamily(typographyFontSans)
      }

      wrapper
    }
  }

  private func getHTMLInputType(_ type: InputType) -> HTML.Input.`Type` {
    switch type {
    case .text: return .text
    case .search: return .search
    case .number: return .number
    case .email: return .email
    case .password: return .password
    case .tel: return .tel
    case .url: return .url
    case .week: return .week
    case .month: return .month
    case .date: return .date
    case .datetimeLocal: return .datetimeLocal
    case .time: return .time
    }
  }
}

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  private class TextInputInstance: @unchecked Sendable {
    private var textInput: DOM.Element
    private var input: DOM.Element?
    private var clearButton: DOM.Element?
    private var isClearable: Bool = false

    init(textInput: DOM.Element) {
      self.textInput = textInput

      input = textInput.querySelector(".text-input-input")
      clearButton = textInput.querySelector(".text-input-clear-button")

      // Check if clearable
      if let clearableAttr = textInput.getAttribute("data-clearable") {
        isClearable = stringEquals(clearableAttr, "true")
      }

      if isClearable {
        bindClearableEvents()
        // Update clear button visibility based on initial value
        updateClearButtonVisibility()
      }
    }

    private func bindClearableEvents() {
      guard let input = input, let clearButton = clearButton else { return }

      // Show/hide clear button based on input value
      _ = input.addEventListener(.input) { [self] _ in
        self.updateClearButtonVisibility()
      }

      // Clear input when clear button is clicked
      _ = clearButton.addEventListener(.click) { [self] _ in
        guard let input = self.input else { return }
        (input as? HTML.HTMLInputElement)?.value = ""
        self.updateClearButtonVisibility()
        input.focus()

        // Dispatch input event for reactivity
        input.dispatchEvent(Event.input)

        // Dispatch custom clear event
        let clearEvent = CustomEvent(type: "text-input-clear", detail: "")
        self.textInput.dispatchEvent(clearEvent)
      }

      // Prevent clear button from taking focus away from input
      _ = clearButton.addEventListener(.mousedown) { event in
        event.preventDefault()
      }
    }

    private func updateClearButtonVisibility() {
      guard let input = input, let clearButton = clearButton else { return }

      if !stringEquals((input as? HTML.HTMLInputElement)?.value ?? "", "") {
        clearButton.style.display(.flex)
      } else {
        clearButton.style.display(.none)
      }
    }
  }

  public class TextInputHydration: @unchecked Sendable {
    private var instances: [TextInputInstance] = []

    public init() {
      hydrateAllTextInputs()
    }

    private func hydrateAllTextInputs() {
      let allTextInputs = document.querySelectorAll(".text-input-view")
      for textInput in allTextInputs {
        let instance = TextInputInstance(textInput: textInput)
        instances.append(instance)
      }
    }

    public func hydrate(element: DOM.Element) {
      let instance = TextInputInstance(textInput: element)
      instances.append(instance)
    }
  }

  public enum TextInputFactory {
    public static func createElement(
      id: String,
      name: String,
      placeholder: String = "",
      value: String = "",
      fullWidth: Bool = true,
      class: String = "",
      hydrator: TextInputHydration? = nil
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = TextInputView(
        id: id,
        name: name,
        placeholder: placeholder,
        value: value,
        fullWidth: fullWidth,
        class: `class`
      )
      wrapper.innerHTML = renderHTML { view.render() }
      let element = wrapper.firstElementChild ?? wrapper
      hydrator?.hydrate(element: element)
      return element
    }
  }
#endif
