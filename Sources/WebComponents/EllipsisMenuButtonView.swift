#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A button that toggles an ellipsis popover menu.
  public struct EllipsisMenuButtonView: HTMLContent {
    let `class`: String
    let weight: ButtonView.ButtonWeight

    public init(class: String = "", weight: ButtonView.ButtonWeight = .quiet) {
      self.class = `class`
      self.weight = weight
    }

    public func build() -> DOM.Node {
      div {
        ButtonView(
          icon: IconView(
            icon: { size in
              EllipsisIconView(width: size, height: size)
            }, size: .medium),
          weight: weight,
          size: .large,
          ariaLabel: "Settings",
          class: "navbar-ellipsis-btn"
        )
      }
      .class(`class`.isEmpty ? "ellipsis-menu-button-view" : "ellipsis-menu-button-view \(`class`)")
      .data("navbar-ellipsis", true)
      .ariaExpanded(false)
      .ariaControls("navbar-ellipsis-menu")
      .style {
        position(.relative)
      }
    }
  }
#endif
