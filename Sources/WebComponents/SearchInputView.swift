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

    @CSSBuilder
    private func searchInputViewCSS(_ useButton: Bool) -> [CSSOM.CSSRule] {
      display(.flex)
      alignItems(.center)
      position(.relative)
      width(perc(100))
      gap(spacing8)

      if useButton {
        flexGrow(1)
      } else {
        flex(1)
      }
    }

    @CSSBuilder
    private func searchInputWrapperCSS(_ useButton: Bool) -> [CSSOM.CSSRule] {
      position(.relative)
      display(.flex)
      alignItems(.center)

      if useButton {
        flexGrow(1)
      } else {
        width(perc(100))
      }
    }

    @CSSBuilder
    private func searchInputCSS(_ clearable: Bool, _ status: ValidationStatus)
      -> [CSSOM.CSSRule]
    {
      width(perc(100))
      minHeight(minSizeInteractivePointer)
      paddingBlock(spacing12)
      paddingInlineStart(px(16))
      paddingInlineEnd(px(132))
      fontFamily(typographyFontSans)
      fontSize(fontSizeMedium16)
      lineHeight(lineHeightSmall22)
      color(colorBase)
      backgroundColor(backgroundColorBase)
      border(borderWidthBase, .solid, borderColorSubtle)
      borderRadius(borderRadiusBase)
      transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      boxSizing(.borderBox)

      if status == .error {
        borderColor(borderColorRed)
      }

      // Hide native WebKit search cancel button
      pseudoElement(.webkitSearchCancelButton) {
        display(.none).important()
      }

      pseudoElement(.placeholder) {
        color(colorPlaceholder).important()
        opacity(1).important()
      }

      pseudoClass(.hover) {
        borderColor(borderColorInteractive).important()
      }

      pseudoClass(.focus) {
        outline(borderWidthBase, .solid, borderColorBlue).important()
        outlineOffset(px(-2)).important()
        borderColor(borderColorBlue).important()
      }

      pseudoClass(.disabled) {
        backgroundColor(backgroundColorDisabled).important()
        color(colorDisabled).important()
        borderColor(borderColorDisabled).important()
        cursor(cursorNotAllowed).important()
      }
    }

    @CSSBuilder
    private func searchInputViewDetailsIconCSS() -> [CSSOM.CSSRule] {
      position(.absolute)
      right(px(52))
      top(perc(50))
      transform(translateY(perc(-50)))
      padding(spacing4)
      color(colorSubtle)
      display(.flex)
      alignItems(.center)
    }

    @CSSBuilder
    private func searchInputClearButtonCSS() -> [CSSOM.CSSRule] {
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

      pseudoClass(.hover) {
        color(colorBlue).important()
        cursor(cursorBaseHover).important()

        // Icon hover color when button is enabled
        descendant(".icon-view") {
          color(colorBlue).important()
        }
      }

      pseudoClass(.active) {
        color(colorBase).important()
      }

      pseudoClass(.focus) {
        outline(borderWidthBase, .solid, outlineColorBlueFocus).important()
        outlineOffset(px(4)).important()
      }

      pseudoClass(.disabled) {
        opacity(opacityIconBaseDisabled).important()
        color(colorDisabled).important()
        cursor(.default).important()

        // Icon hover color when button is disabled - more specific to override IconView default
        descendant(".icon-view") {
          color(colorDisabled).important()

          pseudoClass(.hover) {
            color(colorDisabled).important()
          }
        }
      }
    }

    @CSSBuilder
    private func searchInputButtonCSS(_ disabled: Bool) -> [CSSOM.CSSRule] {
      minHeight(minSizeInteractivePointer)
      padding(spacing12, spacing16)
      fontFamily(typographyFontSans)
      fontSize(fontSizeMedium16)
      fontWeight(fontWeightBold)
      lineHeight(lineHeightSmall22)
      color(colorBlue)
      backgroundColor(.transparent)
      border(borderWidthBase, .solid, borderColorBlue)
      borderRadius(borderRadiusBase)
      cursor(disabled ? cursorNotAllowed : cursorBaseHover)
      transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      whiteSpace(.nowrap)

      if disabled {
        color(colorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
      } else {
        pseudoClass(.hover) {
          backgroundColor(backgroundColorBlueSubtle).important()
        }

        pseudoClass(.active) {
          backgroundColor(backgroundColorBlueActive).important()
          color(colorInverted).important()
          borderColor(borderColorBlueActive).important()
        }

        pseudoClass(.focus) {
          outline(borderWidthThick, .solid, borderColorBlue).important()
          outlineOffset(px(1)).important()
        }
      }
    }

    public func build() -> DOM.Node {
      return div {
        div {

          input()
            .type(.search)
            .class("search-input")
            .value(modelValue)
            .placeholder(placeholder)
            .disabled(disabled)
            .ariaInvalid(status == .error)
            .style {
              searchInputCSS(clearable, status)
            }

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
            .style {
              searchInputClearButtonCSS()
              if modelValue.isEmpty {
                opacity(opacityIconBaseDisabled)
              }
            }

            // View details icon (positioned to the left of clear button)
            span {
              IconView(
                icon: { ViewDetailsIconView() },
                size: .medium
              )
            }
            .class("search-input-view-details-icon")
            .ariaHidden(true)
            .style {
              searchInputViewDetailsIconCSS()
            }
          }

          if searchIcon {
            button {
              SearchIconView(width: px(20), height: px(20))
            }
            .type(.submit)
            .class("search-input-search-icon")
            .ariaLabel("Search")
            .style {
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

              pseudoClass(.hover) {
                color(colorBlue)
              }
            }
          }
        }
        .class("search-input-wrapper")
        .style {
          searchInputWrapperCSS(useButton)
        }

        if useButton {
          button { buttonLabel }
            .type(.submit)
            .class("search-input-button")
            .disabled(disabled)
            .style {
              searchInputButtonCSS(disabled)
            }
        }
      }
      .class(
        `class`.isEmpty
          ? (useButton ? "search-input-view search-input-has-button" : "search-input-view")
          : (useButton
            ? "search-input-view search-input-has-button \(`class`)"
            : "search-input-view \(`class`)")
      )
      .style {
        searchInputViewCSS(useButton)
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
          clear.style.opacity(opacityIconBaseDisabled)
          clear.style.cursor(.notAllowed)
        } else {
          (clear as? HTML.HTMLButtonElement)?.disabled = false
          clear.style.opacity(opacityIconBaseSelected)
          clear.style.cursor(cursorBaseHover)
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
