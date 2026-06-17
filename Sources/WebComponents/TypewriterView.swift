#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Wraps any block element with a cycling typewriter animation on hydration.
  /// Types each phrase, pauses, deletes it, then moves to the next — looping forever.
  /// The first phrase is rendered as textContent for SEO / no-JS fallback.
  /// All phrases are encoded as data attributes; TypewriterHydration discovers and drives them.
  public struct TypewriterView: HTMLContent {
    let phrases: [String]
    let tag: TypewriterTag
    let persistCaret: Bool
    let `class`: String
    let style: [CSSOM.CSSRule]

    public enum TypewriterTag: Sendable {
      case h1, h2, h3, p, span
    }

    public init(
      _ phrases: [String],
      tag: TypewriterTag = .h1,
      persistCaret: Bool = false,
      class: String = "",
      @CSSBuilder style: () -> [CSSOM.CSSRule] = { [] }
    ) {
      self.phrases = phrases
      self.tag = tag
      self.persistCaret = persistCaret
      self.`class` = `class`
      self.style = style()
    }

    /// Convenience init for a single non-cycling phrase.
    public init(
      _ text: String,
      tag: TypewriterTag = .h1,
      persistCaret: Bool = false,
      class: String = "",
      @CSSBuilder style: () -> [CSSOM.CSSRule] = { [] }
    ) {
      self.init([text], tag: tag, persistCaret: persistCaret, class: `class`, style: style)
    }

    public func build() -> DOM.Node {
      let classAttr = `class`.isEmpty ? "typewriter-view" : "typewriter-view \(`class`)"
      let persist = (persistCaret || phrases.count > 1) ? "true" : "false"
      let firstPhrase = phrases.first ?? ""
      let encoded = phrases.joined(separator: "|||")

      switch tag {
      case .h1:
        return h1 { firstPhrase }
          .class(classAttr)
          .data("typewriter", "true")
          .data("typewriter-persist-caret", persist)
          .data("typewriter-phrases", encoded)
          .style { style; caretCSS() }
      case .h2:
        return h2 { firstPhrase }
          .class(classAttr)
          .data("typewriter", "true")
          .data("typewriter-persist-caret", persist)
          .data("typewriter-phrases", encoded)
          .style { style; caretCSS() }
      case .h3:
        return h3 { firstPhrase }
          .class(classAttr)
          .data("typewriter", "true")
          .data("typewriter-persist-caret", persist)
          .data("typewriter-phrases", encoded)
          .style { style; caretCSS() }
      case .p:
        return p { firstPhrase }
          .class(classAttr)
          .data("typewriter", "true")
          .data("typewriter-persist-caret", persist)
          .data("typewriter-phrases", encoded)
          .style { style; caretCSS() }
      case .span:
        return span { firstPhrase }
          .class(classAttr)
          .data("typewriter", "true")
          .data("typewriter-persist-caret", persist)
          .data("typewriter-phrases", encoded)
          .style { style; caretCSS() }
      }
    }

    @CSSBuilder
    private func caretCSS() -> [CSSOM.CSSRule] {
      child(".typewriter-caret") {
        color(colorBlue)
        fontWeight(fontWeightNormal)
        animation(
          duration: .time(s(0.7)),
          easingFunction: .easeInOut,
          iterationCount: .infinite,
          direction: .alternate,
          name: .name("typewriter-blink")
        )
      }
      keyframes("typewriter-blink") {
        from { opacity(1) }
        to { opacity(0) }
      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Discovers all `[data-typewriter="true"]` elements and drives a cycling
  /// typewriter animation: type → pause → delete → next phrase → repeat forever.
  public class TypewriterHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TypewriterHydration?

    public static func hydrateIfPresent() {
      guard document.querySelector(".typewriter-view") != nil else { return }
      instance = TypewriterHydration()
    }

    private let charIntervalMs: Double
    private let deleteIntervalMs: Double
    private let pauseAfterTypeMs: Double
    private let pauseAfterDeleteMs: Double

    public init(
      charIntervalMs: Double = 40,
      deleteIntervalMs: Double = 4,
      pauseAfterTypeMs: Double = 1800,
      pauseAfterDeleteMs: Double = 300
    ) {
      self.charIntervalMs = charIntervalMs
      self.deleteIntervalMs = deleteIntervalMs
      self.pauseAfterTypeMs = pauseAfterTypeMs
      self.pauseAfterDeleteMs = pauseAfterDeleteMs

      let found = document.querySelectorAll(".typewriter-view")
      guard found.count > 0 else { return }
      for element in found {
        animateElement(element)
      }
    }

    private func splitPhrases(_ encoded: String) -> [String] {
      var result: [String] = []
      let bytes = Array(encoded.utf8)
      let sep: [UInt8] = [124, 124, 124] // |||
      var start = 0
      var i = 0
      while i < bytes.count {
        if i + 2 < bytes.count && bytes[i] == sep[0] && bytes[i + 1] == sep[1] && bytes[i + 2] == sep[2] {
          result.append(stringSubstring(encoded, from: start, to: i))
          start = i + 3
          i = i + 3
        } else {
          i += 1
        }
      }
      result.append(stringSubstring(encoded, from: start, to: bytes.count))
      return result
    }

    private func animateElement(_ element: DOM.Element) {
      let encoded = element.getAttribute("data-typewriter-phrases") ?? ""
      let phrases = splitPhrases(encoded)
      guard !phrases.isEmpty, !stringIsEmpty(phrases[0]) else { return }

      let persistRaw = element.getAttribute("data-typewriter-persist-caret") ?? ""
      let persistCaret = stringEquals(persistRaw, "true")

      element.textContent = ""

      let typingSpan = document.createElement("span")
      typingSpan.className = "typewriter-typing"
      element.appendChild(typingSpan)

      let caret = document.createElement("span")
      caret.className = "typewriter-caret"
      caret.textContent = "|"
      element.appendChild(caret)

      typePhrase(
        typingSpan: typingSpan,
        caret: caret,
        phrases: phrases,
        phraseIndex: 0,
        charIndex: 0,
        persist: persistCaret
      )
    }

    private func typePhrase(
      typingSpan: DOM.Element,
      caret: DOM.Element,
      phrases: [String],
      phraseIndex: Int,
      charIndex: Int,
      persist: Bool
    ) {
      let phrase = phrases[phraseIndex]
      let length = phrase.utf8.count
      guard charIndex < length else {
        if phrases.count == 1 && !persist {
          window.setTimeout(500.0) { caret.remove() }
          return
        }
        window.setTimeout(pauseAfterTypeMs) { [self] in
          self.deletePhrase(
            typingSpan: typingSpan,
            caret: caret,
            phrases: phrases,
            phraseIndex: phraseIndex,
            charIndex: length,
            persist: persist
          )
        }
        return
      }

      window.setTimeout(charIntervalMs) { [self] in
        // Advance to next codepoint boundary — multi-byte chars (e.g. —, é, ñ) are
        // 2-4 UTF-8 bytes; slicing mid-codepoint produces invalid UTF-8 → "?" flash.
        let bytes = Array(phrase.utf8)
        var next = charIndex + 1
        while next < bytes.count && (bytes[next] & 0xC0) == 0x80 { next += 1 }
        typingSpan.textContent = stringSubstring(phrase, from: 0, to: next)
        self.typePhrase(
          typingSpan: typingSpan,
          caret: caret,
          phrases: phrases,
          phraseIndex: phraseIndex,
          charIndex: next,
          persist: persist
        )
      }
    }

    private func deletePhrase(
      typingSpan: DOM.Element,
      caret: DOM.Element,
      phrases: [String],
      phraseIndex: Int,
      charIndex: Int,
      persist: Bool
    ) {
      guard charIndex > 0 else {
        let nextIndex = (phraseIndex + 1) % phrases.count
        window.setTimeout(pauseAfterDeleteMs) { [self] in
          self.typePhrase(
            typingSpan: typingSpan,
            caret: caret,
            phrases: phrases,
            phraseIndex: nextIndex,
            charIndex: 0,
            persist: persist
          )
        }
        return
      }

      window.setTimeout(deleteIntervalMs) { [self] in
        let phrase = phrases[phraseIndex]
        // Retreat to previous codepoint start — skip back over continuation bytes.
        let bytes = Array(phrase.utf8)
        var prev = charIndex - 1
        while prev > 0 && (bytes[prev] & 0xC0) == 0x80 { prev -= 1 }
        typingSpan.textContent = stringSubstring(phrase, from: 0, to: prev)
        self.deletePhrase(
          typingSpan: typingSpan,
          caret: caret,
          phrases: phrases,
          phraseIndex: phraseIndex,
          charIndex: prev,
          persist: persist
        )
      }
    }
  }
#endif
