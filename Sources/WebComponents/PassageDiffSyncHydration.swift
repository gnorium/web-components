#if CLIENT
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebAPIs
import WebTypes

/// Synchronize a passage editor and its diff by source line, including
/// wrapped lines. Suppress scroll echoes; never move the outer document.
public enum PassageDiffSyncHydration {
  public static func hydrate(in root: DOM.Element) {
    for field in root.querySelectorAll(".field-diff-view") {
      guard let area = field.querySelector("textarea") as? HTML.HTMLTextAreaElement else { continue }
      if !field.hasAttribute("data-passage-sync") {
        field.setAttribute("data-passage-sync", "true")
        _ = area.addEventListener(.scroll) { _ in synchronize(field, area: area, fromEditor: true) }
      }
      bindBox(field, area: area)
    }
    for comparison in root.querySelectorAll(".prompt-text-comparison") {
      guard let source = comparison.querySelector("pre.prompt-text-source"), let box = comparison.querySelector(".diff-box"),
        !comparison.hasAttribute("data-passage-sync") else { continue }
      comparison.setAttribute("data-passage-sync", "true")
      _ = source.addEventListener(.scroll) { _ in synchronize(comparison, area: source, fromEditor: true) }
      _ = box.addEventListener(.scroll) { _ in synchronize(comparison, area: source, fromEditor: false) }
    }
  }

  public static func bindBox(_ field: DOM.Element, area: HTML.HTMLTextAreaElement) {
    guard let box = field.querySelector(".diff-box"), !box.hasAttribute("data-passage-sync") else { return }
    box.setAttribute("data-passage-sync", "true")
    _ = box.addEventListener(.scroll) { _ in synchronize(field, area: area, fromEditor: false) }
  }

  private static func offsets(_ area: DOM.Element) -> [Double] {
    let mirror = document.createElement(.div)
    let style = window.getComputedStyle(area)
    for name in ["font-family", "font-size", "font-weight", "line-height", "letter-spacing", "word-spacing", "white-space", "overflow-wrap", "word-break", "tab-size"] {
      mirror.style.setProperty(name, style.getPropertyValue(name))
    }
    let padding = (parseDouble(stringRemoveSuffix(style.getPropertyValue("padding-left"), "px")) ?? 0)
      + (parseDouble(stringRemoveSuffix(style.getPropertyValue("padding-right"), "px")) ?? 0)
    mirror.style.setProperty("width", doubleToString(max(1, area.clientWidth - padding)) + "px")
    mirror.style.setProperty("position", "absolute")
    mirror.style.setProperty("visibility", "hidden")
    mirror.style.setProperty("pointer-events", "none")
    mirror.style.setProperty("inset", "0 auto auto 0")
    mirror.style.setProperty("white-space", "pre-wrap")
    let text = (area as? HTML.HTMLTextAreaElement)?.value ?? area.textContent ?? ""
    for line in stringSplit(text, separator: "\n") {
      let row = document.createElement(.div)
      row.textContent = stringIsEmpty(line) ? "\u{00a0}" : line
      mirror.appendChild(row)
    }
    document.body.appendChild(mirror)
    let top = mirror.getBoundingClientRect()?.top ?? 0
    let result = mirror.querySelectorAll("div").map { ($0.getBoundingClientRect()?.top ?? top) - top }
    mirror.remove()
    return result
  }

  private static func synchronize(_ field: DOM.Element, area: DOM.Element, fromEditor: Bool) {
    guard area.clientWidth > 0, let box = field.querySelector(".diff-box") else { return }
    let source = fromEditor ? area : box
    let expected = parseDouble(source.getAttribute("data-passage-scroll") ?? "")
    if let expected, abs(source.scrollTop - expected) < 1 { return }
    let positions = offsets(area)
    guard !positions.isEmpty else { return }
    let rows = box.querySelectorAll(".diff-row")
    guard !rows.isEmpty, let frame = box.getBoundingClientRect() else { return }
    if fromEditor {
      var line = 1
      for (index, top) in positions.enumerated() where top <= area.scrollTop { line = index + 1 }
      var chosen = rows[0]
      var distance = Int.max
      for row in rows {
        let number = parseInt(row.getAttribute("data-diff-at") ?? "") ?? 1
        let delta = abs(number - line)
        if delta < distance { distance = delta; chosen = row }
      }
      guard let row = chosen.getBoundingClientRect() else { return }
      box.scrollTop += row.top - frame.top
      box.setAttribute("data-passage-scroll", doubleToString(box.scrollTop))
    } else {
      var chosen = rows[0]
      for row in rows {
        if let bounds = row.getBoundingClientRect(), bounds.top <= frame.top + 1 { chosen = row }
      }
      let line = parseInt(chosen.getAttribute("data-diff-at") ?? "") ?? 1
      area.scrollTop = positions[max(0, min(positions.count - 1, line - 1))]
      area.setAttribute("data-passage-scroll", doubleToString(area.scrollTop))
    }
  }
}
#endif
