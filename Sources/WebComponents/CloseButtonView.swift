  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import EmbeddedSwiftUtilities
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
        icon: IconView(icon: { size in CloseIconView(size: size) }, size: sizeIconSmall),
        weight: .plain,
        size: .medium,
        ariaLabel: ariaLabel,
        class: "close-button-view \(`class`)"
      ).build()
    }
  }
