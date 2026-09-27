#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes
  import XMLUtilities

  /// One semblance, read: a page of a testament's transcription, the unit a
  /// `TEIView` reads its pages as — its reading, its code (the Raw layer)
  /// and, when the witness is translated, its translation, one showing at a
  /// time. It names the image service it reads (`data-service-id`), which is
  /// what pairs it with its canvas in an `ArtifactView`: beside its image in
  /// a testament's reader, where the pager shows one semblance at a time and
  /// marks one an amendment has edited (`data-edited`), or one after another
  /// with no image, each opened by its label, in an utterance's
  /// (`labeled`). The reading's own rules are its `TEIView`'s, which it is
  /// always drawn in.
  public struct SemblanceView: HTMLContent {
    let page: TEIPage
    let index: Int
    /// Whether its code can be edited, in an amendment.
    let editable: Bool
    /// The witness's translation, of which it shows its own page.
    let translation: TEIView.Translation?
    /// Whether its reading opens with its label.
    let labeled: Bool

    public init(
      page: TEIPage, index: Int, editable: Bool = false, translation: TEIView.Translation? = nil,
      labeled: Bool = false
    ) {
      self.page = page
      self.index = index
      self.editable = editable
      self.translation = translation
      self.labeled = labeled
    }

    /// A page's lines as the reader sets them: each line on its own, except
    /// the furniture at the head of the page (page number, running head,
    /// signature) set on one line, which is one row.
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
        case .forme(.header), .forme(.pageNumber), .forme(.signature):
          end()
          // Furniture that follows furniture with no line break between is
          // on the same line.
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

    private func inlineContent(_ line: TEILine) -> DOM.Node {
      span {
        for run in line.runs {
          if let highlight = run.highlight {
            // An utterance's sentence, or its word: marked, as the page
            // has it.
            mark { runContent(run) }
              .class("tei-highlight")
              .data("highlight", highlight.rawValue)
          } else {
            runContent(run)
          }
        }
      }.build()
    }

    private func runContent(_ run: TEILine.Run) -> DOM.Node {
      switch run.kind {
      case .text:
        if run.alternative.isEmpty {
          return span { run.text }.class("tei-run").data("rend", run.rend).build()
        }
        // A regularized spelling, an expansion or a correction the
        // transcription gives beside the reading: read on hover.
        return TooltipView(tooltip: run.alternative, placement: .top, class: "tei-run-alternative") {
          span { run.text }.class("tei-run").data("rend", run.rend)
        }.build()
      case .tex(let display):
        return span { TeXView(run.text, displayMode: display) }
          .class("tei-run").data("rend", run.rend).build()
      }
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
      case .note(let place):
        return span { inlineContent(line) }.class("tei-line tei-line-note")
          .data("place", place.isEmpty ? "inline" : place).build()
      case .forme(let role):
        return span { inlineContent(line) }.class(
          "tei-line tei-line-forme tei-line-forme-\(role.rawValue)"
        ).data("rend", line.rend).build()
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
      div {
        div {
          if labeled {
            readingLine(.init(kind: .mark, text: page.label.isEmpty ? "—" : page.label), facsimileURL: page.facsimileURL, label: page.label)
          }
          for item in Self.layout(of: page.lines) {
            switch item {
            case .line(let line):
              readingLine(line, facsimileURL: page.facsimileURL, label: page.label)
            case .block(let lines):
              // A block's lines, one to a line as the image sets them; on
              // a phone they run on as one paragraph, a break inside a
              // word joining it with no space.
              div {
                for (index, line) in lines.enumerated() {
                  if index > 0 && !line.joinsPrevious { " " }
                  readingLine(line, facsimileURL: page.facsimileURL, label: page.label)
                }
              }.class("tei-block").data("rend", lines[0].rend)
            case .furniture(let pieces):
              // A page number and a running head set on one line keep
              // their places on it, as the image has them.
              div {
                for place in FurniturePlace.allCases {
                  div {
                    for piece in pieces where FurniturePlace.of(piece) == place {
                      readingLine(piece, facsimileURL: page.facsimileURL, label: page.label)
                    }
                  }.class("tei-forme-row-\(place.rawValue)")
                }
              }.class("tei-forme-row")
            }
          }
        }
        .class("tei-page-text")
        .data("reading-layer", "text")

        div {
          if editable {
            // A form of its own, so the page can be sent to be read back
            // as it is being edited — its semblance and its code.
            form {
              input()
                .type(.hidden)
                .name("semblance")
                .value(TEIView.serviceID(ofFacsimile: page.facsimileURL))
              CodeEditorView(
                id: "tei-page-code-\(index)",
                name: "markup",
                value: page.markup,
                ariaLabel: page.label.isEmpty ? "Code of this page" : "Code of \(page.label)"
              )
            }
            .class("tei-page-edit")
          } else {
            CodeView(XMLFormatter.prettified(page.markup), showLineNumbers: false)
          }
        }
        .class("tei-page-raw")
        .data("reading-layer", "code")

        // The translation, set by the very reader that sets the
        // transcript above: the same lines, the same classes.
        if let translation {
          let translated = translation.pages[TEIView.serviceID(ofFacsimile: page.facsimileURL)]
          div {
            if let note = translated?.note {
              p { note }
                .class("tei-page-translation-note")
            }
            div {
              if let translated {
                for line in translated.page.lines {
                  readingLine(line, facsimileURL: translated.page.facsimileURL, label: translated.page.label)
                }
              } else {
                span { "—" }
                  .class("tei-line")
              }
            }
            .class("tei-page-text")
          }
          .class("tei-page-translation")
          .data("reading-layer", "translation")
          .lang(translation.language)
          .dir("auto")
        }
      }
      .class("semblance-view")
      .id("semblance-view-\(index)")
      // What pairs this reading with a canvas. The viewer matches on it.
      .data("service-id", TEIView.serviceID(ofFacsimile: page.facsimileURL))
      .data("active", index == 0 ? "true" : "false")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
        }
      }
      .build()
    }
  }
#endif
