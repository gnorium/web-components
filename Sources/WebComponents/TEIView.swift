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

    /// The image service a facsimile URL is a request against: everything
    /// before the IIIF Image API parameters. `…/iiif/2/<id>/full/1300,/0/default.jpg`
    /// and `…/iiif/2/<id>/full/max/0/default.jpg` are two requests for one
    /// image, and the manifest names the image.
    public static func serviceID(ofFacsimile url: String) -> String {
      guard let cut = url.range(of: "/full/") else { return url }
      return String(url[url.startIndex..<cut.lowerBound])
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
            span { page.label }
              .class("tei-reading-label")

            div {
              for line in page.lines {
                switch line.kind {
                case .heading:
                  h3 { line.text }.class("tei-line tei-line-heading")
                case .speaker:
                  span { line.text }.class("tei-line tei-line-speaker")
                case .stage:
                  span { line.text }.class("tei-line tei-line-stage")
                case .mark:
                  span { line.text }.class("tei-line tei-line-mark")
                case .forme:
                  span { line.text }.class("tei-line tei-line-forme")
                case .text:
                  span { line.text }.class("tei-line")
                }
              }
            }
            .class("tei-page-text")
            .data("reading-layer", "text")

            pre(XMLFormatter.prettified(page.markup))
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
        descendant(".tei-reading-label") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
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
          padding(spacing12)
          borderRadius(borderRadiusBase)
          backgroundColor(backgroundColorNeutralSubtle)
          fontFamily(typographyFontMono)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
          whiteSpace(.preWrap)
          overflowWrap(.breakWord)
          margin(0)
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
