#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Specialized button for the Admin Console link
  public struct AdminConsoleButtonView: HTMLContent {
    let url: String
    let size: ButtonView.ButtonSize

    public init(url: String = "/admin-console", size: ButtonView.ButtonSize = .large) {
      self.url = url
      self.size = size
    }

    public func build() -> DOM.Node {
      div {
        ButtonView(
          label: "",
          icon: IconView(
            icon: { s in ConfigureIconView(width: s, height: s) },
            size: size == .small ? .xSmall : size == .medium ? .small : .medium),
          weight: .plain,
          size: size,
          url: url,
          ariaLabel: "Admin Console",
          class: "navbar-admin-console-btn"
        )
      }
      .class("admin-console-button-view")
      .title("Admin Console")
      .style {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
      }

    }
  }
#endif
