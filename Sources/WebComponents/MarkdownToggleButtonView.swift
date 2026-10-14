#if SERVER
import DesignTokens
import DOMBuilder
import HTMLBuilder
import WebTypes

/// Shows the Markdown source; pressed while its code is visible.
public struct MarkdownToggleButtonView: HTMLContent {
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
      label: "Markdown",
      icon: IconView(icon: { s in MarkdownIconView(size: s) }, size: sizeIconSmall),
      modelValue: pressed, weight: .subtle, buttonColor: .gray,
      disabled: disabled, iconOnly: true,
      ariaLabel: "Markdown mode (edit source)", size: .medium,
      class: `class`.isEmpty ? "markdown-toggle-button-view" : "markdown-toggle-button-view \(`class`)"
    ).build()
    return (view as? DOM.Element)?.addingAttribute("title", "Markdown source—switch to this mode to edit") ?? view
  }
}
#endif
