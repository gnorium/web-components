#if SERVER
import DesignTokens
import DOMBuilder
import HTMLBuilder
import WebTypes

/// Shows the JSON source; pressed while its code is visible.
public struct JSONToggleButtonView: HTMLContent {
  let pressed: Bool
  let disabled: Bool
  let `class`: String
  public init(pressed: Bool = false, disabled: Bool = false, class: String = "") {
    self.pressed = pressed
    self.disabled = disabled
    self.class = `class`
  }
  public func build() -> DOM.Node {
    let view = ToggleButtonView(
      label: "JSON",
      icon: IconView(icon: { s in BracesIconView(size: s) }, size: ButtonView.ButtonSize.medium.iconSize),
      modelValue: pressed, weight: .subtle, buttonColor: .gray,
      disabled: disabled, iconOnly: true,
      ariaLabel: "JSON mode (edit source)", size: .medium,
      class: `class`.isEmpty ? "json-toggle-button-view" : "json-toggle-button-view \(`class`)"
    ).build()
    return (view as? DOM.Element)?.addingAttribute("title", "JSON source—switch to this mode to edit") ?? view
  }
}
#endif
