#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// One labelled fact, shown as a read-only field shows its value: the label
  /// above, the value in the field's box.
  ///
  /// It looks like a field because it sits among fields and is read the same
  /// way, but it is not one. Nothing can be typed into it and nothing submits
  /// it, so it has no control: the value is ordinary content — text, a link
  /// that clicks, a date — and a screen reader reads it as text rather than
  /// announcing a read-only input. The label is not a `<label>`, since there
  /// is no control for it to label.
  ///
  /// A long value without spaces, an id, breaks anywhere rather than
  /// widening the page.
  public struct DatumView: HTMLContent {
    let label: String
    let value: [DOM.Node]
    let `class`: String

    public init(_ label: String, class: String = "", @HTMLBuilder value: () -> [DOM.Node]) {
      self.label = label
      self.class = `class`
      self.value = value()
    }

    /// The common case: a plain value.
    public init(_ label: String, value: String, class: String = "") {
      self.init(label, class: `class`) { value }
    }

    public func build() -> DOM.Node {
      div {
        div { label }
          .class("datum-label")
        div { value }
          .class("datum-value")
      }
      .class(`class`.isEmpty ? "datum-view" : "datum-view \(`class`)")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          minWidth(0)
        }
        // The field label's type, as TextInputView sets it.
        descendant(".datum-label") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeSmall14)
          fontWeight(fontWeightSemiBold)
          color(colorBase)
        }
        // A read-only field's box, to the pixel: the control height, its
        // padding, border, corner and ground.
        // One line, like the input it looks like: a long id or byline scrolls
        // sideways under a swipe rather than wrapping or ellipsing, with no
        // scrollbar drawn inside the box.
        descendant(".datum-value") {
          display(.flex)
          flexWrap(.nowrap)
          alignItems(.center)
          whiteSpace(.nowrap)
          overflowX(.auto)
          overflowY(.hidden)
          scrollbarWidth(.none)
          minHeight(minSizeInteractiveTouch)
          paddingBlock(spacing8)
          paddingInline(px(15))
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          color(colorBase)
          backgroundColor(backgroundColorNeutralSubtle)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          minWidth(0)
          pseudoElement(.webkitScrollbar) { display(.none).important() }
        }
      }
      .build()
    }
  }
#endif
