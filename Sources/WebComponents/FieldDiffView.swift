#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Wraps a form field with diff-tracking infrastructure for Disputorium change views.
  ///
  /// The form's hydration finds the wrapper by `data-field-diff-view`, compares
  /// the field with `data-original-value` on input/change, marks the field with
  /// `data-diff-state` (unchanged, added, removed, changed) and fills the
  /// annotation with "Previously: X", showing it with `data-visible`. The form
  /// that holds the fields draws those states, so fields outside a wrapper —
  /// a repeatable list's rows — are drawn the same way.
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

        span {}
          .class("diff-annotation")
          .data("diff-annotation", "true")
      }
      .class("field-diff-view")
      .data("field-diff-view", key)
      .data("original-value", originalValue)
      .data("original-display", originalDisplay ?? "")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
        }
        descendant(".diff-field-input") {
          borderRadius(borderRadiusBase)
          transition(.border, transitionDurationMedium, .ease)
        }
        descendant(".diff-annotation") {
          display(.none)
          fontSize(fontSizeXSmall12)
          fontFamily(typographyFontSans)
          paddingInlineStart(spacing16)
          marginBlockStart(spacing4)
        }
      }
    }
  }
#endif
