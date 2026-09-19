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

  public func build() -> DOM.Node {
    let hasStartIcon = if let _ = startIcon { true } else { false }
    let hasEndIcon = if let _ = endIcon { true } else { false }
    let htmlInputType = getHTMLInputType(type)
    let stateClass = "\(fullWidth ? "text-input-full-width " : "")\(disabled ? "text-input-disabled " : "")\(readonly ? "text-input-read-only " : "")\(status == .error ? "text-input-error " : "")\(hasStartIcon ? "text-input-has-start-icon " : "")\(hasEndIcon ? "text-input-has-end-icon " : "")\(clearable ? "text-input-clearable" : "")"
    let textInputClass = stringIsEmpty(`class`)
      ? "text-input-view \(stateClass)"
      : "text-input-view \(stateClass) \(`class`)"

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

    var container = div {
      if !stringIsEmpty(labelText) {
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
        .class("text-input-label-row")
      }

      div {
        if let icon = startIcon {
          span { icon }
            .class("text-input-start-icon")
            .ariaHidden(true)
        }

        inputEl

        if clearable {
          button {
            span { "×" }
              .ariaHidden(true)
          }
          .type(.button)
          .class("text-input-clear-button")
          .ariaLabel("Clear")
          .tabindex(-1)
          .data("visible", !value.isEmpty)
        }

        if let icon = endIcon {
          span { icon }
            .class("text-input-end-icon")
            .ariaHidden(true)
        }
      }
      .class("text-input-control")
    }
    .class(textInputClass)

    if status == .error {
      container = container.data("status", "error")
    }

    if clearable {
      container = container.data("clearable", "true")
    }

    return container.style {
      selector("&") {
        display(.inlineBlock)
      }
      selector("&.text-input-full-width") { width(perc(100)) }
      descendant(".text-input-control") { position(.relative) }
      descendant(".text-input-input") {
        width(perc(100))
        // 40, flat: the height a medium button is, so a form's fields and its
        // buttons sit level. (32 plus this input's padding came to 39.5.)
        minHeight(px(40))
        padding(spacing8, px(15))
        fontFamily(typographyFontSans)
        fontSize(inputFontSize)
        color(colorBase)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        outline(.none)
        cursor(cursorText)
        boxSizing(.borderBox)
      }
      // WebKit paints a disabled control's text with -webkit-text-fill-color,
      // which its UA sheet sets for :disabled — so `color` alone left Safari
      // painting system grey over ours, for the value and the placeholder both.
      selector("&.text-input-disabled .text-input-input") {
        color(colorDisabled)
        customProperty("-webkit-text-fill-color", colorDisabled)
        backgroundColor(backgroundColorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
      }
      selector("&.text-input-read-only .text-input-input") {
        backgroundColor(backgroundColorNeutralSubtle)
      }
      selector("&.text-input-error .text-input-input") { borderColor(borderColorRed) }
      selector("&.text-input-has-start-icon .text-input-input") {
        paddingInlineStart(calc(px(15) + sizeIconMedium + spacing8)).important()
      }
      selector("&.text-input-has-end-icon .text-input-input", "&.text-input-clearable .text-input-input") {
        paddingInlineEnd(calc(px(15) + sizeIconMedium + spacing8)).important()
      }
      selector("& .text-input-input::placeholder") {
        color(colorPlaceholder).important()
        customProperty("-webkit-text-fill-color", colorPlaceholder).important()
      }
      selector("&:not(.text-input-disabled):not(.text-input-read-only) .text-input-input:focus") {
        borderColor(borderColorBlueFocus).important()
        outline(.none).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      // Focus only, like the search bar: a hover border on a field reads as a
      // half-finished focus ring, and tells the reader nothing the cursor has
      // not already told them.
      selector("&:not(.text-input-disabled):not(.text-input-read-only) .text-input-input:focus") {
        borderColor(borderColorBlue).important()
      }
      selector("& .text-input-start-icon", "& .text-input-end-icon") {
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
      }
      descendant(".text-input-start-icon") { left(px(15)) }
      descendant(".text-input-end-icon") { right(px(15)) }
      descendant(".text-input-clear-button") {
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
        cursor(cursorBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      }
      selector("&.text-input-disabled .text-input-clear-button") {
        cursor(cursorNotAllowed)
        opacity(opacityMedium).important()
      }
      selector("&:not(.text-input-disabled) .text-input-clear-button:hover") {
        backgroundColor(backgroundColorInteractiveSubtleHover).important()
        color(colorBase).important()
      }
      selector("&:not(.text-input-disabled) .text-input-clear-button:active") {
        backgroundColor(backgroundColorInteractiveSubtleActive).important()
      }
      descendant(".text-input-clear-button:focus") {
        outline(px(2), .solid, borderColorBlueFocus).important()
        outlineOffset(px(-2)).important()
      }
      descendant(".text-input-clear-button[data-visible='true']") { display(.inlineFlex) }
      descendant(".text-input-label-row") {
        display(.flex)
        alignItems(.center)
        gap(spacing4)
        fontSize(fontSizeSmall14)
        fontWeight(600)
        color(colorBase)
        marginBlockEnd(spacing4)
        fontFamily(typographyFontSans)
      }
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

      // A right-click should land the paste that follows it. Chromium focuses
      // on the click; Safari does not, and Paste from its menu then goes
      // nowhere. Focus on the context menu opening, in every browser.
      if let input {
        _ = input.addEventListener(.contextmenu) { _ in
          input.focus()
        }
      }

      // A focused number input steps its value on a wheel event in Chromium,
      // and the only way to stop that is to cancel the event — which also
      // cancels the scroll. So the scroll is done by hand: the value stands,
      // focus stays, the page moves, exactly as it does over a text field.
      if let input, stringEquals(input.getAttribute("type") ?? "", "number") {
        _ = input.addEventListener(.wheel) { event in
          guard let active = document.activeElement, active.id == input.id else { return }
          event.preventDefault()
          window.scrollTo(window.scrollX, window.scrollY + event.deltaY)
        }
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

      clearButton.setAttribute(data("visible"), !stringEquals((input as? HTML.HTMLInputElement)?.value ?? "", ""))
    }
  }

  public class TextInputHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TextInputHydration?
    private var instances: [TextInputInstance] = []

    public init() {
      hydrateAllTextInputs()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".text-input-view") != nil else { return }
      instance = TextInputHydration()
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
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      hydrator?.hydrate(element: element)
      return element
    }
  }
#endif
