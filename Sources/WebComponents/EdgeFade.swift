import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import WebTypes

#if CLIENT
  import WebAPIs
#endif

// A value too long for its box is clipped and fades out at its edge, instead
// of being cut at a character and ended with an ellipsis: the letters that are
// shown are the value's own, none is replaced by "…", and the fade says the
// line goes on. Both SERVER and CLIENT: tables are drawn on either side, so
// the rules and the hydration live together and must stay embedded-safe.
//
// The line also scrolls sideways under a swipe, a trackpad or a shift-wheel,
// with no scrollbar drawn: the fade says it is cut off, the scroll reaches the
// rest (user, 2026-10-08). A fade stands at each edge that hides some of it—
// the end while more remains, the start once scrolled—and follows the scroll
// as it moves: `EdgeFadeHydration` marks the box `data-overflowing-start` and
// `data-overflowing-end`, and those marks set the custom properties that are
// the mask's two fade lengths. Every box scrolls, a closed dropdown's value
// too (user, 2026-10-08).
//
// The fade is drawn only on a box whose line actually runs past it—a short
// value right-aligned against the box's end would otherwise fade too—so the
// box is marked `data-overflowing` by `EdgeFadeHydration`, which measures it.
// Before hydration a long value is simply clipped.
//
// A box that opts in with `data-edge-fade="expand"` also expands, on every
// device, wide or narrow, by mouse or by touch (user, 2026-10-08): a click or
// a tap wraps it to show the whole value, and another folds it back. A link
// in the box (or the control the box is in: a menu option, a select) keeps
// its click: a click on its words follows it, and only a click in a fade
// itself (the `sizeEdgeFade` of the box at an edge that hides some of it)
// opens the box. Any other box opens on a click anywhere in it. Open, the box
// folds on a click off its link, or anywhere off it. Focused (by a click),
// Enter or Space opens and folds it; Enter on its link follows the link.
//
// No box is made a tab stop, on any device (user, 2026-10-08): a table of
// them would be dozens of stops, and dozens of buttons to a screen reader.
// Where a browser would make a scrollable box focusable on its own (Chrome),
// it is given `tabindex="-1"`, so Tab passes it by while a click still
// focuses it, the arrow keys scroll it, and Enter or Space opens it. Nor is
// it given a role: its open state is `data-edge-fade-expanded`, not
// `aria-expanded`, which ARIA allows on no generic element. Opening is for
// the eye alone: a clipped line is read whole by a screen reader already.
//
// An editable one-line input (`fadeInputOverflow`) keeps its own native
// scroll and caret; it is marked as any box is, from its own scroll, and
// fades only at rest, never while focused. Its fade is drawn over it in its
// ground color rather than by a mask, since a mask would fade its border
// and ground too. A textarea wraps, and has none.
// No vertical writing mode is handled yet: the fade and the measure are the
// inline axis of horizontal text, left-to-right or right-to-left.

/// Clip `selectors` to one line that scrolls sideways, fading out each edge
/// that hides some of it.
///
/// The fades follow the reading direction: the start is the left in
/// left-to-right text, the right under `:dir(rtl)`. Each is `sizeEdgeFade`
/// long. An expanded box (`data-edge-fade-expanded="true"`) wraps instead.
@CSSBuilder
public func fadeOverflow(_ selectors: String...) -> [CSSOM.CSSRule] {
  selector(edgeFadeSelectors(selectors, "")) {
    whiteSpace(.nowrap)
    textOverflow(.clip)
    customProperty("--edge-fade-start", "0px")
    customProperty("--edge-fade-end", sizeEdgeFade.value)
  }
  selector(edgeFadeSelectors(selectors, "")) {
    overflowX(.auto)
    overflowY(.hidden)
    scrollbarWidth(.none)
  }
  selector(edgeFadeSelectors(selectors, "::-webkit-scrollbar")) {
    display(.none).important()
  }
  selector(edgeFadeSelectors(selectors, "[data-overflowing-start='true']")) {
    customProperty("--edge-fade-start", sizeEdgeFade.value)
  }
  selector(edgeFadeSelectors(selectors, "[data-overflowing-end='false']")) {
    customProperty("--edge-fade-end", "0px")
  }
  selector(edgeFadeSelectors(selectors, "[data-overflowing='true']:not([data-edge-fade-expanded='true'])")) {
    maskImage(.custom(edgeFadeGradient(.right)))
    webkitMaskImage(.custom(edgeFadeGradient(.right)))
  }
  selector(edgeFadeSelectors(selectors, "[data-overflowing='true']:not([data-edge-fade-expanded='true']):dir(rtl)")) {
    maskImage(.custom(edgeFadeGradient(.left)))
    webkitMaskImage(.custom(edgeFadeGradient(.left)))
  }
  selector(edgeFadeSelectors(selectors, "[data-edge-fade-expanded]")) {
    cursor(.pointer)
  }
  // Wrapped where it must, anywhere at all: an ID or a URL has no spaces. A
  // box that lays its value out as a row wraps the row as well. Shown whole
  // too, with no fade, while a link or a control in it (or the one it is
  // in) has the keyboard's focus: Tab reaches the link, not the box, so the
  // whole value is in sight as it would be in an input. A click's focus is
  // no `:focus-visible`, and leaves the box as it was.
  selector(edgeFadeSelectors(selectors, "[data-edge-fade-expanded='true']")) {
    whiteSpace(.normal).important()
    overflowWrap(.anywhere).important()
    flexWrap(.wrap).important()
  }
  // A rule of its own: a browser without `:has` drops it, not the one above.
  selector(
    stringJoin(
      [edgeFadeSelectors(selectors, edgeFadeFocusOpen[0]), edgeFadeSelectors(selectors, edgeFadeFocusOpen[1])],
      separator: ", ")
  ) {
    whiteSpace(.normal).important()
    overflowWrap(.anywhere).important()
    flexWrap(.wrap).important()
    maskImage(.custom("none")).important()
    webkitMaskImage(.custom("none")).important()
  }
}

/// Fade the value of the one-line `input` at rest: an input marked
/// `data-edge-fade` (by its component), drawn in the box `control`, which
/// holds it as a direct child and is positioned.
///
/// The input scrolls as inputs do, and `EdgeFadeHydration` marks it from its
/// own `scrollLeft` and `scrollWidth`, as it marks any box. The fades are
/// two layers of `control` (its `::before` at the start, `::after` at the
/// end), `sizeEdgeFade` long, from clear to the input's ground. They stand
/// at the inner edges of its padding, so its border and ground are left
/// whole, and only while it is not focused: focused, the caret is in sight.
/// The component sets on `control` the input's ground,
/// `--edge-fade-ground`, and its border and padding at each side,
/// `--edge-fade-inset-start` and `--edge-fade-inset-end`.
@CSSBuilder
public func fadeInputOverflow(control: String, input: String) -> [CSSOM.CSSRule] {
  selector("\(control)::before", "\(control)::after") {
    content("\"\"")
    position(.absolute)
    top(borderWidthBase)
    bottom(borderWidthBase)
    width(sizeEdgeFade)
    pointerEvents(.none)
    opacity(0)
  }
  selector("\(control)::before") {
    insetInlineStart(`var`("--edge-fade-inset-start") as CSS.Length)
    backgroundImage("linear-gradient(to left, transparent, var(--edge-fade-ground))")
  }
  selector("\(control)::after") {
    insetInlineEnd(`var`("--edge-fade-inset-end") as CSS.Length)
    backgroundImage("linear-gradient(to right, transparent, var(--edge-fade-ground))")
  }
  selector("\(control):dir(rtl)::before") {
    backgroundImage("linear-gradient(to right, transparent, var(--edge-fade-ground))")
  }
  selector("\(control):dir(rtl)::after") {
    backgroundImage("linear-gradient(to left, transparent, var(--edge-fade-ground))")
  }
  selector(
    "\(control):has(> \(input)[data-overflowing='true'][data-overflowing-start='true']:not(:focus))::before"
  ) {
    opacity(1)
  }
  selector(
    "\(control):has(> \(input)[data-overflowing='true'][data-overflowing-end='true']:not(:focus))::after"
  ) {
    opacity(1)
  }
}

/// An expandable box shown whole while the keyboard's focus is on a control
/// in it, or on the control it is in: suffixes for its selectors.
public let edgeFadeFocusOpen = [
  "[data-edge-fade='expand']:has(:focus-visible)",
  "[data-edge-fade='expand']:is(:focus-visible *)",
]

/// Each selector with `suffix` on it, as one selector list.
private func edgeFadeSelectors(_ selectors: [String], _ suffix: String) -> String {
  var parts: [String] = []
  for selector in selectors {
    parts.append("\(selector)\(suffix)")
  }
  return stringJoin(parts, separator: ", ")
}

/// Opaque over the box, clear at both its edges along `toward` (the reading
/// direction: `.right` in left-to-right text): the mask for a line hidden at
/// its start, its end, or both. Each fade's length is a custom property,
/// `--edge-fade-start` and `--edge-fade-end` (`sizeEdgeFade`, or nothing),
/// so the marks the scroll sets move the fades under one mask.
private func edgeFadeGradient(_ toward: CSS.GradientDirection) -> String {
  "linear-gradient(\(toward.rawValue), transparent, black var(--edge-fade-start), "
    + "black calc(100% - var(--edge-fade-end)), transparent)"
}

#if CLIENT
  /// Keeps every `[data-edge-fade]` box on the page marked: `data-overflowing`
  /// on each whose line runs past it, so `fadeOverflow` fades it, and on an
  /// expandable one whether it is open.
  ///
  /// One watcher for the page, not one per box: the boxes are re-read
  /// whenever the page changes in a way that could change a line's fit—a
  /// node added or its text changed, a class or style or `hidden` turned (a
  /// page of rows shown, a column dragged, a menu opened), the window
  /// resized—at most once a frame. A box a component draws on the client
  /// (a search menu's rows, a dropdown's value) is covered the moment it is
  /// in the page. Taps and keys are taken once, for the whole page.
  public final class EdgeFadeHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: EdgeFadeHydration?
    nonisolated(unsafe) static var refreshQueued = false
    /// What a tap already means something on: a box in one, or holding one,
    /// opens only on a tap in its fade.
    static let controls =
      "a, button, label, summary, select, [role='link'], [role='option'], [role='menuitem'], [role='tab'], "
      + "[role='combobox'], [role='checkbox'], [role='radio'], [role='switch'], [role='button']:not([data-edge-fade])"

    /// Starts the watcher, whether or not the page has a box yet: one may be
    /// drawn later.
    public static func hydrateIfPresent() {
      if let _ = instance { return }
      instance = EdgeFadeHydration()
      document.body.observeMutations(
        childList: true, subtree: true, characterData: true,
        attributeFilter: ["class", "style", "hidden", "open", "data-state"]
      ) {
        EdgeFadeHydration.scheduleRefresh()
      }
      _ = window.addEventListener("resize", { _ in EdgeFadeHydration.scheduleRefresh() }, capture: false, passive: true)
      // Web fonts widen or narrow a line after the first measure.
      _ = window.addEventListener("load", { _ in EdgeFadeHydration.scheduleRefresh() }, capture: false, passive: true)
      // Capture, so a box's tap is settled before a row's own click (which
      // would follow the row's link) ever sees it.
      _ = document.addEventListener("click", { event in EdgeFadeHydration.click(event) }, capture: true, passive: false)
      _ = document.addEventListener("keydown", { event in EdgeFadeHydration.keydown(event) }, capture: true, passive: false)
      // A scroll does not bubble, but it is captured: one listener moves the
      // fades of every box as it scrolls.
      _ = document.addEventListener("scroll", { event in EdgeFadeHydration.scrolled(event) }, capture: true, passive: true)
      // An input's value is no node: typing is heard as typing. Left, an
      // input scrolls back to its start, a frame later.
      _ = document.addEventListener("input", { event in EdgeFadeHydration.scrolled(event) }, capture: true, passive: true)
      _ = document.addEventListener("focusout", { _ in EdgeFadeHydration.scheduleRefresh() }, capture: true, passive: true)
      refresh()
    }

    /// Re-reads the boxes at the next frame, however many changes ask.
    public static func scheduleRefresh() {
      if refreshQueued { return }
      refreshQueued = true
      _ = window.requestAnimationFrame {
        EdgeFadeHydration.refreshQueued = false
        EdgeFadeHydration.refresh()
      }
    }

    /// Re-reads every box now: all the measures first, then the marks, so
    /// one layout serves them all.
    public static func refresh() {
      let boxes = document.querySelectorAll("[data-edge-fade]")
      var overflowing: [Bool] = []
      var edges: [(start: Bool, end: Bool)] = []
      for box in boxes {
        overflowing.append(isExpanded(box) ? isOverflowing(box) : box.scrollWidth > box.clientWidth)
        edges.append(hiddenEdges(box))
      }
      for (index, box) in boxes.enumerated() {
        mark(box, overflowing: overflowing[index])
        markEdges(box, edges[index])
      }
    }

    /// A box scrolled, or an input typed in: its marks follow. The scroll
    /// of anything else (the page, whose target is the document and no
    /// element) is passed by.
    static func scrolled(_ event: Event) {
      guard let box = event.target, !stringIsEmpty(box.tagName), box.hasAttribute(data("edge-fade")) else {
        return
      }
      if !isExpanded(box) { mark(box, overflowing: box.scrollWidth > box.clientWidth) }
      markEdges(box, hiddenEdges(box))
    }

    /// Which of the box's edges hide some of its line: the start once it is
    /// scrolled, the end while more remains. Under right-to-left the scroll
    /// runs from 0 into the negative, so its distance is what counts. Half a
    /// pixel is none: a fractional width leaves a sliver to scroll.
    static func hiddenEdges(_ box: DOM.Element) -> (start: Bool, end: Bool) {
      let offset = box.scrollLeft
      let scrolled = offset < 0 ? -offset : offset
      return (scrolled > 0.5, scrolled + box.clientWidth < box.scrollWidth - 0.5)
    }

    /// Sets the box's edge marks, touching only those that change, which
    /// set the lengths of its two fades (`fadeOverflow`).
    static func markEdges(_ box: DOM.Element, _ edges: (start: Bool, end: Bool)) {
      let start = edges.start ? "true" : "false"
      let end = edges.end ? "true" : "false"
      if !stringEquals(box.getAttribute(data("overflowing-start")) ?? "", start) {
        _ = box.setAttribute(data("overflowing-start"), start)
      }
      if !stringEquals(box.getAttribute(data("overflowing-end")) ?? "", end) {
        _ = box.setAttribute(data("overflowing-end"), end)
      }
    }

    /// Sets `box`'s marks, touching only those that change: each write is a
    /// change the watcher would otherwise hear. An expanded box keeps its
    /// mark: wrapped, it no longer overflows, but it is still the value that
    /// did.
    static func mark(_ box: DOM.Element, overflowing: Bool) {
      if overflowing != isOverflowing(box) {
        if overflowing {
          _ = box.setAttribute(data("overflowing"), "true")
        } else {
          box.removeAttribute(data("overflowing"))
        }
      }
      // An input's focus and attributes (a combobox's role) are its own: it
      // is only marked.
      if isInput(box) { return }
      let expandable = isExpandable(box) && (overflowing || isExpanded(box))
      if expandable {
        if !box.hasAttribute(data("edge-fade-expanded")) { _ = box.setAttribute(data("edge-fade-expanded"), "false") }
      } else if box.hasAttribute(data("edge-fade-expanded")) {
        box.removeAttribute(data("edge-fade-expanded"))
      }
      // No tab stop: Chrome would make a scrollable box one. A click still
      // focuses it, for the arrow keys, and Enter or Space.
      if overflowing && !box.hasAttribute("tabindex") {
        _ = box.setAttribute("tabindex", "-1")
      }
    }

    /// Whether the box is an input (`fadeInputOverflow`): a tab stop of
    /// its own already.
    static func isInput(_ box: DOM.Element) -> Bool {
      stringEquals(box.tagName, "INPUT")
    }

    /// A click or a tap on an expandable box opens or folds it. A link's
    /// words are the link's (and a menu option's the option's): a click on
    /// them follows it. Closed, only the fade opens such a box; open, all of
    /// the link is in sight, and a click anywhere off the box folds it.
    static func click(_ event: Event) {
      let target = event.target
      let box = target?.closest("[data-edge-fade='expand'][data-edge-fade-expanded]")
      for open in document.querySelectorAll("[data-edge-fade='expand'][data-edge-fade-expanded='true']") {
        if let box, box.id == open.id { continue }
        setExpanded(open, false)
      }
      guard let box else { return }
      let expanded = isExpanded(box)
      // On a control (a link in the box, or the control the box is in), the
      // tap is the control's; closed, a tap in the fade is the box's.
      let onControl = target?.closest(controls) != nil
      if onControl && (expanded || !inFade(box, event)) { return }
      // Neither the row's link nor the value's own is followed on a tap
      // that opens or folds the box.
      event.preventDefault()
      event.stopPropagation()
      setExpanded(box, !expanded)
    }

    /// Enter or Space on a focused box opens or folds it; Enter on a link in
    /// it follows the link.
    static func keydown(_ event: Event) {
      guard let target = event.target else { return }
      guard stringEquals(target.getAttribute(data("edge-fade")) ?? "", "expand"),
        target.hasAttribute(data("edge-fade-expanded"))
      else { return }
      let key = event.key
      guard stringEquals(key, "Enter") || stringEquals(key, " ") else { return }
      event.preventDefault()
      event.stopPropagation()
      setExpanded(target, !isExpanded(target))
    }

    static func setExpanded(_ box: DOM.Element, _ expanded: Bool) {
      _ = box.setAttribute(data("edge-fade-expanded"), expanded ? "true" : "false")
      if !expanded {
        mark(box, overflowing: box.scrollWidth > box.clientWidth)
        markEdges(box, hiddenEdges(box))
      }
    }

    static func isExpandable(_ box: DOM.Element) -> Bool {
      stringEquals(box.getAttribute(data("edge-fade")) ?? "", "expand")
    }

    /// Whether an expandable box is open.
    static func isExpanded(_ box: DOM.Element) -> Bool {
      isExpandable(box) && stringEquals(box.getAttribute(data("edge-fade-expanded")) ?? "", "true")
    }

    static func isOverflowing(_ box: DOM.Element) -> Bool {
      box.hasAttribute(data("overflowing"))
    }

    /// Whether `event` fell in one of the box's fades: its `sizeEdgeFade` at
    /// an edge that hides some of its line—the end its text reads toward
    /// (the left under right-to-left) while more remains, the start once
    /// scrolled.
    static func inFade(_ box: DOM.Element, _ event: Event) -> Bool {
      guard let rect = box.getBoundingClientRect() else { return false }
      let style = window.getComputedStyle(box)
      let fade = fadeLength(style)
      let edges = hiddenEdges(box)
      let rtl = stringEquals(style.getPropertyValue("direction"), "rtl")
      let inLeft = event.clientX <= rect.left + fade
      let inRight = event.clientX >= rect.right - fade
      if edges.end && (rtl ? inLeft : inRight) { return true }
      if edges.start && (rtl ? inRight : inLeft) { return true }
      return false
    }

    /// `sizeEdgeFade` in pixels, as the box draws it: its value in the box's
    /// `em` (or in pixels, if the token is ever set in them).
    static func fadeLength(_ style: ComputedStyle) -> Double {
      let fontSize = parseDouble(stringRemoveSuffix(style.getPropertyValue("font-size"), "px")) ?? 16
      let token = style.getPropertyValue("--size-edge-fade")
      if stringEndsWith(token, "px") {
        return parseDouble(stringRemoveSuffix(token, "px")) ?? 2 * fontSize
      }
      if stringEndsWith(token, "em") && !stringEndsWith(token, "rem") {
        return (parseDouble(stringRemoveSuffix(token, "em")) ?? 2) * fontSize
      }
      return 2 * fontSize
    }
  }
#endif
