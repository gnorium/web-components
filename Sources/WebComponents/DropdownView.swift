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
    /// Its number in a tree, drawn before `display` as a tree row's is
    /// (mono, subtle, a "." after it): "1.2. a fine word" (user,
    /// 2026-11-02). The closed dropdown shows it the same way. Nil for an
    /// option with no number.
    public let number: String?

    public init(
      value: String, context: String? = nil, display: String, altDisplay: String? = nil,
      displayLower: String? = nil, depth: Int? = nil, number: String? = nil
    ) {
      self.value = value
      self.context = context
      self.display = display
      self.altDisplay = altDisplay
      self.displayLower = displayLower
      self.depth = depth
      self.number = number
    }
  }

  /// An option's number, then its display (`DropdownOption.number`): the
  /// open list's and the closed dropdown's alike. The space is the spacing
  /// on one line (inline flow has no gap); the open list sets them side by
  /// side, its value wrapping beside the number as a tree row's does.
  static func numberedLabel(number: String, display: String) -> DOM.Node {
    span {
      span { number }
        .class("dropdown-option-number")
      " "
      span { display }
        .class("dropdown-numbered-text")
    }
    .class("dropdown-numbered-label")
    .build()
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
  let buttonBorderRadius: ButtonView.ButtonRadius
  let submitFormOnChange: Bool
  /// The id of the form its value submits with, when it sits outside that
  /// form.
  let form: String?
  /// Where its search asks for options, when the server holds too many to
  /// send: typing asks `searchURL?q=…` (debounced, a late answer to an
  /// earlier query dropped) and shows the options of the dropdown the
  /// answer holds in place of its own; an empty query shows its own again.
  /// While the latest query's answer is on its way, the open menu shows a
  /// wait under the options it shows, and one that fails says so in the
  /// wait's place, those options kept (`OptionsStatusView`); the next
  /// keystroke, or the next open, asks again. An earlier query's answer,
  /// or its failure, says nothing.
  let searchURL: String?
  /// Where its own list comes from, when the page draws only its chosen
  /// options (every language: user, 2026-11-05): on its first open it asks
  /// `listURL`, once a page however many dropdowns ask the same, and lists
  /// the options of the dropdown the answer holds after its own (those it
  /// holds already left out), the answer's note after them. While it is on
  /// its way, the open menu shows a wait under the options it draws; one
  /// that fails says so in the wait's place (`OptionsStatusView`), and the
  /// next open asks again (user, 2026-11-05).
  let listURL: String?
  /// Whether the label carries the lighter "(optional)" aside after its
  /// text, as LabelView draws it: not part of the label text.
  let optional: Bool
  let optionalFlag: String
  /// What stands after the label's text (and its "(optional)"), before
  /// its tooltip: a record page's reference marks. Not label text.
  let labelMarks: [DOM.Node]
  /// A line at the end of the menu that is not an option: what the list
  /// leaves out ("Showing the first 100.", `PaginationView.perList`). A
  /// remote search's answer brings its own, as does the list `listURL` gives.
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
    buttonSize: ButtonView.ButtonSize = .large,
    fullWidth: Bool = true,
    width: CSS.Length? = nil,
    menuWidth: CSS.Length? = nil,
    fontSize: CSS.Length = fontSizeMedium16,
    contentJustifyContent: CSS.JustifyContent = .spaceBetween,
    optionLayout: OptionLayout = .inline,
    buttonBorderRadius: ButtonView.ButtonRadius = .base,
    submitFormOnChange: Bool = false,
    form: String? = nil,
    searchURL: String? = nil,
    listURL: String? = nil,
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
    self.listURL = listURL
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
              IconView(icon: { size in InfoIconView(size: size) }, size: sizeIconSmall)
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
          ? (chosenNames.isEmpty ? placeholder : EnglishList.joined(chosenNames))
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
              } else if let option = selectedOption, let number = option.number {
                Self.numberedLabel(number: number, display: option.display)
              } else {
                displayText
              }
            }
              .class("dropdown-selected-text")
              .data("dropdown-selected-text", true)
            // One line, faded at an edge that hides some of it and
            // scrolling sideways (`edgeFadeView`); the open list shows it
            // whole.
            .data("edge-fade-view", true)
              .data("placeholder", placeholder)
              .data(
                "selected",
                multiple
                  ? !chosenNames.isEmpty
                  : (selectedValue.map { value in options.contains { stringEquals($0.value, value) } } ?? false))
              .data("disabled", disabled)
              .data("stacked", optionLayout == .stacked)
              .title(options.first { stringEquals($0.value, selectedValue ?? "") }?.altDisplay ?? displayText)

            // Animated chevron icon, beside the value's text: the text's
            // size, as an icon beside a label is (user, 2026-11-05).
            AnimatedUpDownChevronView(
              id: "dropdown-\(id)",
              expanded: false,
              size: textFontSize,
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
          // The site's search box; the menu's own hydration drives it
          // (filtering, arrows, Enter, focus on open, clearing on close).
          // Medium whatever the dropdown's size: 40 tall, its text 16px.
          div {
            SearchInputView(
              size: .medium, placeholder: "Search", class: "dropdown-search-input", standalone: false)
          }
          .class("dropdown-search-input-wrapper")
          .data("dropdown-search", true)

          // Options list
          div {
            options.map { option in
              let isSelected = isChosen(option.value)
              return div {
                // Several may be chosen: each option's checkbox says whether
                // it is, as a multiselect menu's item does (`MenuItemView`).
                // The hover fill is the selected fill, so without it a
                // toggle under the pointer showed no change at all.
                if multiple {
                  span {
                    span().class("dropdown-option-checkmark").ariaHidden(true)
                  }
                  .class("dropdown-option-checkbox")
                }
                span {
                  if let context = option.context {
                    BreadcrumbLabelView(context: context, text: option.display)
                  } else if let number = option.number {
                    Self.numberedLabel(number: number, display: option.display)
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
              .data("number", option.number ?? "")
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

          // Its list or a search on its way from the server, or failed:
          // said under the options it shows (`OptionsStatusView`). A
          // search's answer goes before it, in the place of its own list.
          if !stringIsEmpty(listURL ?? "") || !stringIsEmpty(searchURL ?? "") {
            OptionsStatusView()
          }
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
    .data("fixed-width", dropdownWidth != nil ? "true" : "false")
    .data("menu-width", menuWidth != nil ? "custom" : (dropdownWidth != nil ? "beside-fixed-trigger" : "auto"))
    .data("search-url", searchURL ?? "")
    .data("list-url", listURL ?? "")
    .data("multiple", multiple)
    .style {
      // This dropdown's own sizes, per instance: the shared rules below
      // read them, and are keyed by the data attributes on the root.
      customProperty("--dropdown-font-size", textFontSize.value)
      if let w = dropdownWidth {
        customProperty("--dropdown-width", w.value)
      }
      if let mw = menuWidth {
        customProperty("--dropdown-menu-width", mw.value)
      }

      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
      }
      selector("&[data-full-width='true']") {
        width(perc(100))
      }
      media(maxWidth(maxWidthBreakpointMobile)) {
        selector("&[data-full-width='false']") {
          width(perc(100)).important()
        }
      }
      descendant(".field-label") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        fontSize(`var`("--dropdown-font-size") as CSS.Length)
        fontWeight(600)
        color(colorBase)
        fontFamily(typographyFontSans)
      }
      // One line, held inside the trigger, fading out at its end when it
      // runs past it (`edgeFadeView`): no tap-to-expand, no ellipsis—the
      // open list shows the whole value.
      // A field's text at every size: a large trigger's 18px is a
      // button's, not a field's.
      descendant(".dropdown-selected-text") {
        fontSize(`var`("--dropdown-font-size") as CSS.Length)
        textAlign(.start)
        color(colorPlaceholder)
        minWidth(0)
      }
      edgeFadeView("& .dropdown-selected-text")
      // The text gives way, not the chevron: beside a cut title it was
      // squeezed to a sliver.
      descendant(".dropdown-chevron") {
        flexShrink(0)
      }
      // A value chosen reads in the base color, disabled or not, as every
      // disabled field's value does; none chosen, the placeholder's.
      descendant(".dropdown-selected-text[data-selected='true']") { color(colorBase) }
      // Only when it is narrow. `stacked` describes the OPTIONS; a full-width
      // trigger has room for the whole title and was cutting it to "An
      // Anglo-Saxon Dic...".
      selector("&:not([data-full-width='true']) .dropdown-selected-text[data-stacked='true']") {
        maxWidth(px(160))
      }
      descendant(".dropdown-trigger-wrapper") {
        width(.fitContent)
        display(.flex)
        flex(1)
        justifyContent(.spaceBetween)
      }
      selector("&[data-full-width='true'] .dropdown-trigger-wrapper") {
        width(perc(100))
      }
      // After the full-width rule: a fixed width wins.
      selector("&[data-fixed-width='true'] .dropdown-trigger-wrapper") {
        width(`var`("--dropdown-width") as CSS.Length)
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
      // Matches LabelView, which every FieldView label uses: a dropdown in a
      // form is a form field and its label has to look like one.
      // A medium trigger is a form FIELD, and a medium button already is
      // one: inset 8 inside its border on every side, on a 22px line, 40.
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
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        color(colorBase)
      }
      // An aside affixed to the label, not label text: LabelView's
      // `.label-optional-flag`.
      descendant(".dropdown-optional-flag") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
      // Not an option: no hover, no pointer, never chosen. At least a
      // one-line option's height (48), its line centered in it, never left
      // at the top with the spare height below it.
      descendant(".dropdown-note") {
        display(.flex)
        alignItems(.center)
        padding(spacing8)
        minHeight(ButtonView.ButtonSize.large.minSize)
        boxSizing(.borderBox)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorSubtle)
        cursor(cursorBase)
        position(.relative)
      }
      // Its rule above it drawn over its top edge, not as a border, so the
      // row keeps a one-line option's measure, 48, its text on the options'
      // inset in every list (user, 2026-11-03).
      descendant(".dropdown-note::before") {
        content("\"\"")
        position(.absolute)
        insetBlockStart(0)
        insetInlineStart(0)
        insetInlineEnd(0)
        height(borderWidthBase)
        backgroundColor(borderColorSubtle)
      }
      ButtonView.phoneStepRowCSS(".dropdown-note", ".dropdown-option")
      // Its search box is as tall as the trigger it hangs from: medium, 40,
      // on a phone, not the step below that a lone medium box takes.
      media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
        selector("\(ButtonView.phoneStep) & .dropdown-search-input[data-size='medium']") {
          customProperty("--search-input-padding", ButtonView.ButtonSize.medium.padding.value).important()
        }
        selector(
          "\(ButtonView.phoneStep) & .dropdown-search-input[data-size='medium'] .search-input",
          "\(ButtonView.phoneStep) & .dropdown-search-input[data-size='medium'] .search-input-button"
        ) {
          fontSize(fontSizeMedium16).important()
        }
      }
      descendant(".dropdown-search-input-wrapper") {
        padding(spacing8)
        borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
      }
      descendant(".dropdown-option") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        // A row: 8 on every side of its 22px line, at least the large
        // control's 48 (user, 2026-10-21), as the field it hangs from.
        padding(spacing8)
        minHeight(ButtonView.ButtonSize.large.minSize)
        lineHeight(lineHeightSmall22)
        boxSizing(.borderBox)
        fontSize(`var`("--dropdown-font-size") as CSS.Length)
        color(colorBase)
        backgroundColor(backgroundColorTransparent)
        cursor(cursorBaseHover)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        pseudoClass(.hover) {
          backgroundColor(backgroundColorBlue).important()
          color(colorOnSolid).important()
          selector(
            ".dropdown-option-display-text", ".dropdown-option-alt-text", ".breadcrumb-label-context",
            ".breadcrumb-separator-view", ".dropdown-option-number"
          ) {
            color(colorOnSolid).important()
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
      // A numbered option's number, as a tree row's (`.record-node-number`):
      // sans, subtle, a "." after it; white on a solid blue row as the
      // other secondary texts are.
      descendant(".dropdown-option-number") {
        fontFamily(typographyFontSans)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
      descendant(".dropdown-option-number::after") {
        content("\".\"")
      }
      // In the open list the number stands beside its value, which wraps
      // in a column of its own.
      descendant(".dropdown-option-display-text .dropdown-numbered-label") {
        display(.flex)
        alignItems(.baseline)
        gap(spacing8)
      }
      descendant(".dropdown-option-display-text .dropdown-option-number") {
        flexShrink(0)
      }
      descendant(".dropdown-option-display-text .dropdown-numbered-text") {
        flex(1)
        minWidth(0)
      }
      // A grouped list: each head a choice of its own, set in semibold, its
      // options indented under it.
      descendant(".dropdown-option[data-depth='0'] .dropdown-option-display-text") {
        fontWeight(fontWeightSemiBold)
      }
      descendant(".dropdown-option[data-depth='1']") {
        paddingInlineStart(spacing32)
      }
      // Two lines on the one-line row's inset, 4 apart: 8 + 22 + 4 + 22 + 8
      // = 64, twice the 32 step of the size scale (user, 2026-11-03).
      descendant(".dropdown-option[data-stacked='true']") {
        flexDirection(.column)
        alignItems(.flexStart)
        gap(spacing4)
        padding(spacing8)
      }
      descendant(".dropdown-option[data-hidden='true']") { display(.none) }
      descendant(".dropdown-option[data-excluded='true']") { display(.none) }
      // One chosen: its row filled. Several: each row's checkbox says it.
      selector("&[data-multiple='false'] .dropdown-option[data-selected='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorOnSolid).important()
      }
      selector(
        "&[data-multiple='false'] .dropdown-option[data-selected='true'] .dropdown-option-display-text",
        "&[data-multiple='false'] .dropdown-option[data-selected='true'] .dropdown-option-alt-text",
        "&[data-multiple='false'] .dropdown-option[data-selected='true'] .breadcrumb-label-context",
        "&[data-multiple='false'] .dropdown-option[data-selected='true'] .breadcrumb-separator-view",
        "&[data-multiple='false'] .dropdown-option[data-selected='true'] .dropdown-option-number"
      ) {
        color(colorOnSolid).important()
      }
      // A checkbox's box and mark, as CheckboxView's: square (the minimal
      // radius), its border the control's, blue with a white tick when on.
      descendant(".dropdown-option-checkbox") {
        display(.inlineBlock)
        position(.relative)
        width(minSizeInputBinary)
        height(minSizeInputBinary)
        flexShrink(0)
        border(borderWidthBase, .solid, borderColorInputBinary)
        borderRadius(borderRadiusMinimal)
        backgroundColor(backgroundColorBase)
        boxSizing(.borderBox)
      }
      descendant(".dropdown-option[data-selected='true'] .dropdown-option-checkbox") {
        backgroundColor(backgroundColorInputBinaryChecked)
        borderColor(borderColorInputBinaryChecked)
      }
      // On a solid blue row (highlighted or under the pointer) the box
      // inverts: unchecked, a white edge on the blue; checked, white filled
      // with the tick in the row's blue.
      selector(
        "& .dropdown-option[data-highlighted='true'] .dropdown-option-checkbox",
        "& .dropdown-option:hover .dropdown-option-checkbox"
      ) {
        backgroundColor(backgroundColorTransparent)
        borderColor(borderColorInvertedFixed)
      }
      selector(
        "& .dropdown-option[data-highlighted='true'][data-selected='true'] .dropdown-option-checkbox",
        "& .dropdown-option[data-selected='true']:hover .dropdown-option-checkbox"
      ) {
        backgroundColor(backgroundColorBaseFixed)
      }
      selector(
        "& .dropdown-option[data-highlighted='true'] .dropdown-option-checkmark",
        "& .dropdown-option:hover .dropdown-option-checkmark"
      ) {
        borderRightColor(backgroundColorBlue)
        borderBottomColor(backgroundColorBlue)
      }
      descendant(".dropdown-option-checkmark") {
        display(.none)
        position(.absolute)
        top(perc(50))
        left(perc(50))
        width(px(5))
        height(px(10))
        borderRight(px(2), .solid, colorOnSolid)
        borderBottom(px(2), .solid, colorOnSolid)
        transform(translate(perc(-50), perc(-60)), rotate(deg(45)))
      }
      descendant(".dropdown-option[data-selected='true'] .dropdown-option-checkmark") {
        display(.block)
      }
      descendant(".dropdown-option[data-highlighted='true']") {
        backgroundColor(backgroundColorBlue).important()
        color(colorOnSolid).important()
      }
      selector(
        ".dropdown-option[data-highlighted='true'] .dropdown-option-display-text",
        ".dropdown-option[data-highlighted='true'] .dropdown-option-alt-text",
        ".dropdown-option[data-highlighted='true'] .breadcrumb-label-context",
        ".dropdown-option[data-highlighted='true'] .breadcrumb-separator-view",
        ".dropdown-option[data-highlighted='true'] .dropdown-option-number"
      ) {
        color(colorOnSolid).important()
      }
      // Wrapped, not cut: the menu is the one place a long title is read
      // whole—the trigger above it is the one that ellipses.
      descendant(".dropdown-option-display-text[data-stacked='true']") {
        fontWeight(fontWeightSemiBold)
        fontSize(fontSizeMedium16)
        color(colorBase)
        overflowWrap(.breakWord)
        width(perc(100))
      }
      descendant(".dropdown-option-alt-text[data-stacked='true']") {
        fontSize(fontSizeMedium16)
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
        width(.maxContent)
        minWidth(perc(100))
        maxWidth(vw(100) - spacing16 * 2)
        marginBlockStart(spacing4)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorSubtle)
        borderRadius(borderRadiusBase)
        boxShadow(boxShadowMedium)
        zIndex(zIndexDropdown)
        display(.none)
        overflow(.hidden)
      }
      // Beside a fixed-width trigger: 250px at least, not the trigger's width.
      selector("&[data-menu-width='beside-fixed-trigger'] .dropdown-menu") {
        minWidth(px(250))
      }
      selector("&[data-menu-width='custom'] .dropdown-menu") {
        width(`var`("--dropdown-menu-width") as CSS.Length)
        minWidth(0)
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
          borderColor(borderColorBlueFocus).important()
          outline(borderWidthBase, .solid, borderColorBlueFocus).important()
          outlineOffset(px(0)).important()
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
    /// Its own options: those the page drew, any chosen search option kept
    /// first (`keepChosen`), the list `listURL` gives after them.
    private var ownOptions: [DOM.Element] = []
    /// A remote search's answer, shown in place of its own list.
    private var resultsList: DOM.Element?
    private var resultOptions: [DOM.Element] = []
    /// The search answer's note, after its options.
    private var resultNote: DOM.Element?
    /// Whether a search's answer shows in place of its own list.
    private var showingResults = false
    private var searchURL: String = ""
    /// Where its own list comes from on its first open
    /// (`DropdownView.listURL`); empty once the list is in.
    private var listURL: String = ""
    /// Whether its list is asked for and not yet in.
    private var listAsked = false
    /// Whether its list's last ask failed, until the next open asks again.
    private var listFailed = false
    /// What it says under the options it shows (`OptionsStatusView`): the
    /// wait for, or the failure of, its list or the latest query's answer.
    private var status: DOM.Element?
    /// Its stable node id, which the page names it by
    /// (`DropdownHydration.option`).
    private(set) var rootID: Int32 = 0
    /// Whether several options may be chosen (`DropdownView.multiple`).
    private var multiple = false
    private var searchTimer: Int32 = 0
    /// Which query is the latest: an answer overtaken by a later one is
    /// dropped.
    private var searchSequence = 0
    /// Whether a query is typed in its search: what it says under the
    /// options is then the search's, not its list's.
    private var hasQuery = false
    /// Whether the latest query's answer is on its way.
    private var searchBusy = false
    /// Whether the latest query's answer failed.
    private var searchFailed = false
    private var placeholder: String = "Select an option"

    private var highlightIndex: Int = -1

    init(container: DOM.Element, dropdownID: String) {
      self.container = container
      trigger = container.querySelector("[data-dropdown-trigger=\"true\"]")
      menu = container.querySelector("[data-dropdown-menu=\"true\"]")
      status = menu?.querySelector(":scope > .options-status-view")
      searchInput = container.querySelector("[data-dropdown-search=\"true\"] .search-input")
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
      let root = container.closest(".dropdown-view")
      rootID = root?.id ?? container.id
      searchURL = root?.getAttribute(data("search-url")) ?? ""
      listURL = root?.getAttribute(data("list-url")) ?? ""
      multiple = stringEquals(root?.getAttribute(data("multiple")) ?? "", "true")
      // One that searches the server can be asked for an option it does
      // not list (`DropdownHydration.option`).
      if !stringIsEmpty(searchURL) { DropdownHydration.searching.append(self) }

      showValue()
      bindEvents()
    }

    /// The trigger and the options showing the value input's choice where
    /// the page drew another. A browser that restores a page's form state (a
    /// tab reopened or brought back, a history entry; Firefox on a reload)
    /// puts a hidden input's value back before the page hydrates, as it does
    /// a select's: the field showed the choice the page drew and posted the
    /// one put back, and a kept draft's restore, finding its value already
    /// there, chose nothing (Submit Testament's Carrier, user 2026-11-03). A
    /// value no option of its own has (a search's) is shown once its search
    /// finds it (`option(_:then:)`), one chosen alone; any other leaves it
    /// as drawn.
    private func showValue() {
      let values = chosenValues()
      var drawn: [String] = []
      for option in optionsList?.querySelectorAll("[data-dropdown-option=\"true\"][data-selected=\"true\"]") ?? [] {
        drawn.append(option.getAttribute(data("value")) ?? "")
      }
      guard !stringEquals(stringJoin(drawn, separator: ","), stringJoin(values, separator: ",")) else { return }
      var chosen: [DOM.Element] = []
      for value in values {
        guard let option = ownOptions.first(where: { stringEquals($0.getAttribute(data("value")) ?? "", value) })
        else {
          guard !multiple, !stringIsEmpty(searchURL) else { return }
          self.option(value) { [self] found in
            // Still its value once found: a choice made meanwhile stands.
            guard self.isChosen(value) else { return }
            self.show([found])
            self.markChosen()
          }
          return
        }
        chosen.append(option)
      }
      show(chosen)
      markChosen()
    }

    /// The option of `value`, as soon as it has one: at once where it lists
    /// it; else, where it searches the server, once its search for `value`
    /// finds the option of exactly that value, kept in its own list, first,
    /// as a chosen search option is (`keepChosen`). A value the search does
    /// not find has none.
    func option(_ value: String, then: @escaping @Sendable (DOM.Element) -> Void) {
      if let option = listed(value) {
        then(option)
        return
      }
      guard !stringIsEmpty(value), !stringIsEmpty(searchURL) else { return }
      let url = stringJoin(
        [searchURL, stringContains(searchURL, "?") ? "&q=" : "?q=", encodeURIComponent(value)], separator: "")
      let answer = document.createElement(.div)
      answer.loadFragment(url) { [self] ok in
        guard ok else { return }
        // Listed meanwhile (its list, or a search, came in): that one.
        if let option = self.listed(value) {
          then(option)
          return
        }
        for found in answer.querySelectorAll("[data-dropdown-option=\"true\"]")
        where stringEquals(found.getAttribute(data("value")) ?? "", value) {
          found.setAttribute(data("hidden"), false)
          self.listFirst([found])
          self.bindOptions([found])
          self.markChosen()
          then(found)
          return
        }
      }
    }

    /// The option of `value` it shows now or has shown, its own or a
    /// search's.
    private func listed(_ value: String) -> DOM.Element? {
      for option in ownOptions + resultOptions where stringEquals(option.getAttribute(data("value")) ?? "", value) {
        return option
      }
      return nil
    }

    /// The trigger showing the options `chosen`, as the server draws them:
    /// one, its label (an option with a context its breadcrumb label, one
    /// with a number its numbered label); several, their names in the order
    /// chosen; none, the placeholder.
    private func show(_ chosen: [DOM.Element]) {
      if !multiple, let option = chosen.first {
        let display = option.getAttribute(data("display")) ?? ""
        if let label = option.querySelector(".breadcrumb-label-view") ?? option.querySelector(".dropdown-numbered-label") {
          selectedText?.innerHTML = ""
          selectedText?.appendChild(label.cloneNode(deep: true))
        } else {
          selectedText?.innerHTML = display
        }
        // Its tooltip, its alternative name where it has one.
        let alt = option.getAttribute(data("alt-display")) ?? ""
        selectedText?.setAttribute(.title, stringIsEmpty(alt) ? display : alt)
      } else {
        var names: [String] = []
        for option in chosen { names.append(option.getAttribute(data("display")) ?? "") }
        let shown = EnglishList.joined(names)
        selectedText?.innerHTML = chosen.isEmpty ? placeholder : shown
        if chosen.isEmpty { selectedText?.removeAttribute(.title) } else { selectedText?.setAttribute(.title, shown) }
      }
      selectedText?.setAttribute(data("selected"), !chosen.isEmpty)
      // A new title starts at its beginning, wherever the last was scrolled to.
      selectedText?.scrollLeft = 0
    }

    /// Every option of a chosen value marked chosen in the menu, its own
    /// or a search's (a value can be both: a listed language a search
    /// found), every other not.
    private func markChosen() {
      for opt in ownOptions + resultOptions {
        let isIn = isChosen(opt.getAttribute(data("value")) ?? "")
        if isIn { _ = opt.classList.add("is-selected") } else { _ = opt.classList.remove("is-selected") }
        opt.setAttribute(data("selected"), isIn)
      }
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
        // What the menu shows chosen is what posts: a hidden value that
        // lost its choice is put back from the option marked chosen.
        if let field = self.hiddenInput as? HTML.HTMLInputElement, stringIsEmpty(field.value), !self.multiple {
          for option in self.ownOptions + self.resultOptions
          where stringEquals(option.getAttribute(data("selected")) ?? "", "true") {
            field.value = option.getAttribute(data("value")) ?? ""
            break
          }
        }
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

      // Toggle dropdown on trigger click. A link in the value it shows (a
      // citation's claim, leading to its field) is a link: a click on its
      // words follows it, one anywhere else on the trigger opens the menu.
      _ = trigger.addEventListener(.click) { [self] event in
        if let target = event.target, let _ = target.closest("a[href]") { return }
        self.toggleDropdown()
      }

      // The label points at the hidden value input, which cannot take the
      // focus: a click on it focuses the trigger and opens nothing, as a
      // native select's label does. One that ends selecting the label's
      // words (to copy them) leaves the focus, and the selection, alone.
      // A link in the label's words (a claimed field's, a citation's
      // Claim) is a link: it leads where it points, the field left alone.
      if let label = container?.closest(".dropdown-view")?.querySelector(".dropdown-label") {
        _ = label.addEventListener(.click) { [self] event in
          if let target = event.target, let _ = target.closest("a[href]") { return }
          event.preventDefault()
          if let selection = window.getSelection(), !selection.isCollapsed { return }
          (self.trigger?.querySelector("button") ?? self.trigger)?.focus()
        }
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
        } else if stringEquals(event.key, "Escape") {
          // Closed, as a native select's list is, the focus back on the
          // field; a dialog it stands in stays open.
          event.preventDefault()
          event.stopPropagation()
          self.closeDropdown()
          (self.trigger?.querySelector("button") ?? self.trigger)?.focus()
        }
      }
    }

    /// Click and hover on each option. Its place is read in the list that
    /// shows it as it is hovered: a chosen search option moves into its
    /// own list (`keepChosen`).
    private func bindOptions(_ options: [DOM.Element]) {
      for option in options {
        _ = option.addEventListener(.click) { [self] _ in
          self.selectOption(option)
        }
        _ = option.addEventListener(.mousemove) { [self] _ in
          guard let i = self.allOptions.firstIndex(where: { $0.id == option.id }), self.highlightIndex != i
          else { return }
          if self.highlightIndex >= 0, self.highlightIndex < self.allOptions.count {
            self.allOptions[self.highlightIndex].setAttribute(data("highlighted"), false)
          }
          self.highlightIndex = i
          option.setAttribute(data("highlighted"), true)
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
      takeList()
      applyExclusions()
      isOpen = true
      menu?.setAttribute(data("open"), true)
      _ = container?.classList.add("is-open")
      place()
      morphChevron()
      highlightIndex = -1
      // Typing goes to the menu's search at once, not to the field that had
      // the focus before the trigger was clicked. The page stays where it is.
      searchInput?.focus(DOM.FocusOptions(preventScroll: true))
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
          || stringContainsCaseInsensitive(option.getAttribute(data("number")) ?? "", searchValue)
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
    /// The wait shows under the options it shows from the key on, until
    /// that answer is in; one that fails says so in the wait's place, the
    /// options it shows kept (as its list's failure keeps its own), and the
    /// next key asks again. An earlier query's answer, or its failure, says
    /// nothing and ends no wait.
    private func searchRemotely(_ query: String) {
      if searchTimer != 0 {
        clearTimeout(searchTimer)
        searchTimer = 0
      }
      searchSequence += 1
      highlightIndex = -1
      searchFailed = false
      hasQuery = !stringIsEmpty(query)
      searchBusy = hasQuery
      if !hasQuery {
        showOwnOptions()
        showStatus()
        return
      }
      showStatus()
      let asked = searchSequence
      let url = stringJoin(
        [searchURL, stringContains(searchURL, "?") ? "&q=" : "?q=", encodeURIComponent(query)], separator: "")
      searchTimer = setTimeout(250) { [self] in
        self.searchTimer = 0
        // The answer is a dropdown: loaded aside, its options taken.
        let answer = document.createElement(.div)
        answer.loadFragment(url) { [self] ok in
          guard asked == self.searchSequence else { return }
          self.searchBusy = false
          // Why it failed is the bridge's to log.
          self.searchFailed = !ok
          if ok { self.showResults(from: answer) }
          self.showStatus()
        }
      }
    }

    /// Says, under the options it shows, the wait for or the failure of the
    /// answer they wait on (`OptionsStatusView`): the latest query's while
    /// one is typed, its list's otherwise.
    private func showStatus() {
      let state: OptionsStatusView.State
      if hasQuery {
        state = searchFailed ? .failed : (searchBusy ? .busy : .idle)
      } else {
        state = listFailed ? .failed : (listAsked ? .busy : .idle)
      }
      OptionsStatusView.show(state, in: status)
    }

    private func showResults(from answer: DOM.Element) {
      keepChosen()
      let results: DOM.Element
      if let resultsList {
        results = resultsList
      } else {
        results = document.createElement(.div)
        _ = results.classList.add("dropdown-options-list")
        results.setAttribute(data("dropdown-results"), true)
        // In its own list's place, before what it says under them.
        if let status { menu?.insertBefore(results, status) } else { menu?.appendChild(results) }
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
      showingResults = true
      applyExclusions()
      highlightIndex = -1
    }

    private func showOwnOptions() {
      keepChosen()
      resultsList?.setAttribute(.hidden, "")
      optionsList?.removeAttribute(.hidden)
      allOptions = ownOptions
      showingResults = false
      applyExclusions()
    }

    /// The chosen options a search found that its own list lacks, moved
    /// into its own list, first (user, 2026-11-05): the next answer
    /// replaces a search's options, and a choice stays in the list—where
    /// what reads it finds it (the origin sentence, its language's name),
    /// and shown before a search.
    private func keepChosen() {
      var kept: [DOM.Element] = []
      var found: [DOM.Element] = []
      for option in resultOptions {
        let value = option.getAttribute(data("value")) ?? ""
        let listed = ownOptions.contains { stringEquals($0.getAttribute(data("value")) ?? "", value) }
        if isChosen(value) && !listed { kept.append(option) } else { found.append(option) }
      }
      guard !kept.isEmpty else { return }
      resultOptions = found
      listFirst(kept)
    }

    /// `options` moved to the head of its own list, before every option it
    /// lists (`ownOptions`).
    private func listFirst(_ options: [DOM.Element]) {
      guard let optionsList else { return }
      let first = ownOptions.first
      for option in options {
        option.setAttribute(data("highlighted"), false)
        if let first, let list = first.parentElement {
          list.insertBefore(option, first)
        } else if let note = optionsList.querySelector(":scope > [data-dropdown-note=\"true\"]") {
          optionsList.insertBefore(option, note)
        } else {
          optionsList.appendChild(option)
        }
      }
      ownOptions = options + ownOptions
      if !showingResults { allOptions = ownOptions }
    }

    /// Its own list asked for (`listURL`), on its first open: once a page
    /// for every dropdown that asks the same (`SharedLists`). The wait
    /// shows under its options until the list is in; a failed answer is
    /// said in the wait's place (`OptionsStatusView`; the bridge logs why)
    /// and asked again on the next open, which takes the message away while
    /// it waits; once the list is in it never shows again.
    private func takeList() {
      guard !stringIsEmpty(listURL), !listAsked else { return }
      listAsked = true
      listFailed = false
      showStatus()
      SharedLists.take(listURL) { [self] answer in
        self.listAsked = false
        if let answer {
          self.listURL = ""
          self.adopt(list: answer)
        } else {
          self.listFailed = true
        }
        self.showStatus()
      }
    }

    /// The options of the list `answer` holds, each a copy (every dropdown
    /// asking the same list takes its own), listed after its own—one of a
    /// value it lists already left out—with the answer's note after them,
    /// before any note of its own.
    private func adopt(list answer: DOM.Element) {
      guard let optionsList else { return }
      let ownNote = optionsList.querySelector(":scope > [data-dropdown-note=\"true\"]")
      var added: [DOM.Element] = []
      for source in answer.querySelectorAll("[data-dropdown-option=\"true\"]") {
        let value = source.getAttribute(data("value")) ?? ""
        if ownOptions.contains(where: { stringEquals($0.getAttribute(data("value")) ?? "", value) }) { continue }
        let option = source.cloneNode(deep: true)
        option.setAttribute(data("hidden"), false)
        if let ownNote { optionsList.insertBefore(option, ownNote) } else { optionsList.appendChild(option) }
        added.append(option)
      }
      if ownNote == nil, let note = answer.querySelector("[data-dropdown-note=\"true\"]") {
        optionsList.appendChild(note.cloneNode(deep: true))
      }
      ownOptions = ownOptions + added
      bindOptions(added)
      markChosen()
      if !showingResults {
        allOptions = ownOptions
        applyExclusions()
      }
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
      let shown = EnglishList.joined(names)
      selectedText?.innerHTML = values.isEmpty ? placeholder : shown
      if values.isEmpty { selectedText?.removeAttribute(.title) } else { selectedText?.setAttribute(.title, shown) }
      selectedText?.setAttribute(data("selected"), !values.isEmpty)
      selectedText?.scrollLeft = 0
      markChosen()
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
        let _ = option.getAttribute(data("display"))
      else { return }

      let currentVal = (hiddenInput as? HTML.HTMLInputElement)?.value ?? ""
      
      if stringEquals(currentVal, value) {
        // Chosen again: a required choice stays (it is never blank after a
        // visible choice, and a repeated click must not blank it); any
        // other toggles off.
        if (hiddenInput as? HTML.HTMLInputElement)?.hasAttribute("required") ?? false {
          closeDropdown()
          return
        }
        clearSelection()
        return
      }

      // Update hidden input
      (hiddenInput as? HTML.HTMLInputElement)?.value = value
      // A choice clears the error the submit guard put there.
      if let container {
        (container.closest(".dropdown-view") ?? container).removeAttribute("data-invalid")
      }

      show([option])
      markChosen()

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
      show([])
      markChosen()

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

  /// The lists dropdowns take on their first open (`DropdownView.listURL`):
  /// each asked once a page, however many dropdowns take it. The answer is
  /// kept by its URL; a dropdown that asks while it is on its way waits for
  /// it, and one that asks after takes it at once. An answer that failed is
  /// forgotten, and told as nil, so the next open asks again.
  ///
  /// Arrays, not a dictionary: hashing a String in Embedded Swift pulls in
  /// Unicode normalization.
  private enum SharedLists {
    nonisolated(unsafe) static var urls: [String] = []
    /// Each URL's answer, nil while it is on its way.
    nonisolated(unsafe) static var answers: [DOM.Element?] = []
    nonisolated(unsafe) static var waiting: [[@Sendable (DOM.Element?) -> Void]] = []

    static func take(_ url: String, _ then: @escaping @Sendable (DOM.Element?) -> Void) {
      for (index, known) in urls.enumerated() where stringEquals(known, url) {
        if let answer = answers[index] { then(answer) } else { waiting[index].append(then) }
        return
      }
      urls.append(url)
      answers.append(nil)
      waiting.append([then])
      let index = urls.count - 1
      let answer = document.createElement(.div)
      answer.loadFragment(url) { ok in
        let told = waiting[index]
        waiting[index] = []
        if ok {
          answers[index] = answer
        } else {
          // Never matched again: the next ask starts afresh.
          urls[index] = ""
        }
        for tell in told { tell(ok ? answer : nil) }
      }
    }
  }

  public class DropdownHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: DropdownHydration?
    private var instances: [DropdownInstance] = []
    /// Every dropdown that searches the server, which `option(_:in:then:)`
    /// can ask for an option it does not list.
    fileprivate static nonisolated(unsafe) var searching: [DropdownInstance] = []

    /// The option of `value` in the dropdown `view` (its `.dropdown-view`),
    /// as soon as it has one: at once where it lists it; else, where it
    /// searches the server, once its search finds it, kept in its own list
    /// (`DropdownInstance.option`). A choice put back—a kept draft, a post
    /// the server turned back—is made through it even where the page does
    /// not list it (every language: `DropdownView.listURL`).
    public static func option(_ value: String, in view: DOM.Element, then: @escaping @Sendable (DOM.Element) -> Void) {
      for option in view.querySelectorAll("[data-dropdown-option=\"true\"]")
      where stringEquals(option.getAttribute(data("value")) ?? "", value) {
        then(option)
        return
      }
      for dropdown in searching where dropdown.rootID == view.id {
        dropdown.option(value, then: then)
        return
      }
    }

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
      buttonSize: ButtonView.ButtonSize = .large,
      fullWidth: Bool = true,
      fontSize: CSS.Length = fontSizeMedium16,
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
