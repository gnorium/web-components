#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A group of toggle buttons, joined edge to edge, of which some are
  /// selected: Codex's ToggleButtonGroup.
  ///
  /// As in Codex, the selection is the group's model: `selectedValues`
  /// (Codex `modelValue`, a value or null when single-select, an array when
  /// multi-select). Pressing a selected button deselects it, pressing
  /// another selects it, and the group's `toggle-button-group-change` event
  /// carries the new selection (its values joined by commas), as Codex's
  /// `update:modelValue` does.
  ///
  /// Two bounds narrow that, enforced on the initial state the server
  /// renders and on every press:
  /// - `minSelected` (default 0): a press that would leave fewer selected is
  ///   refused—with 1, the last selected button stays selected. A rendered
  ///   selection short of it is filled with the first enabled buttons.
  /// - `maxSelected` (default nil, unbounded): 1 is single-select, where a
  ///   press on another button moves the selection to it, as Codex's
  ///   single-select does; above 1, a press that would select more is
  ///   refused (a selection is never dropped behind the reader's back). A
  ///   rendered selection beyond it keeps its first values in button order.
  ///
  /// Exactly one, always (`minSelected` 1, `maxSelected` 1), is a segmented
  /// slider: one selected pill behind the buttons glides to the button
  /// pressed (`SlidingPillView`). Every other group fills its selected
  /// buttons each in place.
  ///
  /// The buttons are ButtonViews at the group's `size`, so a group sits
  /// beside other buttons at their height. Each button carries its value in
  /// `data-value` and its state in `aria-pressed`.
  public struct ToggleButtonGroupView: HTMLContent {
    let buttons: [ButtonItem]
    let selectedValues: [String]
    let minSelected: Int
    let maxSelected: Int?
    let disabled: Bool
    let size: ButtonView.ButtonSize
    let ariaLabel: String?
    let `class`: String

    public struct ButtonItem: Sendable {
      public let value: String
      public let label: String
      public let icon: DOM.Node?
      public let ariaLabel: String?
      public let disabled: Bool

      public init(
        value: String, label: String, icon: DOM.Node? = nil, ariaLabel: String? = nil, disabled: Bool = false
      ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.ariaLabel = ariaLabel
        self.disabled = disabled
      }
    }

    public init(
      buttons: [ButtonItem],
      selectedValues: [String] = [],
      minSelected: Int = 0,
      maxSelected: Int? = nil,
      disabled: Bool = false,
      size: ButtonView.ButtonSize = .medium,
      ariaLabel: String? = nil,
      class: String = ""
    ) {
      self.buttons = buttons
      self.selectedValues = selectedValues
      self.minSelected = max(0, minSelected)
      self.maxSelected = maxSelected.map { max(1, $0) }
      self.disabled = disabled
      self.size = size
      self.ariaLabel = ariaLabel
      self.`class` = `class`
    }

    /// Single-select, as Codex's `modelValue` of one value or null.
    public init(
      buttons: [ButtonItem],
      selectedValue: String?,
      minSelected: Int = 0,
      disabled: Bool = false,
      size: ButtonView.ButtonSize = .medium,
      ariaLabel: String? = nil,
      class: String = ""
    ) {
      self.init(
        buttons: buttons, selectedValues: selectedValue.map { [$0] } ?? [], minSelected: minSelected,
        maxSelected: 1, disabled: disabled, size: size, ariaLabel: ariaLabel, class: `class`)
    }

    /// The selection as rendered: the values given, in button order, within
    /// the bounds.
    var selection: [String] {
      var chosen = buttons.map(\.value).filter { selectedValues.contains($0) }
      if let maxSelected, chosen.count > maxSelected { chosen = Array(chosen.prefix(maxSelected)) }
      for button in buttons where chosen.count < minSelected && !disabled && !button.disabled {
        if !chosen.contains(button.value) { chosen.append(button.value) }
      }
      return buttons.map(\.value).filter { chosen.contains($0) }
    }

    /// One always selected, never more: the segmented slider.
    var slides: Bool { minSelected == 1 && maxSelected == 1 }

    public func build() -> DOM.Node {
      let selected = selection
      var group = div {
        if slides { SlidingPillView() }
        for item in buttons {
          if let icon = item.icon {
            ButtonView(
              label: item.label, icon: span { icon }.class("button-icon").ariaHidden(true), buttonColor: .gray,
              weight: .subtle, size: size, disabled: disabled || item.disabled, ariaLabel: item.ariaLabel,
              class: "toggle-button-group-button"
            )
            .data("value", item.value)
            .ariaPressed(selected.contains(item.value))
          } else {
            ButtonView(
              label: item.label, buttonColor: .gray, weight: .subtle, size: size,
              disabled: disabled || item.disabled, ariaLabel: item.ariaLabel,
              class: "toggle-button-group-button"
            )
            .data("value", item.value)
            .ariaPressed(selected.contains(item.value))
          }
        }
      }
      .class(`class`.isEmpty ? "toggle-button-group-view" : "toggle-button-group-view \(`class`)")
      .role(.group)
      .data("min-selected", "\(minSelected)")
      .data("mode", slides ? "slider" : "joined")
      .data("disabled", disabled)
      if let maxSelected { group = group.data("max-selected", "\(maxSelected)") }
      if let ariaLabel { group = group.ariaLabel(ariaLabel) }

      return group.style {
        selector("&") {
          position(.relative)
          display(.inlineFlex)
          flexWrap(.nowrap)
          alignItems(.stretch)
          maxWidth(perc(100))
          minWidth(0)
          gap(0)
        }
        descendant(".toggle-button-group-button") {
          position(.relative)
          zIndex(1)
        }

        // Joined (Codex): the buttons share their borders, the outer corners
        // round and the inner ones square; the selected ones are filled.
        selector("&[data-mode='joined'] .toggle-button-group-button:not(:first-of-type)") {
          marginInlineStart(calc("-1 * \(borderWidthBase.value)"))
        }
        selector("&[data-mode='joined'] .toggle-button-group-button:not(:first-of-type)") {
          borderStartStartRadius(px(0))
          borderEndStartRadius(px(0))
        }
        selector("&[data-mode='joined'] .toggle-button-group-button:not(:last-of-type)") {
          borderStartEndRadius(px(0))
          borderEndEndRadius(px(0))
        }
        selector("&[data-mode='joined'] .toggle-button-group-button[aria-pressed='true']") {
          zIndex(2)
        }
        selector("&[data-mode='joined'] .toggle-button-group-button:hover", "& .toggle-button-group-button:focus-visible") {
          zIndex(3)
        }

        // Slider: one track, the group's border round its buttons, which
        // are borderless pills; the group's height is a button's.
        selector("&[data-mode='slider']") {
          boxSizing(.borderBox)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusPill)
          backgroundColor(backgroundColorBase)
        }
        selector("&[data-mode='slider'] .toggle-button-group-button") {
          borderColor(borderColorTransparent).important()
          backgroundColor(backgroundColorTransparent).important()
          transition("background-color \(transitionDurationBase.value) \(transitionTimingFunctionSystem.value), color \(transitionDurationBase.value) \(transitionTimingFunctionSystem.value)")
          // Reduced motion: the selection switches at once, its label with
          // the pill (user, 2026-10-08).
          media(prefersReducedMotion(.reduce)) { transition(.none).important() }
        }
        for buttonSize in [ButtonView.ButtonSize.small, .medium, .large] {
          selector("&[data-mode='slider'] .toggle-button-group-button[data-size='\(buttonSize.rawValue)']") {
            minHeight(calc("\(buttonSize.minSize.value) - 2 * \(borderWidthBase.value)"))
          }
        }
        selector("&[data-mode='slider'] .toggle-button-group-button:hover:not(:disabled)[aria-pressed='false']") {
          backgroundColor(backgroundColorInteractiveSubtleHover).important()
        }

        // Selected: the blue fill and inverted label of a pressed
        // ToggleButtonView—on the button itself, or, once the slider's pill
        // is placed, on the pill behind it.
        selector("& .toggle-button-group-button[aria-pressed='true']") {
          backgroundColor(backgroundColorBlue).important()
          borderColor(backgroundColorBlue).important()
          color(colorInvertedFixed).important()
        }
        selector("& .toggle-button-group-button[aria-pressed='true'] .button-label") {
          color(colorInvertedFixed).important()
        }
        selector("& .toggle-button-group-button[aria-pressed='true']:hover:not(:disabled)") {
          backgroundColor(backgroundColorBlueHover).important()
          borderColor(borderColorBlueHover).important()
        }
        selector("&[data-mode='slider'] .toggle-button-group-button[aria-pressed='true']") {
          borderColor(borderColorTransparent).important()
        }
        selector(
          "&[data-mode='slider'][data-sliding-pill='ready'] .toggle-button-group-button[aria-pressed='true']",
          "&[data-mode='slider'][data-sliding-pill='ready'] .toggle-button-group-button[aria-pressed='true']:hover:not(:disabled)"
        ) {
          backgroundColor(backgroundColorTransparent).important()
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Presses in every ToggleButtonGroupView, within its bounds (see the view).
  public final class ToggleButtonGroupHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: ToggleButtonGroupHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector(".toggle-button-group-view") != nil else { return }
      instance = ToggleButtonGroupHydration()
      hydrate(in: document.body)
    }

    public init() {}

    /// The groups under `root`—a fragment swapped in after the page's own
    /// pass—each bound once.
    public static func hydrate(in root: DOM.Element) {
      if root.classList.contains("toggle-button-group-view") { bind(root) }
      for group in root.querySelectorAll(".toggle-button-group-view") { bind(group) }
    }

    static func isPressed(_ button: DOM.Element) -> Bool {
      stringEquals(button.getAttribute("aria-pressed") ?? "", "true")
    }

    static func setPressed(_ button: DOM.Element, _ pressed: Bool) {
      button.setAttribute("aria-pressed", pressed ? "true" : "false")
    }

    static func bind(_ group: DOM.Element) {
      guard !stringEquals(group.getAttribute(data("hydrated")) ?? "", "true") else { return }
      group.setAttribute(data("hydrated"), "true")
      let buttons = Array(group.querySelectorAll(".toggle-button-group-button"))
      let minimum = Int(group.getAttribute(data("min-selected")) ?? "0") ?? 0
      let maximumText = group.getAttribute(data("max-selected")) ?? ""
      let maximum: Int? = stringIsEmpty(maximumText) ? nil : Int(maximumText)
      let pill = group.querySelector(".sliding-pill-view")
      if let pill {
        SlidingPill.attach(pill, in: group) {
          group.querySelector(".toggle-button-group-button[aria-pressed='true']")
        }
      }
      for button in buttons {
        // Enter and Space press the native button, which clicks it.
        _ = button.addEventListener(.click) { _ in
          guard !button.hasAttribute("disabled"),
            !stringEquals(group.getAttribute(data("disabled")) ?? "", "true")
          else { return }
          var count = 0
          for other in buttons where isPressed(other) { count += 1 }
          if isPressed(button) {
            guard count - 1 >= minimum else { return }
            setPressed(button, false)
          } else if maximum == 1 {
            for other in buttons { setPressed(other, false) }
            setPressed(button, true)
          } else {
            if let maximum, count >= maximum { return }
            setPressed(button, true)
          }
          if let pill {
            SlidingPill.place(
              pill, in: group, under: group.querySelector(".toggle-button-group-button[aria-pressed='true']"),
              animate: true)
          }
          var values: [String] = []
          for other in buttons where isPressed(other) { values.append(other.getAttribute(data("value")) ?? "") }
          group.dispatchEvent(CustomEvent(type: "toggle-button-group-change", detail: stringJoin(values, separator: ",")))
        }
      }
    }
  }
#endif
