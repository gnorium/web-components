#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A field under edit, and how it changed.
  ///
  /// The form's hydration finds the wrapper by `data-field-diff-view`, compares
  /// the field with `data-original-value` on input and change, marks the
  /// control that carries the border with `data-diff-state` — `unchanged`,
  /// `added`, `removed`, `changed` — and draws its changes, a `DiffView`, into
  /// the slot under it, shown with `data-visible`. The form that holds the
  /// fields draws those states through `stateCSS()`, so fields outside a
  /// wrapper — a repeatable list's rows, a date's parts — are drawn the same
  /// way.
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

    /// How a field says what an edit did to it, for every form that edits and
    /// every page that shows an edit: green added, red removed, orange changed
    /// — the control's own border, and a ring of the same colour — and its
    /// changes under it shown only once there are some.
    ///
    /// The live diff marks the control with `data-diff-state`; a diff the
    /// server draws wraps it in `.diff-wrap-added`, `-removed` or `-changed`.
    /// The colour is forced: a dropdown's trigger is a button, and a button's
    /// own border colour otherwise wins, leaving a grey border inside an
    /// orange ring.
    @CSSBuilder
    public static func stateCSS() -> [CSSOM.CSSRule] {
      descendant("[data-diff-state='unchanged']") {
        border(borderWidthBase, .solid, borderColorBase)
        boxShadow(.none)
      }
      state("added", color: borderColorGreen)
      state("removed", color: borderColorRed)
      state("changed", color: borderColorOrange)
      descendant("[data-diff-state='focused']") {
        borderColor(borderColorBlueFocus).important()
        boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
      }
      selector(
        "& [data-diff-annotation][data-visible='false']",
        "& [data-form-item-annotation][data-visible='false']"
      ) { display(.none) }
    }

    @CSSBuilder
    static func state(_ name: String, color: CSS.Color) -> [CSSOM.CSSRule] {
      selector(
        "& [data-diff-state='\(name)']",
        "& .diff-wrap-\(name) .text-input-input",
        "& .diff-wrap-\(name) .text-area-input",
        "& .diff-wrap-\(name) .dropdown-trigger"
      ) {
        borderColor(color).important()
        boxShadow(px(0), px(0), px(0), px(1), color).important()
      }
    }

    public func build() -> DOM.Node {
      // The client draws a DiffView into the slot as the field is edited.
      DiffView.preloadStyleSheet()

      return div {
        div {
          content
        }
        .class("diff-field-input")

        div {}
          .class("field-diff-view-changes")
          .data("diff-annotation", "true")
          .data("visible", false)
      }
      .class("field-diff-view")
      .data("field-diff-view", key)
      .data("original-value", originalValue)
      .data("original-display", originalDisplay ?? "")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        descendant(".diff-field-input") {
          borderRadius(borderRadiusBase)
          transition(.border, transitionDurationMedium, .ease)
        }
      }
      .build()
    }
  }
#endif
