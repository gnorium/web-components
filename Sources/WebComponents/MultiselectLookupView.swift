#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A predictive input that allows users to make multiple selections from a menu of options.
  public struct MultiselectLookupView: HTMLContent {
    public struct Chip: Sendable {
      let id: String
      let value: String
      let icon: String?

      public init(id: String, value: String, icon: String? = nil) {
        self.id = id
        self.value = value
        self.icon = icon
      }
    }

    let id: String
    let name: String
    let menuItems: [MenuItemView.MenuItemData]
    let selectedValues: [String]
    let inputChips: [Chip]
    let inputValue: String
    let placeholder: String
    let separateInput: Bool
    let disabled: Bool
    let readonly: Bool
    let status: ValidationStatus
    let visibleItemLimit: Int?
    let keepInputOnSelection: Bool
    let showNoResults: Bool
    let `class`: String

    public enum ValidationStatus: String, Sendable {
      case `default`
      case error
    }

    public init(
      id: String,
      name: String,
      menuItems: [MenuItemView.MenuItemData] = [],
      selectedValues: [String] = [],
      inputChips: [Chip] = [],
      inputValue: String = "",
      placeholder: String = "",
      separateInput: Bool = false,
      disabled: Bool = false,
      readonly: Bool = false,
      status: ValidationStatus = .default,
      visibleItemLimit: Int? = nil,
      keepInputOnSelection: Bool = false,
      showNoResults: Bool = true,
      class: String = ""
    ) {
      self.id = id
      self.name = name
      self.menuItems = menuItems
      self.selectedValues = selectedValues
      self.inputChips = inputChips
      self.inputValue = inputValue
      self.placeholder = placeholder
      self.separateInput = separateInput
      self.disabled = disabled
      self.readonly = readonly
      self.status = status
      self.visibleItemLimit = visibleItemLimit
      self.keepInputOnSelection = keepInputOnSelection
      self.showNoResults = showNoResults
      self.`class` = `class`
    }

    @CSSBuilder
    private func multiselectLookupViewCSS() -> [CSSOM.CSSRule] {
      position(.relative)
      display(.inlineBlock)
      minWidth(px(256))
    }

    public func build() -> DOM.Node {
      var view = div {
        ChipInputView(
          id: id,
          name: name,
          chips: inputChips.map { chip in
            ChipInputView.Chip(
              id: chip.id,
              value: chip.value,
              icon: chip.icon
            )
          },
          placeholder: placeholder,
          separateInput: separateInput,
          disabled: disabled,
          readonly: readonly,
          status: status == .error ? .error : .default
        )

        MenuView(
          menuItems: menuItems,
          selected: selectedValues,
          expanded: false,
          visibleItemLimit: visibleItemLimit,
          multiselect: true, showNoResultsSlot: showNoResults,
          class: "multiselect-lookup-menu"
        ) {
          // No results message
          "No results found"
        }
      }
      .class(`class`.isEmpty ? "multiselect-lookup-view" : "multiselect-lookup-view \(`class`)")

      if keepInputOnSelection {
        view = view.data("keep-input-on-selection", "true")
      }

      return
        view
        .style {
          multiselectLookupViewCSS()
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

  private class MultiselectLookupInstance: @unchecked Sendable {
    private var lookup: DOM.Element
    private var chipInput: DOM.Element?
    private var input: DOM.Element?
    private var menu: DOM.Element?
    private var chips: [DOM.Element] = []
    private var isOpen: Bool = false
    private var keepInputOnSelection: Bool = false

    init(lookup: DOM.Element) {
      self.lookup = lookup

      chipInput = lookup.querySelector(".chip-input-view")
      input = lookup.querySelector(".chip-input-input, .text-input-view input")
      menu = lookup.querySelector(".menu-view")

      if let chipInput = chipInput {
        chips = Array(chipInput.querySelectorAll(".chip"))
      }

      // Get keep input on selection setting
      if let keepSetting = lookup.getAttribute("data-keep-input-on-selection") {
        keepInputOnSelection = stringEquals(keepSetting, "true")
      }

      bindEvents()
    }

    private func bindEvents() {
      guard let input else { return }

      // Input focus - open menu
      _ = input.addEventListener(.focus) { [self] _ in
        self.openMenu()
      }

      // Input blur - close menu (delayed to allow item selection)
      _ = input.addEventListener(.blur) { [self] _ in
        _ = setTimeout(100) {
          self.closeMenu()
        }
      }

      // Input typing
      _ = input.addEventListener(.input) { [self] (event: Event) in
        self.openMenu()
        // Dispatch input event for filtering
        let event = CustomEvent(
          type: "multiselect-lookup-input", detail: (input as? HTML.HTMLInputElement)?.value ?? "")
        self.lookup.dispatchEvent(event)
      }

      // Keyboard navigation on input
      _ = input.addEventListener(.keydown) { [self] (event: Event) in
        self.handleInputKeydown(event)
      }

      // Listen for menu-item-select events from MenuView
      if let menu = menu {
        _ = menu.addEventListener("menu-item-select") { [self] (event: Event) in
          let value = event.detail
          self.toggleSelection(value)
        }
      }

      // Chip removal
      for chip in chips {
        if let removeButton = chip.querySelector(".chip-button") {
          _ = removeButton.addEventListener(.click) { [self] _ in
            self.removeChip(chip)
          }
        }
      }
    }

    private func openMenu() {
      menu?.dataset["expanded"] = "true"
      isOpen = true
    }

    private func closeMenu() {
      menu?.dataset["expanded"] = "false"
      isOpen = false
    }

    private func toggleSelection(_ value: String) {
      // Emit select event (MenuView already handles aria-selected state)
      let event = CustomEvent(type: "multiselect-lookup-select", detail: value)
      lookup.dispatchEvent(event)

      // Clear input unless keepInputOnSelection is true
      if !keepInputOnSelection {
        if let input = input {
          (input as? HTML.HTMLInputElement)?.value = value
        }
        closeMenu()
      }
    }

    private func removeChip(_ chip: DOM.Element) {
      guard let chipID = chip.getAttribute("data-chip-id") else { return }

      // Emit chip remove event
      let event = CustomEvent(type: "multiselect-lookup-chip-remove", detail: chipID)
      lookup.dispatchEvent(event)
    }

    private func handleInputKeydown(_ event: Event) {
      let key = event.key

      if stringEquals(key, "ArrowDown") || stringEquals(key, "ArrowUp") {
        if !isOpen {
          openMenu()
        }
      } else if stringEquals(key, "Escape") {
        if isOpen {
          closeMenu()
        }
      } else if stringEquals(key, "Backspace") {
        // If input is empty, focus last chip
        if let input = input, stringEquals((input as? HTML.HTMLInputElement)?.value ?? "", "") {
          if !chips.isEmpty {
            chips[chips.count - 1].focus()
          }
        }
      }
    }
  }

  public class MultiselectLookupHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: MultiselectLookupHydration?
    private var instances: [MultiselectLookupInstance] = []

    public init() {
      hydrateAllMultiselectLookups()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".multiselect-lookup-view") != nil else { return }
      instance = MultiselectLookupHydration()
    }

    private func hydrateAllMultiselectLookups() {
      let allLookups = document.querySelectorAll(".multiselect-lookup-view")

      for lookup in allLookups {
        let instance = MultiselectLookupInstance(lookup: lookup)
        instances.append(instance)
      }
    }
  }
#endif
