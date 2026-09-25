import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A field, and how it changed: the one way every form part draws a field
/// and its diff — a coloured border on the control and, under it, its
/// "Diff:" line, a `DiffView`.
///
/// Two sources, one look:
///
/// - **Live** (`key:originalValue:`) — a field under edit. The form's
///   hydration finds the wrapper by `data-field-diff-view`, compares the
///   field with `data-original-value` on input and change, marks the control
///   that carries the border with `data-diff-state` — `unchanged`, `added`,
///   `removed`, `changed` — and draws its diff into the slot under it, shown
///   with `data-visible`.
/// - **Saved** (`originalValue:value:`) — a field as an edit left it, drawn by
///   the server: marked `.diff-wrap-added`, `-removed` or `-changed`, its diff
///   already in the slot. A value put where there was none is the new one
///   alone, green; one cleared is the old one alone, red; one changed is
///   "old → new". A field that did not change is the field alone, with
///   neither, and so is one given no original — a form that is not a diff.
///
/// The form that holds the fields draws those states through `stateCSS()`,
/// so fields outside a wrapper — a repeatable list's rows edited live — are
/// drawn the same way.
public struct FieldDiffView: HTMLContent {
  /// How a saved field's two values are compared: the `DiffView` mode.
  public enum Comparison: Sendable {
    /// A one-line text, word by word, then letter by letter.
    case text
    /// A choice — a dropdown's, a date part's — whole, by the names shown.
    case choice
    /// A multi-line text, line by line.
    case passage
    /// A checkbox, its values "true" and "false": one tick, green ticked
    /// (added), red unticked (removed).
    case check
  }

  enum Source {
    case live(key: String)
    case saved(value: String, display: String?, comparison: Comparison)
  }

  let source: Source
  let originalValue: String?
  let originalDisplay: String?
  let content: DOM.Node

  /// A field under edit, its diff drawn in the browser as it changes.
  public init(
    key: String,
    originalValue: String,
    originalDisplay: String? = nil,
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.source = .live(key: key)
    self.originalValue = originalValue
    self.originalDisplay = originalDisplay
    let nodes = content()
    self.content = nodes.count == 1 ? nodes[0] : DOM.DocumentFragment(nodes)
  }

  /// A field as an edit left it, its diff drawn by the server. A choice's
  /// values are shown by their names, `originalDisplay` and `display`, when
  /// given. No `originalValue` draws the field alone.
  public init(
    originalValue: String?,
    value: String,
    originalDisplay: String? = nil,
    display: String? = nil,
    comparison: Comparison = .text,
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.source = .saved(value: value, display: display, comparison: comparison)
    self.originalValue = originalValue
    self.originalDisplay = originalDisplay
    let nodes = content()
    self.content = nodes.count == 1 ? nodes[0] : DOM.DocumentFragment(nodes)
  }

  /// How a field says what an edit did to it, for every form that edits and
  /// every page that shows an edit: green added, red removed, orange changed
  /// — the control's own border, and a ring of the same colour — and its
  /// diff under it shown only once there is one.
  ///
  /// The live diff marks the control with `data-diff-state`; a saved diff
  /// wraps it in `.diff-wrap-added`, `-removed` or `-changed`. The colour is
  /// forced: a dropdown's trigger is a button, and a button's own border
  /// colour otherwise wins, leaving a grey border inside an orange ring.
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
    // A diff the live edit draws inside a control's own box, under the
    // control, spaced from it by the box's gap; hidden, it takes none.
    selector(
      "& .text-input-control:has(> [data-form-item-annotation])",
      "& .dropdown-container:has(> [data-form-item-annotation])",
      "& .dropdown-search-input-wrapper:has(> [data-form-item-annotation])"
    ) {
      display(.flex)
      flexDirection(.column)
      gap(spacing4)
    }
  }

  /// A saved diff colours the field's own control, not the facts a choice
  /// shows about itself in its info panel — they are not fields, and have
  /// no diff line of their own.
  @CSSBuilder
  static func state(_ name: String, color: CSS.Color) -> [CSSOM.CSSRule] {
    selector(
      "& [data-diff-state='\(name)']",
      "& .diff-wrap-\(name) .text-input-input:not(.form-info-panel *)",
      "& .diff-wrap-\(name) .text-area-input:not(.form-info-panel *)",
      "& .diff-wrap-\(name) .dropdown-trigger:not(.form-info-panel *)"
    ) {
      borderColor(color).important()
      boxShadow(px(0), px(0), px(0), px(1), color).important()
    }
  }

  public func build() -> DOM.Node {
    // What the slot under the field holds, and the state its border draws:
    // a live field's are the browser's to fill as it is edited.
    let diff: DiffView?
    let state: String?
    switch source {
    case .live:
      DiffView.preloadStyleSheet()
      diff = nil
      state = nil
    case .saved(let value, let display, let comparison):
      guard let old = originalValue, !stringEquals(old, value) else { return content }
      let emptied = stringIsEmpty(old) ? "added" : (stringIsEmpty(value) ? "removed" : "changed")
      switch comparison {
      case .check:
        // A box ticked is a value added; one unticked, a value removed.
        let ticked = stringEquals(value, "true")
        diff = DiffView(.check(ticked: ticked))
        state = ticked ? "added" : "removed"
      case .text:
        diff = DiffView(.text(old: old, new: value))
        state = emptied
      case .passage:
        diff = DiffView(.passage(old: old, new: value))
        state = emptied
      case .choice:
        diff = DiffView(
          .choice(
            old: stringIsEmpty(old) ? "" : originalDisplay ?? old,
            new: stringIsEmpty(value) ? "" : display ?? value))
        state = emptied
      }
    }

    var wrapper = div {
      div {
        content
      }
      .class("diff-field-input")

      div {
        if let diff { diff }
      }
      .class("field-diff-view-diff")
      .data("diff-annotation", "true")
      .data("visible", state.map { _ in true } ?? false)
    }
    .class(state.map { "field-diff-view diff-wrap-\($0)" } ?? "field-diff-view")
    if case .live(let key) = source {
      wrapper = wrapper
        .data("field-diff-view", key)
        .data("original-value", originalValue ?? "")
        .data("original-display", originalDisplay ?? "")
    }
    return wrapper
      .style {
        // The field, then its diff line: a gap between, none once the
        // slot is hidden.
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          minWidth(0)
        }
        selector("& > .field-diff-view-diff[data-visible='false']") {
          display(.none)
        }
        // A checkbox's diff line starts under its label's text, not under
        // the box: the box's width and the gap the checkbox sets after it.
        selector("&:has(> .diff-field-input > .checkbox-view) > .field-diff-view-diff") {
          paddingInlineStart(calc("\(minSizeInputBinary.value) + \(spacing8.value)"))
        }
        descendant(".diff-field-input") {
          borderRadius(borderRadiusBase)
          transition(.border, transitionDurationMedium, .ease)
        }
      }
      .build()
  }
}
