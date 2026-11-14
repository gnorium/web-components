/// A form's Source box selecting a sentence (user, 2026-11-01): the
/// attribute an ancestor of the reader wears while it does, and the CSS
/// highlights the sentence under the pointer and its lemma are painted
/// with, in a quote's own violet and magenta (`TEIView`).
public enum TEISentenceSelection {
  /// `data-selects-sentences="true"` on an ancestor: its words open no
  /// gloss, nor turn blue.
  public static let attribute = "selects-sentences"
  public static let sentence = "tei-sentence"
  public static let title = "tei-sentence-title"
}

#if SERVER
  import CSSBuilder
  import DesignTokens
  import DiffEngine
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import MathMLBuilder
  import SVGBuilder
  import WebTypes
  import XMLUtilities

  /// An explicated TEI document, read beside the object it was transcribed from.
  ///
  /// The pipeline writes `<pb n="…" facs="…"/>` at every page turn, so the
  /// document carries its own facsimiles and each page can name the image
  /// service it reads. That name is what pairs a page with a canvas inside
  /// ``ArtifactView``: this view draws the readings, the viewer shows the one
  /// belonging to the canvas on screen, and paging moves both at once. Each
  /// page is one `.tei-page` (its text, its code, its translation), paired
  /// with its canvas by `data-service-id`; the page's image is not drawn here.
  ///
  /// Line breaks are kept because they are evidence—a diplomatic transcript
  /// says where the compositor broke the line—and the tags that survive the
  /// strip are the ones a reader of the text needs: headings, speakers, stage
  /// directions.
  public struct TEIView: HTMLContent {
    let teiXml: String
    /// Whether each page's code can be edited. The editor receives the
    /// original source, including significant whitespace; saving an edit
    /// changes only what the reader changed.
    let editable: Bool
    /// Each page's code is edited where it is read, in no form of its own
    /// and posting nothing: its host reads it as it is typed (a typed
    /// quote's XML, user 2026-11-10; gnorium-web `QuoteTyped`).
    let editsCode: Bool
    /// The markup's translation, when it has one: a third layer of each
    /// page's markup, which the viewer's Translated switch shows in the
    /// markup's place.
    let translation: Translation?
    /// What to set apart in each page's markup, by the image service the
    /// page reads: a quote's sentence and its word
    /// (`TEIRenderer.quotation`), each a `<mark>`.
    let highlights: [String: [TEIHighlight]]
    /// Whether each page's markup begins with its label, as a page turn
    /// inside an image is marked: for pages read one after another in one
    /// column rather than paged beside their images.
    let labelsPages: Bool
    /// The direction the document is written in, `ltr` or `rtl`, from its
    /// language as its data gives it (the caller reads it: gnorium-web
    /// `TestamentView.direction(of:)`): a spread's pages run in it. Nil where nothing says, the pages then following the
    /// direction around them.
    let direction: String?
    /// Where a gloss is read (user, 2026-10-08), when what the markup
    /// encodes can be opened: each word of the markup (a `<w>`, as an
    /// anchor counts the page) is then a control that opens its gloss, and
    /// so is what is no word but encoded (a gap, a side mark, a figure, a
    /// running head's page number, a date: `data-gloss-element`, its place
    /// among the page's elements); the client asks this address for it
    /// (`?image=…&line=…&word=…`, or `&element=…`). Nil: the markup
    /// is read whole.
    let glossURL: String?
    /// Whether its words are marked with no gloss to open (a cited web
    /// page's quote on its snapshot, user 2026-11-03): each `<w>` a word
    /// the reader pairs with its zones on the image (`.tei-word`, its place),
    /// tinted there as a quote's, but no control. A gloss marks them too.
    let marksWords: Bool
    /// The one page drawn, by its place in the document from 0, where a
    /// reader draws a page at a time and fetches the others as they are
    /// turned to (`TestamentView.pagesURL`); nil draws every page.
    let page: Int?
    /// The pages drawn beside `page`, by place from 0, where a reader draws
    /// some of them at first: a revision's changed pages and the page either
    /// side of each (`TestamentView.drawn`). Ignored where `page` is nil.
    let drawn: [Int]
    /// The place in its whole document of this document's first page: a
    /// page read alone from a long book's stored pages (`TestamentView`'s
    /// `page(_:service:firstIndex:)`) is drawn at its place in the book.
    let firstIndex: Int
    /// The translator's notes of the layer being set, by the block each
    /// notes: none but while a page's translation is set.
    private var notes: [String: String] = [:]
    /// The page being set's sentences and lemmas, by its words' places
    /// (`marking(_:)`): each word says the `<s>` it is read in
    /// (`data-sentence`, `TEIRenderer.sentences(of:)`) and its `<w>`'s lemma
    /// (`data-lemma`), where its words can be opened; a form's Source box
    /// selects a sentence by them (gnorium-web `QuoteSentenceSelection`).
    private var sentences: [TEIWordPlace: Int] = [:]
    private var lemmas: [TEIWordPlace: String] = [:]
    /// Its words' keys (`data-word-id`, `TEIWord.key`): an `xml:id`
    /// ("w12.31"), or on a calibrated page the word's first zone
    /// ("p3-wz12"); what a quote's chosen words are stored by (`wordIds`).
    private var wordIDs: [TEIWordPlace: String] = [:]
    /// The measure of the type area the page being set is set in, in its em
    /// (`TEIPageTypeArea.measure`; 0 where it has none): how far a line placed
    /// by its zone runs reflowed (`reflowStyle`).
    private var typeAreaMeasure: Double = 0

    /// A translation of the markup, page by page, in its own language:
    /// the translation's own TEI, read by the same reader as the markup,
    /// so the two are set alike line for line.
    public struct Translation: Sendable {
      /// One page's translation, read: whether the page's text has changed
      /// since it was translated, and the translator's notes, each by the
      /// block it notes (`TEILine.Run.segment`), opened as a gloss is.
      public struct Page: Sendable {
        public let page: TEIPage
        public let stale: Bool
        public let notes: [String: String]

        public init(page: TEIPage, stale: Bool = false, notes: [String: String] = [:]) {
          self.page = page
          self.stale = stale
          self.notes = notes
        }
      }

      /// The translation's language, as a BCP 47 tag names it.
      public let language: String
      /// Each page's, by the image service it reads.
      public let pages: [String: Page]

      public init(language: String, pages: [String: Page]) {
        self.language = language
        self.pages = pages
      }
    }

    public init(
      teiXml: String, editable: Bool = false, translation: Translation? = nil,
      highlights: [String: [TEIHighlight]] = [:], labelsPages: Bool = false, glossURL: String? = nil,
      marksWords: Bool = false, page: Int? = nil, drawn: [Int] = [], firstIndex: Int = 0, direction: String? = nil,
      editsCode: Bool = false
    ) {
      self.editsCode = editsCode
      self.marksWords = marksWords
      self.direction = direction
      self.page = page
      self.drawn = drawn
      self.firstIndex = firstIndex
      self.teiXml = teiXml
      self.editable = editable
      self.translation = translation
      self.highlights = highlights
      self.labelsPages = labelsPages
      self.glossURL = glossURL
    }

    public var pages: [TEIPage] {
      TEIRenderer.pages(in: teiXml, highlights: highlights, marksWords: wordsMarked)
    }

    /// Whether its words are marked: each opens its gloss, or is paired
    /// with its zones alone (`marksWords`).
    private var wordsMarked: Bool { glossURL != nil || marksWords }

    /// The image service a canvas reads, which is what pairs it with a
    /// canvas. `TEIRenderer` owns the rule; the view only passes it on.
    /// A run's text as drawn: a ligature's (`TEIRenderer.ligature`) whose
    /// letters Unicode encodes as one character is that character
    /// (`TEIRenderer.presentationForms`), so a copy holds it; every other
    /// run its text.
    /// The cap height of the text's serif face (Noto Serif: 1,462 of 2,048
    /// units), in em: what a dropped initial's size is reckoned by.
    static let dropCapHeight = "0.714"

    static func drawnText(of run: TEILine.Run) -> String {
      guard run.rend.split(whereSeparator: \.isWhitespace).contains(where: { $0 == TEIRenderer.ligature }) else {
        return run.text
      }
      return TEIRenderer.presentationForms[run.text] ?? run.text
    }

    /// A page's fragment as Raw, the Diff and the Revise editor show it:
    /// formatted as stored TEI is (`XMLFormatter.formatted`, user
    /// 2026-11-05: "store it formatted"), one element a line where its
    /// containers hold elements only, its mixed content byte for byte. A
    /// page stored formatted shows as it is stored (formatting it again
    /// changes nothing); a page stored before (one line, or laid out
    /// otherwise) shows formatted alike in all three, so its editor and Raw
    /// never differ, and its edit is compared with what its editor showed.
    public static func shownCode(_ markup: String) -> String {
      XMLFormatter.formatted(markup)
    }

    public static func serviceID(ofFacsimile url: String) -> String {
      TEIRenderer.serviceID(ofFacsimile: url)
    }

    /// The zones a page's markup names (`facs="#…"`), each "id x y w h" in
    /// the 0–1000 space over its image (x y its top-left corner, w h its
    /// size, rounded), one a ";".
    static func zoneData(of page: TEIPage) -> String {
      var seen: Set<String> = []
      return TEIFacsimile.references(in: page.markup).compactMap { id -> String? in
        guard seen.insert(id).inserted, let zone = page.zones[id] else { return nil }
        let box = zone.percent
        let numbers = [box.x, box.y, box.width, box.height].map { String(Int(($0 * 10).rounded())) }
        return ([id] + numbers).joined(separator: " ")
      }.joined(separator: ";")
    }

    /// A page's measured text block (`TEIPage.textBlock`): its four corners
    /// on its scan, clockwise from the top-left, each "x,y" in the 0–1000
    /// space over the image, one a space; "" where it was not measured.
    static func textBlockData(of page: TEIPage) -> String {
      guard let fractions = page.textBlock?.fractions, fractions.count == 8 else { return "" }
      return stride(from: 0, to: 8, by: 2).map {
        // Hundredths of the space: finer than a scan's pixel.
        number((fractions[$0] * 100_000).rounded() / 100) + "," + number((fractions[$0 + 1] * 100_000).rounded() / 100)
      }.joined(separator: " ")
    }

    /// The scan's measured layout on the page's surface
    /// (`TEIFacsimile.layout(of:)`, the tools' zones): each zone its type
    /// ("block", "line", "word"), a block's subtype ("main",
    /// "marginalia"; "-" for the others), a word's id ("-" for the others)
    /// and its four corners in the 0–1000 space over the image, to
    /// hundredths, then a line's baseline (`TEIFacsimile.LayoutZone.baseline`:
    /// its two ends, the same way) where it has one, all one a space; one
    /// zone a ";", in reading order (a line the block's before it, a word
    /// the line's); "" where none was measured. The reader's structure
    /// overlay and its word correspondence read it.
    /// A page whose surface keeps no measured layout (a calibrated page's
    /// base TEI) gives its lines as its line breaks name them
    /// (`TEIFacsimile.layout(of:)` a page): the overlay draws them still.
    static func scanLayoutData(of page: TEIPage) -> String {
      TEIFacsimile.layout(of: page).map { zone in
        ([zone.type, zone.subtype.isEmpty ? "-" : zone.subtype, zone.id.isEmpty ? "-" : zone.id]
          + (zone.fractions + zone.baseline).map { number(($0 * 100_000).rounded() / 100) }).joined(separator: " ")
      }.joined(separator: ";")
    }

    /// A figure's zone on its scan (`TEIZone`): its left, top, right and
    /// bottom in the 0–1000 space over the image, to hundredths, one a
    /// space. The reader's structure overlay lays it under the figure's
    /// drawing and judges where the drawing lands (artifact-core
    /// `ArtifactView.figurePairs`, gnorium-python
    /// `structure_check.figure_pairs`).
    static func figureZoneData(_ zone: TEIZone) -> String {
      let box = zone.percent
      return [box.x, box.y, box.x + box.width, box.y + box.height]
        .map { number(($0 * 1_000).rounded() / 100) }.joined(separator: " ")
    }

    /// Each word of the page and the scan's word zones it is in, as its
    /// `@facs` names them (`TEIWord.zones`, the tools' links: gnorium-python
    /// `facsimile.with_word_links`): "line:word" (its place, a `.tei-word`'s
    /// `data-line` and `data-word`) and its zones' ids, one a space; one
    /// word a ";"; words naming none left out. The reader's word
    /// correspondence reads it.
    static func wordZonesData(of page: TEIPage) -> String {
      TEIRenderer.words(of: page).filter { !$0.zones.isEmpty }.map { word in
        (["\(word.place.line):\(word.place.word)"] + word.zones).joined(separator: " ")
      }.joined(separator: ";")
    }

    /// Each copy-evidence element on the page (`TEIRenderer.elementZones(of:)`)
    /// and its bounding zone in the 0–1000 space over the image:
    /// "element:x y w h" (x y its top-left corner, w h its size, rounded),
    /// one a ";"; "" where the page has none.
    static func elementZonesData(of page: TEIPage) -> String {
      TEIRenderer.elementZones(of: page).map { entry in
        let box = entry.zone.percent
        let numbers = [box.x, box.y, box.width, box.height].map { String(Int(($0 * 10).rounded())) }
        return "\(entry.element):" + numbers.joined(separator: " ")
      }.joined(separator: ";")
    }

    /// The body's leading in rem (`TEIRendition.bodyLeading`), "" where
    /// the scale declares none: the structure overlay's unit.
    static func bodyLeadingData(of page: TEIPage) -> String {
      TEIRendition.bodyLeading(in: page.renditions, markup: page.markup).map { number($0) } ?? ""
    }

    /// The book's em on the page's scan, in the 0–1000 space across its
    /// image (user, 2026-10-18): the book is set in one type, so a scan has
    /// its em as its width over its width in em (`TEIPage.scanWidth`)—the
    /// em the page is set in: a page set in its leaf (a board lettered
    /// in gilt, Hamlet Q1's front cover) its leaf's, 38 em across it
    /// (user, 2026-11-03: at the work's em its overlay drew the cover's
    /// gilt border at 0.63 of the scan's); else the scan's own, as its
    /// measured text block gives it (`TEITextBlock.typeArea`: the body type
    /// measured on it), else the work's type area's (`TEIWorkTypeArea.width`,
    /// `max-inline-size`). The scan's own before the work's: one width in
    /// em for every scan assumes each takes in the page alike, and Hamlet
    /// Q1's photographs (openings, a ruler, more or less of the next leaf)
    /// run 73 to 85 em wide (dev, 2026-10-26). "" where none gives a
    /// width. The reader's overlay always lays the scan at this scale,
    /// never by the main text block's height, the edition's typesetting
    /// (`OverlayRegistration.laid`).
    static func scanEmData(of page: TEIPage) -> String {
      guard let width = page.scanWidth, width > 0 else { return "" }
      // Ten-thousandths of the space: finer than a scan's pixel.
      return number((1000 / width * 10_000).rounded() / 10_000)
    }

    /// The page's type area as the custom properties its rules read
    /// (`.tei-page-text[data-type-area]`, `.tei-text-block`), in em of the
    /// work's body type: the type area's measure and height, the margin around
    /// the page's content, and a genuinely larger page's own size (0 for
    /// any other: its content and margins set its size).
    static func typeAreaStyle(_ typeArea: TEIPageTypeArea) -> String {
      // Ten-thousandths of an em: finer than a device pixel.
      func rounded(_ value: Double) -> String { number((value * 10_000).rounded() / 10_000) }
      return "--tei-type-area-measure: \(rounded(typeArea.measure)); --tei-type-area-height: \(rounded(typeArea.height));"
        + " --tei-type-area-head: \(rounded(typeArea.head)); --tei-type-area-foot: \(rounded(typeArea.foot));"
        + " --tei-type-area-left: \(rounded(typeArea.left)); --tei-type-area-right: \(rounded(typeArea.right));"
        + " --tei-page-width: \(rounded(typeArea.pageWidth)); --tei-page-height: \(rounded(typeArea.pageHeight))"
    }

    /// The area around the type area a line of marginalia is set in: a note's,
    /// placed in a margin beside, above or below it or at a corner
    /// (`TEIRenderer.marginalArea`); nil for a line of the main text.
    static func marginalPlace(of line: TEILine) -> String? {
      guard case .note(let place) = line.kind else { return nil }
      return TEIRenderer.marginalArea(of: place)
    }

    /// A page's markup as the lines a diff compares: each line's runs with
    /// their setting, a formula whole, a figure by its caption and region, a
    /// page turn inside the image as a line of its own. White space that only
    /// lays the code out—a line end and its indent—reads as the one
    /// space markup shows; spaces the transcription set are kept.
    public static func renderedLines(of lines: [TEILine]) -> [DiffEngine.RenderedLine] {
      func style(_ rend: String) -> [String] {
        Set(rend.split(whereSeparator: \.isWhitespace).map { name -> String in
          switch name.lowercased() {
          case "ital", "italic", "italics": return "italic"
          case "sub", "subscript": return "sub"
          case "sup", "super", "superscript": return "sup"
          case "smallcaps", "small-caps", "sc": return "smallcaps"
          case "underline", "underlined", "ul": return "underline"
          case "bold", "b": return "bold"
          default: return String(name)
          }
        }).sorted()
      }
      func role(_ kind: TEILine.Kind) -> String {
        switch kind {
        case .text: return ""
        case .heading: return "heading"
        case .speaker: return "speaker"
        case .stage: return "stage"
        case .mark: return "page"
        case .forme(let role): return "forme-\(role.rawValue)"
        case .gap: return "gap"
        case .figure: return "figure"
        case .table: return "table"
        case .documentBoundary: return "boundary"
        case .note: return "note"
        case .space: return "space"
        case .rule: return "rule"
        }
      }
      func runs(_ line: TEILine) -> [DiffEngine.Token] {
        var tokens: [DiffEngine.Token] = []
        for run in line.runs {
          switch run.kind {
          case .math(let formula):
            // A formula compares as the MathML it draws: two that draw alike
            // compare alike, however their TeX was written.
            tokens.append(.init(kind: .formula, text: formula.markup, style: style(run.rend)))
          case .text:
            // Spaced as XML text is displayed already (`TEIRenderer`).
            if !run.text.isEmpty { tokens.append(.init(text: run.text, style: style(run.rend))) }
          case .space(let quantity, let unit):
            // A gap reads as the space it is, its width a setting of it.
            tokens.append(.init(text: run.text, style: style(run.rend) + ["space \(Self.number(quantity)) \(unit)"]))
          }
        }
        return tokens
      }

      var out: [DiffEngine.RenderedLine] = []
      for line in lines {
        switch line.kind {
        case .figure(_, let zone, _):
          out.append(
            .init(
              tokens: [.init(kind: .figure, text: line.text, style: zone.map { ["region \($0.corners)"] } ?? [])],
              opensBlock: true, role: role(line.kind)))
        case .gap(let reason):
          out.append(.init(tokens: [.init(text: "[\(reason.isEmpty ? "gap" : reason)]")], role: role(line.kind)))
        case .mark, .documentBoundary:
          out.append(.init(tokens: [.init(text: line.text)], role: role(line.kind)))
        case .space(let quantity, let unit):
          out.append(.init(tokens: [.init(text: "[space: \(Self.number(quantity)) \(unit)]")], role: role(line.kind)))
        case .rule:
          out.append(.init(tokens: [.init(text: "[rule]")], role: role(line.kind)))
        case .table(let table):
          // A table reads as its caption, then row by row, a cell's lines run
          // together.
          for caption in table.caption {
            out.append(.init(tokens: runs(caption), role: "table"))
          }
          for row in table.rows {
            var tokens: [DiffEngine.Token] = []
            for (index, cell) in row.cells.enumerated() {
              if index > 0 { tokens.append(.init(text: " | ")) }
              for cellLine in cell.lines { tokens += runs(cellLine) }
            }
            out.append(.init(tokens: tokens, role: "table"))
          }
        default:
          out.append(.init(tokens: runs(line), opensBlock: line.opensBlock, role: role(line.kind)))
        }
      }
      return out
    }

    /// A page's lines as the reader sets them: each block's lines run on as
    /// one paragraph, and the furniture the print sets on one row (a page
    /// number and a running head on the headline, a signature and a
    /// catchword on the direction line) set on one line, which is one row.
    enum LaidOut {
      /// A line that stands alone: a page turn, a gap, a figure, a table,
      /// a piece of furniture.
      case line(TEILine)
      /// The lines of one block of text: a paragraph, a verse line, a
      /// heading, a speech prefix, a stage direction, a note.
      case block([TEILine])
      case furniture([TEILine])
    }

    /// Which lines run on together as one block: those of the same kind
    /// of text, from a line that opens a block to the next.
    static func blockKind(of kind: TEILine.Kind) -> String? {
      switch kind {
      case .text: return "text"
      case .heading: return "heading"
      case .speaker: return "speaker"
      case .stage: return "stage"
      case .note(let place): return "note \(place)"
      default: return nil
      }
    }

    /// Where a piece of furniture sits on its row: its own alignment, else
    /// a running head in the middle and anything else at the start.
    enum FurniturePlace: String, CaseIterable {
      case start, center, end

      static func of(_ line: TEILine) -> FurniturePlace {
        let rend = line.rend.split(whereSeparator: \.isWhitespace)
        if rend.contains("align(center)") { return .center }
        if rend.contains("align(right)") { return .end }
        if rend.contains("align(left)") { return .start }
        if case .forme(.header) = line.kind { return .center }
        return .start
      }
    }

    /// A block's lines by row: each line with the lines after it that share
    /// its row (`TEILine.sharesLine`).
    static func rows(of lines: [TEILine]) -> [[TEILine]] {
      var rows: [[TEILine]] = []
      for line in lines {
        if line.sharesLine, !rows.isEmpty {
          rows[rows.count - 1].append(line)
        } else {
          rows.append([line])
        }
      }
      return rows
    }

    static func layout(of lines: [TEILine]) -> [LaidOut] {
      var out: [LaidOut] = []
      var row: [TEILine] = []
      func close() {
        if row.count > 1 {
          out.append(.furniture(row))
        } else {
          out += row.map { .line($0) }
        }
        row = []
      }
      var block: [TEILine] = []
      func end() {
        if !block.isEmpty { out.append(.block(block)) }
        block = []
      }
      for line in lines {
        switch line.kind {
        case .forme:
          end()
          // Furniture that follows furniture with no line break between is
          // on the same line, whatever its role (Hamlet Q1: its catchword
          // on its signature's row, stacked under it while a catchword
          // never joined one).
          if !row.isEmpty && !line.sharesLine { close() }
          row.append(line)
        default:
          close()
          guard let kind = blockKind(of: line.kind) else {
            end()
            out.append(.line(line))
            continue
          }
          if line.opensBlock || block.first.flatMap({ blockKind(of: $0.kind) }) != kind { end() }
          block.append(line)
        }
      }
      close()
      end()
      return out
    }

    private func inlineContent(_ line: TEILine, facsimileURL: String, tabStop: TEIWordPlace? = nil) -> DOM.Node {
      // A line beside an initial dropped from a line above begins its text
      // after the initial, as the print sets it: what stands before its
      // first letter (a speech prefix, "2. "), then the initial's room (a
      // drop hang, its letter drawn invisible at the initial's size, never
      // the text), then its text.
      guard let hang = line.hang, let start = line.runs.firstIndex(where: { $0.text.contains(where: \.isLetter) })
      else {
        return span { markedContent(line.runs, facsimileURL: facsimileURL, tabStop: tabStop) }.build()
      }
      let before = markedContent(Array(line.runs[..<start]), facsimileURL: facsimileURL, tabStop: tabStop)
      let after = markedContent(Array(line.runs[start...]), facsimileURL: facsimileURL, tabStop: tabStop)
      return span {
        for node in before { node }
        span { "" }.class("tei-drop-hang").addingAttribute("aria-hidden", "true").data("letter", hang.letter)
          .addingAttribute("style", "--tei-drop-lines:\(hang.lines)")
        for node in after { node }
      }.build()
    }

    /// This view setting `page`'s markup, its words marked with their
    /// sentences and lemmas.
    private func marking(_ page: TEIPage) -> TEIView {
      var view = self
      view.sentences = TEIRenderer.sentences(of: page)
      var lemmas: [TEIWordPlace: String] = [:]
      var ids: [TEIWordPlace: String] = [:]
      for word in TEIRenderer.words(of: page) {
        if !word.lemma.isEmpty { lemmas[word.place] = word.lemma }
        let key = word.key
        if !key.isEmpty { ids[word.place] = key }
      }
      view.lemmas = lemmas
      view.wordIDs = ids
      return view
    }

    /// This view setting a translation whose blocks carry `notes`.
    private func noting(_ notes: [String: String]) -> TEIView {
      var view = self
      view.notes = notes
      return view
    }

    /// This view setting a page set in `typeArea` (`typeAreaMeasure`).
    private func measuring(_ typeArea: TEIPageTypeArea?) -> TEIView {
      var view = self
      view.typeAreaMeasure = typeArea?.measure ?? 0
      return view
    }

    /// Runs, each stretch of a block the translator noted one control that
    /// opens the note (`GlossHydration`), as a word opens its gloss.
    private func markedContent(_ runs: [TEILine.Run], facsimileURL: String, tabStop: TEIWordPlace?) -> [DOM.Node] {
      guard !notes.isEmpty else { return highlighted(runs, facsimileURL: facsimileURL, tabStop: tabStop) }
      var noted: [(note: String?, runs: [TEILine.Run])] = []
      for run in runs {
        let note = notes[run.segment]
        if let last = noted.last, last.note == note {
          noted[noted.count - 1].runs.append(run)
        } else {
          noted.append((note, [run]))
        }
      }
      return noted.flatMap { group -> [DOM.Node] in
        guard let note = group.note else { return highlighted(group.runs, facsimileURL: facsimileURL, tabStop: tabStop) }
        return [
          span { highlighted(group.runs, facsimileURL: facsimileURL, tabStop: tabStop) }
            .class("tei-noted")
            .role("button")
            // Notes are few: each in the tab order.
            .tabindex(0)
            .ariaHaspopup("dialog")
            .data("translator-note", note)
            .build()
        ]
      }
    }

    /// Runs, a quote's sentence, or its word, marked as the page has it:
    /// one mark over the runs it covers.
    private func highlighted(_ runs: [TEILine.Run], facsimileURL: String, tabStop: TEIWordPlace?) -> [DOM.Node] {
      var marked: [(highlight: TEIHighlight.Kind?, runs: [TEILine.Run])] = []
      for run in runs {
        if let last = marked.last, last.highlight == run.highlight {
          marked[marked.count - 1].runs.append(run)
        } else {
          marked.append((run.highlight, [run]))
        }
      }
      return marked.flatMap { group -> [DOM.Node] in
        guard let highlight = group.highlight else {
          return wordContent(group.runs, facsimileURL: facsimileURL, tabStop: tabStop)
        }
        return [
          mark { wordContent(group.runs, facsimileURL: facsimileURL, tabStop: tabStop) }
            .class("tei-highlight")
            .data("highlight", highlight.rawValue)
            .build()
        ]
      }
    }

    /// Runs, the runs of one word together as one control: its details open
    /// from it. The page's first word is its one stop in the tab order; the
    /// arrow keys move between its words.
    private func wordContent(_ runs: [TEILine.Run], facsimileURL: String, tabStop: TEIWordPlace?) -> [DOM.Node] {
      var words: [(word: TEIWordPlace?, runs: [TEILine.Run])] = []
      for run in runs {
        if let last = words.last, last.word == run.word {
          words[words.count - 1].runs.append(run)
        } else {
          words.append((run.word, [run]))
        }
      }
      return words.flatMap { group -> [DOM.Node] in
        guard let word = group.word else {
          // What is no word but encoded (a number, a date, a page number)
          // opens its element's gloss: its runs together as one control.
          var elements: [(element: Int?, runs: [TEILine.Run])] = []
          for run in group.runs {
            if let last = elements.last, last.element == (glossURL == nil ? nil : run.element) {
              elements[elements.count - 1].runs.append(run)
            } else {
              elements.append((glossURL == nil ? nil : run.element, [run]))
            }
          }
          return elements.flatMap { part -> [DOM.Node] in
            guard let element = part.element else {
              return runContents(part.runs, facsimileURL: facsimileURL, tabStop: tabStop)
            }
            return [
              glossable(
                span {
                  runContents(part.runs, facsimileURL: facsimileURL, tabStop: tabStop)
                }
                .class("tei-gloss-element"), element
              ).build()
            ]
          }
        }
        let node = span {
          runContents(group.runs, facsimileURL: facsimileURL, tabStop: tabStop)
        }
        .class("tei-word")
        .data("line", word.line)
        .data("word", word.word)
        .build()
        if let element = node as? DOM.Element {
          // A control only where it opens a gloss.
          if glossURL != nil {
            element.addingAttribute("role", "button")
            element.addingAttribute("tabindex", word == tabStop ? "0" : "-1")
            element.addingAttribute("aria-haspopup", "dialog")
          }
          if let sentence = sentences[word] { element.addingAttribute("data-sentence", "\(sentence)") }
          if let lemma = lemmas[word] { element.addingAttribute("data-lemma", lemma) }
          if let id = wordIDs[word] { element.addingAttribute("data-word-id", id) }
        }
        return [node]
      }
    }

    /// What is opened as a whole—a line that is an element (a gap, a side
    /// mark, a figure) or the runs of one that is no word—as a control
    /// that opens its gloss, as a word is; as it is where the markup is
    /// read whole.
    private func glossable<Element: HTMLElementBuildable>(_ node: Element, _ element: Int?) -> Element {
      guard let element, glossURL != nil else { return node }
      return node.setAttribute("role", "button").setAttribute("tabindex", "-1")
        .setAttribute("aria-haspopup", "dialog").setAttribute("data-gloss-element", "\(element)")
    }

    /// A word's runs as printed. Its expansion, regularization or
    /// correction is read in its gloss sheet alone (user, 2026-11-09: the
    /// gloss sheet superseded the hover tooltip; no fallback to it).
    private func runContents(_ runs: [TEILine.Run], facsimileURL: String, tabStop: TEIWordPlace?) -> [DOM.Node] {
      runs.map { runContent($0, facsimileURL: facsimileURL, tabStop: tabStop) }
    }

    private func runContent(_ run: TEILine.Run, facsimileURL: String, tabStop: TEIWordPlace?) -> DOM.Node {
      switch run.kind {
      case .text:
        // An initial the print drops through the lines beside it
        // (`TEIRenderer.dropped`, Hamlet Q1 p. 3's two-line S): the letter in
        // the text's face, still the word's text, its cap from its line's cap
        // height down to the last line's baseline beside it.
        if run.drop > 1 {
          return span {
            span { span { run.text }.class("tei-drop-letter") }.class("tei-drop-shift")
          }.class("tei-run tei-drop-initial").data("rend", run.rend).data("drop", run.drop)
            .addingAttribute("style", TEIRendition.css(from: run.rend) + "--tei-drop-lines:\(run.drop)").build()
        }
        // A decorated initial with its box: the decoration cut from the
        // facsimile as a figure's is, with its letter drawn over it
        // transparent, so the letter stays the word's text (selected, found,
        // copied, read aloud) while the page's own initial is what shows.
        // Asked at twice the 96px it is drawn at, never more: an image service
        // on IIIF Image API 3 refuses to enlarge a small region (HTTP 400).
        if let zone = run.zone, let region = TEIRenderer.regionURL(ofFacsimile: facsimileURL, zone: zone, fitting: 192) {
          return span {
            img().src(region).alt("").loading(.lazy).class("tei-figure-image tei-initial-image")
            span { run.text }.class("tei-initial-letter")
          }.class("tei-run tei-initial").data("rend", run.rend).addingAttribute("style", TEIRendition.css(from: run.rend)).build()
        }
        // A marked ligature Unicode encodes is drawn, and so copied, as its
        // presentation form (user, 2026-10-31: ﬁ, ﬅ); the TEI keeps its
        // letters, and one Unicode lacks (ct, ſi) stays its letters.
        let text = Self.drawnText(of: run)
        let drawn = span { text }.class("tei-run").data("rend", run.rend).addingAttribute("style", TEIRendition.css(from: run.rend))
        return (run.preserved ? drawn.data("space", "preserve") : drawn).build()
      case .math(let formula):
        return mathContent(formula, facsimileURL: facsimileURL, tabStop: tabStop)
      case .space(let quantity, let unit):
        // Space the source leaves in the line, as wide as it says (user,
        // 2026-10-13): a gap in the line, its one space what a reader
        // copies.
        return span { run.text }.class("tei-run tei-run-space").data("rend", run.rend).data("space", "preserve")
          .data("quantity", Self.number(quantity)).data("unit", unit)
          .style { CSS.Property("inline-size", Self.spaceWidth(quantity: quantity, unit: unit)) }.build()
      }
    }

    /// A formula drawn as the browser draws MathML (MathML Core): each
    /// symbol it prints is a word of the page, opened as a printed word is.
    private func mathContent(_ formula: TEIMath, facsimileURL: String, tabStop: TEIWordPlace?) -> DOM.Node {
      TEIMathView(formula) { runs in
        // A symbol is one word: the token element itself is the word (and
        // its highlight), its text its own, so an operator keeps MathML's
        // spacing for it. A token of several words (an <mtext>) marks each.
        if runs.allSatisfy({ $0.word == nil && $0.highlight == nil }) { return TEIMathView.text(runs) }
        guard let word = runs.first?.word, runs.allSatisfy({ $0.word == word && $0.highlight == runs.first?.highlight })
        else {
          return TEIMathView.Token(content: markedContent(runs, facsimileURL: facsimileURL, tabStop: tabStop))
        }
        var attributes: [(String, String)] = [
          ("class", runs.first?.highlight == nil ? "tei-word" : "tei-word tei-highlight"), ("role", "button"),
          ("tabindex", word == tabStop ? "0" : "-1"), ("aria-haspopup", "dialog"),
          ("data-line", "\(word.line)"), ("data-word", "\(word.word)"),
        ]
        if let highlight = runs.first?.highlight { attributes.append(("data-highlight", highlight.rawValue)) }
        return TEIMathView.Token(attributes: attributes, content: [DOM.Text(runs.map(\.text).joined())])
      }.build()
    }

    /// A page's first word, where its words can be opened: the one stop
    /// the page has in the tab order.
    static func firstWord(of lines: [TEILine]) -> TEIWordPlace? {
      for line in lines {
        if case .table(let table) = line.kind {
          if let word = firstWord(of: table.caption + table.rows.flatMap { $0.cells.flatMap(\.lines) }) {
            return word
          }
        } else if let word = line.runs.lazy.flatMap({ run -> [TEIWordPlace] in
          if case .math(let formula) = run.kind { return formula.runs.compactMap(\.word) }
          return run.word.map { [$0] } ?? []
        }).first {
          return word
        }
      }
      return nil
    }

    /// A canvas's lines by the pages it holds: a canvas photographed as an
    /// opening carries a `<pb/>` for each of its sides (the explication
    /// prompt's section 8), each read as a `.mark` line. A page opens at
    /// each such mark after the lines before it; one page where there is
    /// none.
    static func spreadPages(of lines: [TEILine]) -> [[TEILine]] {
      var pages: [[TEILine]] = [[]]
      for line in lines {
        if case .mark = line.kind, !pages[pages.count - 1].isEmpty { pages.append([]) }
        pages[pages.count - 1].append(line)
      }
      return pages
    }

    /// A canvas's rendered lines, headed by `heading` (its label) where
    /// given. A canvas holding two pages or more—an opening photographed
    /// whole—is set as a `.tei-spread` (user, 2026-10-12), each page a
    /// `.tei-spread-page` headed by its own label, in reading order: with
    /// Reflow off side by side, in the document's `direction`, so the
    /// text looks like the image beside it; with Reflow on one after the
    /// other.
    private func columnLayout(_ lines: [TEILine], facsimileURL: String, label: String, tabStop: TEIWordPlace?) -> [DOM.Node] {
      let columns = Array(Set(lines.map(\.column).filter { $0 > 0 })).sorted()
      guard columns.count > 1 else { return laidOut(lines, facsimileURL: facsimileURL, label: label, tabStop: tabStop) }
      // The columns stand in the element holding their `<cb/>`s (a
      // footnote, a division): its column gap between them, its inline
      // margins around them, as CSS sets a multi-column box; its blocks'
      // margins are then the rest of their own.
      let container = lines.first { $0.column > 0 }?.columnRend ?? ""
      let style = (TEIRendition.columnGap(of: container).map { "column-gap:\($0);" } ?? "")
        + TEIRendition.columnMargins(of: container)
      return laidOut(lines.filter { $0.column == 0 }, facsimileURL: facsimileURL, label: label, tabStop: tabStop) + [
        div {
          for column in columns {
            div {
              laidOut(
                lines.filter { $0.column == column }, facsimileURL: facsimileURL, label: label, tabStop: tabStop,
                columns: container)
            }
            .class("tei-column")
          }
        }.class("tei-columns").addingAttribute("style", style).build()
      ]
    }

    private func rendered(
      _ lines: [TEILine], heading: String?, direction: String?, facsimileURL: String, label: String,
      tabStop: TEIWordPlace? = nil
    ) -> [DOM.Node] {
      func mark(_ text: String) -> DOM.Node {
        renderingLine(.init(kind: .mark, text: text.isEmpty ? "—" : text), facsimileURL: facsimileURL, label: label)
      }
      let pages = Self.spreadPages(of: lines)
      guard pages.count > 1 else {
        let content = labelsPages ? lines : lines.filter { if case .mark = $0.kind { false } else { true } }
        return (heading.map { [mark($0)] } ?? []) + columnLayout(content, facsimileURL: facsimileURL, label: label, tabStop: tabStop)
      }
      let spread = div {
        for (index, page) in pages.enumerated() {
          // The first side's own page break is the document's, outside the
          // canvas's markup: its label is the canvas's, set as the other
          // sides' are, so the columns' first lines stand level.
          let headed = index > 0 || page.first.map { if case .mark = $0.kind { true } else { false } } ?? false
          let text = heading ?? label
          div {
            columnLayout(
              labelsPages
                ? (headed ? page : [TEILine(kind: .mark, text: text.isEmpty ? "—" : text)] + page)
                : page.filter { if case .mark = $0.kind { false } else { true } },
              facsimileURL: facsimileURL, label: label, tabStop: tabStop)
          }
          .class("tei-spread-page")
        }
      }
      .class("tei-spread")
      return [(direction.map { spread.dir($0) } ?? spread).build()]
    }

    /// A page's lines as the reader sets them (`layout(of:)`), in sections
    /// a paragraph's space apart: a section opens at a line that opens a
    /// paragraph (`TEILine.opensParagraph`), as a TEI reader sets a `<p>`
    /// (user, 2026-10-11). The markup's own layer and its translation's
    /// alike.
    private func laidOut(
      _ lines: [TEILine], facsimileURL: String, label: String, tabStop: TEIWordPlace? = nil, columns: String = ""
    ) -> [DOM.Node] {
      // Runs of lines one box sets (an epigraph's), each its sections.
      var boxes: [(box: String, sections: [[LaidOut]])] = []
      for item in Self.layout(of: lines) {
        let first: TEILine
        switch item {
        case .line(let line): first = line
        case .block(let lines), .furniture(let lines): first = lines[0]
        }
        if boxes.isEmpty || boxes[boxes.count - 1].box != first.box {
          boxes.append((first.box, [[item]]))
        } else if first.opensParagraph {
          boxes[boxes.count - 1].sections.append([item])
        } else {
          let last = boxes[boxes.count - 1].sections.count - 1
          boxes[boxes.count - 1].sections[last].append(item)
        }
      }
      return boxes.flatMap { run -> [DOM.Node] in
        let sections = sectioned(
          run.sections, facsimileURL: facsimileURL, label: label, tabStop: tabStop, columns: columns)
        guard !run.box.isEmpty else { return sections }
        // Its own box only (a printed box's rule, inset and measure, its
        // margins): its lines carry the rest of their setting.
        return [
          div { sections }.class("tei-box").data("rend", run.box)
            .addingAttribute("style", TEIRendition.css(from: run.box, only: Self.ownBoxProperties)).build()
        ]
      }
    }

    /// What a box draws of its rend: its own setting (`TEIRendition.box(of:)`).
    static let ownBoxProperties = TEIRendition.boxProperties.union([
      "margin-left", "margin-right", "margin-inline-start", "margin-inline-end", "margin-top", "margin-bottom",
      "margin-block-start", "margin-block-end",
    ])

    /// A block's or a line's style from its rend: its print's setting, and
    /// what Reflow sets it by in its place (`reflowStyle`), the leading it
    /// keeps where the box next to it needs it (`keptLeading`).
    private func setting(_ rend: String, kept: KeptLeading = .init()) -> String {
      TEIRendition.css(from: rend) + Self.reflowStyle(of: rend, measure: typeAreaMeasure, kept: kept)
    }

    /// Of the leading a box set solid gives back reflowed (`reflowStyle`),
    /// what it keeps at its start and at its end, in its own em.
    struct KeptLeading {
      var start = 0.0
      var end = 0.0
    }

    /// Reflowed, what each of a run's blocks set solid keeps of the leading
    /// it gives back (`reflowStyle`), so no line's type runs into the next
    /// block's (user, 2026-11-05: Hamlet Q1's title page, "THE" set 0.88 of
    /// its type and straight under it "Tragicall Historie of", their type
    /// 1.6 px into each other once "THE" gave its leading back; "As it hath
    /// beene…" and "1603.", both set solid, 2.6 px). Where the print stands
    /// two blocks closer than their type is tall, it keeps as much as clears
    /// them, the upper one's end first, and what follows stands that much
    /// lower; where the print gives them the room, all of it is given back,
    /// and each stands where its print sets it. Only blocks one straight
    /// after another (`items`, a run's sections in order, which stand with
    /// no room between them): a space, a figure or a rule between two is the
    /// print's own room, and text set over a figure is set so by its print.
    /// Each block's type is its em, centered on its line: set solid its line,
    /// otherwise half its leading over its type inside it, where its rend
    /// says its leading; at its line's edge where it says none.
    static func keptLeading(of items: [LaidOut], columns: String) -> [KeptLeading] {
      var kept = Array(repeating: KeptLeading(), count: items.count)
      /// A block's type size in the body's em, its leading, and the margins
      /// its print declares before and after it in its own em.
      typealias Box = (size: Double, leading: Double?, start: Double, end: Double)
      /// A block's `Box`; nil for what is no block, or where a margin is no
      /// length read here (a `calc`, an unknown unit).
      func box(_ item: LaidOut) -> Box? {
        guard case .block(let lines) = item else { return nil }
        let rend = columns.isEmpty ? lines[0].rend : TEIRendition.inColumns(lines[0].rend, of: columns)
        guard let size = TEIRendition.fontSize(of: rend), size > 0 else { return nil }
        func margin(_ names: [String]) -> Double? {
          for name in names {
            let css = TEIRendition.css(from: rend, only: [name])
            guard css.hasPrefix(name + ":") else { continue }
            let value = String(css.dropFirst(name.count + 1).prefix { $0 != ";" })
            if value.hasSuffix("rem") { return Double(value.dropLast(3)).map { $0 / size } }
            if value.hasSuffix("em") { return Double(value.dropLast(2)) }
            if value.hasSuffix("px") { return Double(value.dropLast(2)).map { $0 / 16 / size } }
            return Double(value).flatMap { $0 == 0 ? 0 : nil }
          }
          return 0
        }
        guard let start = margin(["margin-block-start", "margin-top"]), let end = margin(["margin-block-end", "margin-bottom"])
        else { return nil }
        return (size, TEIRendition.leading(of: rend), start, end)
      }
      guard items.count > 1 else { return kept }
      for index in 1..<items.count {
        guard let above = box(items[index - 1]), let below = box(items[index]) else { continue }
        // In the body's em: what each gives back (set solid, half the
        // leading it gains), and how far inside its line its type stands.
        func given(_ box: Box) -> Double {
          guard let leading = box.leading, leading < 1 else { return 0 }
          return (1 - leading) / 2 * box.size
        }
        func inset(_ box: Box) -> Double {
          guard let leading = box.leading, leading > 1 else { return 0 }
          return (leading - 1) / 2 * box.size
        }
        let up = given(above)
        let down = given(below)
        guard up + down > 0 else { continue }
        let room = above.end * above.size + below.start * below.size + inset(above) + inset(below) - up - down
        guard room < 0 else { continue }
        let atEnd = min(-room, up)
        let atStart = min(-room - atEnd, down)
        kept[index - 1].end = atEnd / above.size
        kept[index].start = atStart / below.size
      }
      return kept
    }

    /// What Reflow sets a box of `rend` by in place of its print's setting
    /// (user, 2026-11-03), as the custom properties its rules read. Reflow
    /// changes only how text runs on and wraps; the page's vertical rhythm
    /// is its print's (user, 2026-11-05: "why reflow changes vertical
    /// gaps?"): a box keeps the room its print gives it, its first line
    /// where the print sets it and each gap to the next box as printed, and
    /// grows only by the lines it wraps. So: lines set closer than their
    /// type is tall (`TEIRendition.leading` under 1: a line placed by its
    /// zone is its box's height, 0.714 of its type) set solid
    /// (`--tei-reflow-leading`), so a line they wrap clears the one above,
    /// the leading that gains taken back half above and half below the box
    /// (`--tei-reflow-margin-start`, `--tei-reflow-margin-end`: its print's
    /// margins less that half); a box the print gives a height at least that
    /// tall (`--tei-reflow-min-block`, less the leading taken back), as tall
    /// as its lines where they need more; a line placed by its zone about
    /// its box's middle, as far as the type area's `measure` lets it
    /// (`TEIPage.reflowedBox`: `--tei-reflow-start`, `--tei-reflow-size`, in
    /// its em), so it wraps where its type area ends, never because the face
    /// fills its box (Hamlet Q1's front cover, reflowed: "HAMLE" over its
    /// "T", "SHAKESPEAR" over its "E", "LONDON" over "1603"); a tracked
    /// line, its tracking as its inset (`--tei-reflow-tracking`). Reflow
    /// off, the print's setting stands. Of the leading it gives back, a box
    /// keeps what `kept` says at either side, so its type never runs into
    /// the box next to it (`keptLeading`).
    static func reflowStyle(of rend: String, measure: Double, kept: KeptLeading = .init()) -> String {
      func em(_ value: Double) -> String { number((value * 10_000).rounded() / 10_000) + "em" }
      /// The value its print declares for the first of `names` it declares.
      func declared(_ names: [String]) -> String? {
        for name in names {
          let css = TEIRendition.css(from: rend, only: [name])
          if css.hasPrefix(name + ":") { return String(css.dropFirst(name.count + 1).prefix { $0 != ";" }) }
        }
        return nil
      }
      var style = ""
      // Half the leading a line set solid gains, in its em (negative).
      var half: String?
      if let leading = TEIRendition.leading(of: rend), leading < 1 {
        let taken = em((leading - 1) / 2)
        half = taken
        let start = declared(["margin-block-start", "margin-top"]) ?? "0em"
        let end = declared(["margin-block-end", "margin-bottom"]) ?? "0em"
        // What it gives back at either side, less what it keeps there.
        let atStart = kept.start > 0 ? em((leading - 1) / 2 + kept.start) : taken
        let atEnd = kept.end > 0 ? em((leading - 1) / 2 + kept.end) : taken
        style += "--tei-reflow-leading:1;--tei-reflow-margin-start:calc(\(start) + \(atStart));"
          + "--tei-reflow-margin-end:calc(\(end) + \(atEnd));"
      }
      if let height = declared(["block-size", "height"]) {
        style += "--tei-reflow-min-block:" + (half.map { "calc(\(height) - 2 * \($0))" } ?? height) + ";"
      }
      if let box = TEIPage.reflowedBox(of: rend, measure: measure) {
        style += "--tei-reflow-start:\(em(box.start));--tei-reflow-size:\(em(box.size));"
      }
      // A tracked box is set past its end by its tracking
      // (`TEIRendition.css(from:)`): as wide as its pane, it ran past the
      // pane, which scrolled sideways (Hamlet Q1's title page, "THE"); in a
      // box of its own, its line still centered half its tracking short.
      // Reflowed, its tracking is its inset at its start instead
      // (`--tei-reflow-tracking`), which only a centered line keeps.
      let tracking = TEIRendition.css(from: rend, only: ["letter-spacing"])
      if tracking.hasPrefix("letter-spacing:"), !tracking.hasPrefix("letter-spacing:-"), !tracking.hasPrefix("letter-spacing:0;") {
        style += "--tei-reflow-tracking:\(tracking.dropFirst("letter-spacing:".count).prefix { $0 != ";" });"
      }
      return style
    }

    /// Sections of laid-out lines, each its own block (`laidOut`); in
    /// columns, the setting of the element they stand in (`columnLayout`).
    private func sectioned(
      _ sections: [[LaidOut]], facsimileURL: String, label: String, tabStop: TEIWordPlace?, columns: String = ""
    ) -> [DOM.Node] {
      // The run's blocks in order, one section straight after another: what
      // each keeps of the leading it gives back reflowed (`keptLeading`).
      let kept = Self.keptLeading(of: sections.flatMap { $0 }, columns: columns)
      // Where each section's first item stands in that order.
      let firsts: [Int] = {
        var out: [Int] = []
        var count = 0
        for items in sections {
          out.append(count)
          count += items.count
        }
        return out
      }()
      return sections.enumerated().map { section, items in
        div {
          for (at, item) in items.enumerated() {
            switch item {
            case .line(let line):
              renderingLine(line, facsimileURL: facsimileURL, label: label, tabStop: tabStop)
            case .block(let lines):
              // A block's lines run on as one paragraph, a break inside a
              // word joining it with no space. The block always holds
              // text between its lines (empty at such a break), so its
              // markup is written inline: an indented block put a
              // newline, a space as read, inside the broken word.
              div {
                for (index, row) in Self.rows(of: lines).enumerated() {
                  if index > 0 { row[0].joinsPrevious ? "" : " " }
                  if row.count == 1 {
                    renderingLine(
                      row[0], facsimileURL: facsimileURL, label: label, tabStop: tabStop, inStyledBlock: true)
                  } else {
                    // Lines the print sets on one row (a turnover beside
                    // the line it stands on): the row's first, and each
                    // other at its own place across, its own setting's.
                    span {
                      for (place, line) in row.enumerated() {
                        if place > 0 { " " }
                        renderingLine(
                          line, facsimileURL: facsimileURL, label: label, tabStop: tabStop, inStyledBlock: place == 0)
                      }
                    }.class("tei-row")
                  }
                }
              }.class("tei-block").data("rend", lines[0].rend).data("part", lines[0].part)
                // How many lines the print sets it in: one runs, reflowed, as far as its pane lets it.
                .data("printed-lines", Self.rows(of: lines).count).addingAttribute(
                "style",
                setting(
                  columns.isEmpty ? lines[0].rend : TEIRendition.inColumns(lines[0].rend, of: columns),
                  kept: kept[firsts[section] + at]))
            case .furniture(let pieces):
              // A page number and a running head set on one line keep
              // their places on it, as the image has them: each piece
              // placed across the whole row by its own setting, never after
              // another (a piece set at its own place, gnorium-python
              // `base_tei._start_of`, is its start from the measure's).
              div {
                for piece in pieces {
                  div {
                    renderingLine(piece, facsimileURL: facsimileURL, label: label, tabStop: tabStop)
                  }.class("tei-forme-row-\(FurniturePlace.of(piece).rawValue)")
                }
              }.class("tei-forme-row")
            }
          }
        }.class("tei-section").build()
      }
    }

    /// The height a vertical `<space/>` leaves: so many of the text's
    /// lines (`lh`, its leading); a length in its own unit where CSS has
    /// it; a character's height as an em.
    static func spaceHeight(quantity: Double, unit: String) -> String {
      switch unit {
      case "mm", "cm", "in", "pt", "pc", "px", "em": return "\(number(quantity))\(unit)"
      case "chars", "char", "ems": return "\(number(quantity))em"
      default: return "\(number(quantity))lh"
      }
    }

    /// The width a horizontal `<space/>` leaves: so many of the text's
    /// characters, each as wide as its header declares a space's character
    /// (`space-char`, the width the tuning fitted to the print's quads: the
    /// page's `--tei-space-char`, `pageTextStyle`), else a `ch`; a length in
    /// its own unit where CSS has it.
    static func spaceWidth(quantity: Double, unit: String) -> String {
      switch unit {
      case "mm", "cm", "in", "pt", "pc", "px", "em": return "\(number(quantity))\(unit)"
      case "ems": return "\(number(quantity))em"
      default: return "calc(\(number(quantity)) * var(--tei-space-char, 1ch))"
      }
    }

    /// A space's character as the header declares it (`<rendition xml:id="space-char">inline-size:…em</rendition>`,
    /// gnorium-python `scale.space_rendition`), nil where it declares none.
    static func spaceCharacter(in renditions: [String: String]) -> String? {
      // As the header's declarations are read (`TEIRendition.declarations`):
      // `css:inline-size=0.3em`.
      guard let tokens = renditions["space-char"] else { return nil }
      for token in tokens.split(whereSeparator: \.isWhitespace) where token.hasPrefix("css:inline-size=") {
        let value = token.dropFirst("css:inline-size=".count)
        guard value.hasSuffix("em"), !value.hasSuffix("rem"), let number = Double(value.dropLast(2)), number > 0
        else { continue }
        return "\(Self.number(number))em"
      }
      return nil
    }

    /// How far before its type area's start a page sets a line, in its em (user,
    /// 2026-11-03): the most a block or a line starts before it (a negative
    /// `margin-inline-start`, in its own type's em, Hamlet Q1's title page's
    /// "Tragicall Hiſtorie of" 2.2 em out), 0 for none. Reflowed, the type area
    /// keeps that much room either side, so no line runs out of sight
    /// (`--tei-reflow-outdent`, in rem: the page's em is the root's, 16 px,
    /// wherever a box of another size reads it).
    static func outdent(of lines: [TEILine]) -> Double {
      lines.reduce(0) { most, line in
        let set = TEIRendition.css(from: line.rend, only: ["margin-inline-start"])
        guard set.hasPrefix("margin-inline-start:-"), set.hasSuffix("em;"), !set.hasSuffix("rem;"),
          let value = Double(set.dropFirst("margin-inline-start:-".count).dropLast(3))
        else { return most }
        return max(most, value * (TEIRendition.fontSize(of: line.rend) ?? 1))
      }
    }

    /// The page's rendering layer's style: its type area (`typeAreaStyle`), the width of a space's character
    /// (`spaceCharacter`) and the body's leading in em (`TEIRendition.bodyLeading`), which the furniture of a
    /// page set in its type area is set at.
    static func pageTextStyle(
      typeArea: TEIPageTypeArea?, renditions: [String: String], bodyLeading: Double? = nil, outdent: Double = 0
    ) -> String {
      let parts = [
        typeArea.map(typeAreaStyle), spaceCharacter(in: renditions).map { "--tei-space-char: \($0)" },
        bodyLeading.map { "--tei-body-leading: \(number($0))" },
        outdent > 0 ? "--tei-reflow-outdent: \(number((outdent * 10_000).rounded() / 10_000))rem" : nil,
      ]
      return parts.compactMap { $0 }.joined(separator: "; ")
    }

    /// A quantity as written: a whole one with no decimal point.
    static func number(_ value: Double) -> String {
      value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
    }

    private func renderingLine(
      _ line: TEILine, facsimileURL: String, label: String, tabStop: TEIWordPlace? = nil, inStyledBlock: Bool = false,
      leads: Bool = false
    ) -> DOM.Node {
      if leads, case .text = line.kind, let leader = Self.leader(of: line.runs) {
        return leadered(line, leader, facsimileURL: facsimileURL, tabStop: tabStop)
      }
      switch line.kind {
      case .heading:
        return h3 { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-line tei-line-heading").data("rend", line.rend).addingAttribute("style", inStyledBlock ? "" : setting(line.rend))
          .build()
      case .speaker:
        return span { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-line tei-line-speaker").data(
          "rend", line.rend
        ).addingAttribute("style", inStyledBlock ? "" : setting(line.rend)).build()
      case .stage:
        return span { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-line tei-line-stage").data("rend", line.rend).addingAttribute("style", inStyledBlock ? "" : setting(line.rend))
          .build()
      case .mark:
        return glossable(span { line.text }.class("tei-line tei-line-mark"), line.element).build()
      case .gap(let reason):
        // A statement about the page, never a mark on it (user, repeated
        // 2026-10-30): the parse shows only what the page bears, so a gap of
        // any reason draws nothing. Its reason stays in the TEI and here.
        return span {}.class("tei-line tei-line-gap").ariaHidden(true).data("reason", reason).build()
      case .documentBoundary:
        return hr().class("tei-document-boundary").build()
      case .rule:
        // A printed rule: a line in the text's ink, as long and placed as
        // its rend says, the measure where it says none.
        return hr().class("tei-rule").data("rend", line.rend)
          .addingAttribute("style", TEIRendition.css(from: line.rend)).build()
      case .space(let quantity, let unit):
        // Blank height the source leaves, as much as it says (user,
        // 2026-10-11): never a line of text.
        // A negative one (lines set closer than their leading) draws them
        // closer: no height, a margin as negative (user, 2026-10-28).
        if quantity < 0 {
          return div {}.class("tei-space").ariaHidden(true)
            .data("quantity", Self.number(quantity)).data("unit", unit)
            .style { CSS.Property("margin-block-start", Self.spaceHeight(quantity: quantity, unit: unit)) }.build()
        }
        return div {}.class("tei-space").ariaHidden(true)
          .data("quantity", Self.number(quantity)).data("unit", unit)
          .style { CSS.Property("height", Self.spaceHeight(quantity: quantity, unit: unit)) }.build()
      case .note(let place):
        return span { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-line tei-line-note")
          .data("place", place.isEmpty ? "inline" : place).data("rend", line.rend).addingAttribute("style", inStyledBlock ? "" : setting(line.rend)).build()
      case .forme(let role):
        return span { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class(
          "tei-line tei-line-forme tei-line-forme-\(role.rawValue)"
        ).data("rend", line.rend).addingAttribute("style", inStyledBlock ? "" : setting(line.rend)).build()
      case .figure(let type, let zone, let graphic):
        let alt = line.text.isEmpty ? "Figure on \(label)" : line.text
        // Its size and its place across as the scan has them, where its setting gives them (gnorium-python
        // `base_tei._figure`, in the body's em): drawn at them, never at an illustration's bounds.
        let placed = TEIRendition.css(from: line.rend, only: TEIPage.figureSetting)
        // Its zone on the scan, which the reader's overlay lays it against (`figureZoneData`).
        let zoneData = zone.map(Self.figureZoneData) ?? ""
        // Its drawing where it has one (its inks traced as vectors, `TEILine
        // .Kind.figure`), used from the file its graphic names (`<use>` of
        // its `TEIDrawing.fragment`, served as `TEIDrawing.referenced`): in
        // the page's ink from the first frame, which an `<img>` of it never
        // is (`currentColor` black), one cached request, never its paths in
        // the page (user, 2026-10-31). Its box is the zone's: its setting's
        // where it is placed; else the zone's proportions on the surface. A
        // crop of the facsimile where it has none.
        // Its `<figDesc>` (`line.text`) is the encoder's description, never
        // printed on the page: the drawing's label (the crop's `alt`), its
        // gloss's and its XML's, never a caption drawn under it (user,
        // 2026-11-05). A caption the page prints (a `<head>` in the figure)
        // is set as the text's own lines after it (`TEIRenderer`).
        if let graphic {
          let box = zone?.percent
          return glossable(
            figure {
              span {
                svg {
                  use().href("\(graphic)#\(TEIDrawing.fragment)").width(perc(100)).height(perc(100))
                }
                .viewBox("0 0 \(Self.number(box?.width ?? 1)) \(Self.number(box?.height ?? 1))")
                .preserveAspectRatio("none").role("img").ariaLabel(alt)
              }.class("tei-figure-drawing")
            }.class("tei-line tei-figure").data("figure-type", type.isEmpty ? "figure" : type)
              .data("placed", placed.isEmpty ? "false" : "true").data("zone", zoneData)
              .addingAttribute("style", placed), line.element
          ).build()
        }
        guard let zone, let region = TEIRenderer.regionURL(ofFacsimile: facsimileURL, zone: zone) else {
          return DOM.Node.fragment([])
        }
        return glossable(
          figure {
            img().src(region).alt(alt).loading(.lazy).class("tei-figure-image")
          }.class("tei-line tei-figure").data("figure-type", type.isEmpty ? "figure" : type)
            .data("placed", placed.isEmpty ? "false" : "true").data("zone", zoneData)
            .addingAttribute("style", placed), line.element
        ).build()
      case .table(let source):
        return div {
          table {
            if !source.caption.isEmpty {
              caption {
                for line in source.caption {
                  renderingLine(line, facsimileURL: facsimileURL, label: label, tabStop: tabStop)
                }
              }
            }
            tbody {
              for row in source.rows {
                tr {
                  for (index, cell) in row.cells.enumerated() {
                    // A contents entry's title runs its printed dots on to
                    // its page reference, the row's last cell.
                    let leads = source.type == "contents" && index < row.cells.count - 1
                    if cell.isLabel {
                      th {
                        for line in cell.lines {
                          renderingLine(line, facsimileURL: facsimileURL, label: label, tabStop: tabStop, leads: leads)
                        }
                      }.rowspan(cell.rows).colspan(cell.columns)
                    } else {
                      td {
                        for line in cell.lines {
                          renderingLine(line, facsimileURL: facsimileURL, label: label, tabStop: tabStop, leads: leads)
                        }
                      }.rowspan(cell.rows).colspan(cell.columns)
                    }
                  }
                }
              }
            }
          }.class("tei-table").data("table-type", source.type)
        }.class("tei-table-scroll").build()
      case .text:
        // Whether the break before it falls inside a word (`<lb
        // break="no"/>`): a reader's find reads the two lines as one word.
        return span { inlineContent(line, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-line").data("rend", line.rend).addingAttribute("style", inStyledBlock ? "" : setting(line.rend))
          .data("joins-previous", line.joinsPrevious).build()
      }
    }

    /// The dots a printed leader is set in; the space between them is any
    /// the TEI keeps (a space, an en space, a no-break space).
    static let leaderDots: Set<Character> = [".", "·", "…"]

    static func isLeader(_ character: Character) -> Bool {
      leaderDots.contains(character) || character.isWhitespace
    }

    /// A contents title's line split before its printed leader: the run of
    /// dots it ends in (at least two), as the TEI keeps them, punctuation;
    /// nil where it ends in none.
    static func leader(of runs: [TEILine.Run]) -> (title: [TEILine.Run], dots: [TEILine.Run])? {
      var title = runs
      var dots: [TEILine.Run] = []
      while let run = title.last, case .text = run.kind {
        let tail = run.text.reversed().prefix(while: isLeader).count
        guard tail > 0 else { break }
        title.removeLast()
        if tail == run.text.count {
          dots.insert(run, at: 0)
          continue
        }
        let cut = run.text.index(run.text.endIndex, offsetBy: -tail)
        func part(_ text: String) -> TEILine.Run {
          .init(
            text: text, rend: run.rend, kind: run.kind, alternative: run.alternative, highlight: run.highlight,
            word: run.word, zone: run.zone, element: run.element, preserved: run.preserved)
        }
        title.append(part(String(run.text[..<cut])))
        dots.insert(part(String(run.text[cut...])), at: 0)
        break
      }
      let printed = dots.map(\.text).joined().filter(leaderDots.contains)
      return printed.count >= 2 ? (title, dots) : nil
    }

    /// A contents title line, its printed dots set as a leader (user,
    /// 2026-10-13): exactly the dots the TEI has, at their printed pitch
    /// (the dot run's own `letter-spacing` and `word-spacing`, else its
    /// type's natural spacing), set from the cell's far edge, so the dots of
    /// every row stand in the same columns, as printed. Nothing is drawn
    /// that the page does not print, and nothing printed is dropped.
    private func leadered(
      _ line: TEILine, _ leader: (title: [TEILine.Run], dots: [TEILine.Run]), facsimileURL: String,
      tabStop: TEIWordPlace?
    ) -> DOM.Node {
      span {
        span { markedContent(leader.title, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-leader-title")
        span { markedContent(leader.dots, facsimileURL: facsimileURL, tabStop: tabStop) }.class("tei-leader")
      }
      .class("tei-line tei-line-leadered").data("rend", line.rend)
      .addingAttribute("style", TEIRendition.css(from: line.rend))
      .data("joins-previous", line.joinsPrevious).build()
    }

    public func build() -> DOM.Node {
      let pages = self.pages
      // Each page's surface, the facsimile read once for all of them.
      let surfaces = TEIFacsimile.surfaces(of: pages, in: teiXml)
      // Record pages register an empty reader before fetching its contents:
      // formula styles are registered then, even with no formula yet.
      _ = TEIMathView(TEIMath(display: false, content: [])).build()
      return div {
        if pages.isEmpty {
          p { "This document has no page breaks to read by. The raw XML is below." }
            .class("tei-empty")
        }
        for (index, page) in pages.enumerated() where self.page == nil || self.page == index || drawn.contains(index) {
          let tabStop = glossURL == nil ? nil : Self.firstWord(of: page.lines)
          // Its words marked with their sentences and lemmas where they open;
          // its lines placed by their zones run, reflowed, in its type area.
          let typeArea = page.typeArea
          let reader = (wordsMarked ? marking(page) : self).measuring(typeArea)
          let pageNode = div {
            div {
              if let typeArea {
                // The work's type area, its body pages' main text block: the
                // page's main text set in it; its marginalia outside it,
                // beside, above or below it where the scan has them (user,
                // 2026-10-14); an equal margin around them all. A blank leaf
                // is the empty page it is (user, 2026-10-29): its `<gap
                // reason="blank"/>` a statement about the page, kept in its
                // TEI, never a mark printed on it.
                let lines = page.lines.filter { if case .gap(reason: "blank") = $0.kind { false } else { true } }
                div {
                  reader.rendered(
                    lines.filter { Self.marginalPlace(of: $0) == nil }, heading: labelsPages ? page.label : nil,
                    direction: direction, facsimileURL: page.facsimileURL, label: page.label, tabStop: tabStop)
                }
                .class("tei-text-block")
                for place in TEIRenderer.marginalAreas {
                  let notes = lines.filter { Self.marginalPlace(of: $0) == place }
                  if !notes.isEmpty {
                    div {
                      reader.rendered(
                        notes, heading: nil, direction: direction, facsimileURL: page.facsimileURL, label: page.label,
                        tabStop: tabStop)
                    }
                    .class("tei-margin")
                    .data("place", place)
                  }
                }
              } else {
                reader.rendered(
                  page.lines, heading: labelsPages ? page.label : nil, direction: direction,
                  facsimileURL: page.facsimileURL, label: page.label, tabStop: tabStop)
              }
            }
            .class("tei-page-text")
            .data("layer", "rendering")
            .data("type-area", typeArea != nil)
            // Its own ink, where it is no theme color (`TEIPage.ink`).
            .data("ink", page.ink ?? "")
            .addingAttribute(
              "style",
              Self.pageTextStyle(
                typeArea: typeArea, renditions: page.renditions,
                bodyLeading: TEIRendition.bodyLeading(in: page.renditions, markup: page.markup),
                outdent: Self.outdent(of: page.lines)))

            // The page's code (user, 2026-10-14), never the document's
            // header: that is its viewer's Header pane's alone (user,
            // 2026-10-21), never in a page's XML.
            // Edited or read, the same text (`shownCode`): the page as it is
            // stored, formatted.
            let code = TEIFacsimile.headed(
              TEIRendition.headedPage(Self.shownCode(page.markup), renditions: ""), surface: surfaces[index])
            div {
              if editable {
                // A form of its own, so the page can be sent to be read back
                // as it is being edited—its image and its code.
                form {
                  input()
                    .type(.hidden)
                    .name("frame")
                    .value(Self.serviceID(ofFacsimile: page.facsimileURL))
                  CodeEditorView(
                    id: "tei-page-raw-\(index + firstIndex)",
                    name: "markup",
                    // Its surface too, edited as any of its code (user,
                    // 2026-10-16); never its header.
                    value: code,
                    ariaLabel: page.label.isEmpty ? "Code of this page" : "Code of \(page.label)",
                    lined: true
                  )
                }
                .class("tei-page-edit")
              } else if editsCode {
                CodeEditorView(
                  id: "tei-page-code-\(index + firstIndex)", name: "", value: code,
                  ariaLabel: page.label.isEmpty ? "Code of this page" : "Code of \(page.label)", lined: true)
              } else {
                // The page's code formatted, one element a line (`shownCode`),
                // its surface as its <facsimile> as its diff shows it (user,
                // 2026-10-16), numbered and soft-wrapped (user, 2026-10-11).
                CodeView(code, showLineNumbers: false, lined: true)
              }
            }
            .class("tei-page-raw")
            .data("layer", "markup")

            // The translation, set by the very reader that sets the
            // markup above: the same lines, the same classes.
            if let translation {
              let translated = translation.pages[Self.serviceID(ofFacsimile: page.facsimileURL)]
              div {
                // A page not translated is empty, never a dash: a dash in a
                // text would read as the page's (user, 2026-10-07).
                div {
                  if let translated {
                    // In the translation's own direction, the layer's; its
                    // noted blocks opening their notes.
                    noting(translated.notes).measuring(translated.page.typeArea).rendered(
                      translated.page.lines, heading: nil, direction: nil,
                      facsimileURL: translated.page.facsimileURL, label: translated.page.label)
                  }
                }
                .class("tei-page-text")
                  }
              .class("tei-page-translation")
              .data("layer", "translated-rendering")
              // Its text has changed since it was translated: the reader's
              // pane is ringed orange while it is shown (`TestamentView`).
              .data("stale", translated?.stale ?? false)
              .lang(translation.language)
              .dir("auto")
              // The translation's own code, under Raw while its language
              // switch is on (user, 2026-10-07): two switches, four layers.
              if let translated {
                div {
                  CodeView(translated.page.markup, showLineNumbers: false, lined: true)
                }
                .class("tei-page-raw")
                .data("layer", "translated-markup")
              }
            }
          }
          .class("tei-page")
          .id("tei-page-\(index + firstIndex)")
          // What pairs this markup with a canvas. The viewer matches on it.
          .data("service-id", Self.serviceID(ofFacsimile: page.facsimileURL))
          // The page's own label, its `pb`'s `n`: the viewer's footer names
          // the page by it before the manifest's label.
          .data("label", page.label)
          // Whether its markup holds anything of its own
          // (`TEIRenderer.hasMarkup`): a page laid in blank renders nothing,
          // and the reader's structure overlay is off and disabled on it
          // (user, 2026-10-17).
          .data("has-markup", TEIRenderer.hasMarkup(page.markup))
          // The zones its markup names, for the reader to draw on its
          // canvas as the caret or the pointer comes to them in Raw.
          .data("zones", Self.zoneData(of: page))
          // Its text block's corners on its scan, for the reader's overlay
          // to lay the scan under the text by.
          .data("text-block", Self.textBlockData(of: page))
          // Whether that text block is derived (a page with no main text:
          // the work's type area placed on its scan), which the overlay lays on
          // the rendered type area itself, whole.
          .data("text-block-derived", page.textBlock?.derived == true)
          pageNode
            // The scan's measured layout (blocks, lines, words) and the body's
            // leading: the structure overlay and the word correspondence; each
            // word's zones, which the correspondence reads; each copy-evidence
            // element's zone, which opens its gloss on the scan.
            .data("scan-layout", Self.scanLayoutData(of: page))
            .data("word-zones", Self.wordZonesData(of: page))
            .data("element-zones", Self.elementZonesData(of: page))
            .data("body-leading", Self.bodyLeadingData(of: page))
            // The em the page is set in, on its scan: the overlay's type scale.
            .data("scan-em", Self.scanEmData(of: page))
            // Its place in the document, from 0: what the reader turns to and
            // a roster names it by, where not every page is drawn.
            .data("page-index", index + firstIndex)
            .data("active", index == (self.page ?? 0) ? "true" : "false")
        }
      }
      .class("tei-view")
      .data("editable", editable)
      .data("gloss", glossURL ?? "")
      .style {
        // No inset on any TEI pane (user, 2026-11-05: "yes, everywhere"):
        // not the view's, not its layers' (the rendered page, the
        // translation), in a reader's markup pane, a quote's box or a bare
        // view (TestamentView's plain box) alike. The white around the text
        // is its page's own, its type area's margins; a page with none runs
        // to its pane's edge, as the scan does. A ring drawn on a reader's
        // pane stands outside it (ArtifactView). The code fills the view edge
        // to edge, square. Only the note of a document with no pages keeps
        // an inset: it is a message, not a page.
        selector("&") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
          CSS.Property("font-variant-ligatures", "none")
        }
        descendant(".tei-page") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
        }
        descendant(".tei-empty") {
          padding(spacing16)
        }
        selector("& .tei-page-raw .code-view", "& .tei-page-raw .code-editor-view") {
          borderRadius(0)
        }
        // A figure is set apart from the markup around it: it is a
        // photograph of part of the surface, not a sentence on it.
        descendant(".tei-figure") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          alignItems(.flexStart)
          margin(0)
          marginBlock(spacing8)
          minWidth(0)
        }
        descendant(".tei-figure-image") {
          maxWidth(perc(100))
          // However the region is shaped, it is an illustration inside a
          // markup and cannot be taller than what it illustrates.
          maxHeight(px(320))
          width(.auto)
          height(.auto)
          objectFit(.contain)
          borderRadius(borderRadiusBase)
          border(borderWidthBase, .solid, borderColorSubtle)
        }
        // A figure's drawing is its ink on the page, not a photograph of the
        // surface: its box is the zone's, no border. Its holder is no box of
        // its own (`contents`): its SVG is the figure's flex item as the
        // crop is, within the same bounds (a block holder in the column's
        // shrink-to-fit would give it no width), and its print's layer takes
        // the text's ink (`currentColor`, which its `<use>` passes on).
        descendant(".tei-figure-drawing") {
          display(.contents)
        }
        selector("& .tei-figure-drawing > svg") {
          display(.block)
          maxWidth(perc(100))
          maxHeight(px(320))
          width(perc(100))
          height(.auto)
          border(.none)
          borderRadius(0)
          // The print's layer (`currentColor`) is the page's ink as the text
          // is (the theme's text color, `colorBase`, as the box and the
          // rule set it: the page's own pair maps to the theme, save an ink
          // of its own, `TEIPage.ink`), set here
          // and not inherited, so the glossable figure's hover and focus
          // (the words' blue) never recolor the drawing; a box in another
          // ink colors it as it colors its lines (`inkSelectors`).
          color(colorBase)
        }
        // A figure the page places (`data-placed`: its size and its place as
        // the scan has them) is the print's, not an illustration inside a
        // markup: its box is its setting's, its image or drawing fills it,
        // no white around it and no border.
        selector("& .tei-figure[data-placed='true']") {
          marginBlock(0)
          gap(0)
        }
        selector(
          "& .tei-figure[data-placed='true'] .tei-figure-image",
          "& .tei-figure[data-placed='true'] .tei-figure-drawing > svg"
        ) {
          width(perc(100))
          height(perc(100))
          maxWidth(perc(100))
          maxHeight(perc(100))
          objectFit("fill")
          border(.none)
          borderRadius(0)
        }
        // A decorated initial is one letter of the text; shown at the width
        // of a plate it stops being an initial and becomes a poster.
        descendant(".tei-initial-image") {
          maxWidth(px(96))
          maxHeight(px(96))
          verticalAlign(.bottom)
        }
        descendant(".tei-initial") {
          position(.relative)
          display(.inlineBlock)
        }
        // The letter the decoration stands for: over the crop, the size of
        // it, transparent; still the word's text.
        descendant(".tei-initial-letter") {
          position(.absolute)
          inset(0)
          display(.flex)
          alignItems(.center)
          justifyContent(.center)
          color(.transparent)
        }
        // A dropped initial (user, 2026-11-01): as wide as its letter, no
        // taller than nothing, so its line keeps its leading; set at the top
        // of its line, where its own strut puts its baseline on the line's,
        // and lowered from there by the lines it drops through, so its
        // baseline is the last line's beside it. Its size makes its cap (the
        // serif face's cap height, `dropCapHeight`) reach from the drop's
        // lines down to its line's cap height. A line beside it holds its
        // room (`tei-drop-hang`): the letter again at that size, invisible
        // and never text.
        selector("& .tei-drop-initial", "& .tei-drop-hang") {
          display(.inlineBlock)
          CSS.Property("block-size", "0")
          verticalAlign(.top)
        }
        descendant(".tei-drop-shift") {
          CSS.Property("vertical-align", "calc((1 - var(--tei-drop-lines)) * 1lh)")
        }
        selector("& .tei-drop-letter", "& .tei-drop-hang::before") {
          CSS.Property("font-size", "calc((var(--tei-drop-lines) - 1) * 1lh / \(Self.dropCapHeight) + 1em)")
          CSS.Property("line-height", "0")
        }
        descendant(".tei-drop-hang::before") {
          CSS.Property("content", "attr(data-letter)")
          visibility(.hidden)
        }
        // `<hi rend="…">` on the run it applies to. Small caps mark an author
        // statement; italic marks a speaker prefix or an emphasis the
        // compositor set—both are on the page, so both are in the markup.
        selector("& .tei-run[data-rend~='smallcaps']", "& .tei-run[data-rend~='small-caps']") {
          // No typed helper for this one; the builder takes a raw property.
          CSS.Property("font-variant-caps", "small-caps")
        }
        // Ligatures only where the print has them (user, 2026-10-31): the
        // face's automatic ligatures are off in every TEI view, modern text
        // too (`selector("&")` above); a ligature the TEI marks (`<g ref>`,
        // TEIRenderer's `ligature`) is drawn as one sort where the face has
        // it: Unicode's presentation form where Unicode has one
        // (`drawnText`), else its letters with the face's ligatures on.
        selector("& .tei-run[data-rend~='ligature']") {
          CSS.Property("font-variant-ligatures", "common-ligatures discretionary-ligatures")
        }
        // Typeface classes (user, 2026-10-11), in Noto where Noto has the
        // face: roman the serif, italic the serif's italic, sans-serif the
        // sans, typewriter the mono. Noto has no Latin blackletter or
        // script: those stay in the serif.
        selector(
          "& .tei-run[data-rend~='italic']", "& .tei-run[data-rend~='ital']",
          "& .tei-block[data-rend~='italic'] > .tei-line",
          "& .tei-block[data-rend~='italic'] > .tei-row > .tei-line", "& .tei-section > .tei-line[data-rend~='italic']",
          "& .tei-box[data-rend~='italic'] .tei-line"
        ) {
          fontFamily(typographyFontSerifItalic)
          fontStyle(.italic)
        }
        selector(
          "& .tei-run[data-rend~='roman']", "& .tei-block[data-rend~='roman'] > .tei-line",
          "& .tei-block[data-rend~='roman'] > .tei-row > .tei-line",
          "& .tei-section > .tei-line[data-rend~='roman']", "& .tei-box[data-rend~='roman'] .tei-line"
        ) {
          fontFamily(typographyFontSerif)
          fontStyle(.normal)
        }
        selector(
          "& .tei-run[data-rend~='sans-serif']", "& .tei-block[data-rend~='sans-serif'] > .tei-line",
          "& .tei-block[data-rend~='sans-serif'] > .tei-row > .tei-line",
          "& .tei-section > .tei-line[data-rend~='sans-serif']", "& .tei-box[data-rend~='sans-serif'] .tei-line"
        ) {
          fontFamily(typographyFontSans)
        }
        selector(
          "& .tei-run[data-rend~='typewriter']", "& .tei-block[data-rend~='typewriter'] > .tei-line",
          "& .tei-block[data-rend~='typewriter'] > .tei-row > .tei-line",
          "& .tei-section > .tei-line[data-rend~='typewriter']", "& .tei-box[data-rend~='typewriter'] .tei-line"
        ) {
          fontFamily(typographyFontMono)
        }
        // The source's own bold, transcribed: content, not the site's
        // chrome, so it stays bold (the semibold rule is for our UI).
        selector("& .tei-run[data-rend~='bold']") {
          fontWeight(fontWeightBold)
        }
        selector("& .tei-run[data-rend~='underline']", "& .tei-run[data-rend~='underlined']") {
          textDecoration(.underline)
        }
        selector("& .tei-run[data-rend~='sub']", "& .tei-run[data-rend~='subscript']") {
          verticalAlign(.sub)
          fontSize(em(0.75))
          lineHeight(0)
        }
        selector(
          "& .tei-run[data-rend~='sup']", "& .tei-run[data-rend~='super']",
          "& .tei-run[data-rend~='superscript']"
        ) {
          verticalAlign(.super)
          fontSize(em(0.75))
          lineHeight(0)
        }
        // A table is a block of the page as a paragraph is: the space
        // around it is the TEI's.
        descendant(".tei-table-scroll") {
          maxWidth(perc(100))
          minWidth(0)
          overflowX(.auto)
        }
        descendant(".tei-table") {
          borderCollapse(.collapse)
          fontFamily(typographyFontSerif)
          fontSize(fontSizeMedium16)
          color(colorBase)
        }
        selector("& .tei-table td", "& .tei-table th") {
          border(borderWidthBase, .solid, borderColorSubtle)
          padding(spacing8)
          verticalAlign(.middle)
          textAlign(.start)
        }
        selector("& .tei-table td > .tei-line", "& .tei-table th > .tei-line") {
          display(.block)
          whiteSpace(.nowrap)
        }
        // A printed contents table has alignment columns, not UI grid edges.
        selector("& .tei-table[data-table-type='contents']") {
          width(perc(100))
        }
        selector("& .tei-table[data-table-type='contents'] td", "& .tei-table[data-table-type='contents'] th") {
          border(.none)
          padding(spacing2, spacing0)
          fontWeight(.inherit)
          // A label, a numeral and a title stand on one first line.
          verticalAlign(.baseline)
        }
        // A column that labels or numbers its entries ("APPENDIX:", "IV.")
        // is as wide as its content; the titles' leaders take the rest.
        selector(
          "& .tei-table[data-table-type='contents'] td:not(:last-child):not(:has(> .tei-line-leadered))",
          "& .tei-table[data-table-type='contents'] th:not(:last-child):not(:has(> .tei-line-leadered))"
        ) {
          width(0)
        }

        // A label row (PAGE over the page references) is set solid over the
        // row it heads, as printed: no cell padding between them, and that
        // row's half-leading above its first line trimmed (`text-box-trim`),
        // so the label stands its own line's height above the first entry.
        selector("& .tei-table[data-table-type='contents'] tr:not(:has(> td)) > th") {
          paddingBlockEnd(spacing0)
        }
        selector("& .tei-table[data-table-type='contents'] tr:not(:has(> td)) + tr > *") {
          paddingBlockStart(spacing0)
        }
        selector(
          "& .tei-table[data-table-type='contents'] tr:not(:has(> td)) + tr > *",
          "& .tei-table[data-table-type='contents'] tr:not(:has(> td)) + tr > * > .tei-line-leadered > *"
        ) {
          CSS.Property("text-box", "trim-start text")
        }
        selector("& .tei-table[data-table-type='contents'] td:last-child", "& .tei-table[data-table-type='contents'] th:last-child") {
          textAlign(.end)
          whiteSpace(.nowrap)
          // A page reference stands on its title's last line, as printed.
          verticalAlign(.bottom)
        }
        selector("& .tei-table[data-table-type='contents'] td > .tei-line", "& .tei-table[data-table-type='contents'] th > .tei-line") {
          whiteSpace(.inherit)
        }
        // A contents title's printed leader (`leadered`): the title, then
        // its dots set from the cell's far edge, so every row's stand in the
        // same columns.
        selector("& .tei-table td > .tei-line.tei-line-leadered", "& .tei-table th > .tei-line.tei-line-leadered") {
          display(.flex)
          alignItems(.baseline)
        }
        descendant(".tei-leader-title") {
          flexShrink(0)
        }
        descendant(".tei-leader") {
          CSS.Property("flex", "1 0 auto")
          textAlign(.end)
          whiteSpace(.nowrap)
        }
        // A printed rule, 1px in the text's ink; its measure, its margins
        // and its alignment its rend's.
        descendant(".tei-rule") {
          flexShrink(0)
          alignSelf(.stretch)
          height(0)
          margin(0)
          border(.none)
          borderTopWidth(borderWidthBase)
          CSS.Property("border-top-style", "solid")
          borderTopColor("currentcolor")
          color(colorBase)
          fontSize(fontSizeMedium16)
        }
        selector("& .tei-rule[data-rend~='align(center)']") {
          CSS.Property("margin-inline", "auto")
        }
        selector("& .tei-rule[data-rend~='align(right)']") {
          marginInlineStart(.auto)
        }
        descendant(".tei-document-boundary") {
          width(perc(100))
          border(.none)
          borderTop(borderWidthBase, .solid, borderColorSubtle)
          marginBlock(spacing8)
        }
        // How each block is set on the image, TEI's rendition style on its
        // rend: alignment and indent, on the block (or on a line standing
        // alone), in logical terms, so that a right-aligned catchword sits
        // at the right however the text runs.
        selector(
          "& .tei-block[data-rend~='align(center)']", "& .tei-section > .tei-line[data-rend~='align(center)']"
        ) {
          textAlign(.center)
        }
        selector(
          "& .tei-block[data-rend~='align(justify)']", "& .tei-section > .tei-line[data-rend~='align(justify)']"
        ) {
          textAlign(.justify)
        }
        selector(
          "& .tei-block[data-rend~='align(left)']", "& .tei-section > .tei-line[data-rend~='align(left)']",
          "& .tei-table :is(td, th) > .tei-line[data-rend~='align(left)']",
          "& .tei-block[data-rend~='align(right)']:dir(rtl)",
          "& .tei-section > .tei-line[data-rend~='align(right)']:dir(rtl)",
          "& .tei-table :is(td, th) > .tei-line[data-rend~='align(right)']:dir(rtl)"
        ) {
          textAlign(.start)
        }
        selector(
          "& .tei-block[data-rend~='align(right)']", "& .tei-section > .tei-line[data-rend~='align(right)']",
          "& .tei-table :is(td, th) > .tei-line[data-rend~='align(right)']",
          "& .tei-block[data-rend~='align(left)']:dir(rtl)",
          "& .tei-section > .tei-line[data-rend~='align(left)']:dir(rtl)",
          "& .tei-table :is(td, th) > .tei-line[data-rend~='align(left)']:dir(rtl)"
        ) {
          textAlign(.end)
        }
        for level in 1...6 {
          selector(
            "& .tei-block[data-rend~='indent(\(level))']",
            "& .tei-section > .tei-line[data-rend~='indent(\(level))']",
            "& .tei-table .tei-line[data-rend~='indent(\(level))']"
          ) {
            CSS.Property("padding-inline-start", "calc(\(level) * \(spacing24.value))")
          }
        }
        // The text is reflowed at every width (user, 2026-10-07, held to
        // on 2026-10-10): a block's lines run on as one paragraph, still
        // set as its block is (align, indent, hanging on the flowing
        // block), so a printed line never wraps into a line and a half on
        // a narrow pane. Its line breaks stay in the TEI, shown in Raw; a
        // verse line, a heading, an item opens a block of its own and
        // keeps its line.
        descendant(".tei-block") {
          display(.block)
          minWidth(0)
        }
        selector("[data-reflow='true'] & .tei-block", "[data-reflow='true'] & .tei-section") {
          maxWidth(perc(100))
          boxSizing(.borderBox)
        }
        // Reflowed, every line it wraps is a whole line of its type (user,
        // 2026-11-03: Hamlet Q1's front cover wrapped "HAMLE" over its "T"
        // 0.714 em below, its box's height): lines set closer than their
        // type set solid, and a box the print gives a height as tall as its
        // lines (`reflowStyle`). Only what it wraps moves anything (user,
        // 2026-11-05: "why reflow changes vertical gaps?"): a box set solid
        // gives back the leading it gains, half above it and half below, so
        // its first line stands where its print sets it and the next box
        // as far below as printed; a box the print gives a height keeps at
        // least that height. A page whose lines do not wrap reads the same
        // reflowed or not, down to the pixel; one whose lines wrap keeps its
        // gaps between boxes.
        selector("[data-reflow='true'] & [style*='--tei-reflow-leading']") {
          CSS.Property("line-height", "var(--tei-reflow-leading)").important()
          CSS.Property("margin-block-start", "var(--tei-reflow-margin-start)").important()
          CSS.Property("margin-block-end", "var(--tei-reflow-margin-end)").important()
        }
        selector(
          "[data-reflow='true'] & .tei-block[style*='block-size']",
          "[data-reflow='true'] & .tei-line[style*='block-size']:not(.tei-figure)",
          "[data-reflow='true'] & .tei-box[style*='block-size']"
        ) {
          CSS.Property("block-size", "auto").important()
          CSS.Property("min-block-size", "var(--tei-reflow-min-block, 0px)")
        }
        // A line placed by its zone, about its box's middle as far as its
        // type area lets it (`reflowStyle`), never held to the pane's width: its
        // type area is its leaf, laid as the print lays it.
        selector("[data-reflow='true'] & [style*='--tei-reflow-size']") {
          CSS.Property("margin-inline-start", "var(--tei-reflow-start)").important()
          CSS.Property("inline-size", "var(--tei-reflow-size)").important()
          maxWidth(.none)
        }
        // Reflowed, a page's type area stands in the middle of its pane, its
        // measure wide where the pane is wider, else the pane's (user,
        // 2026-11-03: Hamlet Q1's title page, its lines placed across its
        // type area from its start, stood at the pane's left), with room on
        // either side for a line the print sets out before it (`outdent`),
        // so no line runs out of sight and a centered line stays on the
        // pane's middle; its lines wrap in it, never past the pane.
        // Its room either side in its page's own width and its em (the
        // root's, `rem`): on the type area's own box (`.tei-text-block`, a
        // margin's), the page's width is its containing block's, `100%`,
        // which every browser resolves inside the zoomed page as the page's
        // own width, whatever stands around it (user, 2026-11-05: Hamlet
        // Q1's front cover stood left of its pane's middle in the in-app
        // browser, which read `100cqi` inside the zoomed page as the page's
        // width on screen and zoomed it again; then right of it in Chrome,
        // by half the scrollbar the pane took after the reader measured the
        // page). A line the print sets alone (`data-printed-lines`, a title
        // page's) runs on past the type area's end into that room, as far
        // as the pane lets it, a centered one either way, so a face that
        // sets it a hair wider than the print never wraps it in a wide
        // pane; a paragraph wraps at the type area's measure, as its print
        // does. The room it runs into (`--tei-reflow-room`) is the same
        // quantity read from a line's own box, where `100%` is its block's:
        // from the reader's measure of the page at its zoom
        // (`--tei-reflow-width`, ArtifactView: the page's width on screen
        // over its zoom, taken once the pane's scrollbars have settled), the
        // query container's `100cqi` only where no reader sets it. A
        // centered line runs into it as far either way, so it stays on the
        // type area's middle whatever that room reads.
        // Above and below it, its leaf's own head and foot, and its type area
        // at least its height (user, 2026-11-03: the title page's "THE"
        // stood at the pane's top, its "1603." at its foot, where its page
        // sets them inside its leaf's margins), in its em, zoomed with it;
        // no inset of a pane's around it (user, 2026-11-05).
        selector("[data-reflow='true'] & .tei-page-text[data-type-area='true']") {
          CSS.Property("container-type", "inline-size")
          CSS.Property(
            "--tei-reflow-room",
            "max(var(--tei-reflow-outdent, 0rem), (var(--tei-reflow-width, 100cqi) - var(--tei-type-area-measure) * 1rem) / 2)")
          CSS.Property("padding-block", "calc(var(--tei-type-area-head) * 1rem) calc(var(--tei-type-area-foot) * 1rem)")
        }
        selector("[data-reflow='true'] & .tei-page-text[data-type-area='true'] > .tei-text-block") {
          CSS.Property("min-block-size", "calc(var(--tei-type-area-height) * 1rem)")
        }
        selector(
          "[data-reflow='true'] & .tei-page-text[data-type-area='true'] > .tei-text-block",
          "[data-reflow='true'] & .tei-page-text[data-type-area='true'] > .tei-margin"
        ) {
          width(perc(100))
          boxSizing(.borderBox)
          CSS.Property(
            "padding-inline", "max(var(--tei-reflow-outdent, 0rem), (100% - var(--tei-type-area-measure) * 1rem) / 2)")
        }
        selector(
          "[data-reflow='true'] & .tei-page-text[data-type-area='true'] > * > .tei-section > .tei-block[data-printed-lines='1']:not([style*='--tei-reflow-size'])"
        ) {
          CSS.Property("margin-inline-end", "calc(-1 * var(--tei-reflow-room))").important()
          maxWidth(.none)
        }
        selector(
          "[data-reflow='true'] & .tei-page-text[data-type-area='true'] > * > .tei-section > .tei-block[data-printed-lines='1']:not([style*='--tei-reflow-size'])[style*='text-align:center']",
          "[data-reflow='true'] & .tei-page-text[data-type-area='true'] > * > .tei-section > .tei-block[data-printed-lines='1']:not([style*='--tei-reflow-size'])[data-rend~='align(center)']"
        ) {
          CSS.Property("margin-inline-start", "calc(-1 * var(--tei-reflow-room))").important()
        }
        selector("[data-reflow='true'] & .tei-page-text:not([data-type-area='true'])") {
          CSS.Property("padding-inline-start", "var(--tei-reflow-outdent, 0rem)")
        }
        // A tracked line's inset in its place (`reflowStyle`): its end on
        // its box's, its centered ink on its box's middle.
        selector("[data-reflow='true'] & [style*='--tei-reflow-tracking']") {
          CSS.Property("margin-inline-end", "0").important()
        }
        selector(
          "[data-reflow='true'] & [style*='--tei-reflow-tracking'][style*='text-align:center']",
          "[data-reflow='true'] & [style*='--tei-reflow-tracking'][data-rend~='align(center)']"
        ) {
          CSS.Property("padding-inline-start", "var(--tei-reflow-tracking)")
        }
        selector("& .tei-block > *") {
          display(.inline)
        }
        // A page's lines as the scan breaks them (user, 2026-10-12): each
        // `<lb/>` a line and no line wrapped, the page scrolling sideways
        // under them, its bar shown and no edge faded (a fade is for one
        // truncated line, never a scrollport); a hanging indent hangs the
        // block's first line alone. Under a reader's Reflow
        // (`[data-reflow='true']`, ArtifactView) its lines run on instead.
        selector("& .tei-page-text:not([data-reflow='true'] *)") {
          whiteSpace(.nowrap)
          overflowX(.auto)
        }
        // A page set in its work's type area (`TEIPage.typeArea`, user,
        // 2026-10-14): 1em the work's body type, the renderer's 16px; the
        // type area its body pages' main text block, its measure and height in
        // that em, holding the main text, which never squeezes: a line wider
        // than its measure runs past it (it never wraps), and a page taller
        // than its height grows it, a page that does regularized in its TEI
        // to fit. Across, it never grows (user, 2026-10-30): the measure is
        // what the compositor set against, so a centered line stands on
        // its middle and a right-set one on its end, never on a type area
        // widened by a line the unfitted face sets wider than the print's
        // (Hamlet Q1 p. 13's "Enter Corambis.", an em right of the print's);
        // the marginalia outside it, a side note beside it, a top or bottom
        // note above or below it, each placed from it by its own measured
        // margins; around the type area and its marginalia, the content box,
        // the leaf's own margins, empty. A page with side notes
        // is wider, never its text narrower. A page genuinely larger than
        // its work's (a plate, a foldout) is its scan's own size at the same
        // scale, its content centered in it. Reflowed, the text runs on in
        // the pane. Its margins are the leaf's (user, 2026-10-26, 2026-10-28):
        // the white its typesetter left between the leaf's edges and the main
        // text block, its head and foot, its inner margin at the fold and its
        // outer at the fore-edge, a verso's mirrored (`--tei-type-area-head`,
        // `--tei-type-area-foot`, `--tei-type-area-left`, `--tei-type-area-right`,
        // gnorium-python `type_scale.type_area`, from the leaf the measuring found,
        // never the photograph's table, target or facing leaf beyond it);
        // only the structure overlay lays the page on the scan's geometry.
        selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *)") {
          display(.grid)
          CSS.Property(
            "grid-template-areas",
            "\"top-left top top-right\" \"margin-left type-area margin-right\" \"bottom-left bottom bottom-right\"")
          CSS.Property("grid-template-columns", "auto max-content auto")
          CSS.Property("grid-template-rows", "auto auto auto")
          CSS.Property("justify-content", "center")
          CSS.Property("align-content", "center")
          boxSizing(.borderBox)
          // Physical sides: a leaf's fold is on its left or its right
          // whatever its text's direction.
          CSS.Property(
            "padding",
            "calc(var(--tei-type-area-head) * 1em) calc(var(--tei-type-area-right) * 1em) calc(var(--tei-type-area-foot) * 1em) calc(var(--tei-type-area-left) * 1em)"
          )
          fontSize(fontSizeMedium16)
          CSS.Property("inline-size", "max-content")
          CSS.Property("min-inline-size", "calc(var(--tei-page-width) * 1em)")
          CSS.Property("min-block-size", "calc(var(--tei-page-height) * 1em)")
        }
        selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *) > .tei-text-block") {
          CSS.Property("grid-area", "type-area")
          display(.flex)
          flexDirection(.column)
          boxSizing(.contentBox)
          CSS.Property("inline-size", "calc(var(--tei-type-area-measure) * 1em)")
          CSS.Property("min-block-size", "calc(var(--tei-type-area-height) * 1em)")
        }
        selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *) > .tei-margin") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        // Each area against the type area: a side note from the type area's top,
        // against its side; a top note ending where the type area begins, a
        // bottom note beginning where it ends, across the type area's measure
        // (from its left, or centered over it as its rend sets it: an
        // owner's mark regularized to the head's middle, user, 2026-10-14);
        // a corner note against both.
        for (area, align, justify) in [
          ("top-left", "end", "end"), ("top", "end", "stretch"), ("top-right", "end", "start"),
          ("margin-left", "start", "end"), ("margin-right", "start", "start"),
          ("bottom-left", "start", "end"), ("bottom", "start", "stretch"), ("bottom-right", "start", "start"),
        ] {
          selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *) > .tei-margin[data-place='\(area)']") {
            CSS.Property("grid-area", area)
            CSS.Property("align-self", align)
            CSS.Property("justify-self", justify)
          }
        }
        // A page with no type area: its lines set on the canonical render's
        // page, never a narrower pane's, so a pane too narrow scrolls the
        // page whole rather than running its long lines into the margin on
        // one side only.
        selector("& .tei-page-text:not([data-type-area='true']):not([data-reflow='true'] *) > *") {
          CSS.Property("min-inline-size", "calc(\(size640.value) - 2 * \(spacing16.value))")
        }
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block > *") {
          display(.block)
          CSS.Property("text-indent", "0")
        }
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block > :first-child") {
          CSS.Property("text-indent", "inherit")
        }
        // A block run on from the column or page before (`<p part="F|M">`,
        // or a `<cb/>` inside it): its first line here is no paragraph's
        // first, and takes no indent.
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block:is([data-part='F'], [data-part='M']) > :first-child") {
          CSS.Property("text-indent", "0")
        }
        // Only explicitly justified text expands its word spacing, and a
        // block's last line keeps its natural width, as printed: its lines
        // carry its rend, so the rule is the block's, never a line's. A
        // paragraph that runs on to the next page (`<p part="I|M">`) sets
        // its last line here full, as the lines before it.
        selector(
          "& .tei-page-text:not([data-reflow='true'] *) .tei-block[data-rend~='align(justify)'] > .tei-line:not(:last-child)",
          "& .tei-page-text:not([data-reflow='true'] *) .tei-block[data-rend~='align(justify)']:is([data-part='I'], [data-part='M']) > .tei-line"
        ) {
          textAlign(.justify)
          CSS.Property("text-align-last", "justify")
        }
        selector(
          "& .tei-page-text:not([data-reflow='true'] *)::-webkit-scrollbar-track",
          "& .tei-page-text:not([data-reflow='true'] *)::-webkit-scrollbar-track-piece",
          "& .tei-page-text:not([data-reflow='true'] *)::-webkit-scrollbar-corner"
        ) {
          backgroundColor(.transparent).important()
        }
        // A hanging indent: the paragraph's first line at its edge, the rest in.
        selector("& .tei-block[data-rend~='hanging']") {
          paddingInlineStart(spacing24)
          CSS.Property("text-indent", "calc(-1 * \(spacing24.value))")
        }
        // The furniture on one line, each piece in its place on it: all in
        // the row's one cell, each placed across the whole row.
        descendant(".tei-forme-row") {
          display(.grid)
          gridTemplateColumns("minmax(0, 1fr)")
          alignItems(.baseline)
        }
        selector("& .tei-forme-row > *") { CSS.Property("grid-area", "1 / 1") }
        descendant(".tei-forme-row-start") { justifySelf("start") }
        descendant(".tei-forme-row-center") { justifySelf("center") }
        descendant(".tei-forme-row-end") { justifySelf("end") }
        // Lines set on one row in a block (a turnover beside its line), each
        // from the row's start, the others at their own places across.
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block > .tei-row") {
          display(.grid)
          gridTemplateColumns("minmax(0, 1fr)")
          alignItems(.baseline)
        }
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block > .tei-row > *") {
          CSS.Property("grid-area", "1 / 1")
          justifySelf("start")
        }
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-block > .tei-row > :not(:first-child)") {
          CSS.Property("text-indent", "0")
        }
        // Paragraphs set close, as printed: the space between them is the
        // TEI's own (its margins, its vertical `<space/>`), never one the
        // reader adds (user, 2026-10-13).
        descendant(".tei-page-text") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        // A page's columns, and a spread's pages: each set as a page is;
        // reflowed, one after the other a paragraph's space apart.
        selector("& .tei-spread", "& .tei-columns") {
          display(.flex)
          flexDirection(.column)
          gap(spacing16)
          minWidth(0)
          boxSizing(.borderBox)
        }
        selector("& .tei-spread-page", "& .tei-column") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        // Reflow off, side by side as the image has them, in its direction
        // (the spread's `dir`): one column a page, all as wide as the widest
        // page's lines, filling the pane where they are narrower.
        selector("& .tei-page-text:not([data-reflow='true'] *) .tei-spread", "& .tei-page-text:not([data-reflow='true'] *) .tei-columns") {
          display(.grid)
          CSS.Property("grid-auto-flow", "column")
          CSS.Property("grid-auto-columns", "1fr")
          gap(spacing32)
          width(.maxContent)
          minWidth(perc(100))
        }
        descendant(".tei-section") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        // An epigraph set as a whole (user, 2026-10-11): as wide as its
        // lines, placed as its rend says, its lines set within it.
        // A printed box (`border-style`, user, 2026-10-13) is a 1px rule
        // in its ink, its inset and measure its rend's; its ground only
        // where the page encodes one (`background-color`, user, 2026-10-25:
        // a shaded box, a tinted panel), drawn as encoded in every theme
        // (its style's), never the page's paper.
        descendant(".tei-box") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
          maxWidth(perc(100))
          boxSizing(.borderBox)
          borderWidth(borderWidthBase)
          borderColor("currentcolor")
          color(colorBase)
        }
        selector("& .tei-box[data-rend~='align(center)']") { alignSelf(.center) }
        selector("& .tei-box[data-rend~='align(right)']") { alignSelf(.flexEnd) }
        selector("& .tei-box[data-rend~='align(left)']") { alignSelf(.flexStart) }
        // Ink (user, 2026-10-11): a rend's color(NAME), one of the 13
        // ISCC–NBS basic color names (`TEIRenderer.inks`), on a run, a block
        // or a box, and a figure's layer by its class (`ink-NAME`). The
        // TEI is faithful to the print (user, 2026-10-25): the page's own
        // ink, on its <pb>, is mapped to the theme, and its ground is never
        // the edition's (user, 2026-10-30: every page sits on the theme's
        // background, a near-black board included—black and white follow
        // the theme as ground and as ink alike); every other ink is the
        // class the printer chose, drawn in the palette's color for it
        // (`inks`, user, 2026-10-29: never a scan's faded shade), which
        // follows the theme as the palette does, and no ground is drawn
        // behind it.
        // A page's own ink (`TEIPage.ink`, user, 2026-10-30): black and
        // white are the theme's, every other ink the page names on its <pb>
        // is drawn as encoded—its lines (a cover's gilt lettering, yellow),
        // its rules and its figures' drawings. Before the inks a run, a
        // block, a line or a box names, which the same weight lets win.
        for (name, ink) in Self.inks where name != "black" && name != "white" {
          selector(
            "& .tei-page-text[data-ink='\(name)'] .tei-line", "& .tei-page-text[data-ink='\(name)'] .tei-rule",
            "& .tei-page-text[data-ink='\(name)'] .tei-figure-drawing > svg"
          ) {
            color(ink)
          }
        }
        // A drawing's layer in an ink of its own (`ink-NAME`): its file is no
        // part of the page, which no selector reaches into; each ink's
        // property is inherited through its `<use>` (`TEIDrawing.inkProperty`).
        selector("& .tei-figure-drawing > svg") {
          for (name, ink) in Self.inks {
            CSS.Property(TEIDrawing.inkProperty("ink-\(name)"), ink.value)
          }
        }
        for (name, ink) in Self.inks {
          selector(Self.inkSelectors(name).joined(separator: ", ")) {
            color(ink)
          }
        }
        // Type a step larger or smaller than the text's, on a run, a block,
        // or a box's lines (user, 2026-10-11).
        selector(
          "& .tei-run[data-rend~='larger']", "& .tei-block[data-rend~='larger'] > .tei-line",
          "& .tei-block[data-rend~='larger'] > .tei-row > .tei-line",
          "& .tei-section > .tei-line[data-rend~='larger']", "& .tei-box[data-rend~='larger'] .tei-line"
        ) {
          fontSize(fontSizeLarge18)
        }
        selector(
          "& .tei-run[data-rend~='smaller']", "& .tei-block[data-rend~='smaller'] > .tei-line",
          "& .tei-block[data-rend~='smaller'] > .tei-row > .tei-line",
          "& .tei-section > .tei-line[data-rend~='smaller']", "& .tei-box[data-rend~='smaller'] .tei-line"
        ) {
          fontSize(fontSizeSmall14)
        }
        // A section's first line starts where the space before it ends: a
        // heading's or a speaker's space above it is space from the line
        // before, and at the top of the page there is none (user, 2026-09-29).
        selector("& .tei-section > :first-child:not([style*='margin-'])", "& .tei-section > :first-child:not([style*='margin-']) > .tei-line:first-child:not([style*='margin-'])") {
          marginBlockStart(0).important()
        }
        // Vertical space measured in the text's own lines.
        descendant(".tei-space") {
          flexShrink(0)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightContent)
        }
        // Editable only in Raw: the markup is for reading, and nothing in it
        // looks as if it could be typed into.
        selector("&[data-editable='true'] .tei-page-text") {
          cursor(.default)
        }
        descendant(".tei-page-edit") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
          margin(0)
        }
        // The rendered layer at the body's 16 on its content leading, as the
        // translation's prose and beside the code's 16: switching layers
        // never changes the size (user, 2026-10-08).
        descendant(".tei-line") {
          fontFamily(typographyFontSerif)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightContent)
          color(colorBase)
          overflowWrap(.breakWord)
        }
        // The markup looks as the printed page does (user, 2026-09-29):
        // only what the TEI encodes as typography (`<hi rend>`) is styled; a
        // tag (a heading, a speaker, a stage direction, a note, the forme
        // work) keeps its place on the page and no face or color of its own.
        selector("& .tei-block[style*='font-size'] > .tei-line", "& .tei-block[style*='font-size'] > .tei-row > .tei-line") {
          fontSize(.inherit)
        }
        selector(
          "& .tei-block[style*='line-height'] > .tei-line", "& .tei-block[style*='line-height'] > .tei-row > .tei-line"
        ) { CSS.Property("line-height", "inherit") }
        selector(
          "& .tei-block[style*='letter-spacing'] > .tei-line", "& .tei-block[style*='letter-spacing'] > .tei-row > .tei-line"
        ) { CSS.Property("letter-spacing", "inherit") }
        selector(
          "& .tei-block[style*='word-spacing'] > .tei-line", "& .tei-block[style*='word-spacing'] > .tei-row > .tei-line"
        ) { CSS.Property("word-spacing", "inherit") }
        // A heading's space is the TEI's, as a paragraph's is.
        descendant(".tei-line-heading") {
          fontSize(.inherit)
          fontWeight(.inherit)
          margin(0)
        }
        descendant(".tei-line-speaker") {
          marginBlockStart(spacing8)
        }
        // The work's own apparatus, set where the compositor set it: the head
        // over the text, the catchword at the foot by the outer edge, the
        // signature at the foot by the inner one. In the flow they read as
        // lines of the play, which is what they are not.
        descendant(".tei-line-forme-header") {
          textAlign(.center)
          marginBlockEnd(spacing8)
        }
        descendant(".tei-line-forme-pageNumber") {
          textAlign(.center)
        }
        descendant(".tei-line-forme-catchword") {
          textAlign(.end)
          marginBlockStart(spacing8)
        }
        descendant(".tei-line-forme-signature") {
          textAlign(.start)
          marginBlockStart(spacing8)
        }
        // Typeset in its type area, the work's furniture is set as the print
        // set it: a line of the body's type at the body's leading, its white
        // from the text its placement's (`#fw-<type>`, gnorium-python
        // `scale.placement_renditions`), never the reading layout's (user,
        // 2026-10-27: a running head's 26px line and 8px margin set Hamlet
        // Q1's every line under it 0.6em low, its catchword a line low).
        selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *) .tei-line-forme") {
          margin(0)
          CSS.Property("line-height", "calc(var(--tei-body-leading) * 1em)")
        }
        // Its row too: the pieces on it are no taller than a line of it.
        selector("& .tei-page-text[data-type-area='true']:not([data-reflow='true'] *) .tei-forme-row") {
          CSS.Property("line-height", "calc(var(--tei-body-leading) * 1em)")
        }
        // An original note, set apart from the text it annotates as the
        // work's apparatus is.

        // The makers' own deletions, struck through as on the page; what
        // the transcription supplies is set in its brackets.
        selector("& .tei-run[data-rend~='del']") {
          textDecoration(.lineThrough)
        }
        // Not a word on the page: a statement that there is none, drawn as
        // nothing.
        descendant(".tei-line-gap") {
          display(.none)
        }
        // A side of the leaf, inside an image that carries two of them.
        descendant(".tei-line-mark") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeMedium16)
          color(colorSubtle)
          marginBlockStart(spacing8)
        }
        // The markup takes the markup's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers.
        // The markup takes the markup's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers, and the
        // block itself is a CodeView like any other.
        descendant(".tei-page-raw") {
          display(.none)
          margin(0)
          minWidth(0)
        }
        // The translation takes the markup's place too, under the language
        // switch on the page's record rule.
        descendant(".tei-page-translation") {
          display(.none)
          flexDirection(.column)
          gap(spacing12)
          minWidth(0)
        }
        // A side of the leaf, inside an image that carries two of them.
        descendant(".tei-line-mark") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeMedium16)
          color(colorSubtle)
          marginBlockStart(spacing8)
        }
        // The markup takes the markup's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers.
        descendant(".tei-page-raw") {
          display(.none)
          padding(0)
          backgroundColor(backgroundColorBase)
          fontFamily(typographyFontMono)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(syntaxPlainText)
          whiteSpace(.preWrap)
          overflowWrap(.breakWord)
          margin(0)
        }
        // The source's own white space (`xml:space="preserve"`, a
        // `<space/>`'s width), drawn as written.
        descendant(".tei-run[data-space='preserve']") {
          whiteSpace(.preWrap)
        }
        // A horizontal `<space/>`: a gap as wide as its inline size, its
        // space (blank, never drawn past it) inside.
        descendant(".tei-run-space") {
          display(.inlineBlock)
        }
        descendant(".tei-page-raw") {
          fontFamily(typographyFontMono)
          backgroundColor(.transparent)
          padding(0)
        }
        // A quote on a subtle violet ground, and its lemma, the word
        // quoted, on a subtle magenta one that stands out from it (user,
        // 2026-10-31): grounds alone, no line; never blue, a pointed
        // word's, nor yellow, Find's (a <mark>'s own yellow is replaced).
        // Each word and each space between is a span of its own: where two
        // meet on a fraction of a pixel a hairline of the page shows
        // between their grounds (user, 2026-11-11), so each ground runs a
        // pixel under the next and takes no room for it.
        descendant(".tei-highlight") {
          backgroundColor(backgroundColorVioletSubtle)
          color(.inherit)
          paddingInlineEnd(borderWidthBase)
          marginInlineEnd(calc("-\(borderWidthBase.value)"))
        }
        descendant(".tei-highlight[data-highlight='title']") {
          backgroundColor(backgroundColorMagentaSubtle)
        }
        // A word that opens its details: the printed page's own type, the
        // accent color only under the pointer, on keyboard focus and while
        // its details are open (user, 2026-09-29). The focus ring every
        // control has, from the keyboard only (:focus-visible), never for a
        // click or a tap.
        // What is no word but encoded opens its gloss the same way, and a
        // translated block the translator noted, its note.
        // The question-mark cursor, as over every term that opens a gloss
        // or a preview (user, 2026-11-01).
        selector("& .tei-word[role='button']", "& [data-gloss-element]", "& .tei-noted") {
          cursor(cursorHelp)
          borderRadius(borderRadiusMinimal)
          outline(.none)
        }
        selector("& .tei-word:focus-visible", "& [data-gloss-element]:focus-visible", "& .tei-noted:focus-visible") {
          outline(borderWidthThick, .solid, borderColorBlueFocus)
          outlineOffset(borderWidthBase)
        }
        selector(
          "& .tei-word[role='button']:hover", "& .tei-word:focus-visible", "& .tei-word[aria-expanded='true']",
          "& [data-gloss-element]:hover", "& [data-gloss-element]:focus-visible",
          "& [data-gloss-element][aria-expanded='true']", "& .tei-noted:hover", "& .tei-noted:focus-visible",
          "& .tei-noted[aria-expanded='true']"
        ) {
          color(colorBlue)
        }
        // Where a form's Source box selects a sentence (user, 2026-11-01)
        // its words open no gloss: the hand over them, never the accent
        // color; the sentence under the pointer tinted as a quote is, its
        // lemma as a quote's lemma (`TEISentenceSelection`).
        selector(
          "[data-selects-sentences='true'] & .tei-word", "[data-selects-sentences='true'] & [data-gloss-element]",
          "[data-selects-sentences='true'] & .tei-noted"
        ) {
          cursor(cursorBaseHover)
        }
        selector(
          "[data-selects-sentences='true'] & .tei-word:hover",
          "[data-selects-sentences='true'] & .tei-word:focus-visible",
          "[data-selects-sentences='true'] & .tei-word[aria-expanded='true']",
          "[data-selects-sentences='true'] & [data-gloss-element]:hover",
          "[data-selects-sentences='true'] & .tei-noted:hover"
        ) {
          color(.inherit)
        }
        selector(pseudoElement("& *", .highlight(TEISentenceSelection.sentence))) {
          backgroundColor(backgroundColorVioletSubtle)
        }
        selector(pseudoElement("& *", .highlight(TEISentenceSelection.title))) {
          backgroundColor(backgroundColorMagentaSubtle)
        }
        selector(".tei-empty") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          color(colorSubtle)
          margin(0)
        }
      }
      .build()
    }
  }

  extension TEIView {
    /// The inks a rend may name (`TEIRenderer.inks`) and the color each is
    /// drawn in (user, 2026-10-29): the palette's color for its hue, light
    /// and dark as the palette is, never a centroid or a sampled shade. A
    /// gilt is yellow (gnorium-python `base_tei.INK_CLASSES`), a silver
    /// gray; brown and olive, which the palette has no hue for, the orange
    /// and the yellow nearest them; black the text's ink and white the
    /// white that stays white in every theme.
    static let inks: [(name: String, ink: CSS.Color)] = [
      ("pink", colorPink), ("red", colorRed), ("orange", colorOrange), ("brown", colorOrange),
      ("yellow", colorYellow), ("olive", colorYellow), ("yellow-green", colorLime), ("green", colorGreen),
      ("blue", colorBlue), ("purple", colorViolet), ("white", colorInvertedFixed), ("gray", colorGray),
      ("black", colorBase),
    ]

    /// The rules that draw a run, a block's lines, a box and a section's line in `name`'s ink.
    static func inkSelectors(_ name: String) -> [String] {
      [
        "& .tei-run[data-rend~='color(\(name))']", "& .tei-block[data-rend~='color(\(name))'] > .tei-line",
        "& .tei-block[data-rend~='color(\(name))'] > .tei-row > .tei-line",
        "& .tei-box[data-rend~='color(\(name))']",
        "& .tei-section > .tei-line[data-rend~='color(\(name))']",
        "& .tei-box[data-rend~='color(\(name))'] .tei-line",
        "& .tei-box[data-rend~='color(\(name))'] .tei-figure-drawing > svg",
      ]
    }
  }
#endif
