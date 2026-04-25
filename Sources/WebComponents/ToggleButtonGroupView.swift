#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A ToggleButtonGroup is a group of ToggleButtons that allows single or multi-select.
  public struct ToggleButtonGroupView: HTMLContent {
    let buttons: [ButtonItem]
    let selectedValues: [String]
    let isMultiSelect: Bool
    let disabled: Bool
    let `class`: String

    public struct ButtonItem: Sendable {
      public let value: String
      public let label: String
      public let icon: String?
      public let disabled: Bool

      public init(value: String, label: String, icon: String? = nil, disabled: Bool = false) {
        self.value = value
        self.label = label
        self.icon = icon
        self.disabled = disabled
      }
    }

    public init(
      buttons: [ButtonItem],
      selectedValues: [String] = [],
      isMultiSelect: Bool = false,
      disabled: Bool = false,
      class: String = ""
    ) {
      self.buttons = buttons
      self.selectedValues = selectedValues
      self.isMultiSelect = isMultiSelect
      self.disabled = disabled
      self.`class` = `class`
    }

    @CSSBuilder
    private func toggleButtonGroupViewCSS() -> [CSSRule] {
      display(.inlineFlex)
      flexWrap(.wrap)
      gap(0)

      // Rounded corners for first/last buttons
      selector(".toggle-button-view:first-child") {
        borderStartStartRadius(borderRadiusBase).important()
        borderEndStartRadius(borderRadiusBase).important()
      }

      selector(".toggle-button-view:last-child") {
        borderStartEndRadius(borderRadiusBase).important()
        borderEndEndRadius(borderRadiusBase).important()
      }

      // Collapse borders between buttons
      selector(".toggle-button-view:not(:first-child)") {
        marginInlineStart(calc(-borderWidthBase)).important()
      }

      // Bring focused/hovered button to front
      selector(".toggle-button-view:hover") {
        zIndex(1).important()
      }

      selector(".toggle-button-view:focus") {
        zIndex(2).important()
      }
    }

    public func render() -> Node {
      var container = div {
        for buttonItem in buttons {
          let isSelected = selectedValues.contains(buttonItem.value)
          let isDisabled = disabled || buttonItem.disabled

          ToggleButtonView(
            label: buttonItem.label,
            icon: buttonItem.icon.map { iconStr in span(content: { iconStr }) },
            modelValue: isSelected,
            weight: .subtle,
            disabled: isDisabled,
            iconOnly: false,
            class: "toggle-button-group-item"
          )
        }
      }
      .class(`class`.isEmpty ? "toggle-button-group-view" : "toggle-button-group-view \(`class`)")
      .role(.group)
      .ariaLabel("Toggle button group")

      if isMultiSelect {
        container = container.data("multi-select", "true")
      }

      return container.style {
        toggleButtonGroupViewCSS()
      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  public class ToggleButtonGroupHydration: @unchecked Sendable {
    public init() {}

    public func hydrate() {
      let groups = document.querySelectorAll(".toggle-button-group-view")

      for group in groups {
        let buttons = group.querySelectorAll(".toggle-button")

        for button in buttons {
          _ = button.addEventListener(.click) { (event: Event) in
            guard let ariaPressed = button.getAttribute(.ariaPressed),
              !stringEquals(button.getAttribute(.disabled) ?? "", "true")
            else { return }

            let isPressed = stringEquals(ariaPressed, "true")
            let newPressed = !isPressed

            // Check if this is a multi-select group by looking for data-multi-select
            let isMultiSelect = group.hasAttribute(data("multi-select"))

            if !isMultiSelect {
              // Single select - deselect all other buttons first
              for otherButton in buttons {
                if !stringEquals(otherButton.idString, button.idString) {
                  otherButton.setAttribute(.ariaPressed, false)
                  _ = otherButton.classList.remove("toggle-button-selected")
                }
              }
            }

            // Toggle this button
            button.setAttribute(.ariaPressed, newPressed ? true : false)
            if newPressed {
              _ = button.classList.add("toggle-button-selected")
            } else {
              _ = button.classList.remove("toggle-button-selected")
            }

            // Dispatch change event
            guard let value = button.getAttribute("data-value") else { return }
            let event = CustomEvent(type: "toggle-button-change", detail: value)
            group.dispatchEvent(event)
          }

          // Keyboard support
          _ = button.addEventListener(.keydown) { (event: Event) in
            let key = event.key
            if stringEquals(key, "Enter") || stringEquals(key, " ") {
              event.preventDefault()
              button.click()
            }
          }
        }
      }
    }
  }
#endif
