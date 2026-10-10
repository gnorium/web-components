import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// SearchInputView is available in both SERVER and CLIENT, as DropdownView
// is, which draws one: build() must stay embedded-safe (stringIsEmpty, and a
// switch on the String-raw status, never ==).

/// A SearchInput allows users to enter and submit a search query.
///
/// Its size is ButtonView's scale (`ButtonView.ButtonSize`), so a box sits
/// level with the controls beside it: its inset is that size's `padding`
/// on every side (8 or 12) and its height that size's `minSize` (40 or
/// 48). Its text is 16px at every size (user, 2026-10-08): smaller text in
/// a field makes iOS Safari zoom the page as it is focused. Its icons,
/// beside that text, are 16 (the text's size).
public struct SearchInputView: HTMLContent {
  let modelValue: String
  let size: ButtonView.ButtonSize
  let ariaLabel: String?
  let useButton: Bool
  let clearable: Bool
  let buttonLabel: String
  let searchIcon: Bool
  let disabled: Bool
  let status: ValidationStatus
  let placeholder: String
  let `class`: String
  let standalone: Bool

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    modelValue: String = "",
    size: ButtonView.ButtonSize = .large,
    useButton: Bool = false,
    clearable: Bool = false,
    buttonLabel: String = "",
    searchIcon: Bool = false,
    disabled: Bool = false,
    status: ValidationStatus = .default,
    placeholder: String = "",
    ariaLabel: String? = nil,
    class: String = "",
    standalone: Bool = true
  ) {
    self.modelValue = modelValue
    self.size = size
    self.ariaLabel = ariaLabel
    self.useButton = useButton
    self.clearable = clearable
    self.buttonLabel = stringIsEmpty(buttonLabel) ? "Search" : buttonLabel
    self.searchIcon = searchIcon
    self.disabled = disabled
    self.status = status
    self.placeholder = placeholder
    self.`class` = `class`
    self.standalone = standalone
  }

  public func build() -> DOM.Node {
    // Beside the 16px text, at every size.
    let iconSize = sizeIconSmall
    // The box's measures, set per size on the root (`data-size`).
    let side: CSS.Length = `var`("--search-input-padding")
    // A control's room: its icon and its 4px padding at either side; the
    // controls 8px apart.
    let step = iconSize + spacing4 + spacing4 + spacing8
    let isError: Bool
    switch status {
    case .error: isError = true
    case .default: isError = false
    }
    let stateClass = "\(useButton ? "search-input-has-button " : "")\(clearable || searchIcon ? "search-input-has-controls " : "")\(isError ? "search-input-error" : "")"
    let rootClass = stringIsEmpty(`class`)
      ? "search-input-view \(stateClass)"
      : "search-input-view \(stateClass) \(`class`)"

    return div {
      div {

        input()
          .type(.search)
          .class("search-input")
          .value(modelValue)
          .placeholder(placeholder)
          .ariaLabel(ariaLabel)
          .disabled(disabled)
          .ariaInvalid(isError)
          // A long query fades at rest (`fadeInputOverflow`).
          .data("edge-fade", true)

        if clearable {
          // Clear button
          button {
            IconView(
              icon: { size in DeleteIconView(size: size) },
              size: iconSize
            )
          }
          .type(.button)
          .class("search-input-clear-button")
          .ariaLabel("Clear search")
          .disabled(stringIsEmpty(modelValue))

          // View details icon (positioned to the left of clear button)
          span {
            IconView(
              icon: { size in ViewDetailsIconView(size: size) },
              size: iconSize
            )
          }
          .class("search-input-details-icon")
          .ariaHidden(true)
        }

        if searchIcon {
          button {
            SearchIconView(size: iconSize)
          }
          .type(.submit)
          .class("search-input-search-icon")
          .ariaLabel("Search")
        }
      }
      .class("search-input-wrapper")

      if useButton {
        button { buttonLabel }
          .type(.submit)
          .class("search-input-button")
          .disabled(disabled)
      }
    }
    .class(rootClass)
    // False when the view that holds the box drives its keys and value
    // itself (DropdownView): SearchInputHydration leaves it alone, so its
    // Enter, Escape and arrows reach the holder's own listeners.
    .data("standalone", standalone)
    .data("size", size.rawValue)
    .style {
      selector("&") {
        display(.flex)
        alignItems(.center)
        position(.relative)
        width(perc(100))
        gap(spacing8)
      }
      // ButtonView's scale: one inset on every side, 8 or 12, on the 22px
      // line, so a box is 40 or 48 as the buttons beside it.
      selector("&[data-size='medium']") {
        customProperty("--search-input-padding", ButtonView.ButtonSize.medium.padding.value)
      }
      selector("&[data-size='large']") {
        customProperty("--search-input-padding", ButtonView.ButtonSize.large.padding.value)
      }
      selector("&.search-input-has-button") { flexGrow(1) }
      selector("&:not(.search-input-has-button)") { flex(1) }
      // The box the input is drawn in, and its fades at rest: the input's
      // ground, and its border and padding at each side (EdgeFade.swift).
      descendant(".search-input-wrapper") {
        position(.relative)
        display(.flex)
        alignItems(.center)
        customProperty("--edge-fade-ground", backgroundColorBase)
        customProperty("--edge-fade-inset-start", (borderWidthBase + side).value)
        customProperty("--edge-fade-inset-end", (borderWidthBase + side).value)
      }
      // Room at the end for the clear button and the icons, only when
      // they are drawn: a bare box pads its end as its start.
      selector("&.search-input-has-controls .search-input-wrapper") {
        customProperty("--edge-fade-inset-end", (borderWidthBase + side + step + step + step).value)
      }
      selector("& .search-input-wrapper:has(> .search-input:disabled)") {
        customProperty("--edge-fade-ground", backgroundColorDisabled)
      }
      fadeInputOverflow(control: "& .search-input-wrapper", input: ".search-input")
      selector("&.search-input-has-button .search-input-wrapper") { flexGrow(1) }
      selector("&:not(.search-input-has-button) .search-input-wrapper") { width(perc(100)) }
      descendant(".search-input") {
        width(perc(100))
        padding(side)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        backgroundColor(backgroundColorBase)
        // Base, not subtle: the field reads as a field at rest, which is
        // what a hover border was being used to say late.
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        boxSizing(.borderBox)
      }
      selector("&.search-input-has-controls .search-input") { paddingInlineEnd(side + step + step + step) }
      selector("&.search-input-error .search-input") { borderColor(borderColorRed) }
      selector("& .search-input::-webkit-search-cancel-button") { display(.none).important() }
      selector("& .search-input::placeholder") {
        color(colorPlaceholder).important()
        opacity(1).important()
      }
      selector("& .search-input:disabled::placeholder") {
        color(colorDisabled).important()
        customProperty("-webkit-text-fill-color", colorDisabled).important()
      }
      descendant(".search-input:focus") {
        outline(borderWidthBase, .solid, borderColorBlue).important()
        outlineOffset(px(-2)).important()
        borderColor(borderColorBlue).important()
      }
      descendant(".search-input:disabled") {
        backgroundColor(backgroundColorDisabled).important()
        color(colorDisabled).important()
        borderColor(borderColorDisabled).important()
        cursor(cursorNotAllowed).important()
      }
      descendant(".search-input-details-icon") {
        position(.absolute)
        insetInlineEnd(side + step)
        top(perc(50))
        transform(translateY(perc(-50)))
        padding(spacing4)
        color(colorSubtle)
        display(.flex)
        alignItems(.center)
      }
      descendant(".search-input-clear-button") {
        position(.absolute)
        insetInlineEnd(side + step + step)
        top(perc(50))
        transform(translateY(perc(-50)))
        padding(spacing4)
        backgroundColor(.transparent)
        border(.none)
        borderRadius(borderRadiusBase)
        cursor(cursorBaseHover)
        color(colorDisabled)
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      }
      selector("& .search-input-clear-button:hover:not(:disabled)") {
        color(colorBlue).important()
        cursor(cursorBaseHover).important()
      }
      selector("& .search-input-clear-button:hover:not(:disabled) .icon-view") {
        color(colorBlue).important()
      }
      selector("& .search-input-clear-button:active:not(:disabled)") { color(colorBase).important() }
      descendant(".search-input-clear-button:focus") {
        outline(borderWidthBase, .solid, outlineColorBlueFocus).important()
        outlineOffset(px(4)).important()
      }
      descendant(".search-input-clear-button:disabled") {
        opacity(opacityIconBaseDisabled).important()
        color(colorDisabled).important()
        cursor(.default).important()
      }
      selector("& .search-input-clear-button:disabled .icon-view", "& .search-input-clear-button:disabled .icon-view:hover") {
        color(colorDisabled).important()
      }
      descendant(".search-input-search-icon") {
        position(.absolute)
        insetInlineEnd(side)
        top(perc(50))
        transform(translateY(perc(-50)))
        background(.transparent)
        border(.none)
        color(colorSubtle)
        cursor(cursorBaseHover)
        padding(spacing4)
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        zIndex(1)
      }
      // As tall as the field beside it.
      descendant(".search-input-button") {
        alignSelf(.stretch)
        boxSizing(.borderBox)
        padding(side)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        lineHeight(lineHeightSmall22)
        color(colorBlue)
        backgroundColor(.transparent)
        border(borderWidthBase, .solid, borderColorBlue)
        borderRadius(borderRadiusBase)
        cursor(cursorBaseHover)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        whiteSpace(.nowrap)
      }
      descendant(".search-input-button:disabled") {
        color(colorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
      }
      selector("& .search-input-button:hover:not(:disabled)") { backgroundColor(backgroundColorBlueSubtle).important() }
      selector("& .search-input-button:active:not(:disabled)") {
        backgroundColor(backgroundColorBlueActive).important()
        color(colorInverted).important()
        borderColor(borderColorBlueActive).important()
      }
      selector("& .search-input-button:focus:not(:disabled)") {
        outline(borderWidthThick, .solid, borderColorBlue).important()
        outlineOffset(px(1)).important()
      }
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

  private class SearchInputInstance: @unchecked Sendable {
    private var searchInputElement: DOM.Element
    private var inputElement: DOM.Element?
    private var clearButton: DOM.Element?
    private var submitButton: DOM.Element?

    init(searchInput: DOM.Element) {
      self.searchInputElement = searchInput
      self.inputElement = searchInput.querySelector(".search-input")
      self.clearButton = searchInput.querySelector(".search-input-clear-button")
      self.submitButton = searchInput.querySelector(".search-input-button")

      bindEvents()
    }

    private func bindEvents() {
      if let input = inputElement {
        _ = input.addEventListener(.input) { [self] _ in
          self.handleInput()
        }

        _ = input.addEventListener(.keydown) { [self] (event: Event) in
          let key = event.key
          self.handleKeydown(key: key, event: event)
        }
      }

      if let clear = clearButton {
        _ = clear.addEventListener(.click) { [self] _ in
          self.clearInput()
        }
      }

      if let submit = submitButton {
        _ = submit.addEventListener(.click) { [self] _ in
          self.handleSubmit()
        }
      }
    }

    private func handleInput() {
      guard let input = inputElement else { return }
      let value: String
      if let inputElement = input as? HTML.HTMLInputElement {
        value = inputElement.value
      } else {
        value = ""
      }

      // Update clear button disabled state and styling
      if let clear = clearButton {
        if stringIsEmpty(value) {
          (clear as? HTML.HTMLButtonElement)?.disabled = true
        } else {
          (clear as? HTML.HTMLButtonElement)?.disabled = false
        }
      }

      // Emit input event
      let event = CustomEvent(type: "update:modelValue", detail: value)
      searchInputElement.dispatchEvent(event)
    }

    private func handleKeydown(key: String, event: Event) {
      if stringEquals(key, "Escape") || stringEquals(key, "Esc") {
        clearInput()
      } else if stringEquals(key, "Enter") {
        event.preventDefault()
        event.stopPropagation()
        handleSubmit()
      } else if stringEquals(key, "ArrowDown") {
        // Prevent cursor movement in input
        event.preventDefault()
        // Forward navigation keys to parent typeahead
        let customEvent = CustomEvent(type: "arrow-down", detail: key)
        searchInputElement.dispatchEvent(customEvent)
      } else if stringEquals(key, "ArrowUp") {
        // Prevent cursor movement in input
        event.preventDefault()
        // Forward navigation keys to parent typeahead
        let customEvent = CustomEvent(type: "arrow-up", detail: key)
        searchInputElement.dispatchEvent(customEvent)
      }
    }

    private func clearInput() {
      guard let input = inputElement else { return }
      (input as? HTML.HTMLInputElement)?.value = ""
      input.focus()
      handleInput()
    }

    private func handleSubmit() {
      guard let input = inputElement else { return }
      let value: String
      if let inputElement = input as? HTML.HTMLInputElement {
        value = inputElement.value
      } else {
        value = ""
      }

      let event = CustomEvent(type: "submit-click", detail: value)
      searchInputElement.dispatchEvent(event)
    }
  }

  public class SearchInputHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: SearchInputHydration?
    private var instances: [SearchInputInstance] = []

    public init() {
      hydrateAllSearchInputs()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".search-input-view[data-standalone='true']") != nil else { return }
      instance = SearchInputHydration()
    }

    private func hydrateAllSearchInputs() {
      let allSearchInputs = document.querySelectorAll(".search-input-view[data-standalone='true']")

      for searchInput in allSearchInputs {
        let instance = SearchInputInstance(searchInput: searchInput)
        instances.append(instance)
      }
    }
  }
#endif
