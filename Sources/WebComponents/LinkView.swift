import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Navigates the user to another page, view or section.
public struct LinkView: HTMLContent {
  public enum LinkWeight: String, Sendable {
    case `default`
    case plain
  }

  let url: String
  let underlined: Bool
  let redLink: Bool
  let external: Bool
  let weight: LinkWeight
  let linkHeight: CSS.Length?
  let content: [DOM.Node]
  let `class`: String
  let title: String?

  public init(
    url: String,
    underlined: Bool = false,
    redLink: Bool = false,
    external: Bool = false,
    weight: LinkWeight = .default,
    linkHeight: CSS.Length? = nil,
    class: String = "",
    title: String? = nil,
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.url = url
    self.underlined = underlined
    self.redLink = redLink
    self.external = external
    self.weight = weight
    self.linkHeight = linkHeight
    self.content = content()
    self.`class` = `class`
    self.title = title
  }

  public func build() -> DOM.Node {
    let linkClasses = {
      var classes = "link-view"
      if weight == .plain {
        classes += " link-plain"
      }
      if underlined {
        classes += " link-underlined"
      }
      if redLink {
        classes += " link-red"
      }
      if external {
        classes += " link-external"
      }
      if !stringIsEmpty(`class`) {
        classes += " \(`class`)"
      }
      return classes
    }()

    var link = a {
      content

      if external {
        span { "↗" }
          .class("link-external-icon")
          .ariaHidden(true)
          .style {
            linkExternalIconCSS()
          }
      }
    }
    .href(url)
    .class(linkClasses)

    if let title {
      link = link.title(title)
    }

    if external {
      link =
        link
        .target(.blank)
        .rel(.noopener, .noreferrer)
    }

    return link
      .style {
        if weight == .plain {
          linkViewPlainCSS()
        } else {
          linkViewCSS(underlined, redLink)
        }
      }
  }

  @CSSBuilder
  private func linkViewCSS(_ underlined: Bool, _ redLink: Bool) -> [CSSOM.CSSRule] {
    if redLink {
      color(colorRed)
    } else {
      color(colorLink)
    }

    if underlined {
      textDecoration(.underline)
    } else {
      textDecoration(.none)
    }
    cursor(cursorBaseHover)

    pseudoClass(.hover) {
      if redLink {
        color(colorRedHover).important()
      } else {
        color(colorLinkHover).important()
      }
    }

    pseudoClass(.active) {
      if redLink {
        color(colorRedActive).important()
      } else {
        color(colorLinkActive).important()
      }
    }

    pseudoClass(.focus) {
      outline(borderWidthThick, .solid, borderColorBlue).important()
      outlineOffset(px(-2)).important()
      borderRadius(borderRadiusBase).important()
    }

    if redLink {
      pseudoClass(.visited) {
        color(colorRed).important()
      }
    }
  }

  @CSSBuilder
  private func linkViewPlainCSS() -> [CSSOM.CSSRule] {
    display(.flex)
    alignItems(.center)
    gap(spacing8)
    if let linkHeight = linkHeight {
      height(linkHeight)
    } else {
      height(.auto)
    }
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    fontWeight(fontWeightNormal)
    color(colorBase).important()
    textDecoration(.none)
    borderRadius(borderRadiusBase)
    cursor(cursorBaseHover)

    pseudoClass(.focus) {
      outline(borderWidthThick, .solid, borderColorBlue).important()
      outlineOffset(px(-2)).important()
      borderRadius(borderRadiusBase).important()
    }
  }

  @CSSBuilder
  private func linkExternalIconCSS() -> [CSSOM.CSSRule] {
    display(.inlineBlock)
    width(sizeIconXSmall)
    height(sizeIconXSmall)
    marginInlineStart(spacing4)
    verticalAlign(.middle)
    fontSize(sizeIconXSmall)
  }
}
