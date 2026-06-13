#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Wraps a form field with diff-tracking infrastructure for Disputorium change views.
  ///
  /// WASM hydration listens to input/change events and adds `.diff-changed`, `.diff-added`,
  /// or `.diff-deleted` classes, then populates the annotation span with "Previously: X".
  public struct FieldDiffView: HTMLContent {
    let key: String
    let originalValue: String
    let originalDisplay: String?
    let content: DOM.Node

    public init(
      key: String,
      originalValue: String,
      originalDisplay: String? = nil,
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.key = key
      self.originalValue = originalValue
      self.originalDisplay = originalDisplay
      let nodes = content()
      self.content = nodes.count == 1 ? nodes[0] : DOM.DocumentFragment(nodes)
    }

    public func build() -> DOM.Node {
      div {
        div {
          content
        }
        .class("diff-field-input")
        .style {
          borderRadius(borderRadiusBase)
          transition(.border, transitionDurationMedium, .ease)
        }

        span {}
          .class("diff-annotation")
          .data("diff-annotation", "true")
          .style {
            display(.none)
            fontSize(fontSizeXSmall12)
            fontFamily(typographyFontSans)
            paddingInlineStart(spacing16)
            marginBlockStart(spacing4)
          }
      }
      .class("diff-field")
      .data("diff-field", key)
      .data("original-value", originalValue)
      .data("original-display", originalDisplay ?? "")
      .style {
        display(.flex)
        flexDirection(.column)

        selector("[data-diff-field].diff-changed .diff-annotation") {
          display(.block).important()
          color(colorSubtle)
        }
        selector("[data-diff-field].diff-changed .text-input-input, [data-diff-field].diff-changed .text-input-input:focus, [data-diff-field].diff-changed .text-input-input:hover, [data-diff-field].diff-changed .text-input-input:focus:hover, [data-diff-field].diff-changed .dropdown-trigger, [data-diff-field].diff-changed .dropdown-trigger:focus, [data-diff-field].diff-changed .dropdown-trigger:hover, [data-diff-field].diff-changed .dropdown-trigger:focus:hover, [data-diff-field].diff-changed textarea, [data-diff-field].diff-changed textarea:focus, [data-diff-field].diff-changed textarea:hover, [data-diff-field].diff-changed textarea:focus:hover") {
          borderColor(borderColorOrange).important()
          boxShadow(px(0), px(0), px(0), px(1), borderColorOrange).important()
        }
        selector("[data-diff-field].diff-added .text-input-input, [data-diff-field].diff-added .text-input-input:focus, [data-diff-field].diff-added .text-input-input:hover, [data-diff-field].diff-added .text-input-input:focus:hover, [data-diff-field].diff-added .dropdown-trigger, [data-diff-field].diff-added .dropdown-trigger:focus, [data-diff-field].diff-added .dropdown-trigger:hover, [data-diff-field].diff-added .dropdown-trigger:focus:hover, [data-diff-field].diff-added textarea, [data-diff-field].diff-added textarea:focus, [data-diff-field].diff-added textarea:hover, [data-diff-field].diff-added textarea:focus:hover") {
          borderColor(borderColorGreen).important()
          boxShadow(px(0), px(0), px(0), px(1), borderColorGreen).important()
        }
        selector("[data-diff-field].diff-deleted .text-input-input, [data-diff-field].diff-deleted .text-input-input:focus, [data-diff-field].diff-deleted .text-input-input:hover, [data-diff-field].diff-deleted .text-input-input:focus:hover, [data-diff-field].diff-deleted .dropdown-trigger, [data-diff-field].diff-deleted .dropdown-trigger:focus, [data-diff-field].diff-deleted .dropdown-trigger:hover, [data-diff-field].diff-deleted .dropdown-trigger:focus:hover, [data-diff-field].diff-deleted textarea, [data-diff-field].diff-deleted textarea:focus, [data-diff-field].diff-deleted textarea:hover, [data-diff-field].diff-deleted textarea:focus:hover") {
          borderColor(borderColorRed).important()
          boxShadow(px(0), px(0), px(0), px(1), borderColorRed).important()
        }
      }
    }
  }
#endif
