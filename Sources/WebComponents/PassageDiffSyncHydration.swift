#if CLIENT
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebAPIs
import WebTypes

/// Corresponding source lines, including wrapped portions, move together.
/// Listen on actual scrollports; only the latest user scroll drives matching.
public enum PassageDiffSyncHydration {
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
      let translated = stringEquals(reader.closest("[data-translated]")?.getAttribute("data-translated") ?? "false", "true")
      let layer = translated ? "translated-markup" : "markup"
      if let source = reader.querySelector(".tei-page[data-active='true'] [data-layer='" + layer + "'] .code-code"),
        let slot = reader.querySelector(".testament-diff[data-active='true']") {
        let box = translated ? slot.querySelector(".testament-translation-diff .diff-box") : slot.querySelector(".resemblance-diff-view .diff-box")
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
    let key = intToString(Int(source.id)) + ":" + intToString(Int(box.id))
    if stringEquals(scope.getAttribute("data-passage-pair") ?? "", key) { return }
    scope.setAttribute("data-passage-pair", key)
    let pair = Pair(scope: scope, source: source, port: port, box: box, key: key)
    _ = port.addEventListener(.scroll) { _ in pair.schedule(fromSource: true) }
    _ = box.addEventListener(.scroll) { _ in pair.schedule(fromSource: false) }
  }

  private final class Pair: @unchecked Sendable {
    let scope: DOM.Element, source: DOM.Element, port: DOM.Element, box: DOM.Element
    let key: String
    var queued = false
    var fromSource = true
    var cachedText = ""
    var cachedStyle = ""
    var cachedWidth = 0.0
    var cachedHeight = 0.0
    var cachedPositions: [Double] = []

    init(scope: DOM.Element, source: DOM.Element, port: DOM.Element, box: DOM.Element, key: String) {
      self.scope = scope; self.source = source; self.port = port; self.box = box; self.key = key
    }

    func schedule(fromSource: Bool) {
      guard stringEquals(scope.getAttribute("data-passage-pair") ?? "", key), source.clientWidth > 0,
        port.clientHeight > 0, box.clientHeight > 0 else { return }
      let origin = fromSource ? port : box
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
        var offsets = live.map { (($0.getBoundingClientRect()?.top ?? frame.top) - frame.top) / max(0.01, scale) }
        if let last = live.last?.getBoundingClientRect() { offsets.append((last.bottom - frame.top) / max(0.01, scale)) }
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

    func synchronize() {
      guard source.clientWidth > 0, port.clientHeight > 0, box.clientHeight > 0,
        let sourceFrame = source.getBoundingClientRect(), let portFrame = port.getBoundingClientRect(),
        let boxFrame = box.getBoundingClientRect() else { return }
      let lines = positions()
      let rows = box.querySelectorAll(".diff-row")
      guard lines.count > 1, !rows.isEmpty else { return }
      let scale = source.offsetWidth > 0 ? sourceFrame.width / source.offsetWidth : 1
      let padding = pixels(window.getComputedStyle(source).getPropertyValue("padding-top")) * scale
      let origin = source.id == port.id ? padding : port.scrollTop + sourceFrame.top - portFrame.top + padding
      if fromSource {
        let y = max(0, (port.scrollTop - origin) / max(0.01, scale))
        var line = 0
        for index in 0..<(lines.count - 1) where lines[index] <= y { line = index }
        let fraction = min(1, max(0, (y - lines[line]) / max(1, lines[line + 1] - lines[line])))
        var chosen = rows[0]
        var distance = Int.max
        for row in rows {
          let number = parseInt(row.getAttribute("data-diff-at") ?? "") ?? 1
          let delta = abs(number - line - 1)
          if delta < distance || (delta == distance && !stringEquals(row.getAttribute("data-diff-line") ?? "", "removed")) {
            distance = delta; chosen = row
          }
        }
        guard let frame = chosen.getBoundingClientRect() else { return }
        box.scrollTop += frame.top - boxFrame.top + fraction * frame.height
        box.setAttribute("data-passage-scroll", doubleToString(box.scrollTop))
      } else {
        var chosen = rows[0]
        for row in rows {
          if let frame = row.getBoundingClientRect(), frame.top <= boxFrame.top + 1 { chosen = row }
        }
        guard let frame = chosen.getBoundingClientRect() else { return }
        let index = max(0, min(lines.count - 2, (parseInt(chosen.getAttribute("data-diff-at") ?? "") ?? 1) - 1))
        let fraction = max(0, min(1, (boxFrame.top - frame.top) / max(1, frame.height)))
        port.scrollTop = origin + (lines[index] + fraction * (lines[index + 1] - lines[index])) * scale
        port.setAttribute("data-passage-scroll", doubleToString(port.scrollTop))
      }
    }
  }

  private static func pixels(_ value: String) -> Double { parseDouble(stringRemoveSuffix(value, "px")) ?? 0 }
}
#endif
