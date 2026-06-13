import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

// DropdownView is available in both SERVER and CLIENT so DropdownFactory can render +
// hydrate it dynamically (no hand-built replicas). Build() must stay embedded-safe:
// use stringIsEmpty()/stringEquals() instead of String.isEmpty / String.==.
public struct DropdownView: HTMLContent {
  public struct DropdownOption: Sendable {
    public let value: String
    public let display: String
    public let altDisplay: String?
    /// Lowercase form of display, for mid-sentence use (e.g. tooltip text). Pre-computed server-side to avoid WASI string ops.
    public let displayLower: String?

    public init(value: String, display: String, altDisplay: String? = nil, displayLower: String? = nil) {
      self.value = value
      self.display = display
      self.altDisplay = altDisplay
      self.displayLower = displayLower
    }
  }

  public enum OptionLayout: Sendable {
    case standard
    case sidebar
  }

  let id: String
  let name: String
  let labelText: String
  let options: [DropdownOption]
  let placeholder: String
  let selectedValue: String?
  let required: Bool
  let disabled: Bool
  let tooltip: String?
  let `class`: String
  let buttonWeight: ButtonView.ButtonWeight
  let buttonSize: ButtonView.ButtonSize
  let fullWidth: Bool
  let dropdownWidth: CSS.Length?
  let menuWidth: CSS.Length?
  let textFontSize: CSS.Length
  let contentJustifyContent: CSS.JustifyContent
  let optionLayout: OptionLayout
  let buttonBorderRadius: CSS.Length
  let submitFormOnChange: Bool

  public init(
    id: String,
    name: String,
    label: String,
    options: [DropdownOption],
    placeholder: String = "Select an option",
    selectedValue: String? = nil,
    required: Bool = false,
    disabled: Bool = false,
    tooltip: String? = nil,
    class: String = "",
    buttonWeight: ButtonView.ButtonWeight = .`static`,
    buttonSize: ButtonView.ButtonSize = .medium,
    fullWidth: Bool = true,
    width: CSS.Length? = nil,
    menuWidth: CSS.Length? = nil,
    fontSize: CSS.Length = fontSizeSmall14,
    contentJustifyContent: CSS.JustifyContent = .spaceBetween,
    optionLayout: OptionLayout = .standard,
    borderRadius: CSS.Length = borderRadiusBase,
    submitFormOnChange: Bool = false
  ) {
    self.id = id
    self.name = name
    self.labelText = label
    self.options = options
    self.placeholder = placeholder
    self.selectedValue = selectedValue
    self.required = required
    self.disabled = disabled
    self.tooltip = tooltip
    self.`class` = `class`
    self.buttonWeight = buttonWeight
    self.buttonSize = buttonSize
    self.fullWidth = fullWidth
    self.dropdownWidth = width
    self.menuWidth = menuWidth
    self.textFontSize = fontSize
    self.contentJustifyContent = contentJustifyContent
    self.optionLayout = optionLayout
    self.buttonBorderRadius = borderRadius
    self.submitFormOnChange = submitFormOnChange
  }

  public func build() -> DOM.Node {
    div {
      // Label
      if !stringIsEmpty(labelText) {
        label {
          span { labelText }
            .class("dropdown-label-text")

          if let tooltipText = tooltip {
            TooltipView(tooltip: tooltipText, placement: .bottom) {
              IconView {
                InfoIconView()
              }
            }
          }
        }
        .for(id)
        .style {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
          fontSize(textFontSize)
          fontWeight(600)
          color(colorBase)
          fontFamily(typographyFontSans)
        }
      }

      // Dropdown container
      div {
        // Hidden input to store the selected value
        input()
          .type(.hidden)
          .id(id)
          .name(name)
          .value(selectedValue ?? "")
          .required(required)
          .disabled(disabled)

        // Determine display text - use selected option's display or placeholder
        let displayText: String = {
          if let value = selectedValue,
            let option = options.first(where: { stringEquals($0.value, value) })
          {
            return option.display
          }
          return placeholder
        }()
        // Trigger button
        div {
          ButtonView(
            label: "",
            weight: buttonWeight,
            size: buttonSize,
            disabled: disabled,
            fullWidth: fullWidth,
            class: "dropdown-trigger",
            labelFontWeight: fontWeightNormal,
            contentJustifyContent: contentJustifyContent,
            borderRadius: buttonBorderRadius
          ) {
            span { displayText }
              .class("dropdown-selected-text")
              .data("dropdown-selected-text", true)
              .data("placeholder", placeholder)
              .style {
                textAlign(.start)
                let hasSelectedValue = selectedValue.map { sv in options.contains { stringEquals($0.value, sv) } } ?? false
                if disabled {
                  color(hasSelectedValue ? colorDisabled : colorPlaceholder)
                } else {
                  color(hasSelectedValue ? colorBase : colorPlaceholder)
                }
                whiteSpace(.nowrap)
                if optionLayout == .sidebar {
                  overflow(.hidden)
                  textOverflow(.ellipsis)
                  maxWidth(px(160))
                }
              }
              .title(options.first { stringEquals($0.value, selectedValue ?? "") }?.altDisplay ?? displayText)

            // Animated chevron icon (switch, not ==, since ButtonSize is String-raw)
            let chevronDim: CSS.Length =
              switch buttonSize {
              case .small: px(12)
              case .medium: px(16)
              case .large: px(20)
              }
            AnimatedUpDownChevronView(
              id: "dropdown-\(id)",
              expanded: false,
              width: chevronDim,
              height: chevronDim,
              class: "dropdown-chevron"
            )
          }
        }
        .class("dropdown-trigger-wrapper")
        .data("dropdown-trigger", true)
        .data("dropdown-id", id)
        .style {
          if let w = dropdownWidth {
            width(w)
          } else if fullWidth {
            width(perc(100))
          } else {
            width(.fitContent)
          }
          display(.flex)
          flex(1)
          justifyContent(.spaceBetween)
          media(maxWidth(maxWidthBreakpointMobile)) {
            width(perc(100)).important()
          }
        }

        // Dropdown menu
        div {
          // Search input
          div {
            input()
              .type(.text)
              .placeholder("Search...")
              .class("dropdown-search-input")
              .data("dropdown-search", true)
              .style {
                width(perc(100))
                padding(spacing8, spacing12)
                fontSize(textFontSize)
                lineHeight(1.618)
                color(colorBase)
                backgroundColor(backgroundColorBase)
                border(borderWidthBase, .solid, borderColorBase)
                borderRadius(borderRadiusBase)
                boxSizing(.borderBox)
                pseudoClass(.focus) {
                  outline(borderWidthThick, .solid, colorBlue).important()
                  borderColor(borderColorBlue).important()
                }
              }
          }
          .style {
            padding(spacing8)
            borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
          }

          // Options list
          div {
            options.map { option in
              let isSelected = stringEquals(option.value, selectedValue ?? "")
              return div {
                span { option.display }
                  .class("dropdown-option-display-text")
                  .style {
                    if optionLayout == .sidebar {
                      fontWeight(fontWeightSemiBold)
                      fontSize(fontSizeSmall14)
                      color(isSelected ? colorInvertedFixed : colorBase)
                      whiteSpace(.nowrap)
                      overflow(.hidden)
                      textOverflow(.ellipsis)
                      width(perc(100))
                    }
                  }
                
                if let alt = option.altDisplay, !stringIsEmpty(alt) {
                  span { alt }
                    .class("dropdown-option-alt-text")
                    .style {
                      if optionLayout == .sidebar {
                        fontSize(fontSizeXSmall12)
                        color(isSelected ? colorInvertedFixed : colorSubtle)
                        whiteSpace(.nowrap)
                        overflow(.hidden)
                        textOverflow(.ellipsis)
                        width(perc(100))
                      } else {
                        marginInlineStart(.auto)
                      }
                    }
                }
              }
              .class(isSelected ? "dropdown-option is-selected" : "dropdown-option")
              .data("dropdown-option", true)
              .data("value", option.value)
              .data("display", option.display)
              .data("display-lower", option.displayLower ?? option.display)
              .data("alt-display", option.altDisplay ?? "")
              .style {
                display(.flex)
                if optionLayout == .sidebar {
                  flexDirection(.column)
                  alignItems(.flexStart)
                  gap(spacing2)
                  padding(spacing12)
                } else {
                  alignItems(.center)
                  gap(spacing8)
                  padding(spacing8, spacing12)
                }
                fontSize(textFontSize)
                color(isSelected ? colorInvertedFixed : colorBase)
                backgroundColor(isSelected ? backgroundColorBlue : backgroundColorTransparent)
                cursor(cursorBaseHover)
                transition(
                  transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                pseudoClass(.hover) {
                  backgroundColor(backgroundColorBlue).important()
                  color(colorInvertedFixed).important()
                  selector(".dropdown-option-display-text", ".dropdown-option-alt-text") {
                    color(colorInvertedFixed).important()
                  }
                }
                
                if isSelected {
                  backgroundColor(backgroundColorBlue).important()
                  color(colorInvertedFixed).important()
                  selector(".dropdown-option-display-text", ".dropdown-option-alt-text") {
                    color(colorInvertedFixed).important()
                  }
                }
              }

            }
          }
          .class("dropdown-options-list")
          .data("dropdown-options-list", true)
          .style {
            maxHeight(px(300))
            overflowY(.auto)
          }
        }
        .class("dropdown-menu")
        .data("dropdown-menu", true)
        .style {
          position(.absolute)
          top(perc(100))
          insetInlineStart(0)
          if let mw = menuWidth {
            width(mw)
          } else if dropdownWidth != nil {
            minWidth(px(250))
          } else {
            insetInlineEnd(0)
          }
          marginBlockStart(spacing4)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          boxShadow(boxShadowMedium)
          zIndex(zIndexDropdown)
          display(.none)
          overflow(.hidden)
          media(maxWidth(maxWidthBreakpointMobile)) {
            width(perc(100)).important()
            insetInlineStart(0).important()
            insetInlineEnd(0).important()
          }
        }
      }
      .class("dropdown-container")
      .data("dropdown-container", true)
      .data("dropdown-disabled", disabled)
      .style {
        position(.relative)
        pseudoClass(.focusWithin) {
          zIndex(zIndexDropdown).important()
        }
        selector(".is-open") {
          zIndex(zIndexDropdown).important()
        }
        selector(".dropdown-trigger:focus-visible") {
          outline(.none).important()
          boxShadow(px(0), px(0), px(0), px(2), colorBlue).important()
        }
        media(maxWidth(maxWidthBreakpointMobile)) {
          width(perc(100)).important()
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "dropdown-view" : "dropdown-view \(`class`)")
    .data("submitFormOnChange", submitFormOnChange ? "true" : "false")
    .style {
      display(.flex)
      flexDirection(.column)
      gap(spacing8)
      if fullWidth {
        width(perc(100))
      } else {
        media(maxWidth(maxWidthBreakpointMobile)) {
          width(perc(100)).important()
        }
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

  private class DropdownInstance: @unchecked Sendable {
    private var container: DOM.Element?
    private var trigger: DOM.Element?
    private var menu: DOM.Element?
    private var searchInput: DOM.Element?
    private var optionsList: DOM.Element?
    private var selectedText: DOM.Element?
    private var hiddenInput: DOM.Element?
    private var chevronInstance: AnimatedUpDownChevronInstance?
    private var isOpen: Bool = false
    private var allOptions: [DOM.Element] = []
    private var placeholder: String = "Select an option"

    private var highlightIndex: Int = -1

    init(container: DOM.Element, dropdownID: String) {
      self.container = container
      trigger = container.querySelector("[data-dropdown-trigger=\"true\"]")
      menu = container.querySelector("[data-dropdown-menu=\"true\"]")
      searchInput = container.querySelector("[data-dropdown-search=\"true\"]")
      optionsList = container.querySelector("[data-dropdown-options-list=\"true\"]")
      selectedText = container.querySelector("[data-dropdown-selected-text=\"true\"]")
      
      // Read the real placeholder from its data attribute — not the current
      // button text, which for a preselected dropdown is the selected option's
      // display (so deselecting would wrongly restore that instead of the
      // placeholder).
      placeholder =
        selectedText?.getAttribute("data-placeholder") ?? selectedText?.innerHTML
        ?? "Select an option"

      if let chevronEl = container.querySelector(".animated-up-down-chevron-view") {
        chevronInstance = AnimatedUpDownChevronFactory.from(element: chevronEl)
      }

      // Find hidden input relative to container
      hiddenInput = container.querySelector("input[type=\"hidden\"]")
      if hiddenInput == nil {
        hiddenInput = container.parentElement?.querySelector("input[type=\"hidden\"]")
      }

      // Get all options
      if let optionsList {
        allOptions = Array(optionsList.querySelectorAll("[data-dropdown-option=\"true\"]"))
      }

      bindEvents()
    }

    private func bindEvents() {
      guard let trigger, let searchInput else { return }

      // Toggle dropdown on trigger click
      _ = trigger.addEventListener(.click) { [self] event in
        self.toggleDropdown()
      }

      // Search functionality
      _ = searchInput.addEventListener(.input) { [self] _ in
        self.filterOptions()
      }

      // Option click + hover handlers
      for (i, option) in allOptions.enumerated() {
        _ = option.addEventListener(.click) { [self] _ in
          self.selectOption(option)
        }
        _ = option.addEventListener(.mousemove) { [self] _ in
          if self.highlightIndex != i {
            if self.highlightIndex >= 0, self.highlightIndex < self.allOptions.count {
              let prev = self.allOptions[self.highlightIndex]
              if prev.classList.contains("is-selected") {
                prev.style.backgroundColor(backgroundColorBlue)
                prev.style.color(colorInvertedFixed)
              } else {
                prev.style.backgroundColor(backgroundColorTransparent)
                prev.style.color(colorBase)
              }
            }
            self.highlightIndex = i
            option.style.backgroundColor(backgroundColorBlue)
            option.style.color(colorInvertedFixed)
          }
        }
      }

      // Clear hover highlight when mouse leaves the options list
      if let list = optionsList {
        _ = list.addEventListener(.mouseleave) { [self] _ in
          if self.highlightIndex >= 0, self.highlightIndex < self.allOptions.count {
            let prev = self.allOptions[self.highlightIndex]
            if prev.classList.contains("is-selected") {
              prev.style.backgroundColor(backgroundColorBlue)
              prev.style.color(colorInvertedFixed)
            } else {
              prev.style.backgroundColor(backgroundColorTransparent)
              prev.style.color(colorBase)
            }
          }
          self.highlightIndex = -1
        }
      }

      // Click outside handler
      _ = document.addEventListener(.click) { [self] event in
        guard self.isOpen,
          let target = event.target,
          let container = self.container
        else { return }

        // Close if click is outside the dropdown container
        if !container.contains(target) {
          self.closeDropdown()
        }
      }

      // Keydown handler for auto-focusing search and arrow navigation
      _ = document.addEventListener(.keydown) { [self] event in
        guard self.isOpen, let searchInput = self.searchInput else { return }
        if stringIsAlphanumeric(event.key) {
          searchInput.focus()
        } else if stringEquals(event.key, "ArrowDown") {
          event.preventDefault()
          self.moveHighlight(1)
        } else if stringEquals(event.key, "ArrowUp") {
          event.preventDefault()
          self.moveHighlight(-1)
        } else if stringEquals(event.key, "Enter") {
          event.preventDefault()
          self.selectHighlighted()
        }
      }
    }

    private func toggleDropdown() {
      if isOpen {
        closeDropdown()
      } else {
        openDropdown()
      }
    }

    private func openDropdown() {
      menu?.style.display(.block)
      _ = container?.classList.add("is-open")
      morphChevron()
      isOpen = true
      highlightIndex = -1
    }

    private func closeDropdown() {
      menu?.style.display(.none)
      _ = container?.classList.remove("is-open")
      morphChevron()
      isOpen = false
      (searchInput as? HTML.HTMLInputElement)?.value = ""
      filterOptions()  // Reset filter
    }

    private func morphChevron() {
      chevronInstance?.setState(expanded: isOpen, animated: true)
    }

    private func filterOptions() {
      guard let searchInput else { return }

      let searchValue = (searchInput as? HTML.HTMLInputElement)?.value ?? ""

      for option in allOptions {
        guard let displayValue = option.getAttribute(data("display")) else {
          option.style.display(.none)
          continue
        }

        // Use utility function for case-insensitive substring match
        let matches =
          stringContainsCaseInsensitive(displayValue, searchValue)
          || stringContainsCaseInsensitive(
            option.getAttribute(data("alt-display")) ?? "", searchValue)
        if matches {
          option.style.display(.flex)
          option.setAttribute(data("hidden"), "false")
        } else {
          option.style.display(.none)
          option.setAttribute(data("hidden"), "true")
        }
      }
      highlightIndex = -1
    }

    private func selectOption(_ option: DOM.Element) {
      guard let value = option.getAttribute(data("value")),
        let display = option.getAttribute(data("display"))
      else { return }

      let currentVal = (hiddenInput as? HTML.HTMLInputElement)?.value ?? ""
      
      if stringEquals(currentVal, value) {
        // Toggle off if already selected
        clearSelection()
        return
      }

      // Update hidden input
      (hiddenInput as? HTML.HTMLInputElement)?.value = value

      // Get altDisplay for tooltip
      let altDisplay = option.getAttribute(data("alt-display")) ?? display

      // Update selected text and title (tooltip)
      selectedText?.innerHTML = display
      selectedText?.setAttribute(.title, altDisplay)
      selectedText?.style.color(colorBase)

      // Update selected state in menu
      for opt in allOptions {
        _ = opt.classList.remove("is-selected")
        opt.style.backgroundColor(backgroundColorTransparent)
        opt.style.color(colorBase)
      }
      _ = option.classList.add("is-selected")
      option.style.backgroundColor(backgroundColorBlue)
      option.style.color(colorInvertedFixed)

      // Dispatch change event on hidden input
      if let hiddenInput {
        hiddenInput.dispatchEvent(.change)
      }

      closeDropdown()

      // Submit the closest form if the dropdown was configured to do so
      if let container, stringEquals(container.dataset["submitFormOnChange"], "true") {
        if let form = container.closest("form") as? HTML.HTMLFormElement {
          form.submit()
        }
      }
    }

    private func moveHighlight(_ delta: Int) {
      guard allOptions.count > 0 else { return }
      if highlightIndex >= 0, highlightIndex < allOptions.count {
        let prev = allOptions[highlightIndex]
        if prev.classList.contains("is-selected") {
          prev.style.backgroundColor(backgroundColorBlue)
          prev.style.color(colorInvertedFixed)
        } else {
          prev.style.backgroundColor(backgroundColorTransparent)
          prev.style.color(colorBase)
        }
      }
      var steps = 0
      while steps < allOptions.count {
        highlightIndex = ((highlightIndex + delta) % allOptions.count + allOptions.count) % allOptions.count
        steps += 1
        if !stringEquals(allOptions[highlightIndex].getAttribute(data("hidden")) ?? "", "true") {
          break
        }
      }
      allOptions[highlightIndex].style.backgroundColor(backgroundColorBlue)
      allOptions[highlightIndex].style.color(colorInvertedFixed)
      if let list = optionsList {
        let optionTop = allOptions[highlightIndex].offsetTop - list.offsetTop
        let optionBottom = optionTop + allOptions[highlightIndex].offsetHeight
        let listScrollTop = list.scrollTop
        let listBottom = listScrollTop + Double(list.clientHeight)
        if optionTop < listScrollTop {
          list.scrollTop = optionTop
        } else if optionBottom > listBottom {
          list.scrollTop = optionBottom - Double(list.clientHeight)
        }
      }
    }

    private func selectHighlighted() {
      guard highlightIndex >= 0, highlightIndex < allOptions.count else { return }
      selectOption(allOptions[highlightIndex])
    }

    private func clearSelection() {
      (hiddenInput as? HTML.HTMLInputElement)?.value = ""
      selectedText?.innerHTML = placeholder
      selectedText?.removeAttribute(.title)
      selectedText?.style.color(colorPlaceholder)

      for opt in allOptions {
        _ = opt.classList.remove("is-selected")
        opt.style.backgroundColor(backgroundColorTransparent)
        opt.style.color(colorBase)
      }

      if let hiddenInput {
        hiddenInput.dispatchEvent(.change)
      }

      closeDropdown()

      if let container, stringEquals(container.dataset["submitFormOnChange"], "true") {
        if let form = container.closest("form") as? HTML.HTMLFormElement {
          form.submit()
        }
      }
    }
  }

  public class DropdownHydration: @unchecked Sendable {
    private var instances: [DropdownInstance] = []

    public init() {
      hydrateAllDropdowns()
    }

    private func hydrateAllDropdowns() {
      let allContainers = document.querySelectorAll("[data-dropdown-container=\"true\"]")
      for container in allContainers {
        if container.hasAttribute("data-dropdown-hydrated") { continue }

        guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
          let dropdownID = trigger.getAttribute("data-dropdown-id")
        else { continue }

        let instance = DropdownInstance(container: container, dropdownID: dropdownID)
        instances.append(instance)
        container.setAttribute(data("dropdown-hydrated"), true)
      }
    }

    public func hydrate(element: DOM.Element) {
      if element.hasAttribute("data-dropdown-hydrated") { return }

      guard let trigger = element.querySelector("[data-dropdown-trigger=\"true\"]"),
        let dropdownID = trigger.getAttribute("data-dropdown-id")
      else { return }

      let instance = DropdownInstance(container: element, dropdownID: dropdownID)
      instances.append(instance)
      element.setAttribute(data("dropdown-hydrated"), true)
    }

    public func hydrateDropdown(dropdownID: String) {
      let allContainers = document.querySelectorAll("[data-dropdown-container=\"true\"]")

      for container in allContainers {
        if container.hasAttribute("data-dropdown-hydrated") { continue }

        guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
          let id = trigger.getAttribute("data-dropdown-id"),
          stringEquals(id, dropdownID)
        else { continue }

        let instance = DropdownInstance(container: container, dropdownID: dropdownID)
        instances.append(instance)
        container.setAttribute(data("dropdown-hydrated"), true)
        break
      }
    }
  }

  /// CLIENT factory for creating a real `DropdownView` element dynamically (e.g. inside the
  /// translation chain) instead of hand-building a dropdown replica. Pass a retained
  /// `DropdownHydration` (the page-level one, e.g. the chain's `dropdownHydrator`) so the
  /// created dropdown is hydrated and its instance stays alive.
  public enum DropdownFactory {
    public static func createElement(
      id: String,
      name: String,
      label: String = "",
      options: [DropdownView.DropdownOption],
      placeholder: String = "Select an option",
      selectedValue: String? = nil,
      required: Bool = false,
      tooltip: String? = nil,
      class: String = "",
      buttonSize: ButtonView.ButtonSize = .medium,
      fullWidth: Bool = true,
      fontSize: CSS.Length = fontSizeSmall14,
      hydrator: DropdownHydration? = nil
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = DropdownView(
        id: id,
        name: name,
        label: label,
        options: options,
        placeholder: placeholder,
        selectedValue: selectedValue,
        required: required,
        tooltip: tooltip,
        class: `class`,
        buttonSize: buttonSize,
        fullWidth: fullWidth,
        fontSize: fontSize
      )
      wrapper.innerHTML = renderHTML { view.render() }
      let element = wrapper.firstElementChild ?? wrapper
      if let hydrator = hydrator,
        let container = element.querySelector("[data-dropdown-container=\"true\"]")
      {
        hydrator.hydrate(element: container)
      }
      return element
    }
  }
#endif
