#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes
  import XMLUtilities

  /// One labelled entry of a rendered TEI header (`TEIHeaderEntry`): its
  /// label, then what it holds—a value, paragraphs, tables—and the entries
  /// nested beneath it, each of them this view again. Text wraps; it is
  /// never faded, since nothing here is a single line to cut.
  public struct HeaderEntryView: HTMLContent {
    let entry: TEIHeaderEntry

    public init(_ entry: TEIHeaderEntry) {
      self.entry = entry
    }

    public func build() -> DOM.Node {
      div {
        span { entry.label }.class("header-entry-label")
        if !entry.value.isEmpty {
          span { entry.value }.class("header-entry-value")
        }
        for paragraph in entry.paragraphs {
          p { paragraph }.class("header-entry-paragraph")
        }
        for headed in entry.tables {
          table {
            if !headed.title.isEmpty { caption { headed.title } }
            thead {
              tr {
                for column in headed.columns { th { column }.scope(.col) }
              }
            }
            tbody {
              for row in headed.rows {
                tr {
                  for cell in row { td { cell } }
                }
              }
            }
          }
          .class("header-entry-table")
        }
        if !entry.entries.isEmpty {
          div {
            for nested in entry.entries { HeaderEntryView(nested) }
          }
          .class("header-entry-entries")
        }
      }
      .class("header-entry-view")
      .style {
        selector("&") {
          display(.flex); flexDirection(.column); gap(spacing4); minWidth(0)
          fontFamily(typographyFontSans); fontSize(fontSizeMedium16); lineHeight(lineHeightSmall22)
          color(colorBase); overflowWrap(.anywhere)
        }
        descendant(".header-entry-label") { fontWeight(fontWeightSemiBold); color(colorSubtle) }
        descendant(".header-entry-paragraph") { margin(0) }
        descendant(".header-entry-entries") {
          display(.flex); flexDirection(.column); gap(spacing8); paddingInlineStart(spacing16)
        }
        descendant(".header-entry-table") {
          borderCollapse(.collapse); inlineSize(perc(100)); maxInlineSize(perc(100))
        }
        descendant(".header-entry-table caption") {
          textAlign(.start); fontWeight(fontWeightSemiBold); color(colorSubtle); paddingBlockEnd(spacing4)
        }
        selector("& .header-entry-table th, & .header-entry-table td") {
          textAlign(.start); padding(spacing8)
          border(borderWidthBase, .solid, borderColorSubtle)
        }
        descendant(".header-entry-table th") { fontWeight(fontWeightSemiBold) }
      }
      .build()
    }
  }
#endif
