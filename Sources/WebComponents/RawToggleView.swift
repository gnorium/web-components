#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The switch between a text and the code it was made from: the markup
  /// icon (`<>`) alone, named "Raw" (user, 2026-10-12)—a reader's footer, a
  /// locution's. A toggle (ToggleButtonView), pressed while the code shows;
  /// its host listens for its `toggle-button-update`.
  public struct RawToggleView: HTMLContent {
    let pressed: Bool
    let disabled: Bool
    let `class`: String

    public init(pressed: Bool = false, disabled: Bool = false, class: String = "") {
      self.pressed = pressed
      self.disabled = disabled
      self.class = `class`
    }

    public func build() -> DOM.Node {
      ToggleButtonView(
        label: "Raw",
        icon: IconView(icon: { s in MarkupIconView(size: s) }, size: sizeIconSmall),
        modelValue: pressed,
        // Subtle, its border showing, as the reactions button beside it
        // in a locution's footer (user, 2026-10-12).
        weight: .subtle,
        buttonColor: .gray,
        disabled: disabled,
        iconOnly: true,
        ariaLabel: "Raw",
        size: .medium,
        class: `class`.isEmpty ? "raw-toggle-view" : "raw-toggle-view \(`class`)"
      )
      .build()
    }
  }
#endif
