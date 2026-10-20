#if SERVER
import DesignTokens
import DOMBuilder
import HTMLBuilder
import WebTypes

/// Shows a document's header, as code (user, 2026-10-21): after the XML
/// switch where there is one, and like it subtle and bordered, but never
/// tied to it—a header shows with or without its pages' XML. "Header" is the
/// browser's own tooltip; "Show the header" its accessible name.
public struct HeaderToggleButtonView: HTMLContent {
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
      label: "Header",
      icon: IconView(icon: { s in PanelTopIconView(size: s) }, size: sizeIconSmall),
      modelValue: pressed, weight: .subtle, buttonColor: .gray,
      disabled: disabled, iconOnly: true,
      ariaLabel: "Show the header", size: .medium,
      class: `class`.isEmpty ? "header-toggle-button-view" : "header-toggle-button-view \(`class`)"
    ).build()
    return (view as? DOM.Element)?.addingAttribute("title", "Header") ?? view
  }
}
#endif
