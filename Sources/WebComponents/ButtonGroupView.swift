#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A ButtonGroup consists of a set of two or more normal buttons.
  /// Children that actually wrap to a new line (detected at runtime by
  /// `ButtonGroupHydration` via offsetTop comparison) automatically stretch
  /// to fill the row's full width — no hardcoded breakpoint required.
  public struct ButtonGroupView: HTMLContent {
    public struct ButtonItem: Sendable {
      public let value: String
      public let label: String
      public let icon: DOM.Node?
      public let disabled: Bool
      public let ariaLabel: String?
      public let url: String?
      public let buttonColor: ButtonView.ButtonColor
      public let weight: ButtonView.ButtonWeight
      public let size: ButtonView.ButtonSize
      public let type: ButtonView.ButtonType
      public let `class`: String
      public let fullWidth: Bool
      public let labelFontWeight: CSS.FontWeight
      public let contentJustifyContent: CSS.JustifyContent

      public init(
        value: String,
        label: String,
        icon: DOM.Node? = nil,
        disabled: Bool = false,
        ariaLabel: String? = nil,
        url: String? = nil,
        buttonColor: ButtonView.ButtonColor = .gray,
        weight: ButtonView.ButtonWeight = .subtle,
        size: ButtonView.ButtonSize = .large,
        type: ButtonView.ButtonType = .button,
        class: String = "",
        fullWidth: Bool = false,
        labelFontWeight: CSS.FontWeight = fontWeightBold,
        contentJustifyContent: CSS.JustifyContent = .center
      ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.disabled = disabled
        self.ariaLabel = ariaLabel
        self.url = url
        self.buttonColor = buttonColor
        self.weight = weight
        self.size = size
        self.type = type
        self.`class` = `class`
        self.fullWidth = fullWidth
        self.labelFontWeight = labelFontWeight
        self.contentJustifyContent = contentJustifyContent
      }
    }

    /// `.fused` is a single segmented control with joined borders and one
    /// shared radius across the whole group (the classic toggle-group look).
    /// `.apart` spaces each button apart with a gap, keeping each button's
    /// own independent shape — used for action toolbars and preference
    /// pickers like color scheme / contrast toggles.
    public enum Shape: Sendable, Equatable {
      case fused
      case apart
    }

    let buttons: [ButtonItem]
    let disabled: Bool
    let `class`: String
    let shape: Shape
    let direction: CSS.FlexDirection
    let data: [String: String]
    let ariaLabel: String?
    let style: @Sendable () -> [CSSOM.CSSRule]

    public init(
      buttons: [ButtonItem],
      disabled: Bool = false,
      shape: Shape = .apart,
      direction: CSS.FlexDirection = .row,
      class: String = "",
      data: [String: String] = [:],
      ariaLabel: String? = nil,
      @CSSBuilder style: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] }
    ) {
      self.buttons = buttons
      self.disabled = disabled
      self.shape = shape
      self.direction = direction
      self.`class` = `class`
      self.data = data
      self.ariaLabel = ariaLabel
      self.style = style
    }

    @CSSBuilder
    private func buttonGroupViewCSS() -> [CSSOM.CSSRule] {
      display(.flex)
      flexDirection(direction)
      flexWrap(.wrap)
      gap(shape == .apart ? spacingHorizontalButton : 0)

      // Once children have actually wrapped to multiple lines, stretch each
      // child to fill the row so a wrapped button list reads as a column.
      selector("&[data-wrapped='true'] > *") {
        flexGrow(1)
        flexBasis(perc(100))
      }

      if shape == .fused {
        selector(".button-view") {
          borderRadius(0).important()
        }
        selector(".button-view:first-child") {
          borderStartStartRadius(borderRadiusBase).important()
          borderEndStartRadius(borderRadiusBase).important()
        }
        selector(".button-view:last-child") {
          borderStartEndRadius(borderRadiusBase).important()
          borderEndEndRadius(borderRadiusBase).important()
        }
      }

      // Self-contained "selected" override — entirely local to this group's
      // own stylesheet, independent of which button-color-*/button-weight-*
      // combination any individual button happens to render with. The
      // repeated ".button-group-button" classes exist purely to push
      // specificity above the base per-button color/weight rule (which can
      // have up to 5 class selectors), so this reliably wins regardless of
      // what color/weight the button itself was given.
      selector(
        ".button-group-button.button-group-button.button-group-button.button-group-button.button-group-button.selected"
      ) {
        backgroundColor(backgroundColorBlue).important()
        borderColor(backgroundColorBlue).important()
        color(colorInvertedFixed).important()
      }
      selector(
        ".button-group-button.button-group-button.button-group-button.button-group-button.button-group-button.selected:hover:not(:disabled)"
      ) {
        backgroundColor(backgroundColorBlueHover).important()
        borderColor(borderColorBlueHover).important()
      }
      selector(
        ".button-group-button.button-group-button.button-group-button.button-group-button.button-group-button.selected:active:not(:disabled)"
      ) {
        backgroundColor(backgroundColorBlueActive).important()
        borderColor(borderColorBlueActive).important()
      }

      style()
    }

    public func build() -> DOM.Node {
      var group =
        div {
          for item in buttons {
            let isDisabled = disabled || item.disabled
            let itemData = ["value": item.value]
            let itemClass = item.class.isEmpty ? "button-group-button" : "button-group-button \(item.class)"

            if let icon = item.icon {
              ButtonView(
                label: item.label,
                icon: icon,
                buttonColor: item.buttonColor,
                weight: item.weight,
                size: item.size,
                disabled: isDisabled,
                url: item.url,
                type: item.type,
                ariaLabel: item.ariaLabel ?? item.label,
                fullWidth: item.fullWidth,
                class: itemClass,
                labelFontWeight: item.labelFontWeight,
                contentJustifyContent: item.contentJustifyContent,
                data: itemData
              )
            } else {
              ButtonView(
                label: item.label,
                buttonColor: item.buttonColor,
                weight: item.weight,
                size: item.size,
                disabled: isDisabled,
                url: item.url,
                type: item.type,
                ariaLabel: item.ariaLabel ?? item.label,
                fullWidth: item.fullWidth,
                class: itemClass,
                labelFontWeight: item.labelFontWeight,
                contentJustifyContent: item.contentJustifyContent,
                data: itemData
              )
            }
          }
        }
        .class(`class`.isEmpty ? "button-group-view" : "button-group-view \(`class`)")
        .role(.group)
        .ariaLabel(ariaLabel)
        .style {
          buttonGroupViewCSS()
        }

      for (key, value) in data {
        group = group.data(key, value)
      }

      return group
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

  /// Toggles a single `selected` class on each `.button-group-button` inside `group` —
  /// the button matching `selectedValue` (compared against its `data-value` attribute)
  /// gets `.selected`, every other button has it removed. Styling for `.selected` is
  /// emitted once, self-contained, by `ButtonGroupView.buttonGroupViewCSS()` — it does
  /// not depend on any other button on the page sharing a particular color/weight, so
  /// it can't drift out of sync the way swapping `button-color-*`/`button-weight-*`
  /// classes across buttons could.
  public func selectButtonGroupValue(
    _ group: DOM.Element,
    selectedValue: String
  ) {
    let buttons = group.querySelectorAll(".button-group-button")
    for button in buttons {
      guard let value = button.getAttribute("data-value") else { continue }

      if stringEquals(value, selectedValue) {
        button.classList.add("selected")
        // Inline, because it's the same element ButtonView's own SSR styling sets
        // background-color/border-color/color on — an inline declaration always beats
        // anything from the `.selected` rule in the external stylesheet, so we override
        // inline here too rather than relying on the stylesheet rule to win.
        button.style.backgroundColor(backgroundColorBlue)
        button.style.borderColor(backgroundColorBlue)
        button.style.color(colorInvertedFixed)
      } else {
        button.classList.remove("selected")
        // Restore (not remove) — removing would also wipe the SSR-baked base inline
        // declarations, since inline styles aren't tagged with who set them.
        button.style.backgroundColor(backgroundColorBase)
        button.style.borderColor(borderColorBase)
        button.style.color(colorBase)
      }
    }
  }

  private class ButtonGroupInstance: @unchecked Sendable {
    private var buttons: [DOM.Element] = []

    init(group: DOM.Element) {
      buttons = Array(group.querySelectorAll(".button-group-button"))
      bindEvents()
    }

    private func bindEvents() {
      for button in buttons {
        // Click event
        _ = button.addEventListener(.click) { [self] _ in
          self.handleClick(button)
        }

        // Keyboard events
        _ = button.addEventListener(.keydown) { [self] (event: Event) in
          self.handleKeydown(button, event: event)
        }
      }
    }

    private func handleClick(_ button: DOM.Element) {
      if let ariaDisabled = button.getAttribute("aria-disabled"), stringEquals(ariaDisabled, "true") {
        return
      }

      guard let value = button.getAttribute("data-value") else { return }

      // Emit custom event
      let event = CustomEvent(type: "button-group-click", detail: value)
      button.dispatchEvent(event)
    }

    private func handleKeydown(_ button: DOM.Element, event: Event) {
      if let ariaDisabled = button.getAttribute("aria-disabled"), stringEquals(ariaDisabled, "true") {
        return
      }

      // Handle Enter and Space keys
      let key = event.key
      if stringEquals(key, "Enter") || stringEquals(key, " ") {
        handleClick(button)
      }
    }
  }

  public class ButtonGroupHydration: @unchecked Sendable {
    private var instances: [ButtonGroupInstance] = []

    public init() {
      hydrateAllButtonGroups()
      hydrateWrapDetection()
    }

    private func hydrateAllButtonGroups() {
      let allGroups = document.querySelectorAll(".button-group-view")

      for group in allGroups {
        let instance = ButtonGroupInstance(group: group)
        instances.append(instance)
      }
    }

    private func hydrateWrapDetection() {
      let groups = document.querySelectorAll(".button-group-view")

      for group in groups {
        updateWrappedState(group)
        group.observeResize { [self] _, _ in
          self.updateWrappedState(group)
        }
      }
    }

    // Detects when a button group's children have actually wrapped to
    // multiple lines (by comparing child offsetTop values) and toggles
    // `data-wrapped` so CSS can stretch children to full width only then.
    private func updateWrappedState(_ group: DOM.Element) {
      let children = group.querySelectorAll(":scope > *")
      guard let firstTop = children.first?.offsetTop else { return }
      let wrapped = children.contains { $0.offsetTop != firstTop }
      if wrapped {
        group.setAttribute("data-wrapped", "true")
      } else {
        group.removeAttribute("data-wrapped")
      }
    }
  }
#endif
