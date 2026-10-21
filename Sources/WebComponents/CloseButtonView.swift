  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  public struct CloseButtonView: HTMLContent {
    let ariaLabel: String
    let size: ButtonView.ButtonSize
    let `class`: String

    public init(
      ariaLabel: String = "Close",
      size: ButtonView.ButtonSize = .medium,
      class customClass: String = ""
    ) {
      self.ariaLabel = ariaLabel
      self.size = size
      self.class = customClass
    }

    public func build() -> DOM.Node {
      ButtonView(
        icon: IconView(icon: { size in XIconView(size: size) }, size: size.iconSize),
        weight: .plain,
        size: size,
        ariaLabel: ariaLabel,
        class: "close-button-view \(`class`)"
      ).build()
    }
  }
