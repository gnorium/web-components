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
    /// What the option belongs to, drawn before `display` as a breadcrumb
    /// is, with BreadcrumbView's chevron between: "English › computer"
    /// (BreadcrumbLabelView). The closed dropdown shows it the same way.
    public let context: String?
    public let display: String
    public let altDisplay: String?
    /// Lowercase form of display, for mid-sentence use (e.g. tooltip text). Pre-computed server-side to avoid WASI string ops.
    public let displayLower: String?
    /// Its level in a grouped list: 0 a group's head (itself a choice, the
    /// broad one), 1 an option under the head before it, drawn indented.
    /// Nil in a list that is not grouped.
    public let depth: Int?

    public init(
      value: String, context: String? = nil, display: String, altDisplay: String? = nil,
      displayLower: String? = nil, depth: Int? = nil
    ) {
      self.value = value
      self.context = context
      self.display = display
      self.altDisplay = altDisplay
      self.displayLower = displayLower
      self.depth = depth
    }
  }

  /// How one option lays out. Named for the shape, not for the one page that
  /// first wanted it: a form field needs the stacked form just as much as a
  /// sidebar does.
  public enum OptionLayout: Sendable {
    /// Display and alt on one line, alt pushed to the far end.
    case inline
    /// Display over alt, two rows—so neither has to be truncated.
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
  /// What stands after the label's text (and its "(optional)"), before
  /// its tooltip: a record page's reference marks. Not label text.
  let labelMarks: [DOM.Node]
  /// A line at the end of the menu that is not an option: what the list
  /// leaves out ("Showing the first 50. Type to narrow the list."). A
  /// remote search's answer brings its own.
  let note: String?
  /// Whether several options may be chosen at once (an origin step's
  /// relations): a click toggles an option and the menu stays open, the
  /// closed dropdown shows the chosen ones' names in the order chosen
  /// ("Translation, Abridgment"), and the value input holds their values
  /// comma-separated. `selectedValues` are the chosen ones then.
  let multiple: Bool
  let selectedValues: [String]

  public init(
    id: String,
    name: String,
    label: String,
    optional: Bool = false,
    optionalFlag: String = "(optional)",
    labelMarks: [DOM.Node] = [],
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
    note: String? = nil,
    multiple: Bool = false,
    selectedValues: [String] = []
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
    self.labelMarks = labelMarks
    self.note = note
    self.multiple = multiple
    self.selectedValues = selectedValues
  }

  /// Whether `value` is chosen: one of `selectedValues` when several may
  /// be, else `selectedValue`.
  private func isChosen(_ value: String) -> Bool {
    if multiple {
      for chosen in selectedValues where stringEquals(chosen, value) { return true }
      return false
    }
    return stringEquals(value, selectedValue ?? "")
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

          labelMarks

          if let tooltipText = tooltip {
            TooltipView(tooltip: tooltipText, placement: .bottom) {
              IconView(icon: { size in InfoIconView(size: size) }, size: fontSizeSmall14)
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
          .value(multiple ? stringJoin(selectedValues, separator: ",") : (selectedValue ?? ""))
          .required(required)
          .disabled(disabled)
        if let form { hidden.form(form) } else { hidden }

        // Determine display text - use selected option's display or placeholder
        let selectedOption: DropdownOption? =
          multiple
          ? nil
          : selectedValue.flatMap { value in
            options.first(where: { stringEquals($0.value, value) })
          }
        // Several chosen: their names in the order chosen.
        var chosenNames: [String] = []
        if multiple {
          for value in selectedValues {
            if let option = options.first(where: { stringEquals($0.value, value) }) { chosenNames.append(option.display) }
          }
        }
        let displayText =
          multiple
          ? (chosenNames.isEmpty ? placeholder : stringJoin(chosenNames, separator: ", "))
          : (selectedOption?.display ?? placeholder)
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
            span {
              if let option = selectedOption, let context = option.context {
                BreadcrumbLabelView(context: context, text: option.display)
              } else {
                displayText
              }
            }
              .class("dropdown-selected-text")
              .data("dropdown-selected-text", true)
            // One line, faded at its end when it runs past the trigger
            // (`fadeOverflow`); the open list shows it whole.
            .data("edge-fade", true)
              .data("placeholder", placeholder)
              .data(
                "selected",
                multiple
                  ? !chosenNames.isEmpty
                  : (selectedValue.map { value in options.contains { stringEquals($0.value, value) } } ?? false))
              .data("disabled", disabled)
              .data("stacked", optionLayout == .stacked)
              .title(options.first { stringEquals($0.value, selectedValue ?? "") }?.altDisplay ?? displayText)

            // Animated chevron icon (switch, not ==, since ButtonSize is String-raw)
            let chevronDim: CSS.Length =
              switch buttonSize {
              case .mini: sizeIconXSmall
              case .small: fontSizeSmall14
              case .medium: sizeIconSmall
              case .large: fontSizeLarge18
              }
            AnimatedUpDownChevronView(
              id: "dropdown-\(id)",
              expanded: false,
              size: chevronDim,
              class: "dropdown-chevron"
            )
          }
        }
        .class("dropdown-trigger-wrapper")
        .data("dropdown-trigger", true)
        .data("dropdown-id", id)

        // Shown by the submit guard when this dropdown is required and empty:
        // a red border alone said something was wrong without saying what.
        // The same message every field draws (FieldValidationMessageView).
        if required {
          div { FieldValidationMessageView(status: .error, message: requiredMessage) }
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
              let isSelected = isChosen(option.value)
              return div {
                span {
                  if let context = option.context {
                    BreadcrumbLabelView(context: context, text: option.display)
                  } else {
                    option.display
                  }
                }
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
              .data("context", option.context ?? "")
              .data("display-lower", option.displayLower ?? option.display)
              .data("alt-display", option.altDisplay ?? "")
              .data("selected", isSelected)
              .data("stacked", optionLayout == .stacked)
              .data("hidden", false)
              .data("depth", option.depth.map { "\($0)" } ?? "")
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
    .data("multiple", multiple)
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
        gap(spacing8)
        fontSize(textFontSize)
        fontWeight(600)
        color(colorBase)
        fontFamily(typographyFontSans)
      }
      // One line, held inside the trigger, fading out at its end when it
      // runs past it (`fadeOverflow`): no tap-to-expand, no ellipsis—the
      // open list shows the whole value.
      descendant(".dropdown-selected-text") {
        textAlign(.start)
        color(colorPlaceholder)
        minWidth(0)
      }
      fadeOverflow("& .dropdown-selected-text")
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
      // Trigger radius comes from ButtonView(borderRadius:)—do not override here
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
        // Placed over the page from a scrollport: its field's width, as a
        // phone's menu is.
        descendant(".dropdown-menu[data-placement='fixed']") {
          width((`var`("--dropdown-placed-width") as CSS.Length)).important()
          insetInlineStart((`var`("--dropdown-placed-start") as CSS.Length)).important()
          insetInlineEnd(.auto).important()
        }
      }
      // Placed over the page from a scrollport (`place()`): fixed at its
      // field's place on the screen, which the page writes as it moves.
      descendant(".dropdown-menu[data-placement='fixed']") {
        position(.fixed)
        top((`var`("--dropdown-placed-top") as CSS.Length))
        insetInlineStart((`var`("--dropdown-placed-start") as CSS.Length))
        insetInlineEnd(.auto)
        minWidth((`var`("--dropdown-placed-width") as CSS.Length))
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
      // The field's ring in red: its 1px border and a 1px outline, two
      // pixels in all without the border growing and moving the text.
      selector("&[data-invalid='true'] .dropdown-trigger") {
        borderColor(borderColorRed).important()
        outline(borderWidthBase, .solid, borderColorRed).important()
        outlineOffset(px(0)).important()
      }
      descendant(".dropdown-required-message") { display(.none) }
      selector("&[data-invalid='true'] .dropdown-required-message") {
        display(.block)
      }
      // Semi-bold, matching the field labels beside it. Bold made a dropdown
      // read as a heavier field than the text inputs it sits among.
      // The label and its tooltip in a row, 8px apart, as every field's.
      descendant(".dropdown-label") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
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
        borderBlockStart(borderWidthBase, .solid, borderColorBase)
        cursor(cursorBase)
      }
      descendant(".dropdown-search-input-wrapper") {
        padding(spacing8)
        borderBlockEnd(borderWidthBase, .solid, borderColorBase)
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
          selector(
            ".dropdown-option-display-text", ".dropdown-option-alt-text", ".breadcrumb-label-context",
            ".breadcrumb-separator-view"
          ) {
            color(colorInvertedFixed).important()
          }
        }
      }
      // In the open list an option wraps to as many lines as it needs: a
      // tap chooses it, nothing is cut or faded. It wraps between words
      // only, and only when the viewport is narrower than it (the menu is
      // as wide as its longest option): "anywhere" broke "transform/ation"
      // in a menu as narrow as its trigger. A word wider than the viewport
      // itself is the one that breaks.
      descendant(".dropdown-option-display-text") {
        flex(1)
        minWidth(0)
        whiteSpace(.normal)
        overflowWrap(.breakWord)
      }
      // A grouped list: each head a choice of its own, set in semibold, its
      // options indented under it.
      descendant(".dropdown-option[data-depth='0'] .dropdown-option-display-text") {
        fontWeight(fontWeightSemiBold)
      }
      descendant(".dropdown-option[data-depth='1']") {
        paddingInlineStart(spacing32)
      }
      descendant(".dropdown-option[data-stacked='true']") {
        flexDirection(.column)
        alignItems(.flexStart)
        gap(spacing2)
        padding(spacing12)
      }
      descendant(".dropdown-option[data-hidden='true']") { display(.none) }
      descendant(".dropdown-option[data-excluded='true']") { display(.none) }
      descendant(".dropdown-option[data-selected='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
      }
      selector(
        ".dropdown-option[data-selected='true'] .dropdown-option-display-text",
        ".dropdown-option[data-selected='true'] .dropdown-option-alt-text",
        ".dropdown-option[data-selected='true'] .breadcrumb-label-context",
        ".dropdown-option[data-selected='true'] .breadcrumb-separator-view"
      ) {
        color(colorInvertedFixed).important()
      }
      descendant(".dropdown-option[data-highlighted='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
      }
      selector(
        ".dropdown-option[data-highlighted='true'] .dropdown-option-display-text",
        ".dropdown-option[data-highlighted='true'] .dropdown-option-alt-text",
        ".dropdown-option[data-highlighted='true'] .breadcrumb-label-context",
        ".dropdown-option[data-highlighted='true'] .breadcrumb-separator-view"
      ) {
        color(colorInvertedFixed).important()
      }
      // Wrapped, not cut: the menu is the one place a long title is read
      // whole—the trigger above it is the one that ellipses.
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
        // At least as wide as its longest option on one line (and as its
        // trigger, or 250px beside a fixed-width trigger), never wider than
        // the viewport's page, its gutters aside: the options wrap only
        // when the viewport forces them to.
        if let mw = menuWidth {
          width(mw)
        } else if dropdownWidth != nil {
          width(.maxContent)
          minWidth(px(250))
        } else {
          width(.maxContent)
          minWidth(perc(100))
        }
        maxWidth(vw(100) - spacing16 * 2)
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
    /// Whether several options may be chosen (`DropdownView.multiple`).
    private var multiple = false
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

      // Read the real placeholder from its data attribute—not the current
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
      multiple = stringEquals(container.closest(".dropdown-view")?.getAttribute(data("multiple")) ?? "", "true")

      bindEvents()
    }

    /// Enforces `required` for this dropdown on its form's submit.
    ///
    /// Server-side guards stay—they are the real protection. This only makes
    /// the failure visible where the reader can fix it.
    private func bindRequiredValidation() {
      guard let input = hiddenInput as? HTML.HTMLInputElement,
        input.hasAttribute("required"),
        let _ = container,
        // Its form, as the platform's `form` property says: the one its
        // `form` attribute names, else the one it stands in.
        let form = FieldValidationHydration.owner(of: input)
      else { return }

      _ = form.addEventListener(.submit) { [self] (event: Event) in
        // Only a submit the reader made is checked. The page dispatches one
        // itself only to have the form's lists and statements written out
        // (a draft carried to an amendment, the outline's work form), and
        // marking an empty dropdown red there flashed on the way out.
        guard event.isTrusted else { return }
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
      applyExclusions()
      isOpen = true
      menu?.setAttribute(data("open"), true)
      _ = container?.classList.add("is-open")
      place()
      morphChevron()
      highlightIndex = -1
    }

    private func closeDropdown() {
      isOpen = false
      menu?.setAttribute(data("open"), false)
      _ = container?.classList.remove("is-open")
      unplace()
      morphChevron()
      (searchInput as? HTML.HTMLInputElement)?.value = ""
      filterOptions()  // Reset filter
    }

    private func morphChevron() {
      chevronInstance?.setState(expanded: isOpen, animated: true)
    }

    // MARK: - In a scrollport

    /// Whether the scroll and resize listeners that keep a placed menu by
    /// its field are bound.
    private var placementBound = false

    /// A dropdown in a scrollport—a box that scrolls sideways, as a deep
    /// tree does (`OutlinerView`), marked `data-scrollport`—would have its
    /// menu cut off at the box's edge, or scrolled inside it. There the open
    /// menu is placed over the page instead, under its field (fixed, at the
    /// field's place on the screen, at least its width), and kept there as
    /// anything scrolls or the window resizes. Anywhere else it hangs from
    /// the field as its stylesheet says.
    private func place() {
      guard let menu, let container, let _ = container.closest("[data-scrollport='true']"),
        let rect = container.getBoundingClientRect()
      else { return }
      menu.setAttribute(data("placement"), "fixed")
      menu.setStyleProperty("--dropdown-placed-top", stringJoin([intToString(Int(rect.bottom)), "px"], separator: ""))
      menu.setStyleProperty("--dropdown-placed-width", stringJoin([intToString(Int(rect.width)), "px"], separator: ""))
      // From the field's start: its left, or its right where the line runs
      // right to left.
      let rightToLeft = stringEquals(container.closest("[dir]")?.getAttribute("dir") ?? "", "rtl")
      let start = rightToLeft ? window.innerWidth - rect.right : rect.left
      menu.setStyleProperty("--dropdown-placed-start", stringJoin([intToString(Int(start)), "px"], separator: ""))
      // A menu hanging from its field scrolls with the page, so an option
      // below the screen's foot is scrolled to; a placed one stays put, so
      // the page is scrolled up to bring its foot on screen, as far as the
      // field's top allows. The scroll listener places it again.
      if let box = menu.getBoundingClientRect() {
        let overflow = box.bottom + 16 - window.innerHeight
        if overflow > 0 {
          let room = rect.top - 16
          window.scrollTo(window.scrollX, window.scrollY + (overflow < room ? overflow : max(room, 0)))
        }
      }
      guard !placementBound else { return }
      placementBound = true
      let follow: @Sendable (Event) -> Void = { [self] _ in
        guard self.isOpen else { return }
        self.place()
      }
      _ = document.addEventListener(Event.scroll, follow, capture: true, passive: true)
      _ = window.addEventListener("resize", follow, capture: false, passive: true)
    }

    /// Back to hanging from its field.
    private func unplace() {
      guard let menu else { return }
      menu.removeAttribute(data("placement"))
      for property in ["--dropdown-placed-top", "--dropdown-placed-width", "--dropdown-placed-start"] {
        menu.setStyleProperty(property, "")
      }
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
          || stringContainsCaseInsensitive(option.getAttribute(data("context")) ?? "", searchValue)
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
      var options: [DOM.Element] = []
      for option in answer.querySelectorAll("[data-dropdown-option=\"true\"]") {
        let selected = isChosen(option.getAttribute(data("value")) ?? "")
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
      applyExclusions()
      highlightIndex = -1
    }

    private func showOwnOptions() {
      resultsList?.setAttribute(.hidden, "")
      optionsList?.removeAttribute(.hidden)
      allOptions = ownOptions
      applyExclusions()
    }

    /// Marks the options the page withholds: values a page sets on the
    /// root as `data-excluded-values` (comma-separated) while it runs—an
    /// origin step's record, which another step already names. Such an
    /// option, its own or a search's, is neither shown nor reached by the
    /// keyboard; read afresh each time the menu shows.
    private func applyExclusions() {
      let listed = container?.closest(".dropdown-view")?.getAttribute(data("excluded-values")) ?? ""
      let excluded = stringIsEmpty(listed) ? [] : stringSplit(listed, separator: ",")
      for option in allOptions {
        let value = option.getAttribute(data("value")) ?? ""
        var out = false
        for other in excluded where stringEquals(other, value) { out = true }
        option.setAttribute(data("excluded"), out)
      }
    }

    /// The chosen values: the value input's, comma-separated when several
    /// may be chosen.
    private func chosenValues() -> [String] {
      let value = (hiddenInput as? HTML.HTMLInputElement)?.value ?? ""
      if stringIsEmpty(value) { return [] }
      return multiple ? stringSplit(value, separator: ",") : [value]
    }

    private func isChosen(_ value: String) -> Bool {
      if stringIsEmpty(value) { return false }
      for chosen in chosenValues() where stringEquals(chosen, value) { return true }
      return false
    }

    /// Several may be chosen: the option toggled in or out, the names shown
    /// in the order chosen, the menu kept open.
    private func toggleOption(_ option: DOM.Element) {
      guard let value = option.getAttribute(data("value")) else { return }
      var values: [String] = []
      var removed = false
      for chosen in chosenValues() {
        if stringEquals(chosen, value) { removed = true } else { values.append(chosen) }
      }
      if !removed { values.append(value) }
      (hiddenInput as? HTML.HTMLInputElement)?.value = stringJoin(values, separator: ",")
      if let container {
        (container.closest(".dropdown-view") ?? container).removeAttribute("data-invalid")
      }
      var names: [String] = []
      for chosen in values {
        for opt in ownOptions + resultOptions where stringEquals(opt.getAttribute(data("value")) ?? "", chosen) {
          names.append(opt.getAttribute(data("display")) ?? chosen)
          break
        }
      }
      let shown = stringJoin(names, separator: ", ")
      selectedText?.innerHTML = values.isEmpty ? placeholder : shown
      if values.isEmpty { selectedText?.removeAttribute(.title) } else { selectedText?.setAttribute(.title, shown) }
      selectedText?.setAttribute(data("selected"), !values.isEmpty)
      selectedText?.scrollLeft = 0
      for opt in ownOptions + resultOptions {
        let chosen = isChosen(opt.getAttribute(data("value")) ?? "")
        if chosen { _ = opt.classList.add("is-selected") } else { _ = opt.classList.remove("is-selected") }
        opt.setAttribute(data("selected"), chosen)
      }
      if let hiddenInput {
        hiddenInput.dispatchEvent(.change)
      }
    }

    private func selectOption(_ option: DOM.Element) {
      if multiple {
        toggleOption(option)
        return
      }
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

      // Update selected text and title (tooltip): an option with a context
      // shows its breadcrumb label, as the server draws a chosen one.
      if let label = option.querySelector(".breadcrumb-label-view") {
        selectedText?.innerHTML = ""
        selectedText?.appendChild(label.cloneNode(deep: true))
      } else {
        selectedText?.innerHTML = display
      }
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
        if !stringEquals(allOptions[highlightIndex].getAttribute(data("hidden")) ?? "", "true")
          && !stringEquals(allOptions[highlightIndex].getAttribute(data("excluded")) ?? "", "true")
        {
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
