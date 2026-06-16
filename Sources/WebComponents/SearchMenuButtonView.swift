#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A button that opens the search menu overlay.
  public struct SearchMenuButtonView: HTMLContent {
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
            icon: { size in SearchIconView(width: size, height: size) },
            size: .medium),
          weight: weight,
          size: .large,
          ariaLabel: "Search"
        )
      }
      .class(`class`.isEmpty ? "search-menu-button-view" : "search-menu-button-view \(`class`)")
      .data("search-trigger", "true")
    }
  }
#endif
