#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import Foundation
  import HTMLBuilder
  import DOMBuilder
  import WebTypes

  /// A Tab is one of the selectable items included within Tabs.
  /// Must be used with Tabs component - this component is only meant to be used inside TabsView.
  public struct TabView: HTMLContent, Sendable {
    public let name: String
    public let label: String
    public let disabled: Bool
    public let url: String?
    public let content: [DOM.Node]
    let `class`: String

    public init(
      name: String,
      label: String = "",
      disabled: Bool = false,
      url: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.name = name
      self.label = label.isEmpty ? name : label
      self.disabled = disabled
      self.url = url
      self.content = content()
      self.`class` = `class`
    }

    /// Renders the tab button (called by TabsView)
    public func renderButton(isActive: Bool, tabindex: Int, framed: Bool) -> DOM.Node {
      let displayLabel = label.isEmpty ? name : label
      let tabStateClass = isActive
        ? (framed ? "tab-active tab-framed" : "tab-active")
        : (framed ? "tab-framed" : "")
      let tabClass = `class`.isEmpty
        ? (tabStateClass.isEmpty ? "tab-view" : "tab-view \(tabStateClass)")
        : (tabStateClass.isEmpty ? "tab-view \(`class`)" : "tab-view \(tabStateClass) \(`class`)")

      return button { displayLabel }
        .type(.button)
        .class(tabClass)
        .role("tab")
        .ariaSelected(isActive)
        .ariaControls("panel-\(name)")
        .id("tab-\(name)")
        .data("tab-name", name)
        .disabled(disabled)
        .tabindex(tabindex)
        .style {
          selector("&") {
            display(.inlineFlex)
            alignItems(.center)
            justifyContent(.center)
            minWidth(px(64))
            padding(spacing12, spacing16)
            fontSize(fontSizeMedium16)
            fontWeight(fontWeightNormal)
            lineHeight(lineHeightSmall22)
            whiteSpace(.nowrap)
            textAlign(.center)
            backgroundColor(.transparent)
            border(.none)
            borderBlockEnd(borderWidthThick, .solid, borderColorTransparent)
            color(colorBase)
            cursor(cursorBaseHover)
            transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            position(.relative)
          }
          selector("&.tab-active") {
            color(colorBlue)
            fontWeight(fontWeightSemiBold)
          }
          selector("&.tab-active:not(.tab-framed)") {
            borderBlockEnd(borderWidthThick, .solid, borderColorBlue)
          }
          selector("&.tab-active.tab-framed") {
            backgroundColor(backgroundColorBase)
          }
          selector("&:disabled") {
            color(colorDisabled)
            cursor(cursorNotAllowed)
          }
          selector("&:not(:disabled):not(.tab-active):hover") {
            color(colorBlue).important()
            backgroundColor(backgroundColorBlueSubtle).important()
          }
          selector("&:not(:disabled):not(.tab-active):active") {
            backgroundColor(backgroundColorBlueSubtle).important()
          }
          selector("&:focus") {
            outline(borderWidthThick, .solid, borderColorBlue).important()
            outlineOffset(px(-2)).important()
          }
        }
    }

    /// Renders the tab panel content (called by TabsView)
    public func renderPanel(isActive: Bool, framed: Bool) -> DOM.Node {
      return section {
        content
      }
      .class(framed ? "tab-panel tab-framed" : "tab-panel")
      .role("tabpanel")
      .id("panel-\(name)")
      .ariaLabelledby("tab-\(name)")
      .tabindex(0)
      .hidden(!isActive)
      .style {
        selector("&") {
          padding(spacing16, 0)
        }
        selector("&.tab-framed") {
          padding(spacing16)
        }
      }
    }

    public func build() -> DOM.Node {
      // TabView should not be rendered directly - use TabsView
      .fragment([])
    }
  }
#endif
