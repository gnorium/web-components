import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A Combobox is a text input with a list of suggestions below it (the
/// WAI-ARIA combobox pattern, list autocomplete): one field in which the
/// reader types, the suggestions narrowing as they type. Choosing one takes
/// it; a value no suggestion names is kept as typed. It stands where a
/// dropdown with an "Other" choice and a second field to name it stood: a
/// field whose values are usually on a list and sometimes are not (a
/// provider, a holding institution, a genre).
///
/// What it posts (`name`, on a hidden input whose id is `id`) is the chosen
/// suggestion's value, or the typed text when it names none—a typed text
/// equal to a suggestion's name, letter case aside, is that suggestion.
///
/// The suggestions are its own (`options`), or a server's (`searchURL`):
/// typing asks `searchURL?q=…` (debounced; a late answer to an earlier query
/// is dropped) and shows the suggestions of the ComboboxView the answer
/// holds, its own again for an empty query.
///
/// Built on both sides: a list's rows clone it, and the client may build
/// one. `build()` stays embedded-safe (stringIsEmpty/stringEquals).
public struct ComboboxView: HTMLContent {
  /// One suggestion: its value (what is posted), its name (what is shown
  /// and typed), what it belongs to (a breadcrumb before its name), a
  /// second line (`altDisplay`), its depth in a grouped list.
  public typealias Option = DropdownView.DropdownOption

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  let id: String
  let name: String
  let labelText: String
  /// The field's name for a screen reader where no label is drawn (a
  /// query row read as a sentence); ignored when `label` is given.
  let ariaLabel: String?
  let optional: Bool
  let optionalFlag: String
  /// What stands after the label's text (and its "(optional)"), before its
  /// tooltip: a record page's reference marks. Not label text.
  let labelMarks: [DOM.Node]
  let tooltip: String?
  let options: [Option]
  /// The value it holds: a suggestion's value, or text as typed.
  let selectedValue: String
  let placeholder: String
  let startIcon: String?
  let required: Bool
  let disabled: Bool
  let status: ValidationStatus
  /// How many suggestions show before the list scrolls; nil for the
  /// standard height.
  let visibleItemLimit: Int?
  /// Where it asks for suggestions, when the server holds too many to send.
  let searchURL: String?
  /// A line after the suggestions that is not one: what the list leaves out
  /// ("Showing the first 50."). A search's answer
  /// brings its own.
  let note: String?
  /// The id of the form its value submits with, when it sits outside it.
  let form: String?
  let `class`: String

  public init(
    id: String,
    name: String,
    label: String = "",
    ariaLabel: String? = nil,
    optional: Bool = false,
    optionalFlag: String = "(optional)",
    labelMarks: [DOM.Node] = [],
    tooltip: String? = nil,
    options: [Option] = [],
    selectedValue: String = "",
    placeholder: String = "",
    startIcon: String? = nil,
    required: Bool = false,
    disabled: Bool = false,
    status: ValidationStatus = .default,
    visibleItemLimit: Int? = nil,
    searchURL: String? = nil,
    note: String? = nil,
    form: String? = nil,
    class: String = ""
  ) {
    self.id = id
    self.name = name
    self.labelText = label
    self.ariaLabel = ariaLabel
    self.optional = optional
    self.optionalFlag = optionalFlag
    self.labelMarks = labelMarks
    self.tooltip = tooltip
    self.options = options
    self.selectedValue = selectedValue
    self.placeholder = placeholder
    self.startIcon = startIcon
    self.required = required
    self.disabled = disabled
    self.status = status
    self.visibleItemLimit = visibleItemLimit
    self.searchURL = searchURL
    self.note = note
    self.form = form
    self.`class` = `class`
  }

  /// The suggestion a value is, when it is one.
  private var chosen: Option? {
    options.first { stringEquals($0.value, selectedValue) }
  }

  public func build() -> DOM.Node {
    let inputID = "\(id)-input"
    let listboxID = "\(id)-listbox"
    let labelID = "\(id)-label"
    let text = chosen?.display ?? selectedValue
    let hasLabel = !stringIsEmpty(labelText)
    var attributes: [(String, String)] = [
      ("role", "combobox"),
      ("aria-autocomplete", "list"),
      ("aria-expanded", "false"),
      ("aria-controls", listboxID),
      ("autocomplete", "off"),
      ("autocapitalize", "off"),
      ("spellcheck", "false"),
      ("data-combobox-input", "true"),
    ]
    if hasLabel {
      attributes.append(("aria-labelledby", labelID))
    } else if let ariaLabel {
      attributes.append(("aria-label", ariaLabel))
    }
    let hidden = input()
      .type(.hidden)
      .id(id)
      .name(name)
      .value(selectedValue)
      .disabled(disabled)
      .data("combobox-value", true)
    return div {
      if hasLabel {
        label {
          span { labelText }
            .class("combobox-label-text")
          if optional {
            span { optionalFlag }
              .class("combobox-optional-flag")
              .data("optional-flag", true)
          }
          labelMarks
          if let tooltip {
            TooltipView(tooltip: tooltip, placement: .bottom) {
              IconView(icon: { size in InfoIconView(size: size) }, size: sizeIconSmall)
            }
          }
        }
        .for(inputID)
        .id(labelID)
        .class("combobox-label")
      }

      div {
        TextInputView(
          id: inputID,
          name: "",
          placeholder: placeholder,
          value: text,
          type: .text,
          status: status == .error ? .error : .default,
          disabled: disabled,
          required: required,
          startIcon: startIcon,
          form: form,
          inputAttributes: attributes
        )

        // Shows every suggestion, whatever is typed; not a stop in the tab
        // order (the arrow keys open the list from the field).
        button {
          AnimatedUpDownChevronView(id: "combobox-\(id)", expanded: false, size: sizeIconSmall)
        }
        .type(.button)
        .class("combobox-toggle")
        .tabindex(-1)
        .ariaLabel("Show suggestions")
        .ariaControls(listboxID)
        .ariaExpanded(false)
        .disabled(disabled)
        .data("combobox-toggle", true)

        // The list, under the field.
        div {
          ul {
            for (i, option) in options.enumerated() {
              Self.option(option, id: "\(id)-option-\(i)", chosen: stringEquals(option.value, selectedValue))
            }
          }
          .id(listboxID)
          .class("combobox-listbox")
          .role(.listbox)
          .ariaLabelledby(hasLabel ? labelID : nil)
          .ariaLabel(hasLabel ? nil : ariaLabel)
          .data("combobox-listbox", true)

          if let note {
            div { note }
              .class("combobox-note")
              .data("combobox-note", true)
          }
        }
        .class("combobox-menu")
        .data("combobox-menu", true)
        .data("open", false)
      }
      .class("combobox-input-wrapper")

      // Last, so what a form draws under the field (its diff) goes after it.
      if let form { hidden.form(form) } else { hidden }
    }
    .class(stringIsEmpty(`class`) ? "combobox-view" : "combobox-view \(`class`)")
    .data("combobox", true)
    .data("search-url", searchURL ?? "")
    .data("disabled", disabled)
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        width(perc(100))
        minWidth(0)
      }
      // The label as every field's: LabelView's, which TextInputView and
      // DropdownView draw too.
      descendant(".combobox-label") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
      }
      descendant(".combobox-label-text") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        color(colorBase)
      }
      descendant(".combobox-optional-flag") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
      descendant(".combobox-input-wrapper") {
        position(.relative)
        minWidth(0)
      }
      // Room for the toggle at the field's end.
      descendant(".combobox-input-wrapper .text-input-input") {
        paddingInlineEnd(calc(spacing12 + sizeIconMedium + spacing8))
      }
      // The toggle the field's full height, its icon where a field's end
      // icon sits: 12 inside the border.
      descendant(".combobox-toggle") {
        position(.absolute)
        insetBlockStart(0)
        insetBlockEnd(0)
        insetInlineEnd(0)
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        width(calc(borderWidthBase + spacing12 + sizeIconMedium + spacing12))
        padding(0)
        color(colorSubtle)
        backgroundColor(backgroundColorTransparent)
        border(.none)
        cursor(cursorBaseHover)
      }
      descendant(".combobox-toggle:disabled") {
        color(colorDisabled)
        cursor(cursorNotAllowed)
      }
      // The list, as a dropdown's menu: under the field, as wide as it.
      descendant(".combobox-menu") {
        position(.absolute)
        top(perc(100))
        insetInlineStart(0)
        insetInlineEnd(0)
        marginBlockStart(spacing4)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        boxShadow(boxShadowMedium)
        zIndex(zIndexDropdown)
        display(.none)
        overflow(.hidden)
      }
      descendant(".combobox-menu[data-open='true']") {
        display(.block)
      }
      descendant(".combobox-listbox") {
        listStyle(.none)
        margin(0)
        padding(0)
        if let visibleItemLimit {
          maxHeight(calc(visibleItemLimit * minSizeInteractiveTouch))
        } else {
          maxHeight(px(300))
        }
        overflowY(.auto)
      }
      descendant(".combobox-option") {
        display(.flex)
        flexDirection(.column)
        justifyContent(.center)
        gap(spacing2)
        // A row: 8 on every side, at least 40.
        minHeight(minSizeInteractiveTouch)
        padding(spacing8)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        backgroundColor(backgroundColorTransparent)
        cursor(cursorBaseHover)
        boxSizing(.borderBox)
      }
      // A suggestion wraps to as many lines as it needs: a tap takes it,
      // nothing is cut or faded.
      descendant(".combobox-option-display-text") {
        minWidth(0)
        whiteSpace(.normal)
        overflowWrap(.anywhere)
      }
      descendant(".combobox-option-alt-text") {
        fontSize(fontSizeMedium16)
        color(colorSubtle)
        whiteSpace(.normal)
        overflowWrap(.anywhere)
      }
      descendant(".combobox-option[data-depth='0'] .combobox-option-display-text") {
        fontWeight(fontWeightSemiBold)
      }
      descendant(".combobox-option[data-depth='1']") {
        paddingInlineStart(spacing32)
      }
      descendant(".combobox-option[data-hidden='true']") {
        display(.none)
      }
      // The one it holds, the one the arrow keys are on, the one under the
      // pointer: the dropdown's highlight.
      selector(
        "& .combobox-option[data-chosen='true']", "& .combobox-option[aria-selected='true']",
        "& .combobox-option:hover"
      ) {
        backgroundColor(backgroundColorBlue)
        color(colorInvertedFixed)
      }
      selector(
        "& .combobox-option[data-chosen='true'] *", "& .combobox-option[aria-selected='true'] *",
        "& .combobox-option:hover *"
      ) {
        color(colorInvertedFixed).important()
      }
      descendant(".combobox-note") {
        padding(spacing8)
        minHeight(minSizeInteractiveTouch)
        boxSizing(.borderBox)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorSubtle)
        borderBlockStart(borderWidthBase, .solid, borderColorBase)
      }
    }
  }

  /// One suggestion of the list, `id` its element's id.
  public static func option(_ option: Option, id: String, chosen: Bool) -> DOM.Node {
    li {
      span {
        if let context = option.context {
          BreadcrumbLabelView(context: context, text: option.display)
        } else {
          option.display
        }
      }
      .class("combobox-option-display-text")
      if let alt = option.altDisplay, !stringIsEmpty(alt) {
        span { alt }
          .class("combobox-option-alt-text")
      }
    }
    .id(id)
    .class("combobox-option")
    .role(.option)
    .ariaSelected(false)
    .data("combobox-option", true)
    .data("value", option.value)
    .data("display", option.display)
    .data("context", option.context ?? "")
    .data("alt-display", option.altDisplay ?? "")
    .data("depth", option.depth.map { intToString($0) } ?? "")
    .data("chosen", chosen)
    .data("hidden", false)
  }
}

#if SERVER
  extension ComboboxView {
    /// A combobox of menu items: each item's label its name (its value when
    /// it has none), its description its second line.
    public init(
      id: String,
      name: String,
      menuItems: [MenuItemView.MenuItemData],
      selectedValue: String = "",
      placeholder: String = "",
      startIcon: String? = nil,
      disabled: Bool = false,
      status: ValidationStatus = .default,
      visibleItemLimit: Int? = nil,
      class: String = ""
    ) {
      self.init(
        id: id,
        name: name,
        options: menuItems.map {
          Option(value: $0.value, display: $0.label ?? $0.value, altDisplay: $0.description)
        },
        selectedValue: selectedValue,
        placeholder: placeholder,
        startIcon: startIcon,
        disabled: disabled,
        status: status,
        visibleItemLimit: visibleItemLimit,
        class: `class`
      )
    }
  }
#endif

#if CLIENT
  import WebAPIs

  /// One combobox on the page: its field, its list, what it posts.
  private final class ComboboxInstance: @unchecked Sendable {
    private let root: DOM.Element
    private let field: DOM.Element
    private let hidden: DOM.Element
    private let menu: DOM.Element
    private let listbox: DOM.Element
    private let toggle: DOM.Element?
    private let chevron: AnimatedUpDownChevronInstance?
    /// Its own suggestions, as the page drew them.
    private let own: [DOM.Element]
    private let ownNote: DOM.Element?
    /// The suggestions the list holds now: its own, or a search's.
    private var shown: [DOM.Element]
    /// A search's answer, in the list in place of its own.
    private var results: [DOM.Element] = []
    private var resultNote: DOM.Element?
    private let searchURL: String
    private var searchTimer: Int32 = 0
    /// Which query is the latest: an answer overtaken by a later one is
    /// dropped.
    private var searchState = ComboboxSearch()
    private var isOpen = false
    /// The suggestion the arrow keys are on, in `shown`; -1 for none.
    private var active = -1

    init?(root: DOM.Element) {
      guard let field = root.querySelector("[data-combobox-input='true']"),
        let hidden = root.querySelector("[data-combobox-value='true']"),
        let menu = root.querySelector("[data-combobox-menu='true']"),
        let listbox = root.querySelector("[data-combobox-listbox='true']")
      else { return nil }
      self.root = root
      self.field = field
      self.hidden = hidden
      self.menu = menu
      self.listbox = listbox
      toggle = root.querySelector("[data-combobox-toggle='true']")
      chevron = root.querySelector(".animated-up-down-chevron-view").flatMap {
        AnimatedUpDownChevronFactory.from(element: $0)
      }
      own = Array(listbox.querySelectorAll("[data-combobox-option='true']"))
      ownNote = root.querySelector("[data-combobox-note='true']")
      shown = own
      searchURL = root.getAttribute(data("search-url")) ?? ""
      bind()
    }

    private var text: String {
      (field as? HTML.HTMLInputElement)?.value ?? ""
    }

    private var value: String {
      (hidden as? HTML.HTMLInputElement)?.value ?? ""
    }

    private func bind() {
      bindOptions(own)

      _ = field.addEventListener(.input) { [self] _ in
        self.typed()
      }
      _ = field.addEventListener(.keydown) { [self] event in
        self.key(event)
      }
      // A click on the label focuses the field and opens nothing, as a
      // native select's label does: the browser would pass it on to the
      // field as a click, which opens the list. One that ends selecting the
      // label's words (to copy them) leaves the focus alone: in the field it
      // would drop the selection.
      if let label = root.querySelector(".combobox-label") {
        _ = label.addEventListener(.click) { [self] event in
          event.preventDefault()
          if let selection = window.getSelection(), !selection.isCollapsed { return }
          self.field.focus()
        }
      }
      // A click or tap in the field opens the list, as the toggle does: on a
      // phone it is the only way to see what is on it.
      _ = field.addEventListener(.click) { [self] _ in
        if !self.isOpen { self.open(all: true) }
      }
      _ = field.addEventListener(.focusout) { [self] event in
        if let next = event.payload.relatedTarget, self.root.contains(next) { return }
        self.close()
      }
      if let toggle {
        // The field keeps the focus, and with it the keyboard.
        _ = toggle.addEventListener(.mousedown) { event in
          event.preventDefault()
        }
        _ = toggle.addEventListener(.click) { [self] _ in
          if self.isOpen {
            self.close()
          } else {
            self.open(all: true)
          }
          self.field.focus()
        }
      }
      // A press in the list keeps the focus in the field.
      _ = menu.addEventListener(.mousedown) { event in
        event.preventDefault()
      }
      _ = document.addEventListener(.click) { [self] event in
        guard self.isOpen, let target = event.target else { return }
        if !self.root.contains(target) { self.close() }
      }
    }

    private func bindOptions(_ options: [DOM.Element]) {
      for option in options {
        _ = option.addEventListener(.click) { [self] _ in
          self.choose(option)
        }
      }
    }

    /// The reader typed: what it posts follows at once, and the list
    /// narrows to what matches.
    private func typed() {
      // A server's suggestion is taken only by choosing it: namesakes read
      // alike, and a name typed is the name typed.
      commit(value: Self.valueOf(text, among: own))
      if stringIsEmpty(searchURL) {
        filter(text)
        setActive(-1)
        if visibleCount() > 0 { open(all: false) } else { close() }
      } else {
        search(stringTrim(text))
      }
    }

    /// A typed text is the suggestion it names, letter case aside; any
    /// other is itself, trimmed.
    private static func valueOf(_ text: String, among options: [DOM.Element]) -> String {
      let typed = stringTrim(text)
      let lowered = stringLowercased(typed)
      for option in options {
        let display = option.getAttribute(data("display")) ?? ""
        if stringEquals(stringLowercased(display), lowered) {
          return option.getAttribute(data("value")) ?? typed
        }
      }
      return typed
    }

    private func filter(_ query: String) {
      let needle = stringTrim(query)
      for option in shown {
        let matches =
          stringIsEmpty(needle)
          || stringContainsCaseInsensitive(option.getAttribute(data("display")) ?? "", needle)
          || stringContainsCaseInsensitive(option.getAttribute(data("alt-display")) ?? "", needle)
          || stringContainsCaseInsensitive(option.getAttribute(data("context")) ?? "", needle)
        option.setAttribute(data("hidden"), !matches)
      }
    }

    private func visibleCount() -> Int {
      var count = 0
      for option in shown where !isHidden(option) { count += 1 }
      return count
    }

    private func isHidden(_ option: DOM.Element) -> Bool {
      stringEquals(option.getAttribute(data("hidden")) ?? "", "true")
    }

    private func key(_ event: Event) {
      let key = event.key
      if stringEquals(key, "ArrowDown") {
        event.preventDefault()
        if !isOpen {
          open(all: !isNarrowing)
          if event.altKey { return }
        }
        move(1)
      } else if stringEquals(key, "ArrowUp") {
        event.preventDefault()
        if !isOpen {
          open(all: !isNarrowing)
          if event.altKey { return }
        }
        move(-1)
      } else if stringEquals(key, "Enter") {
        // An open list takes the Enter: a suggestion the keys are on is
        // chosen, and none closes the list with the text as typed. A closed
        // one lets the form have it.
        guard isOpen else { return }
        event.preventDefault()
        if active >= 0 {
          choose(shown[active])
        } else {
          close()
        }
      } else if stringEquals(key, "Escape") {
        if isOpen {
          event.preventDefault()
          event.stopPropagation()
          close()
        } else if !stringIsEmpty(text) {
          // A second Escape clears the field.
          event.preventDefault()
          (field as? HTML.HTMLInputElement)?.value = ""
          commit(value: "")
          if stringIsEmpty(searchURL) { filter("") } else { search("") }
        }
      } else if stringEquals(key, "Tab") {
        // Leaving with the keys on a suggestion takes it; the focus goes on.
        if isOpen && active >= 0 { choose(shown[active]) }
        close()
      }
    }

    /// Whether the text in the field is the reader's own typing rather than
    /// a suggestion's name: a list opened then shows what matches it.
    private var isNarrowing: Bool {
      guard !stringIsEmpty(stringTrim(text)) else { return false }
      for option in own + results where stringEquals(option.getAttribute(data("value")) ?? "", value) {
        return false
      }
      return true
    }

    /// Opens the list: every suggestion (`all`), or those matching the text.
    private func open(all: Bool) {
      let currentQuery = stringTrim(text)
      if !results.isEmpty && !searchState.matches(currentQuery) { showOwn() }
      if !stringIsEmpty(searchURL) && isNarrowing && !searchState.matches(currentQuery) {
        search(stringTrim(text))
      }
      // A server's suggestions already match the text, as the server
      // matches it (diacritics aside): none is hidden again here.
      filter(all || searchState.matches(currentQuery) ? "" : text)
      guard visibleCount() > 0 else { return }
      isOpen = true
      menu.setAttribute(data("open"), true)
      field.setAttribute("aria-expanded", "true")
      toggle?.setAttribute("aria-expanded", "true")
      chevron?.setState(expanded: true, animated: true)
      // The one it holds in view.
      for (i, option) in shown.enumerated() where stringEquals(option.getAttribute(data("chosen")) ?? "", "true") {
        scroll(to: i)
      }
    }

    private func close() {
      setActive(-1)
      guard isOpen else { return }
      isOpen = false
      menu.setAttribute(data("open"), false)
      field.setAttribute("aria-expanded", "false")
      toggle?.setAttribute("aria-expanded", "false")
      chevron?.setState(expanded: false, animated: true)
    }

    /// Moves the keys' place `delta` suggestions on, among those shown,
    /// round from the last to the first.
    private func move(_ delta: Int) {
      let count = shown.count
      guard count > 0 else { return }
      var next = active
      var steps = 0
      repeat {
        if next < 0 {
          next = delta > 0 ? 0 : count - 1
        } else {
          next = ((next + delta) % count + count) % count
        }
        steps += 1
      } while isHidden(shown[next]) && steps <= count
      if isHidden(shown[next]) { return }
      setActive(next)
      scroll(to: next)
    }

    private func setActive(_ index: Int) {
      if active >= 0 && active < shown.count {
        shown[active].setAttribute("aria-selected", "false")
      }
      active = index
      if index >= 0 && index < shown.count {
        let option = shown[index]
        option.setAttribute("aria-selected", "true")
        field.setAttribute("aria-activedescendant", option.getAttribute("id") ?? "")
      } else {
        field.removeAttribute("aria-activedescendant")
      }
    }

    private func scroll(to index: Int) {
      let option = shown[index]
      let top = option.offsetTop - listbox.offsetTop
      let bottom = top + option.offsetHeight
      let height = Double(listbox.clientHeight)
      if top < listbox.scrollTop {
        listbox.scrollTop = top
      } else if bottom > listbox.scrollTop + height {
        listbox.scrollTop = bottom - height
      }
    }

    /// Takes a suggestion: its name in the field, its value posted.
    private func choose(_ option: DOM.Element) {
      (field as? HTML.HTMLInputElement)?.value = option.getAttribute(data("display")) ?? ""
      commit(value: option.getAttribute(data("value")) ?? "")
      close()
      filter("")
    }

    /// Posts `value` and says so (a `change` on the hidden input), when it
    /// is new; marks the suggestion it is.
    private func commit(value next: String) {
      for option in own + results {
        let chosen = !stringIsEmpty(next) && stringEquals(option.getAttribute(data("value")) ?? "", next)
        option.setAttribute(data("chosen"), chosen)
      }
      guard !stringEquals(next, value) else { return }
      (hidden as? HTML.HTMLInputElement)?.value = next
      hidden.dispatchEvent(.change)
    }

    /// Asks the server for the suggestions matching `query`, shortly: each
    /// key typed restarts the wait, and only the latest query's answer is
    /// shown.
    private func search(_ query: String) {
      if searchTimer != 0 {
        clearTimeout(searchTimer)
        searchTimer = 0
      }
      let asked = searchState.begin()
      setActive(-1)
      // Remove the previous query's DOM options immediately: reopening
      // during the debounce must never make them selectable again.
      showOwn()
      if stringIsEmpty(query) {
        return
      }
      filter(query)
      let url = stringJoin(
        [searchURL, stringContains(searchURL, "?") ? "&q=" : "?q=", encodeURIComponent(query)], separator: "")
      searchTimer = setTimeout(250) { [self] in
        self.searchTimer = 0
        let answer = document.createElement(.div)
        answer.loadFragment(url) { [self] ok in
          guard ok,
            self.searchState.receive(query: query, sequence: asked, currentQuery: stringTrim(self.text))
          else { return }
          self.show(answer)
        }
      }
    }

    /// A search's suggestions, in the list in place of its own.
    private func show(_ answer: DOM.Element) {
      setActive(-1)
      for option in shown { option.remove() }
      resultNote?.remove()
      ownNote?.remove()
      resultNote = nil
      let prefix = stringJoin([listbox.getAttribute("id") ?? "", "-result-"], separator: "")
      var found: [DOM.Element] = []
      for (i, option) in answer.querySelectorAll("[data-combobox-option='true']").enumerated() {
        option.setAttribute("id", stringJoin([prefix, intToString(i)], separator: ""))
        option.setAttribute(data("hidden"), false)
        option.setAttribute(
          data("chosen"), !stringIsEmpty(value) && stringEquals(option.getAttribute(data("value")) ?? "", value))
        listbox.appendChild(option)
        found.append(option)
      }
      if let note = answer.querySelector("[data-combobox-note='true']") {
        menu.appendChild(note)
        resultNote = note
      }
      bindOptions(found)
      results = found
      shown = found
      if found.count > 0 {
        open(all: true)
      } else {
        close()
      }
    }

    private func showOwn() {
      setActive(-1)
      for option in results { option.remove() }
      resultNote?.remove()
      resultNote = nil
      results = []
      for option in own { listbox.appendChild(option) }
      if let ownNote { menu.appendChild(ownNote) }
      shown = own
      filter("")
      close()
    }
  }

  /// A combobox built on the client—a filter bar's row added or switched to
  /// a combobox field—bound as it is made.
  public enum ComboboxFactory {
    public static func createElement(
      id: String, name: String, label: String, options: [ComboboxView.Option], value: String, searchURL: String,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      wrapper.innerHTML = ComboboxView(
        id: id, name: name, ariaLabel: label, options: options, selectedValue: value, placeholder: label,
        searchURL: stringIsEmpty(searchURL) ? nil : searchURL, class: `class`
      ).render()
      let element = wrapper.firstElementChild ?? wrapper
      ComboboxHydration.hydrate(element: element)
      return element
    }
  }

  /// Every combobox on the page, and those a fragment brings in later.
  public enum ComboboxHydration {
    private static nonisolated(unsafe) var instances: [ComboboxInstance] = []
    /// The comboboxes bound, by element: a row cloned from one is a new
    /// element, bound when it arrives.
    private static nonisolated(unsafe) var bound: [Int32] = []

    public static func hydrateIfPresent() {
      hydrate(in: document.body)
    }

    /// Every combobox inside `root` not bound yet.
    public static func hydrate(in root: DOM.Element?) {
      guard let root else { return }
      for element in root.querySelectorAll(".combobox-view[data-combobox='true']") {
        hydrate(element: element)
      }
    }

    public static func hydrate(element: DOM.Element) {
      if bound.contains(element.id) { return }
      guard let instance = ComboboxInstance(root: element) else { return }
      bound.append(element.id)
      instances.append(instance)
    }
  }
#endif
