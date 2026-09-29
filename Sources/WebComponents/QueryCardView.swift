#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The card a page's query sits in: a form sent by GET, bordered and
  /// tinted, its parts one under another. The records lists' filter bar
  /// (`FilterBarView`) and the Graph page's query are each one.
  public struct QueryCardView: HTMLContent {
    let action: String
    let ariaLabel: String?
    let `class`: String
    let content: [DOM.Node]

    public init(
      action: String,
      ariaLabel: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.action = action
      self.ariaLabel = ariaLabel
      self.`class` = `class`
      self.content = content()
    }

    public func build() -> DOM.Node {
      let card = form {
        content
      }
      .action(action)
      .method(.get)
      .class(`class`.isEmpty ? "query-card-view" : "query-card-view \(`class`)")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing12)
          padding(spacing12, spacing16)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          backgroundColor(backgroundColorNeutralSubtle)
          width(perc(100))
        }
      }
      if let ariaLabel {
        return card.ariaLabel(ariaLabel).build()
      }
      return card.build()
    }
  }
#endif
