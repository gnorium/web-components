#if CLIENT
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebAPIs
import WebTypes

/// Corresponding source lines, including wrapped portions, move together.
/// Listen on actual scrollports; only the latest user scroll drives matching.
/// A diff box drawn as large as its lines (under a reader's markup pane)
/// scrolls in its zone, which is then the diff's side (user, 2026-10-16).
public enum PassageDiffSyncViewHydration {
  public static func hydrate(in root: DOM.Element) {
    for field in root.querySelectorAll(".field-diff-view") {
      if let source = field.querySelector(".diff-field-input .code-code, .diff-field-input textarea, textarea") {
        bind(field, source: source, box: field.querySelector(".diff-box"))
      }
    }
    for comparison in root.querySelectorAll(".prompt-text-comparison") {
      if let source = comparison.querySelector("pre.prompt-text-source") {
        bind(comparison, source: source, box: comparison.querySelector(".diff-box"))
      }
    }
    for reader in root.querySelectorAll(".testament-view") {
      let translated = stringEquals(reader.querySelector(".artifact-view")?.getAttribute("data-translated") ?? "false", "true")
      let layer = translated ? "translated-markup" : "markup"
      if let source = reader.querySelector(".tei-page[data-active='true'] [data-layer='" + layer + "'] .code-code"),
        let slot = reader.querySelector(".testament-diff[data-active='true']") {
        let box = translated ? slot.querySelector(".testament-translation-diff .diff-box") : slot.querySelector(".image-diff-view .diff-box")
        bind(reader, source: source, box: box)
      }
    }
  }

  public static func bindBox(_ field: DOM.Element, area: HTML.HTMLTextAreaElement) {
    bind(field, source: field.querySelector(".code-code") ?? area, box: field.querySelector(".diff-box"))
  }

  private static func scrollport(_ source: DOM.Element, within scope: DOM.Element) -> DOM.Element {
    if let pane = source.closest(".artifact-markup, .sense-editor-raw") { return pane }
    var node: DOM.Element? = source
    while let current = node {
      let overflow = window.getComputedStyle(current).getPropertyValue("overflow-y")
      if stringEquals(overflow, "auto") || stringEquals(overflow, "scroll") {
        // An unconstrained inner code block can have overflow:auto without
        // owning vertical scrolling. Continue to its constrained parent.
        if current.id == source.id || current.clientHeight == 0 || current.scrollHeight > current.clientHeight + 1 { return current }
      }
      if current.id == scope.id { break }
      node = current.parentElement
    }
    return source
  }

  private static func bind(_ scope: DOM.Element, source: DOM.Element, box: DOM.Element?) {
    guard let box else { return }
    let port = scrollport(source, within: scope)
    let diffPort = box.closest(".artifact-under-markup") ?? box
    let key = intToString(Int(source.id)) + ":" + intToString(Int(box.id))
    if stringEquals(scope.getAttribute("data-passage-pair") ?? "", key) { return }
    scope.setAttribute("data-passage-pair", key)
    let pair = Pair(scope: scope, source: source, port: port, box: box, diffPort: diffPort, key: key)
    pair.presentation()
    source.observeResize { _, _ in pair.presentation() }
    scope.observeMutations(subtree: true, attributeFilter: ["data-reflow", "style", "class"]) { pair.presentation() }
    _ = port.addEventListener(.scroll) { _ in pair.schedule(fromSource: true) }
    _ = diffPort.addEventListener(.scroll) { _ in pair.schedule(fromSource: false) }
  }

  private final class Pair: @unchecked Sendable {
    let scope: DOM.Element, source: DOM.Element, port: DOM.Element, box: DOM.Element
    /// What scrolls the diff: its box, or the zone it is drawn whole in.
    let diffPort: DOM.Element
    let key: String
    var queued = false
    var fromSource = true
    var cachedText = ""
    var cachedStyle = ""
    var cachedWidth = 0.0
    var cachedHeight = 0.0
    var cachedPositions: [Double] = []
    var presentationKey = ""

    init(scope: DOM.Element, source: DOM.Element, port: DOM.Element, box: DOM.Element, diffPort: DOM.Element, key: String) {
      self.scope = scope; self.source = source; self.port = port; self.box = box; self.diffPort = diffPort; self.key = key
    }

    /// The diff follows the source's wrapping mode and effective code size.
    /// Its different viewport width is handled by logical-line geometry.
    func presentation() {
      guard stringEquals(scope.getAttribute("data-passage-pair") ?? "", key),
        source.clientWidth > 0, let frame = source.getBoundingClientRect(),
        let lines = box.querySelector(".diff-lines") else { return }
      let style = window.getComputedStyle(source)
      let scale = source.offsetWidth > 0 ? frame.width / source.offsetWidth : 1
      let wrap = style.getPropertyValue("white-space")
      let family = style.getPropertyValue("font-family")
      let size = pixels(style.getPropertyValue("font-size")) * scale
      let leading = pixels(style.getPropertyValue("line-height")) * scale
      let signature = wrap + family + doubleToString(size) + ":" + doubleToString(leading)
      if stringEquals(signature, presentationKey) { return }
      presentationKey = signature
      box.setAttribute("data-passage-linked", "true")
      box.setAttribute("data-passage-wrap", stringEquals(wrap, "pre") || stringEquals(wrap, "nowrap") ? "false" : "true")
      lines.style.setProperty("font-family", family)
      lines.style.setProperty("font-size", doubleToString(size) + "px")
      if leading > 0 {
        lines.style.setProperty("line-height", doubleToString(leading) + "px")
        box.style.setProperty("--passage-line-height", doubleToString(leading) + "px")
      }
    }

    func schedule(fromSource: Bool) {
      guard stringEquals(scope.getAttribute("data-passage-pair") ?? "", key), source.clientWidth > 0,
        port.clientHeight > 0, diffPort.clientHeight > 0 else { return }
      let origin = fromSource ? port : diffPort
      if let expected = parseDouble(origin.getAttribute("data-passage-scroll") ?? "") {
        origin.removeAttribute("data-passage-scroll")
        if abs(origin.scrollTop - expected) < 1 { return }
      }
      self.fromSource = fromSource
      if queued { return }
      queued = true
      _ = window.requestAnimationFrame { [self] in
        queued = false
        guard stringEquals(scope.getAttribute("data-passage-pair") ?? "", key) else { return }
        synchronize()
      }
    }

    func positions() -> [Double] {
      let text: String
      if let area = source as? HTML.HTMLTextAreaElement { text = area.value }
      else {
        // No ?? here: HTMLContent's optional textContent is a separate,
        // non-live overload. DOM.Element's String getter reads the real DOM.
        text = source.textContent
      }
      // Numbered code lines already have exact geometry, including their
      // gutter, wrapping, and inherited CSS zoom. Use it without a mirror.
      let live = source.querySelectorAll(".code-line")
      if live.count == stringSplit(text, separator: "\n").count, !live.isEmpty,
        let frame = source.getBoundingClientRect() {
        let scale = source.offsetWidth > 0 ? frame.width / source.offsetWidth : 1
        let inset = pixels(window.getComputedStyle(source).getPropertyValue("padding-top"))
        var offsets = live.map { (($0.getBoundingClientRect()?.top ?? frame.top) - frame.top) / max(0.01, scale) - inset }
        if let last = live.last?.getBoundingClientRect() { offsets.append((last.bottom - frame.top) / max(0.01, scale) - inset) }
        return offsets
      }
      let style = window.getComputedStyle(source)
      let names = ["font-family", "font-size", "font-weight", "line-height", "letter-spacing", "word-spacing", "white-space", "overflow-wrap", "word-break", "tab-size"]
      let values = names.map { style.getPropertyValue($0) }
      let signature = stringJoin(values, separator: ";")
      if source.clientWidth == cachedWidth && source.scrollHeight == cachedHeight && stringEquals(text, cachedText)
        && stringEquals(signature, cachedStyle) { return cachedPositions }
      let mirror = document.createElement(.div)
      for (index, name) in names.enumerated() { mirror.style.setProperty(name, values[index]) }
      let padding = pixels(style.getPropertyValue("padding-left")) + pixels(style.getPropertyValue("padding-right"))
      mirror.style.setProperty("width", doubleToString(max(1, source.clientWidth - padding)) + "px")
      mirror.style.setProperty("position", "fixed")
      mirror.style.setProperty("visibility", "hidden")
      mirror.style.setProperty("pointer-events", "none")
      mirror.style.setProperty("inset", "0 auto auto 0")
      for line in stringSplit(text, separator: "\n") {
        let row = document.createElement(.div)
        row.textContent = stringIsEmpty(line) ? "\u{00a0}" : line
        mirror.appendChild(row)
      }
      document.body.appendChild(mirror)
      let top = mirror.getBoundingClientRect()?.top ?? 0
      var result = mirror.querySelectorAll("div").map { ($0.getBoundingClientRect()?.top ?? top) - top }
      result.append((mirror.getBoundingClientRect()?.height ?? 0))
      mirror.remove()
      cachedText = text; cachedStyle = signature; cachedWidth = source.clientWidth; cachedHeight = source.scrollHeight
      cachedPositions = result
      return result
    }

    /// The pair's correspondence, as points of the two scrolled contents
    /// (source, diff) that stand for the same place: both tops, each source
    /// line's top with its own row's (an unchanged or inserted row, by
    /// `data-diff-at`), the last line's end with the last row's, and both
    /// ends. Between two points either side moves in proportion, so a
    /// stretch only one side has—removed rows, lines outside the hunks—is
    /// spread over its neighbors' span instead of leapt. Each point is past
    /// the one before on both sides, so the mapping runs one way, without
    /// steps.
    func anchors(origin: Double, scale: Double, boxFrame: DOM.Rect) -> [(source: Double, diff: Double)] {
      let lines = positions()
      // Each line number's row top, -1 where it has none.
      var rowTops = [Double](repeating: -1, count: lines.count + 1)
      var lastBottom = 0.0
      for row in box.querySelectorAll(".diff-row") {
        guard let frame = row.getBoundingClientRect() else { continue }
        lastBottom = diffPort.scrollTop + frame.bottom - boxFrame.top
        if stringEquals(row.getAttribute("data-diff-line") ?? "", "removed") { continue }
        let number = parseInt(row.getAttribute("data-diff-at") ?? "") ?? 0
        if number > 0, number < rowTops.count, rowTops[number] < 0 {
          rowTops[number] = diffPort.scrollTop + frame.top - boxFrame.top
        }
      }
      let sourceEnd = port.scrollHeight, diffEnd = diffPort.scrollHeight
      var points: [(source: Double, diff: Double)] = [(0, 0)]
      func add(_ source: Double, _ diff: Double) {
        guard let last = points.last, source > last.source, diff > last.diff, source < sourceEnd, diff < diffEnd
        else { return }
        points.append((source, diff))
      }
      if lines.count > 1 {
        for index in 0..<(lines.count - 1) {
          if rowTops[index + 1] >= 0 { add(origin + lines[index] * scale, rowTops[index + 1]) }
        }
        add(origin + lines[lines.count - 1] * scale, lastBottom)
      }
      points.append((sourceEnd, diffEnd))
      return points
    }

    /// `value` carried from one side's points to the other's: in proportion
    /// within the span that holds it.
    static func carry(_ value: Double, _ points: [(source: Double, diff: Double)], fromSource: Bool) -> Double {
      guard let first = points.first, let last = points.last else { return value }
      let from = { (point: (source: Double, diff: Double)) in fromSource ? point.source : point.diff }
      let to = { (point: (source: Double, diff: Double)) in fromSource ? point.diff : point.source }
      if value <= from(first) { return to(first) }
      for index in 1..<points.count where value <= from(points[index]) {
        let a = points[index - 1], b = points[index]
        let span = from(b) - from(a)
        return to(a) + (span > 0 ? (value - from(a)) / span : 1) * (to(b) - to(a))
      }
      return to(last)
    }

    /// The other side scrolled to the place the moved one shows. A side's
    /// place is the point of its content at the same fraction of its
    /// viewport as it has scrolled of its range (its top at the start, its
    /// end at the end), so both ends meet, and carrying a place back gives
    /// the scroll it came from.
    func synchronize() {
      presentation()
      guard source.clientWidth > 0, port.clientHeight > 0, diffPort.clientHeight > 0,
        let sourceFrame = source.getBoundingClientRect(), let portFrame = port.getBoundingClientRect(),
        let boxFrame = diffPort.getBoundingClientRect(), !box.querySelectorAll(".diff-row").isEmpty else { return }
      let scale = source.offsetWidth > 0 ? sourceFrame.width / source.offsetWidth : 1
      let padding = pixels(window.getComputedStyle(source).getPropertyValue("padding-top")) * scale
      let origin = source.id == port.id ? padding : port.scrollTop + sourceFrame.top - portFrame.top + padding
      let points = anchors(origin: origin, scale: scale, boxFrame: boxFrame)
      let sourceRange = max(0, port.scrollHeight - port.clientHeight)
      let diffRange = max(0, diffPort.scrollHeight - diffPort.clientHeight)
      if fromSource {
        diffPort.scrollLeft = port.scrollLeft
        let place = port.scrollTop + (sourceRange > 0 ? port.scrollTop / sourceRange : 0) * port.clientHeight
        let focus = Self.carry(place, points, fromSource: true)
        diffPort.scrollTop = focus * diffRange / max(1, diffPort.scrollHeight)
        diffPort.setAttribute("data-passage-scroll", doubleToString(diffPort.scrollTop))
      } else {
        port.scrollLeft = diffPort.scrollLeft
        let place = diffPort.scrollTop + (diffRange > 0 ? diffPort.scrollTop / diffRange : 0) * diffPort.clientHeight
        let focus = Self.carry(place, points, fromSource: false)
        port.scrollTop = focus * sourceRange / max(1, port.scrollHeight)
        port.setAttribute("data-passage-scroll", doubleToString(port.scrollTop))
      }
    }
  }

  private static func pixels(_ value: String) -> Double { parseDouble(stringRemoveSuffix(value, "px")) ?? 0 }
}
#endif
