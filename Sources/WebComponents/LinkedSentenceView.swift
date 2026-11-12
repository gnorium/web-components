import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A sentence said to a person that names an object by its id with where it
/// is in parentheses, "… is already submitted: 01A1… (/mission-control/
/// overtures/bibliographic/01A1…).": the id is drawn alone, linked to it
/// (user, 2026-11-12). A sentence that names none is drawn as it is.
///
/// An id is a word of 36 characters (a UUID) followed by a space and a site
/// path in parentheses.
public struct LinkedSentenceView: HTMLContent {
  let sentence: String

  public init(_ sentence: String) {
    self.sentence = sentence
  }

  /// The sentence in order: its words as they are (`url` empty), and each
  /// id with its path as `url`, the parentheses gone.
  public static func parts(_ sentence: String) -> [(text: String, url: String)] {
    let bytes = Array(sentence.utf8)
    let open = Array(" (/".utf8), close = UInt8(ascii: ")"), space = UInt8(ascii: " ")
    let idLength = 36
    var out: [(text: String, url: String)] = []
    var plain = 0
    var index = idLength
    while index + open.count < bytes.count {
      let named =
        bytes[index] == open[0] && bytes[index + 1] == open[1] && bytes[index + 2] == open[2]
        && (index == idLength || bytes[index - idLength - 1] == space)
        && !bytes[(index - idLength)..<index].contains(space) && index - idLength >= plain
      var end = index + 2
      while named, end < bytes.count, bytes[end] != close, bytes[end] != space { end += 1 }
      guard named, end < bytes.count, bytes[end] == close else {
        index += 1
        continue
      }
      let start = index - idLength
      if plain < start { out.append((stringSubstring(sentence, from: plain, to: start), "")) }
      out.append((stringSubstring(sentence, from: start, to: index), stringSubstring(sentence, from: index + 2, to: end)))
      plain = end + 1
      index = plain + idLength
    }
    if plain < bytes.count { out.append((stringSubstring(sentence, from: plain, to: bytes.count), "")) }
    return out
  }

  public func build() -> DOM.Node {
    span {
      for part in Self.parts(sentence) {
        if stringIsEmpty(part.url) {
          part.text
        } else {
          LinkView(url: part.url) { part.text }
        }
      }
    }
    .class("linked-sentence-view")
  }
}
