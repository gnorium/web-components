#if SERVER
import DesignTokens
import DOMBuilder
import HTMLBuilder
import WebTypes

/// Shows the XML source; pressed while its code is visible.
public struct XMLToggleButtonView: HTMLContent {
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
      label: "XML",
      icon: IconView(icon: { s in CodeXMLIconView(size: s) }, size: ButtonView.ButtonSize.medium.iconSize),
      modelValue: pressed, weight: .subtle, buttonColor: .gray,
      disabled: disabled, iconOnly: true,
      ariaLabel: "XML", size: .medium,
      class: `class`.isEmpty ? "xml-toggle-button-view" : "xml-toggle-button-view \(`class`)"
    ).build()
    return (view as? DOM.Element)?.addingAttribute("title", "XML").addingAttribute("data-phone-floor", "true") ?? view
  }
}
#endif
