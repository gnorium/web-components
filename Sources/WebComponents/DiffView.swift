#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DiffEngine
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Inline diff view with two levels of highlighting:
  /// - Line-level: subtle red/green background on entire changed lines
  /// - Word-level: strong red/green highlight on specific changed words
  public struct DiffView: HTMLContent {
    let segments: [DiffSegment]
    let stats: DiffStats
    let `class`: String

    public struct DiffStats: Sendable {
      public let inserted: Int
      public let deleted: Int
      public let unchanged: Int

      public var hasChanges: Bool { inserted > 0 || deleted > 0 }
    }

    public init(old: String, new: String, class: String = "") {
      self.segments = DiffEngine.diff(old: old, new: new)
      self.`class` = `class`

      var inserted = 0
      var deleted = 0
      var unchanged = 0
      for segment in segments {
        switch segment {
        case .inserted(let t): inserted += t.count
        case .deleted(let t): deleted += t.count
        case .unchanged(let t), .deletedContext(let t), .insertedContext(let t):
          unchanged += t.count
        }
      }
      self.stats = DiffStats(inserted: inserted, deleted: deleted, unchanged: unchanged)
    }

    public func build() -> DOM.Node {
      let rootClass =
        `class`.isEmpty
        ? "diff-view"
        : "diff-view \(`class`)"

      return div {
        // Stats bar
        if stats.hasChanges {
          div {
            if stats.deleted > 0 {
              span { "\u{2212}\(stats.deleted)" }
                .class("diff-stat-deleted")
            }

            if stats.inserted > 0 {
              span { "+\(stats.inserted)" }
                .class("diff-stat-inserted")
            }

            span { "\(stats.deleted + stats.inserted) chars changed" }
              .class("diff-stat-summary")
          }
          .class("diff-stats")
        }

        // Legend
        div {
          div {
            span {}
              .class("diff-legend-swatch-deleted")

            span { "Removed" }
              .class("diff-legend-label")
          }
          .class("diff-legend-item")

          div {
            span {}
              .class("diff-legend-swatch-inserted")

            span { "Added" }
              .class("diff-legend-label")
          }
          .class("diff-legend-item")
        }
        .class("diff-legend")

        // Diff content
        if stats.hasChanges {
          code {
            for segment in segments {
              switch segment {
              case .unchanged(let text):
                text
              case .deleted(let text):
                del(text)
                  .class("diff-deleted")
              case .inserted(let text):
                ins(text)
                  .class("diff-inserted")
              case .deletedContext(let text):
                span { text }
                  .class("diff-deleted-context")
              case .insertedContext(let text):
                span { text }
                  .class("diff-inserted-context")
              }
            }
          }
          .class("diff-content")
        } else {
          div {
            p { "No changes between these versions." }
              .class("diff-empty")
          }
          .class("diff-empty-box")
        }
      }
      .class(rootClass)
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing16)
        }
        selector(".diff-stats") {
          display(.flex)
          alignItems(.center)
          gap(spacing12)
          fontFamily(typographyFontMono)
          fontSize(fontSizeSmall14)
        }
        selector(".diff-stat-deleted") {
          color(colorRed)
          fontWeight(fontWeightBold)
        }
        selector(".diff-stat-inserted") {
          color(colorGreen)
          fontWeight(fontWeightBold)
        }
        selector(".diff-stat-summary") {
          color(colorSubtle)
          fontWeight(fontWeightNormal)
        }
        selector(".diff-legend") {
          display(.flex)
          alignItems(.center)
          gap(spacing16)
        }
        selector(".diff-legend-item") {
          display(.flex)
          alignItems(.center)
          gap(spacing4)
        }
        selector(".diff-legend-swatch-deleted", ".diff-legend-swatch-inserted") {
          display(.inlineBlock)
          width(px(14))
          height(px(14))
          borderRadius(borderRadiusMinimal)
        }
        selector(".diff-legend-swatch-deleted") { backgroundColor(colorRed) }
        selector(".diff-legend-swatch-inserted") { backgroundColor(colorGreen) }
        selector(".diff-legend-label") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
        }
        selector(".diff-content") {
          display(.block)
          fontFamily(typographyFontMono)
          fontSize(fontSizeSmall14)
          lineHeight(1.618)
          color(colorBase)
          backgroundColor(backgroundColorNeutralSubtle)
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
          padding(spacing16)
          margin(0)
          whiteSpace(.preWrap)
          wordBreak(.breakWord)
          overflow(.auto)
        }
        selector(".diff-deleted", ".diff-inserted") {
          color(colorInvertedFixed)
          textDecoration(.none)
          borderRadius(borderRadiusMinimal)
          padding(0, spacing4)
        }
        selector(".diff-deleted") { backgroundColor(backgroundColorRed) }
        selector(".diff-inserted") { backgroundColor(backgroundColorGreen) }
        selector(".diff-deleted-context") { backgroundColor(backgroundColorRedSubtle) }
        selector(".diff-inserted-context") { backgroundColor(backgroundColorGreenSubtle) }
        selector(".diff-empty-box") {
          backgroundColor(backgroundColorNeutralSubtle)
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
        }
        selector(".diff-empty") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          color(colorSubtle)
          textAlign(.center)
          padding(spacing32)
          margin(0)
        }
      }
    }
  }
#endif
