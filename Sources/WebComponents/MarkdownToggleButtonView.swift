import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Shows the Markdown source; pressed while its code is visible. SERVER +
/// CLIENT: a streamed continuation prompt's legend carries it too.
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
      icon: IconView(icon: { s in MarkdownIconView(size: s) }, size: ButtonView.ButtonSize.medium.iconSize),
      modelValue: pressed, weight: .subtle, buttonColor: .gray,
      disabled: disabled, iconOnly: true,
      ariaLabel: "Markdown mode (edit source)", size: .medium,
      class: stringIsEmpty(`class`) ? "markdown-toggle-button-view" : "markdown-toggle-button-view \(`class`)"
    ).build()
    return (view as? DOM.Element)?.addingAttribute("title", "Markdown source—switch to this mode to edit") ?? view
  }
}
