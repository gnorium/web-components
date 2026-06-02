#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  public struct CloseButtonView: HTMLContent {
    let ariaLabel: String
    let `class`: String

    public init(
      ariaLabel: String = "Close",
      class customClass: String = ""
    ) {
      self.ariaLabel = ariaLabel
      self.class = customClass
    }

    public func build() -> DOM.Node {
      ButtonView(
        icon: IconView {
          CloseIconView()
        },
        weight: .plain,
        size: .large,
        ariaLabel: ariaLabel,
        class: "close-button-view \(`class`)"
      )
      .render()
    }
  }
#endif
