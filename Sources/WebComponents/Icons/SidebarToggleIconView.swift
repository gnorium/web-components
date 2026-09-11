#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct SidebarToggleIconView: HTMLContent {
    let `class`: String

    public init(class: String = "") {
      self.class = `class`
    }

    public func build() -> DOM.Node {
      span {
        span {}
          .class("sidebar-toggle-icon-line sidebar-toggle-icon-line-middle")
      }
      .class(`class`.isEmpty ? "sidebar-toggle-icon-view" : "sidebar-toggle-icon-view \(`class`)")
      .style {
        selector("&") {
          position(.relative)
          display(.inlineBlock)
          width(px(20))
          height(px(16))
          cursor(.pointer)
        }

        selector("& .sidebar-toggle-icon-line-middle", "&::before", "&::after") {
          position(.absolute)
          width(perc(100))
          height(px(2))
          backgroundColor(.currentColor)
          transition(.all, s(0.2), .easeInOut)
          left(0)
          display(.block)
          borderRadius(px(1))
        }

        descendant(".sidebar-toggle-icon-line-middle") {
          top(perc(50))
          transform(translateY(perc(-50)))
        }

        pseudoElement(.before) {
          content("\"\"")
          top(0)
        }

        pseudoElement(.after) {
          content("\"\"")
          bottom(0)
        }
      }
    }
  }
#endif
