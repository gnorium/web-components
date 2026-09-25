#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import Foundation
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A SearchInput allows users to enter and submit a search query.
  public struct SearchInputView: HTMLContent {
    let modelValue: String
    let useButton: Bool
    let clearable: Bool
    let buttonLabel: String
    let searchIcon: Bool
    let disabled: Bool
    let status: ValidationStatus
    let placeholder: String
    let `class`: String

    public enum ValidationStatus: String, Sendable {
      case `default`
      case error
    }

    public init(
      modelValue: String = "",
      useButton: Bool = false,
      clearable: Bool = false,
      buttonLabel: String = "",
      searchIcon: Bool = false,
      disabled: Bool = false,
      status: ValidationStatus = .default,
      placeholder: String = "",
      class: String = ""
    ) {
      self.modelValue = modelValue
      self.useButton = useButton
      self.clearable = clearable
      self.buttonLabel = buttonLabel.isEmpty ? "Search" : buttonLabel
      self.searchIcon = searchIcon
      self.disabled = disabled
      self.status = status
      self.placeholder = placeholder
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      let stateClass = "\(useButton ? "search-input-has-button " : "")\(status == .error ? "search-input-error" : "")"
      let rootClass = `class`.isEmpty
        ? "search-input-view \(stateClass)"
        : "search-input-view \(stateClass) \(`class`)"

      return div {
        div {

          input()
            .type(.search)
            .class("search-input")
            .value(modelValue)
            .placeholder(placeholder)
            .disabled(disabled)
            .ariaInvalid(status == .error)

          if clearable {
            // Clear button
            button {
              IconView(
                icon: { DeleteIconView() },
                size: .medium
              )
            }
            .type(.button)
            .class("search-input-clear-button")
            .ariaLabel("Clear search")
            .disabled(modelValue.isEmpty)

            // View details icon (positioned to the left of clear button)
            span {
              IconView(
                icon: { ViewDetailsIconView() },
                size: .medium
              )
            }
            .class("search-input-view-details-icon")
            .ariaHidden(true)
          }

          if searchIcon {
            button {
              SearchIconView(width: px(20), height: px(20))
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
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          position(.relative)
          width(perc(100))
          gap(spacing8)
        }
        selector("&.search-input-has-button") { flexGrow(1) }
        selector("&:not(.search-input-has-button)") { flex(1) }
        descendant(".search-input-wrapper") {
          position(.relative)
          display(.flex)
          alignItems(.center)
        }
        selector("&.search-input-has-button .search-input-wrapper") { flexGrow(1) }
        selector("&:not(.search-input-has-button) .search-input-wrapper") { width(perc(100)) }
        descendant(".search-input") {
          width(perc(100))
          height(minSizeInteractiveTouch)
          paddingBlock(0)
          paddingInlineStart(px(16))
          paddingInlineEnd(px(132))
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
        descendant(".search-input-view-details-icon") {
          position(.absolute)
          right(px(52))
          top(perc(50))
          transform(translateY(perc(-50)))
          padding(spacing4)
          color(colorSubtle)
          display(.flex)
          alignItems(.center)
        }
        descendant(".search-input-clear-button") {
          position(.absolute)
          insetInlineEnd(px(88))
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
          insetInlineEnd(px(16))
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
        descendant(".search-input-button") {
          height(minSizeInteractiveTouch)
          boxSizing(.borderBox)
          padding(0, spacing16)
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
#endif

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
        if value.isEmpty {
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
      guard document.querySelector(".search-input-view") != nil else { return }
      instance = SearchInputHydration()
    }

    private func hydrateAllSearchInputs() {
      let allSearchInputs = document.querySelectorAll(".search-input-view")

      for searchInput in allSearchInputs {
        let instance = SearchInputInstance(searchInput: searchInput)
        instances.append(instance)
      }
    }
  }
#endif
