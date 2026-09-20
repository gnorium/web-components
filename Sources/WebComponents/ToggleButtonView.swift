#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A button that can be toggled on and off with state persistence.
  ///
  /// Unselected (off): `colorBase` label + base surface / subtle border — same language
  /// as ColorScheme “Dark”. Selected (on): solid blue fill + inverted label — same as
  /// ColorScheme “Light”.
  public struct ToggleButtonView: HTMLContent {
    let label: String
    let icon: DOM.Node?
    let modelValue: Bool
    let weight: ButtonView.ButtonWeight
    let buttonColor: ButtonView.ButtonColor
    let disabled: Bool
    let iconOnly: Bool
    let fullWidth: Bool
    let ariaLabel: String?
    let ariaExpanded: Bool?
    let indicateSelection: Bool
    let size: ButtonView.ButtonSize
    var `class`: String
    let labelFontWeight: CSS.FontWeight

    public init<T: HTMLContent>(
      label: String,
      icon: T? = nil,
      modelValue: Bool = false,
      weight: ButtonView.ButtonWeight = .static,
      buttonColor: ButtonView.ButtonColor = .gray,
      disabled: Bool = false,
      iconOnly: Bool = false,
      fullWidth: Bool = false,
      ariaLabel: String? = nil,
      ariaExpanded: Bool? = nil,
      indicateSelection: Bool = true,
      size: ButtonView.ButtonSize = .medium,
      class: String = "",
      labelFontWeight: CSS.FontWeight = fontWeightNormal
    ) {
      self.label = label
      self.icon = icon.map { $0.build() }
      self.modelValue = modelValue
      self.weight = weight
      self.buttonColor = buttonColor
      self.disabled = disabled
      self.iconOnly = iconOnly
      self.fullWidth = fullWidth
      self.ariaLabel = ariaLabel
      self.ariaExpanded = ariaExpanded
      self.indicateSelection = indicateSelection
      self.size = size
      self.class = `class`
      self.labelFontWeight = labelFontWeight
    }

    public func build() -> DOM.Node {
      let isIconOnly = iconOnly || (icon != nil && label.isEmpty)
      let fullClass = `class`.isEmpty ? "toggle-button-view" : "toggle-button-view \(`class`)"

      return div {
        ButtonView(
          label: "",
          buttonColor: buttonColor,
          weight: weight,
          size: size,
          disabled: disabled,
          ariaLabel: ariaLabel ?? label,
          fullWidth: fullWidth,
          class: "",
          labelFontWeight: self.labelFontWeight,
          borderRadius: borderRadiusPill
        ) {
          if let icon = icon {
            span { icon }
              .class("button-icon")
              .ariaHidden(true)
              .data("size", size.rawValue)
              .style {
                selector("&") {
                  display(.flex)
                  alignItems(.center)
                  justifyContent(.center)
                }
                selector("&[data-size='mini']", "&[data-size='small']") {
                  width(sizeIconXSmall)
                  height(sizeIconXSmall)
                }
                selector("&[data-size='medium']") {
                  width(sizeIconSmall)
                  height(sizeIconSmall)
                }
                selector("&[data-size='large']") {
                  width(sizeIconMedium)
                  height(sizeIconMedium)
                }
              }
          }

          if !label.isEmpty {
            span { label }
              .class(isIconOnly ? "toggle-button-label-hidden" : "toggle-button-label")
          }
        }
      }
      .class(fullClass)
      .data("toggle-button", "true")
      .data("full-width", fullWidth)
      .data("indicate-selection", indicateSelection)
      .ariaPressed(modelValue)
      .ariaExpanded(ariaExpanded ?? false)
      .style {
        selector("&") {
          flexShrink(0)
        }
        selector("&[data-full-width='true']") {
          display(.flex)
        }
        selector("&[data-full-width='false']") {
          display(.inlineFlex)
        }

        // Off: colorBase (ColorScheme unselected / “Dark”). Gated the same
        // way the ON rule below is — a caller that passes `indicateSelection:
        // false` to keep its own coloured base (a permanently solid button
        // that merely toggles WHAT it does, not how it looks) was having its
        // white-on-blue label overridden back to colorBase regardless, which
        // read as black text on a blue pill.
        selector("&[data-indicate-selection='true'][aria-pressed='false'] .button-view") {
          color(colorBase).important()
        }
        selector("&[data-indicate-selection='true'][aria-pressed='false'] .button-view .button-label") {
          color(colorBase).important()
        }
        selector("&[data-indicate-selection='true'][aria-pressed='false'] .button-view .button-icon") {
          color(colorBase).important()
        }

        // On: solid blue pill (ColorScheme selected / “Light”).
        selector("&[data-indicate-selection='true'][aria-pressed='true'] .button-view") {
          backgroundColor(backgroundColorBlue).important()
          borderColor(backgroundColorBlue).important()
          color(colorInvertedFixed).important()
        }
        selector("&[data-indicate-selection='true'][aria-pressed='true'] .button-view .button-label") {
          color(colorInvertedFixed).important()
        }
        selector("&[data-indicate-selection='true'][aria-pressed='true'] .button-view .button-icon") {
          color(colorInvertedFixed).important()
        }
        selector(
          "&[data-indicate-selection='true'][aria-pressed='true'] .button-view:hover:not(:disabled)"
        ) {
          backgroundColor(backgroundColorBlueHover).important()
          borderColor(borderColorBlueHover).important()
        }
        selector(
          "&[data-indicate-selection='true'][aria-pressed='true'] .button-view:active:not(:disabled)"
        ) {
          backgroundColor(backgroundColorBlueActive).important()
          borderColor(borderColorBlueActive).important()
        }

        descendant(".toggle-button-label-hidden") {
          position(.absolute)
          width(px(1))
          height(px(1))
          padding(0)
          margin(px(-1))
          overflow(.hidden)
          clip(rect(0, 0, 0, 0))
          whiteSpace(.nowrap)
          borderWidth(0)
        }
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

  private class ToggleButtonInstance: @unchecked Sendable {
    private var button: DOM.Element
    private var modelValue: Bool = false

    init(button: DOM.Element) {
      self.button = button

      if let ariaPressed = button.getAttribute("aria-pressed") {
        modelValue = stringEquals(ariaPressed, "true")
      }

      bindEvents()
    }

    private func bindEvents() {
      _ = button.addEventListener(.click) { [self] _ in
        self.toggle()
      }

      _ = button.addEventListener(.keydown) { [self] (event: Event) in
        let key = event.key
        if stringEquals(key, "Enter") || stringEquals(key, " ") {
          self.toggle()
        }
      }
    }

    private func toggle() {
      if let ariaPressed = button.getAttribute("aria-pressed") {
        modelValue = stringEquals(ariaPressed, "true")
      }

      modelValue.toggle()
      button.setAttribute(.ariaPressed, modelValue ? true : false)

      let event = CustomEvent(type: "toggle-button-update", detail: modelValue ? "true" : "false")
      button.dispatchEvent(event)
    }
  }

  public class ToggleButtonHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: ToggleButtonHydration?
    private var instances: [ToggleButtonInstance] = []

    public init() {
      hydrateAllToggleButtons()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".toggle-button-view") != nil else { return }
      instance = ToggleButtonHydration()
    }

    private func hydrateAllToggleButtons() {
      let allButtons = document.querySelectorAll("[data-toggle-button=\"true\"]")

      for button in allButtons {
        // Readers and other fragments can arrive after the document's first
        // hydration pass. Mark each binding so a later pass wires only those
        // new controls, rather than making every existing toggle fire twice.
        guard !stringEquals(button.dataset["toggleHydrated"] ?? "false", "true") else { continue }
        button.dataset["toggleHydrated"] = "true"
        let instance = ToggleButtonInstance(button: button)
        instances.append(instance)
      }
    }
  }
#endif
