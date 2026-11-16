#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A button that toggles an ellipsis popover menu; `marked`, its three
  /// dots blue, says something in the menu is new (unread Notices), as the
  /// blue count beside Notices inside it does (user, 2026-11-16: no dot).
  public struct EllipsisMenuButtonView: HTMLContent {
    let `class`: String
    let weight: ButtonView.ButtonWeight
    let marked: Bool

    public init(class: String = "", weight: ButtonView.ButtonWeight = .plain, marked: Bool = false) {
      self.class = `class`
      self.weight = weight
      self.marked = marked
    }

    public func build() -> DOM.Node {
      div {
        ButtonView(
          icon: IconView(
            icon: { size in
              EllipsisIconView(size: size)
            }, size: ButtonView.ButtonSize.large.iconSize),
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
      .data("marked", marked)
      .style {
        selector("&") { position(.relative) }
        selector("&[data-marked='true'] .navbar-ellipsis-btn", "&[data-marked='true'] .navbar-ellipsis-btn:hover") {
          color(colorBlue).important()
        }
      }
    }
  }
#endif
