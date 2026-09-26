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

    public init(
      value: String, display: String, altDisplay: String? = nil, displayLower: String? = nil
    ) {
      self.value = value
      self.display = display
      self.altDisplay = altDisplay
      self.displayLower = displayLower
    }
  }

  /// How one option lays out. Named for the shape, not for the one page that
  /// first wanted it: a form field needs the stacked form just as much as a
  /// sidebar does.
  public enum OptionLayout: Sendable {
    /// Display and alt on one line, alt pushed to the far end.
    case inline
    /// Display over alt, two rows — so neither has to be truncated.
    case stacked
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
  /// The id of the form its value submits with, when it sits outside that
  /// form.
  let form: String?
  /// Where its search asks for options, when the server holds too many to
  /// send: typing asks `searchURL?q=…` (debounced, a late answer to an
  /// earlier query dropped) and shows the options of the dropdown the
  /// answer holds in place of its own; an empty query shows its own again.
  let searchURL: String?
  /// Whether the label carries the lighter "(optional)" aside after its
  /// text, as LabelView draws it: not part of the label text.
  let optional: Bool
  let optionalFlag: String
  /// A line at the end of the menu that is not an option: what the list
  /// leaves out ("Showing the first 50. Type to narrow the list."). A
  /// remote search's answer brings its own.
  let note: String?

  public init(
    id: String,
    name: String,
    label: String,
    optional: Bool = false,
    optionalFlag: String = "(optional)",
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
    optionLayout: OptionLayout = .inline,
    buttonBorderRadius: CSS.Length = borderRadiusBase,
    submitFormOnChange: Bool = false,
    form: String? = nil,
    searchURL: String? = nil,
    note: String? = nil
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
    self.buttonBorderRadius = buttonBorderRadius
    self.submitFormOnChange = submitFormOnChange
    self.form = form
    self.searchURL = searchURL
    self.optional = optional
    self.optionalFlag = optionalFlag
    self.note = note
  }

  public func build() -> DOM.Node {
    let requiredMessage = "\(labelText.isEmpty ? "A value" : labelText) is required."
    div {
      // Label
      if !stringIsEmpty(labelText) {
        label {
          span { labelText }
            .class("dropdown-label-text")

          if optional {
            span { optionalFlag }
              .class("dropdown-optional-flag")
              .data("optional-flag", true)
          }

          if let tooltipText = tooltip {
            TooltipView(tooltip: tooltipText, placement: .bottom) {
              IconView {
                InfoIconView()
              }
            }
          }
        }
        .for(id)
        .class("dropdown-label")
      }

      // Dropdown container
      div {
        // Hidden input to store the selected value
        let hidden = input()
          .type(.hidden)
          .id(id)
          .name(name)
          .value(selectedValue ?? "")
          .required(required)
          .disabled(disabled)
        if let form { hidden.form(form) } else { hidden }

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
              .data("selected", selectedValue.map { value in options.contains { stringEquals($0.value, value) } } ?? false)
              .data("disabled", disabled)
              .data("stacked", optionLayout == .stacked)
              .title(options.first { stringEquals($0.value, selectedValue ?? "") }?.altDisplay ?? displayText)

            // Animated chevron icon (switch, not ==, since ButtonSize is String-raw)
            let chevronDim: CSS.Length =
              switch buttonSize {
              case .mini, .small: px(12)
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

        // Shown by the submit guard when this dropdown is required and empty:
        // a red border alone said something was wrong without saying what.
        if required {
          span { requiredMessage }
            .class("dropdown-required-message")
            .role(.alert)
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
          }
          .class("dropdown-search-input-wrapper")

          // Options list
          div {
            options.map { option in
              let isSelected = stringEquals(option.value, selectedValue ?? "")
              return div {
                span { option.display }
                  .class("dropdown-option-display-text")
                  .data("stacked", optionLayout == .stacked)
                
                if let alt = option.altDisplay, !stringIsEmpty(alt) {
                  span { alt }
                    .class("dropdown-option-alt-text")
                    .data("stacked", optionLayout == .stacked)
                }
              }
              .class(isSelected ? "dropdown-option is-selected" : "dropdown-option")
              .data("dropdown-option", true)
              .data("value", option.value)
              .data("display", option.display)
              .data("display-lower", option.displayLower ?? option.display)
              .data("alt-display", option.altDisplay ?? "")
              .data("selected", isSelected)
              .data("stacked", optionLayout == .stacked)
              .data("hidden", false)
            }
            if let note {
              div { note }
                .class("dropdown-note")
                .data("dropdown-note", true)
            }
          }
          .class("dropdown-options-list")
          .data("dropdown-options-list", true)
        }
        .class("dropdown-menu")
        .data("dropdown-menu", true)
        .data("open", false)
      }
      .class("dropdown-container")
      .data("dropdown-container", true)
      .data("dropdown-disabled", disabled)
    }
    .class(stringIsEmpty(`class`) ? "dropdown-view" : "dropdown-view \(`class`)")
    .data("submit-form-on-change", submitFormOnChange ? "true" : "false")
    .data("full-width", fullWidth ? "true" : "false")
    .data("search-url", searchURL ?? "")
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        if fullWidth {
          width(perc(100))
        }
      }
      if !fullWidth {
        media(maxWidth(maxWidthBreakpointMobile)) {
          selector("&") {
            width(perc(100)).important()
          }
        }
      }
      descendant(".field-label") {
        display(.flex)
        alignItems(.center)
        gap(spacing4)
        fontSize(textFontSize)
        fontWeight(600)
        color(colorBase)
        fontFamily(typographyFontSans)
      }
      // One line, held inside the trigger: a title longer than the field was
      // drawn straight through the border. It scrolls sideways, as a text
      // input does — a swipe or a trackpad reads the rest — with no scrollbar
      // drawn inside the trigger. No ellipsis: it stayed painted over the
      // text while the text scrolled.
      descendant(".dropdown-selected-text") {
        textAlign(.start)
        color(colorPlaceholder)
        whiteSpace(.nowrap)
        overflowX(.auto)
        overflowY(.hidden)
        scrollbarWidth(.none)
        minWidth(0)
        pseudoElement(.webkitScrollbar) { display(.none).important() }
      }
      // The text gives way, not the chevron: beside a cut title it was
      // squeezed to a sliver.
      descendant(".dropdown-chevron") {
        flexShrink(0)
      }
      descendant(".dropdown-selected-text[data-selected='true'][data-disabled='false']") { color(colorBase) }
      descendant(".dropdown-selected-text[data-disabled='true']") { color(colorDisabled) }
      // Only when it is narrow. `stacked` describes the OPTIONS; a full-width
      // trigger has room for the whole title and was cutting it to "An
      // Anglo-Saxon Dic...".
      selector("&:not([data-full-width='true']) .dropdown-selected-text[data-stacked='true']") {
        maxWidth(px(160))
      }
      descendant(".dropdown-trigger-wrapper") {
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
      }
      // Trigger radius comes from ButtonView(borderRadius:) — do not override here
      // (shared .dropdown-view CSS would otherwise force one radius for all instances).
      media(maxWidth(maxWidthBreakpointMobile)) {
        descendant(".dropdown-trigger-wrapper") {
          width(perc(100)).important()
        }
        descendant(".dropdown-container") {
          width(perc(100)).important()
        }
        descendant(".dropdown-menu") {
          width(perc(100)).important()
          insetInlineStart(0).important()
          insetInlineEnd(0).important()
        }
      }
      descendant(".dropdown-search-input") {
        width(perc(100))
        height(minSizeInteractiveTouch)
        padding(0, spacing12)
        fontSize(textFontSize)
        lineHeight(lineHeightContent)
        color(colorBase)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        boxSizing(.borderBox)
        // One ring, the text input's: a blue border and a 1px shadow
        // around it. A thick outline on top of them drew two rings.
        pseudoClass(.focus) {
          outline(.none).important()
          borderColor(borderColorBlue).important()
          boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
        }
      }
      // Matches LabelView, which every FieldView label uses: a dropdown in a
      // form is a form field and its label has to look like one.
      // A trigger is a form FIELD, so its text must start where a text
      // input's does: the input pads 15px inside a 1px border, the button it
      // is built on pads a button's 11px. Three classes and an attribute to
      // outrank ButtonView's size rule without an important.
      selector("&.dropdown-view .dropdown-trigger.button-view[data-size='medium']") {
        paddingInline(px(15))
      }
      // Set by the submit guard when a required dropdown has no value.
      selector("&[data-invalid='true'] .dropdown-trigger") {
        borderColor(borderColorRed).important()
        borderWidth(borderWidthThick).important()
      }
      descendant(".dropdown-required-message") {
        display(.none)
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        color(colorRed)
      }
      selector("&[data-invalid='true'] .dropdown-required-message") {
        display(.block)
      }
      // Semi-bold, matching the field labels beside it. Bold made a dropdown
      // read as a heavier field than the text inputs it sits among.
      // The label and its tooltip in a row, 4px apart, as every field's.
      descendant(".dropdown-label") {
        display(.flex)
        alignItems(.center)
        gap(spacing4)
      }
      descendant(".dropdown-label-text") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        fontWeight(fontWeightSemiBold)
        color(colorBase)
      }
      // An aside affixed to the label, not label text: LabelView's
      // `.label-optional-flag`.
      descendant(".dropdown-optional-flag") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
      // Not an option: no hover, no pointer, never chosen.
      descendant(".dropdown-note") {
        padding(spacing8, spacing12)
        fontFamily(typographyFontSans)
        fontSize(fontSizeXSmall12)
        lineHeight(lineHeightSmall22)
        color(colorSubtle)
        borderBlockStart(borderWidthBase, .solid, borderColorSubtle)
        cursor(cursorBase)
      }
      descendant(".dropdown-search-input-wrapper") {
        padding(spacing8)
        borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
      }
      descendant(".dropdown-option") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        padding(spacing8, spacing12)
        fontSize(textFontSize)
        color(colorBase)
        backgroundColor(backgroundColorTransparent)
        cursor(cursorBaseHover)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        pseudoClass(.hover) {
          backgroundColor(backgroundColorBlue).important()
          color(colorInvertedFixed).important()
          selector(".dropdown-option-display-text", ".dropdown-option-alt-text") {
            color(colorInvertedFixed).important()
          }
        }
      }
      descendant(".dropdown-option[data-stacked='true']") {
        flexDirection(.column)
        alignItems(.flexStart)
        gap(spacing2)
        padding(spacing12)
      }
      descendant(".dropdown-option[data-hidden='true']") { display(.none) }
      descendant(".dropdown-option[data-selected='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
      }
      selector(".dropdown-option[data-selected='true'] .dropdown-option-display-text", ".dropdown-option[data-selected='true'] .dropdown-option-alt-text") {
        color(colorInvertedFixed).important()
      }
      descendant(".dropdown-option[data-highlighted='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
      }
      selector(".dropdown-option[data-highlighted='true'] .dropdown-option-display-text", ".dropdown-option[data-highlighted='true'] .dropdown-option-alt-text") {
        color(colorInvertedFixed).important()
      }
      // Wrapped, not cut: the menu is the one place a long title is read
      // whole — the trigger above it is the one that ellipses.
      descendant(".dropdown-option-display-text[data-stacked='true']") {
        fontWeight(fontWeightSemiBold)
        fontSize(fontSizeSmall14)
        color(colorBase)
        overflowWrap(.breakWord)
        width(perc(100))
      }
      descendant(".dropdown-option-alt-text[data-stacked='true']") {
        fontSize(fontSizeXSmall12)
        color(colorSubtle)
        overflowWrap(.breakWord)
        width(perc(100))
      }
      descendant(".dropdown-option-alt-text[data-stacked='false']") {
        marginInlineStart(.auto)
      }
      descendant(".dropdown-options-list") {
        maxHeight(px(300))
        overflowY(.auto)
      }
      descendant(".dropdown-menu") {
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
      }
      descendant(".dropdown-menu[data-open='true']") {
        display(.block)
      }
      descendant(".dropdown-container") {
        position(.relative)
        pseudoClass(.focusWithin) {
          zIndex(zIndexDropdown).important()
        }
        descendant(".is-open") {
          zIndex(zIndexDropdown).important()
        }
        descendant(".dropdown-trigger:focus-visible") {
          outline(.none).important()
          boxShadow(px(0), px(0), px(0), px(2), colorBlue).important()
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
    /// The options the list shows now: its own, or a search's.
    private var allOptions: [DOM.Element] = []
    /// Its own options, as the page drew them.
    private var ownOptions: [DOM.Element] = []
    /// A remote search's answer, shown in place of its own list.
    private var resultsList: DOM.Element?
    private var resultOptions: [DOM.Element] = []
    /// The search answer's note, after its options.
    private var resultNote: DOM.Element?
    private var searchURL: String = ""
    private var searchTimer: Int32 = 0
    /// Which query is the latest: an answer overtaken by a later one is
    /// dropped.
    private var searchSequence = 0
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
      ownOptions = allOptions
      searchURL = container.closest(".dropdown-view")?.getAttribute(data("search-url")) ?? ""

      bindEvents()
    }

    /// Enforces `required` for this dropdown on its form's submit.
    ///
    /// Server-side guards stay — they are the real protection. This only makes
    /// the failure visible where the reader can fix it.
    private func bindRequiredValidation() {
      guard let input = hiddenInput as? HTML.HTMLInputElement,
        input.hasAttribute("required"),
        let container,
        let form = container.closest("form")
      else { return }

      _ = form.addEventListener(.submit) { [self] (event: Event) in
        guard let field = self.hiddenInput as? HTML.HTMLInputElement,
          let container = self.container
        else { return }
        let mark = container.closest(".dropdown-view") ?? container
        // A dropdown the reader cannot see cannot be filled in: the
        // translation chain's language sits required inside a hidden group
        // on every non-translation, and blocked every submit with no
        // visible reason. Hidden means not asked.
        let hidden = mark.getBoundingClientRect().map { $0.height <= 0 } ?? true
        if hidden {
          mark.removeAttribute("data-invalid")
          return
        }
        if stringIsEmpty(field.value) {
          event.preventDefault()
          mark.setAttribute("data-invalid", "true")
          mark.scrollIntoView()
          self.trigger?.focus()
        } else {
          mark.removeAttribute("data-invalid")
        }
      }
    }

    private func bindEvents() {
      guard let trigger, let searchInput else { return }

      bindRequiredValidation()

      // Toggle dropdown on trigger click
      _ = trigger.addEventListener(.click) { [self] event in
        self.toggleDropdown()
      }

      // `required` on the value input does NOTHING: it is type="hidden", and
      // hidden inputs are barred from constraint validation. The browser
      // submitted a dropdown with nothing chosen and the reader got the
      // server's 400 page instead of an error on the field. So the form is
      // checked here, on the one element that can actually be focused.
      // Search functionality
      _ = searchInput.addEventListener(.input) { [self] _ in
        self.filterOptions()
      }

      bindOptions(allOptions)

      // Clear hover highlight when mouse leaves the options list
      if let list = optionsList {
        bindLeave(list)
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

    /// Click and hover on each option; `i` is its place in the list that
    /// shows it.
    private func bindOptions(_ options: [DOM.Element]) {
      for (i, option) in options.enumerated() {
        _ = option.addEventListener(.click) { [self] _ in
          self.selectOption(option)
        }
        _ = option.addEventListener(.mousemove) { [self] _ in
          if self.highlightIndex != i {
            if self.highlightIndex >= 0, self.highlightIndex < self.allOptions.count {
              self.allOptions[self.highlightIndex].setAttribute(data("highlighted"), false)
            }
            self.highlightIndex = i
            option.setAttribute(data("highlighted"), true)
          }
        }
      }
    }

    private func bindLeave(_ list: DOM.Element) {
      _ = list.addEventListener(.mouseleave) { [self] _ in
        if self.highlightIndex >= 0, self.highlightIndex < self.allOptions.count {
          self.allOptions[self.highlightIndex].setAttribute(data("highlighted"), false)
        }
        self.highlightIndex = -1
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
      isOpen = true
      menu?.setAttribute(data("open"), true)
      _ = container?.classList.add("is-open")
      morphChevron()
      highlightIndex = -1
    }

    private func closeDropdown() {
      isOpen = false
      menu?.setAttribute(data("open"), false)
      _ = container?.classList.remove("is-open")
      morphChevron()
      (searchInput as? HTML.HTMLInputElement)?.value = ""
      filterOptions()  // Reset filter
    }

    private func morphChevron() {
      chevronInstance?.setState(expanded: isOpen, animated: true)
    }

    private func filterOptions() {
      guard let searchInput else { return }

      let searchValue = (searchInput as? HTML.HTMLInputElement)?.value ?? ""
      if !stringIsEmpty(searchURL) {
        searchRemotely(stringTrim(searchValue))
        return
      }

      for option in allOptions {
        guard let displayValue = option.getAttribute(data("display")) else {
          option.setAttribute(data("hidden"), true)
          continue
        }

        // Use utility function for case-insensitive substring match
        let matches =
          stringContainsCaseInsensitive(displayValue, searchValue)
          || stringContainsCaseInsensitive(
            option.getAttribute(data("alt-display")) ?? "", searchValue)
        if matches {
          option.setAttribute(data("hidden"), "false")
        } else {
          option.setAttribute(data("hidden"), "true")
        }
      }
      highlightIndex = -1
    }

    /// Asks the server for the options matching `query`, shortly: each key
    /// typed restarts the wait, and only the latest query's answer is shown.
    private func searchRemotely(_ query: String) {
      if searchTimer != 0 {
        clearTimeout(searchTimer)
        searchTimer = 0
      }
      searchSequence += 1
      highlightIndex = -1
      if stringIsEmpty(query) {
        showOwnOptions()
        return
      }
      let asked = searchSequence
      let url = stringJoin(
        [searchURL, stringContains(searchURL, "?") ? "&q=" : "?q=", encodeURIComponent(query)], separator: "")
      searchTimer = setTimeout(250) { [self] in
        self.searchTimer = 0
        // The answer is a dropdown: loaded aside, its options taken.
        let answer = document.createElement(.div)
        answer.loadFragment(url) { [self] ok in
          guard ok, asked == self.searchSequence else { return }
          self.showResults(from: answer)
        }
      }
    }

    private func showResults(from answer: DOM.Element) {
      let results: DOM.Element
      if let resultsList {
        results = resultsList
      } else {
        results = document.createElement(.div)
        _ = results.classList.add("dropdown-options-list")
        results.setAttribute(data("dropdown-results"), true)
        menu?.appendChild(results)
        bindLeave(results)
        resultsList = results
      }
      for old in resultOptions { results.removeChild(old) }
      if let resultNote { results.removeChild(resultNote) }
      resultNote = nil
      let value = (hiddenInput as? HTML.HTMLInputElement)?.value ?? ""
      var options: [DOM.Element] = []
      for option in answer.querySelectorAll("[data-dropdown-option=\"true\"]") {
        let selected = !stringIsEmpty(value) && stringEquals(option.getAttribute(data("value")) ?? "", value)
        if selected {
          _ = option.classList.add("is-selected")
        } else {
          _ = option.classList.remove("is-selected")
        }
        option.setAttribute(data("selected"), selected)
        option.setAttribute(data("hidden"), false)
        results.appendChild(option)
        options.append(option)
      }
      resultOptions = options
      if let note = answer.querySelector("[data-dropdown-note=\"true\"]") {
        results.appendChild(note)
        resultNote = note
      }
      bindOptions(options)
      optionsList?.setAttribute(.hidden, "")
      results.removeAttribute(.hidden)
      allOptions = options
      highlightIndex = -1
    }

    private func showOwnOptions() {
      resultsList?.setAttribute(.hidden, "")
      optionsList?.removeAttribute(.hidden)
      allOptions = ownOptions
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
      // A choice clears the error the submit guard put there.
      if let container {
        (container.closest(".dropdown-view") ?? container).removeAttribute("data-invalid")
      }

      // Get altDisplay for tooltip
      let altDisplay = option.getAttribute(data("alt-display")) ?? display

      // Update selected text and title (tooltip)
      selectedText?.innerHTML = display
      selectedText?.setAttribute(.title, altDisplay)
      selectedText?.setAttribute(data("selected"), true)
      // A new title starts at its beginning, wherever the last was scrolled to.
      selectedText?.scrollLeft = 0

      // Update selected state in menu
      for opt in ownOptions + resultOptions {
        _ = opt.classList.remove("is-selected")
        opt.setAttribute(data("selected"), false)
      }
      _ = option.classList.add("is-selected")
      option.setAttribute(data("selected"), true)

      // Dispatch change event on hidden input
      if let hiddenInput {
        hiddenInput.dispatchEvent(.change)
      }

      closeDropdown()

      // Submit the closest form if the dropdown was configured to do so. The
      // flag is on the view's root, above the container this instance holds.
      if let container,
        stringEquals(
          container.closest(".dropdown-view")?.getAttribute(data("submit-form-on-change")) ?? "", "true")
      {
        if let form = container.closest("form") as? HTML.HTMLFormElement {
          form.submit()
        }
      }
    }

    private func moveHighlight(_ delta: Int) {
      guard allOptions.count > 0 else { return }
      if highlightIndex >= 0, highlightIndex < allOptions.count {
        allOptions[highlightIndex].setAttribute(data("highlighted"), false)
      }
      var steps = 0
      while steps < allOptions.count {
        highlightIndex = ((highlightIndex + delta) % allOptions.count + allOptions.count) % allOptions.count
        steps += 1
        if !stringEquals(allOptions[highlightIndex].getAttribute(data("hidden")) ?? "", "true") {
          break
        }
      }
      allOptions[highlightIndex].setAttribute(data("highlighted"), true)
      if let list = allOptions[highlightIndex].parentElement {
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
      selectedText?.setAttribute(data("selected"), false)
      selectedText?.scrollLeft = 0

      for opt in ownOptions + resultOptions {
        _ = opt.classList.remove("is-selected")
        opt.setAttribute(data("selected"), false)
      }

      if let hiddenInput {
        hiddenInput.dispatchEvent(.change)
      }

      closeDropdown()

      // The flag is on the view's root, above the container this instance holds.
      if let container,
        stringEquals(
          container.closest(".dropdown-view")?.getAttribute(data("submit-form-on-change")) ?? "", "true")
      {
        if let form = container.closest("form") as? HTML.HTMLFormElement {
          form.submit()
        }
      }
    }
  }

  public class DropdownHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: DropdownHydration?
    private var instances: [DropdownInstance] = []

    public init() {
      hydrateAllDropdowns()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".dropdown-view") != nil else { return }
      instance = DropdownHydration()
    }

    /// The dropdowns a fragment brought in after the page was hydrated, and
    /// only those: every dropdown inside `root`, which must be new to the
    /// page.
    public static func hydrate(in root: DOM.Element) {
      for container in root.querySelectorAll("[data-dropdown-container=\"true\"]") {
        guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
          let dropdownID = trigger.getAttribute("data-dropdown-id")
        else { continue }
        fragments.append(DropdownInstance(container: container, dropdownID: dropdownID))
        container.setAttribute(data("dropdown-hydrated"), true)
      }
    }
    private static nonisolated(unsafe) var fragments: [DropdownInstance] = []

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
      optional: Bool = false,
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
        optional: optional,
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
      wrapper.innerHTML = view.render()
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
