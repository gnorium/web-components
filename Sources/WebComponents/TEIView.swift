#if SERVER
  import CSSBuilder
  import DesignTokens
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

    public init(teiXml: String) {
      self.teiXml = teiXml
    }

    public var pages: [TEIPage] { TEIRenderer.pages(in: teiXml) }

    /// The image service a rendition reads, which is what pairs it with a
    /// canvas. `TEIRenderer` owns the rule; the view only passes it on.
    public static func serviceID(ofFacsimile url: String) -> String {
      TEIRenderer.serviceID(ofFacsimile: url)
    }

    public func build() -> DOM.Node {
      let pages = self.pages

      return div {
        if pages.isEmpty {
          p { "This document has no page breaks to read by. The raw XML is below." }
            .class("tei-view-empty")
        }
        for (index, page) in pages.enumerated() {
          div {
            div {
              for line in page.lines {
                switch line.kind {
                case .heading:
                  h3 { line.text }
                    .class("tei-line tei-line-heading")
                    .data("rend", line.rend)
                case .speaker:
                  span { line.text }.class("tei-line tei-line-speaker")
                case .stage:
                  span { line.text }.class("tei-line tei-line-stage")
                case .mark:
                  span { line.text }.class("tei-line tei-line-mark")
                case .gap(let reason):
                  span { "[\(reason.isEmpty ? "gap" : reason)]" }
                    .class("tei-line tei-line-gap")
                case .forme(let role):
                  span { line.text }
                    .class("tei-line tei-line-forme tei-line-forme-\(role.rawValue)")
                case .figure(let type, let bbox):
                  // Drawn, not written: the region is cut from the facsimile by
                  // its bbox, so the reader sees the thing itself with its
                  // description under it as a caption.
                  //
                  // No bbox, no figure. A caption alone describes a picture
                  // that is not there — and the surface it describes is already
                  // on screen in the facsimile pane, so "gold-tooled dark
                  // leather binding" beside a photograph of one says nothing.
                  // The markup still carries it; the reading does not.
                  if let region = TEIRenderer.regionURL(
                    ofFacsimile: page.facsimileURL, bbox: bbox)
                  {
                    figure {
                      img()
                        .src(region)
                        .alt(line.text.isEmpty ? "Figure on \(page.label)" : line.text)
                        .loading(.lazy)
                        .class("tei-figure-image")
                      if !line.text.isEmpty {
                        figcaption { line.text }
                          .class("tei-figure-caption")
                      }
                    }
                    .class("tei-line tei-figure")
                    .data("figure-type", type.isEmpty ? "figure" : type)
                  }
                case .text:
                  // The setting comes through as the transcription recorded it:
                  // a reader comparing a reading against its facsimile is
                  // comparing where the type sits as much as what it says.
                  span {
                    for run in line.runs {
                      span { run.text }
                        .class("tei-run")
                        .data("rend", run.rend)
                    }
                  }
                  .class("tei-line")
                  .data("rend", line.rend)
                }
              }
            }
            .class("tei-page-text")
            .data("reading-layer", "text")

            div {
              SourceView(XMLFormatter.prettified(page.markup), showLineNumbers: false)
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
        selector("& .tei-run[data-rend='smallcaps']", "& .tei-run[data-rend='small-caps']") {
          // No typed helper for this one; the builder takes a raw property.
          property("font-variant-caps", "small-caps")
        }
        selector("& .tei-run[data-rend='italic']", "& .tei-run[data-rend='ital']") {
          fontStyle(.italic)
        }
        selector("& .tei-run[data-rend='bold']") {
          fontWeight(fontWeightBold)
        }
        // TEI's rend, honoured. `center` is the one that carries meaning on a
        // title page; the others are recorded and shown as they are written.
        selector("& .tei-line[data-rend='center']") {
          display(.block)
          textAlign(.center)
        }
        selector("& .tei-line[data-rend='right']") {
          display(.block)
          textAlign(.end)
        }
        descendant(".tei-page-text") {
          display(.flex)
          flexDirection(.column)
          gap(spacing2)
          minWidth(0)
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
