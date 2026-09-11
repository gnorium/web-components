#if SERVER
  import CSSBuilder
  import DesignTokens
  import CSSOMBuilder
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A Card groups information related to a single topic.
  public struct CardView: HTMLContent {
    let url: String
    let icon: String?
    let thumbnail: Thumbnail?
    let forceThumbnail: Bool
    let customPlaceholderIcon: String?
    let titleContent: [DOM.Node]
    let descriptionContent: [DOM.Node]
    let supportingTextContent: [DOM.Node]
    let `class`: String

    public struct Thumbnail: Sendable {
      let url: String
      let alt: String

      public init(url: String, alt: String = "") {
        self.url = url
        self.alt = alt
      }
    }

    public init(
      url: String = "",
      icon: String? = nil,
      thumbnail: Thumbnail? = nil,
      forceThumbnail: Bool = false,
      customPlaceholderIcon: String? = nil,
      class: String = "",
      @HTMLBuilder title: () -> [DOM.Node],
      @HTMLBuilder description: () -> [DOM.Node] = { [] },
      @HTMLBuilder supportingText: () -> [DOM.Node] = { [] }
    ) {
      self.url = url
      self.icon = icon
      self.thumbnail = thumbnail
      self.forceThumbnail = forceThumbnail
      self.customPlaceholderIcon = customPlaceholderIcon
      self.`class` = `class`
      self.titleContent = title()
      self.descriptionContent = description()
      self.supportingTextContent = supportingText()
    }

    @DOMBuilder
    public func build() -> DOM.Node {
      let isLink = !url.isEmpty
      let hasThumbnail = thumbnail != nil || forceThumbnail
      let hasIcon = icon != nil
      let hasMedia = hasThumbnail || hasIcon
      let hasDescription = !descriptionContent.isEmpty
      let hasSupportingText = !supportingTextContent.isEmpty
      let hasTitleOnly = !hasDescription && !hasSupportingText

      let cardContentElement = div {
        if hasThumbnail {
          div {
            if let thumb = thumbnail {
              img()
                .src(thumb.url)
                .alt(thumb.alt)
                .class("card-thumbnail-image")
            } else {
              div {
                customPlaceholderIcon ?? "📷"
              }
              .class("card-thumbnail-placeholder")
            }
          }
          .class("card-thumbnail")
        } else if let icon = icon {
          div {
            icon
          }
          .class("card-icon")
        }

        div {
          h3 { titleContent }
            .class("card-title")

          if hasDescription {
            p { descriptionContent }
              .class("card-description")
          }

          if hasSupportingText {
            p { supportingTextContent }
              .class("card-supporting-text")
          }
        }
        .class("card-text")
      }
      .class("card-content-wrapper")

      if isLink {
        a { cardContentElement }
          .href(url)
          .class(`class`.isEmpty ? "card-view card-is-link" : "card-view card-is-link \(`class`)")
          .data("has-media", hasMedia && !hasTitleOnly)
          .style {
            selector("&") {
              display(.block)
              backgroundColor(backgroundColorBase)
              border(borderWidthBase, .solid, borderColorSubtle)
              borderRadius(borderRadiusBase)
              overflow(.hidden)
              boxShadow(boxShadowSmall)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            }
            selector("&.card-is-link") {
              textDecoration(.none)
              cursor(cursorBase)
            }
            selector("&.card-is-link:hover") {
              borderColor(borderColorBlueHover).important()
              boxShadow(boxShadowMedium).important()
            }
            selector("&.card-is-link:focus") {
              borderColor(borderColorBlueFocus).important()
              boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
              outline(px(1), .solid, .transparent).important()
            }
            selector("&.card-is-link:active") { borderColor(borderColorBlueActive).important() }
            descendant(".card-content-wrapper") {
              display(.flex)
              alignItems(.center)
              gap(spacing16)
              width(perc(100))
            }
            selector("&[data-has-media='true'] .card-content-wrapper") { alignItems(.flexStart) }
            descendant(".card-thumbnail") {
              width(px(80))
              height(px(80))
              overflow(.hidden)
              borderRadius(borderRadiusBase)
              flexShrink(0)
            }
            descendant(".card-thumbnail-image") {
              width(perc(100))
              height(perc(100))
              objectFit(.cover)
              display(.block)
            }
            descendant(".card-thumbnail-placeholder") {
              display(.flex)
              alignItems(.center)
              justifyContent(.center)
              width(perc(100))
              height(perc(100))
              backgroundColor(backgroundColorNeutralSubtle)
              color(colorPlaceholder)
              fontSize(fontSizeLarge18)
            }
            descendant(".card-icon") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              color(colorSubtle)
            }
            descendant(".card-text") {
              display(.flex)
              flexDirection(.column)
              gap(spacing16)
              padding(spacing12)
              flex(1)
              minWidth(0)
            }
            selector("&[data-has-media='true'] .card-text") { justifyContent(.flexStart) }
            descendant(".card-title") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeXXLarge24)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              margin(0)
              wordWrap(.breakWord)
            }
            selector("&.card-is-link .card-title") {
              color(colorBlue)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem).important()
            }
            descendant(".card-description") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeSmall14)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              margin(0)
            }
            descendant(".card-supporting-text") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeXSmall12)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
              margin(0)
            }
          }
      } else {
        div { cardContentElement }
          .class(`class`.isEmpty ? "card-view" : "card-view \(`class`)")
          .data("has-media", hasMedia && !hasTitleOnly)
          .style {
            selector("&") {
              display(.block)
              backgroundColor(backgroundColorBase)
              border(borderWidthBase, .solid, borderColorSubtle)
              borderRadius(borderRadiusBase)
              overflow(.hidden)
              boxShadow(boxShadowSmall)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            }
            selector("&.card-is-link") {
              textDecoration(.none)
              cursor(cursorBase)
            }
            selector("&.card-is-link:hover") {
              borderColor(borderColorBlueHover).important()
              boxShadow(boxShadowMedium).important()
            }
            selector("&.card-is-link:focus") {
              borderColor(borderColorBlueFocus).important()
              boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
              outline(px(1), .solid, .transparent).important()
            }
            selector("&.card-is-link:active") { borderColor(borderColorBlueActive).important() }
            descendant(".card-content-wrapper") {
              display(.flex)
              alignItems(.center)
              gap(spacing16)
              width(perc(100))
            }
            selector("&[data-has-media='true'] .card-content-wrapper") { alignItems(.flexStart) }
            descendant(".card-thumbnail") {
              width(px(80))
              height(px(80))
              overflow(.hidden)
              borderRadius(borderRadiusBase)
              flexShrink(0)
            }
            descendant(".card-thumbnail-image") {
              width(perc(100))
              height(perc(100))
              objectFit(.cover)
              display(.block)
            }
            descendant(".card-thumbnail-placeholder") {
              display(.flex)
              alignItems(.center)
              justifyContent(.center)
              width(perc(100))
              height(perc(100))
              backgroundColor(backgroundColorNeutralSubtle)
              color(colorPlaceholder)
              fontSize(fontSizeLarge18)
            }
            descendant(".card-icon") {
              display(.inlineFlex)
              alignItems(.center)
              justifyContent(.center)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
              color(colorSubtle)
            }
            descendant(".card-text") {
              display(.flex)
              flexDirection(.column)
              gap(spacing16)
              padding(spacing12)
              flex(1)
              minWidth(0)
            }
            selector("&[data-has-media='true'] .card-text") { justifyContent(.flexStart) }
            descendant(".card-title") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeXXLarge24)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              margin(0)
              wordWrap(.breakWord)
            }
            selector("&.card-is-link .card-title") {
              color(colorBlue)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem).important()
            }
            descendant(".card-description") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeSmall14)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              margin(0)
            }
            descendant(".card-supporting-text") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeXSmall12)
              lineHeight(lineHeightSmall22)
              color(colorSubtle)
              margin(0)
            }
          }
      }
    }
  }
#endif
