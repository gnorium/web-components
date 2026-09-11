#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A ToggleSwitch enables the user to instantly toggle between on and off states.
  ///
  /// Component Integration:
  /// - Integrates LabelView for label and description rendering
  public struct ToggleSwitchView: HTMLContent {
    let id: String
    let name: String
    let inputValue: String
    let checked: Bool
    let alignSwitch: Bool
    let hideLabel: Bool
    let disabled: Bool
    let labelContent: [DOM.Node]
    let descriptionContent: [DOM.Node]
    let `class`: String

    public init(
      id: String,
      name: String,
      inputValue: String = "",
      checked: Bool = false,
      alignSwitch: Bool = false,
      hideLabel: Bool = false,
      disabled: Bool = false,
      class: String = "",
      @HTMLBuilder label: () -> [DOM.Node],
      @HTMLBuilder description: () -> [DOM.Node] = { [] }
    ) {
      self.id = id
      self.name = name
      self.inputValue = inputValue
      self.checked = checked
      self.alignSwitch = alignSwitch
      self.hideLabel = hideLabel
      self.disabled = disabled
      self.`class` = `class`
      self.labelContent = label()
      self.descriptionContent = description()
    }

  public func build() -> DOM.Node {
    let hasDescription = !descriptionContent.isEmpty
    let descriptionID = hasDescription ? "\(id)-description" : nil

    // Create a wrapper div to hold LabelView and apply toggle-specific styles
    let labelWrapper: HTML.HTMLDivElement = div {
      LabelView(
        visuallyHidden: hideLabel,
        inputID: id,
        descriptionID: descriptionID,
        disabled: disabled
      ) {
        labelContent
      } description: {
        if hasDescription {
          descriptionContent
        }
      }
    }
    .class("toggle-switch-label-wrapper")
    .data("align-switch", alignSwitch)
    .data("disabled", disabled)

    return div {
      input()
        .type(.checkbox)
        .id(id)
        .name(name)
        .value(inputValue)
        .checked(checked)
        .disabled(disabled)
        .ariaDescribedby(descriptionID ?? "")
        .class("toggle-switch-input")

      span {
        span {}
          .class("toggle-switch-grip")
          .ariaHidden(true)
      }
      .class("toggle-switch-switch")
      .ariaHidden(true)
      .data("disabled", disabled)

      labelWrapper
    }
    .class(`class`.isEmpty ? "toggle-switch-view" : "toggle-switch-view \(`class`)")
    .data("align-switch", alignSwitch)
    .style {
      selector("&") {
        display(.flex)
        alignItems(.center)
        minHeight(minSizeInteractivePointer)
        gap(spacing8)
      }
      selector("&[data-align-switch='true']") {
        justifyContent(.spaceBetween).important()
      }
      descendant(".toggle-switch-label-wrapper") {
        fontWeight(fontWeightNormal).important()
        cursor(cursorBase).important()
        userSelect(.none).important()
      }
      selector("& .toggle-switch-label-wrapper[data-align-switch='true']") {
        flex(1).important()
      }
      selector("& .toggle-switch-label-wrapper[data-disabled='true']") {
        cursor(cursorNotAllowed).important()
      }
      descendant(".toggle-switch-input") {
        position(.absolute)
        width(px(1))
        height(px(1))
        margin(px(-1))
        padding(0)
        overflow(.hidden)
        clip(rect(0, 0, 0, 0))
        whiteSpace(.nowrap)
        borderWidth(0)
        cursor(cursorBase)
        pseudoClass(.disabled) {
          cursor(cursorNotAllowed)
        }
        pseudoClass(.checked, .not(.disabled)) {
          nextSibling(".toggle-switch-switch") {
            backgroundColor(backgroundColorInputBinaryChecked).important()
          }
          selector("+ .toggle-switch-switch .toggle-switch-grip") {
            left(spacingToggleSwitchGripEnd).important()
          }
        }
        pseudoClass(.focus) {
          nextSibling(".toggle-switch-switch") {
            borderColor(borderColorInputBinaryFocus).important()
            boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
          }
        }
        pseudoClass(.hover, .not(.disabled)) {
          nextSibling(".toggle-switch-switch") {
            borderColor(borderColorInputBinaryHover).important()
          }
        }
      }
      descendant(".toggle-switch-switch") {
        position(.relative)
        display(.inlineBlock)
        flexShrink(0)
        width(widthToggleSwitch)
        height(heightToggleSwitch)
        minWidth(minWidthToggleSwitch)
        minHeight(minHeightToggleSwitch)
        backgroundColor(backgroundColorInteractive)
        border(borderWidthBase, .solid, borderColorInputBinary)
        borderRadius(borderRadiusPill)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        cursor(cursorBase)
      }
      selector("& .toggle-switch-switch[data-disabled='true']") {
        backgroundColor(backgroundColorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
        opacity(opacityMedium).important()
      }
      descendant(".toggle-switch-grip") {
        position(.absolute)
        top(perc(50))
        left(spacingToggleSwitchGripStart)
        transform(translateY(perc(-50)))
        width(minSizeToggleSwitchGrip)
        height(minSizeToggleSwitchGrip)
        backgroundColor(colorInvertedFixed)
        borderRadius(borderRadiusCircle)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        boxShadow(boxShadowSmall)
      }
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

  private class ToggleSwitchInstance: @unchecked Sendable {
    private var toggleSwitch: DOM.Element
    private var input: DOM.Element?

    init(toggleSwitch: DOM.Element) {
      self.toggleSwitch = toggleSwitch
      input = toggleSwitch.querySelector(".toggle-switch-input")

      bindEvents()
    }

    private func bindEvents() {
      guard let input else { return }

      // Dispatch custom change event when toggle state changes
      _ = input.addEventListener(.change) { [self] _ in
        let isChecked = input.hasAttribute("checked")
        let event = CustomEvent(type: "toggle-switch-change", detail: isChecked ? "true" : "false")
        self.toggleSwitch.dispatchEvent(event)
      }
    }
  }

  public class ToggleSwitchHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: ToggleSwitchHydration?
    private var instances: [ToggleSwitchInstance] = []

    public init() {
      hydrateAllToggleSwitches()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".toggle-switch-view") != nil else { return }
      instance = ToggleSwitchHydration()
    }

    private func hydrateAllToggleSwitches() {
      let allToggleSwitches = document.querySelectorAll(".toggle-switch-view")

      for toggleSwitch in allToggleSwitches {
        let instance = ToggleSwitchInstance(toggleSwitch: toggleSwitch)
        instances.append(instance)
      }
    }
  }
#endif
