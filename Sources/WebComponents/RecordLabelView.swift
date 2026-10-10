import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// Both SERVER and CLIENT: the search menu draws it on the client from its
// JSON, a gloss's title on the server. Build() must stay embedded-safe
// (stringIsEmpty, not String.isEmpty).

/// A record as the records search menu offers one, in two rows: its
/// language › its title (`BreadcrumbLabelView`), the language and chevron
/// subordinate by color (16px, as the title), the title the linked
/// grain the path leads to; then, small and subtle, a path of what tells it
/// from the records listed with it (`metas`, the clash rule), the same for
/// works and words, as its address is: Class › Voice names › Homograph—its
/// class always › its voice names only where another listed record has its
/// language, title and class › its homograph number only where another has
/// its voice names too. "Middle English › anker", "Noun"; "English
/// › bank", "Noun › Margery Kempe"; "Old English › An Anglo-Saxon
/// Dictionary", "Dictionary". One record alone (a gloss's title) is its
/// class alone. Only the title is ever a link.
///
/// With a `url` the title is a link to the record, in the link's colors
/// (a gloss's title); without, it takes its container's (a search menu
/// row, which is the link itself). With no `context`, the title alone: a
/// term with no record.
public struct RecordLabelView: HTMLContent {
  let context: String
  let text: String
  /// The meta row's segments, a path as the first row is: class, then
  /// voice names, then a homograph's number, where the clash rule shows
  /// them.
  let meta: [String]
  let url: String
  let `class`: String

  /// A record among those listed together, as the clash rule reads it.
  public struct Entry: Sendable {
    public let language: String
    public let title: String
    /// Its class by its name ("Dictionary", "Noun"); "" when unknown.
    public let type: String
    /// Its voice names as its address takes them, as English lists them,
    /// the same on both sides: a work's own, a word's those of the work
    /// holding its earliest attestation ("Margery Kempe"); "" or "—" when
    /// none is recorded.
    public let voiceNames: String
    /// Its homograph number, its address's last segment where others share
    /// its title, class and voice names (`/eng/bank/noun/margery-kempe/2`); 0
    /// for none.
    public let homograph: Int

    public init(language: String, title: String, type: String, voiceNames: String = "", homograph: Int = 0) {
      self.language = language
      self.title = title
      self.type = type
      self.voiceNames = voiceNames
      self.homograph = homograph
    }
  }

  /// The clash rule (user, 2026-10-08), each record's meta row against the
  /// others listed with it, down its address—class › voice names ›
  /// homograph,
  /// the same for works and words: its class, always ("—" when unknown);
  /// then its voice names where another has the same language, title and
  /// class ("—" when none is recorded, a voice-names segment like any
  /// other); then its homograph number where another has the same voice
  /// names too.
  /// Embedded-safe: it runs in the search menu.
  public static func metas(_ entries: [Entry]) -> [[String]] {
    func same(_ a: Entry, _ b: Entry) -> Bool {
      stringEquals(a.language, b.language) && stringEquals(a.title, b.title) && stringEquals(a.type, b.type)
    }
    // None recorded reads one way, however it was sent.
    func voiceNames(_ entry: Entry) -> String { stringIsEmpty(entry.voiceNames) ? "—" : entry.voiceNames }
    var out: [[String]] = []
    for (index, entry) in entries.enumerated() {
      let type = stringIsEmpty(entry.type) ? "—" : entry.type
      var namesake = false
      var twin = false
      for (other, candidate) in entries.enumerated() where other != index && same(entry, candidate) {
        namesake = true
        if stringEquals(voiceNames(entry), voiceNames(candidate)) { twin = true }
      }
      guard namesake else {
        out.append([type])
        continue
      }
      var segments = [type, voiceNames(entry)]
      if twin && entry.homograph > 0 { segments.append("\(entry.homograph)") }
      out.append(segments)
    }
    return out
  }

  public init(context: String, text: String, meta: [String], url: String = "", class: String = "") {
    self.context = context
    self.text = text
    self.meta = meta
    self.url = url
    self.`class` = `class`
  }

  /// One record alone (a gloss's title): its class, a meta row of one.
  public init(context: String, text: String, meta: String, url: String = "", class: String = "") {
    self.init(context: context, text: text, meta: [meta], url: url, class: `class`)
  }

  public func build() -> DOM.Node {
    span {
      if stringIsEmpty(url) {
        span {
          if stringIsEmpty(context) { text } else { BreadcrumbLabelView(context: context, text: text) }
        }
        .class("record-label-title")
      } else {
        LinkView(url: url, class: "record-label-title") {
          if stringIsEmpty(context) { text } else { BreadcrumbLabelView(context: context, text: text) }
        }
      }
      // A path as the first row is: class › voice names › homograph number,
      // the same small chevron between them. None: no row (a quotation's
      // gloss is headed by its words alone).
      if !meta.isEmpty {
      span {
        for (index, segment) in meta.enumerated() {
          if index > 0 {
            "\u{00A0}"
            BreadcrumbSeparatorView()
            " "
          }
          segment
        }
      }
      .class("record-label-meta")
      }
    }
    .class(stringIsEmpty(`class`) ? "record-label-view" : "record-label-view \(`class`)")
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        minWidth(px(0))
        fontFamily(typographyFontSans)
        lineHeight(lineHeightSmall22)
      }
      descendant(".record-label-title") {
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        overflowWrap(.breakWord)
      }
      // The language and its chevron are subordinate to the title: the
      // language at the meta line's size, the chevron at that size (the
      // icon rule). Here only: every other breadcrumb keeps its own.
      descendant(".breadcrumb-label-context") {
        fontSize(fontSizeMedium16)
        color(colorSubtle)
      }
      // The meta row's chevrons as its first row's: quiet, on the baseline.
      descendant(".record-label-meta .breadcrumb-separator-view") {
        color(colorSubtle)
        verticalAlign(.baseline)
      }
      descendant(".breadcrumb-separator-view .next-icon-view") {
        height(sizeIconSmall).important()
      }
      descendant(".record-label-meta") {
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        color(colorSubtle)
      }
    }
  }
}
