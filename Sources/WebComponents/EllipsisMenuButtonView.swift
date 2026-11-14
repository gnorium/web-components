#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A button that toggles an ellipsis popover menu; `marked`, a small blue
  /// dot at its corner, says something in the menu is new (unread Notices).
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
        if marked {
          span { DiscIconView(size: spacing8) }
            .class("ellipsis-menu-button-mark")
            .ariaHidden(true)
        }
      }
      .class(`class`.isEmpty ? "ellipsis-menu-button-view" : "ellipsis-menu-button-view \(`class`)")
      .data("navbar-ellipsis", true)
      .ariaExpanded(false)
      .ariaControls("navbar-ellipsis-menu")
      .style {
        selector("&") { position(.relative) }
        selector("& .ellipsis-menu-button-mark") {
          position(.absolute)
          insetBlockStart(spacing8)
          insetInlineEnd(spacing8)
          display(.flex)
          color(colorBlue)
          pointerEvents(.none)
        }
      }
    }
  }
#endif
