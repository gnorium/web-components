#if SERVER
  import CSSBuilder
  import DesignTokens
  import DiffEngine
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes
  import XMLUtilities

  /// A vouched TEI document, read beside the object it was transcribed from.
  ///
  /// The pipeline writes `<pb n="…" facs="…"/>` at every page turn, so the
  /// document carries its own facsimiles and each page can name the image
  /// service it reads. That name is what pairs a page with a canvas inside
  /// ``ArtifactView``: this view draws the readings, the viewer shows the one
  /// belonging to the canvas on screen, and paging moves both at once.
  ///
  /// Line breaks are kept because they are evidence — a diplomatic transcript
  /// says where the compositor broke the line — and the tags that survive the
  /// strip are the ones a reader of the text needs: headings, speakers, stage
  /// directions.
  public struct TEIView: HTMLContent {
    let teiXml: String
    /// Whether each page's source can be edited. The source is edited as it
    /// is, not as the Raw view prettifies it: prettifying drops the spaces
    /// between tags, and a correction must not quietly make others. The
    /// reading stays a reading — nothing in it can be typed into.
    let editable: Bool

    public init(teiXml: String, editable: Bool = false) {
      self.teiXml = teiXml
      self.editable = editable
    }

    public var pages: [TEIPage] { TEIRenderer.pages(in: teiXml) }

    /// The image service a rendition reads, which is what pairs it with a
    /// canvas. `TEIRenderer` owns the rule; the view only passes it on.
    public static func serviceID(ofFacsimile url: String) -> String {
      TEIRenderer.serviceID(ofFacsimile: url)
    }

    /// A page's reading as the lines a diff compares: each line's runs with
    /// their setting, a formula whole, a figure by its caption and region, a
    /// page turn inside the image as a line of its own. White space that only
    /// lays the source out — a line end and its indent — reads as the one
    /// space a reading shows; spaces the transcription set are kept.
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
      func spaced(_ text: String) -> String {
        var out = ""
        var pending = ""
        for character in text {
          if character.isNewline || (character.isWhitespace && pending.contains(where: \.isNewline)) {
            pending.append(character)
            continue
          }
          if !pending.isEmpty {
            out += pending.contains(where: \.isNewline) ? " " : pending
            pending = ""
          }
          if character.isWhitespace {
            pending.append(character)
          } else {
            out.append(character)
          }
        }
        return out + (pending.contains(where: \.isNewline) ? " " : pending)
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
        }
      }
      func runs(_ line: TEILine) -> [DiffEngine.Token] {
        var tokens: [DiffEngine.Token] = []
        for (index, run) in line.runs.enumerated() {
          switch run.kind {
          case .tex:
            tokens.append(.init(kind: .formula, text: run.text, style: style(run.rend)))
          case .text:
            var text = spaced(run.text)
            if index == 0 { text = String(text.drop(while: \.isWhitespace)) }
            if index == line.runs.count - 1 {
              while text.last?.isWhitespace == true { text.removeLast() }
            }
            if !text.isEmpty { tokens.append(.init(text: text, style: style(run.rend))) }
          }
        }
        return tokens
      }

      var out: [DiffEngine.RenderedLine] = []
      for line in lines {
        switch line.kind {
        case .figure(_, let bbox):
          out.append(
            .init(
              tokens: [.init(kind: .figure, text: line.text, style: bbox.isEmpty ? [] : ["region \(bbox)"])],
              opensBlock: true, role: role(line.kind)))
        case .gap(let reason):
          out.append(.init(tokens: [.init(text: "[\(reason.isEmpty ? "gap" : reason)]")], role: role(line.kind)))
        case .mark, .documentBoundary:
          out.append(.init(tokens: [.init(text: line.text)], role: role(line.kind)))
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

    private func inlineContent(_ line: TEILine) -> DOM.Node {
      span {
        for run in line.runs {
          switch run.kind {
          case .text:
            span { run.text }.class("tei-run").data("rend", run.rend)
          case .tex(let display):
            span { TeXView(run.text, displayMode: display) }
              .class("tei-run").data("rend", run.rend)
          }
        }
      }.build()
    }

    private func readingLine(_ line: TEILine, facsimileURL: String, label: String) -> DOM.Node {
      switch line.kind {
      case .heading:
        return h3 { inlineContent(line) }.class("tei-line tei-line-heading").data("rend", line.rend)
          .build()
      case .speaker:
        return span { inlineContent(line) }.class("tei-line tei-line-speaker").data(
          "rend", line.rend
        ).build()
      case .stage:
        return span { inlineContent(line) }.class("tei-line tei-line-stage").data("rend", line.rend)
          .build()
      case .mark:
        return span { line.text }.class("tei-line tei-line-mark").build()
      case .gap(let reason):
        return span { "[\(reason.isEmpty ? "gap" : reason)]" }.class("tei-line tei-line-gap")
          .build()
      case .documentBoundary:
        return hr().class("tei-document-boundary").build()
      case .forme(let role):
        return span { inlineContent(line) }.class(
          "tei-line tei-line-forme tei-line-forme-\(role.rawValue)"
        ).build()
      case .figure(let type, let bbox):
        guard let region = TEIRenderer.regionURL(ofFacsimile: facsimileURL, bbox: bbox) else {
          return DOM.Node.fragment([])
        }
        return figure {
          img().src(region).alt(line.text.isEmpty ? "Figure on \(label)" : line.text)
            .loading(.lazy).class("tei-figure-image")
          if !line.text.isEmpty { figcaption { line.text }.class("tei-figure-caption") }
        }.class("tei-line tei-figure").data("figure-type", type.isEmpty ? "figure" : type).build()
      case .table(let source):
        return div {
          table {
            if !source.caption.isEmpty {
              caption {
                for line in source.caption {
                  readingLine(line, facsimileURL: facsimileURL, label: label)
                }
              }
            }
            tbody {
              for row in source.rows {
                tr {
                  for cell in row.cells {
                    if cell.isLabel {
                      th {
                        for line in cell.lines {
                          readingLine(line, facsimileURL: facsimileURL, label: label)
                        }
                      }.rowspan(cell.rows).colspan(cell.columns)
                    } else {
                      td {
                        for line in cell.lines {
                          readingLine(line, facsimileURL: facsimileURL, label: label)
                        }
                      }.rowspan(cell.rows).colspan(cell.columns)
                    }
                  }
                }
              }
            }
          }.class("tei-table")
        }.class("tei-table-scroll").build()
      case .text:
        return span { inlineContent(line) }.class("tei-line").data("rend", line.rend).build()
      }
    }

    public func build() -> DOM.Node {
      let pages = self.pages
      // Record pages register an empty reader before fetching its contents.
      // Include formula styles then, even when no formula is present yet.
      _ = TeXView("").build()

      return div {
        if pages.isEmpty {
          p { "This document has no page breaks to read by. The raw XML is below." }
            .class("tei-view-empty")
        }
        for (index, page) in pages.enumerated() {
          div {
            div {
              for line in page.lines {
                readingLine(line, facsimileURL: page.facsimileURL, label: page.label)
              }
            }
            .class("tei-page-text")
            .data("reading-layer", "text")

            div {
              if editable {
                // A form of its own, so the page can be sent to be read back
                // as it is being edited — its rendition and its source.
                form {
                  input()
                    .type(.hidden)
                    .name("rendition")
                    .value(Self.serviceID(ofFacsimile: page.facsimileURL))
                  SourceEditorView(
                    id: "tei-page-source-\(index)",
                    name: "markup",
                    value: page.markup,
                    ariaLabel: page.label.isEmpty ? "Source of this page" : "Source of \(page.label)"
                  )
                }
                .class("tei-page-edit")
              } else {
                SourceView(XMLFormatter.prettified(page.markup), showLineNumbers: false)
              }
            }
            .class("tei-page-raw")
            .data("reading-layer", "source")
          }
          .class("tei-reading")
          .id("tei-reading-\(index)")
          // What pairs this reading with a canvas. The viewer matches on it.
          .data("service-id", Self.serviceID(ofFacsimile: page.facsimileURL))
          .data("active", index == 0 ? "true" : "false")
        }
      }
      .class("tei-view")
      .data("editable", editable)
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
        }
        descendant(".tei-reading") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
        }
        // A figure is set apart from the reading around it: it is a
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
          // reading and cannot be taller than what it illustrates.
          maxHeight(px(320))
          width(.auto)
          height(.auto)
          objectFit(.contain)
          borderRadius(borderRadiusBase)
          border(borderWidthBase, .solid, borderColorSubtle)
        }
        // A decorated initial is one letter tall in the text; shown at the
        // width of a plate it stops being an initial and becomes a poster.
        selector("& .tei-figure[data-figure-type='initial'] .tei-figure-image") {
          maxWidth(px(96))
        }
        descendant(".tei-figure-caption") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          fontStyle(.italic)
          color(colorSubtle)
        }
        // `<hi rend="…">` on the run it applies to. Small caps mark an author
        // statement; italic marks a speaker prefix or an emphasis the
        // compositor set — both are on the page, so both are in the reading.
        selector("& .tei-run[data-rend~='smallcaps']", "& .tei-run[data-rend~='small-caps']") {
          // No typed helper for this one; the builder takes a raw property.
          CSS.Property("font-variant-caps", "small-caps")
        }
        selector("& .tei-run[data-rend~='italic']", "& .tei-run[data-rend~='ital']") {
          fontStyle(.italic)
        }
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
        descendant(".tei-table-scroll") {
          maxWidth(perc(100))
          minWidth(0)
          overflowX(.auto)
          marginBlock(spacing8)
        }
        descendant(".tei-table") {
          borderCollapse(.collapse)
          fontFamily(typographyFontSerif)
          fontSize(fontSizeSmall14)
          color(colorBase)
        }
        selector("& .tei-table td", "& .tei-table th") {
          border(borderWidthBase, .solid, borderColorSubtle)
          padding(spacing4, spacing8)
          verticalAlign(.middle)
          textAlign(.start)
        }
        selector("& .tei-table td > .tei-line", "& .tei-table th > .tei-line") {
          display(.block)
          whiteSpace(.nowrap)
        }
        descendant(".tei-document-boundary") {
          width(perc(100))
          border(.none)
          borderTop(borderWidthBase, .solid, borderColorSubtle)
          marginBlock(spacing8)
        }
        // TEI's rend, honoured. `center` is the one that carries meaning on a
        // title page; the others are recorded and shown as they are written.
        selector("& .tei-line[data-rend~='center']") {
          display(.block)
          textAlign(.center)
        }
        selector("& .tei-line[data-rend~='right']") {
          display(.block)
          textAlign(.end)
        }
        descendant(".tei-page-text") {
          display(.flex)
          flexDirection(.column)
          gap(spacing2)
          minWidth(0)
        }
        // Editable only in Raw: the reading is for reading, and nothing in it
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
        descendant(".tei-line") {
          fontFamily(typographyFontSerif)
          fontSize(fontSizeSmall14)
          lineHeight(lineHeightMedium26)
          color(colorBase)
          overflowWrap(.breakWord)
        }
        descendant(".tei-line-heading") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          fontWeight(fontWeightSemiBold)
          margin(spacing8, spacing0, spacing4)
        }
        descendant(".tei-line-speaker") {
          fontWeight(fontWeightSemiBold)
          marginBlockStart(spacing8)
        }
        descendant(".tei-line-stage") {
          fontStyle(.italic)
          color(colorSubtle)
        }
        // The work's own apparatus, set where the compositor set it: the head
        // over the text, the catchword at the foot by the outer edge, the
        // signature at the foot by the inner one. In the flow they read as
        // lines of the play, which is what they are not.
        descendant(".tei-line-forme") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          letterSpacing(px(0.3))
          color(colorSubtle)
        }
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
        // Not a word on the page: a statement that there is none.
        descendant(".tei-line-gap") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          fontStyle(.italic)
          color(colorSubtle)
        }
        // A side of the leaf, inside an image that carries two of them.
        descendant(".tei-line-mark") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
          marginBlockStart(spacing8)
        }
        // The markup takes the reading's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers.
        // The markup takes the reading's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers, and the
        // block itself is a SourceView like any other.
        descendant(".tei-page-raw") {
          display(.none)
          margin(0)
          minWidth(0)
        }
        // The work's own apparatus: a running head is on the page and not in
        // the play, so it is shown as what it is rather than as a line of it.
        descendant(".tei-line-forme") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          letterSpacing(px(0.3))
          color(colorSubtle)
        }
        // A side of the leaf, inside an image that carries two of them.
        descendant(".tei-line-mark") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
          marginBlockStart(spacing8)
        }
        // The markup takes the reading's place rather than adding a block to
        // scroll past: the viewer's Raw switch swaps the two layers.
        descendant(".tei-page-raw") {
          display(.none)
          padding(0)
          backgroundColor(backgroundColorBase)
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          color(syntaxPlainText)
          whiteSpace(.preWrap)
          overflowWrap(.breakWord)
          margin(0)
        }
        descendant(".tei-page-source") {
          fontFamily(typographyFontMono)
          backgroundColor(.transparent)
          padding(0)
        }
        // The same token colours the session trace gives a tool call's markup:
        // one palette for code across the site, from design tokens rather than
        // from a highlight.js theme.
        selector(".tei-page-raw .hljs-tag", ".tei-page-raw .hljs-name") {
          color(syntaxKeywords).important()
        }
        selector(".tei-page-raw .hljs-attr", ".tei-page-raw .hljs-attribute") {
          color(syntaxAttributes).important()
        }
        selector(".tei-page-raw .hljs-string") { color(syntaxStrings).important() }
        selector(".tei-page-raw .hljs-comment") { color(syntaxComments).important() }
        selector(".tei-page-raw .hljs-meta") { color(syntaxOtherDeclarations).important() }
        selector(".tei-page-raw .hljs-symbol", ".tei-page-raw .hljs-punctuation") {
          color(syntaxPlainText).important()
        }
        selector(".tei-view-empty") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeSmall14)
          color(colorSubtle)
          margin(0)
        }
      }
      .build()
    }
  }
#endif
