import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Navigates the user to another page, view or section—or, as a form's
/// submit control (`init(submit:…)`), posts its form while reading exactly
/// as a link: a row of links whose acts are POSTs (Nullify) stays one
/// row of links.
public struct LinkView: HTMLContent {
  public enum LinkWeight: String, Sendable {
    case `default`
    case plain
  }

  /// A link drawn as a form's submit control: `<button type="submit">`.
  public enum Submit: Sendable {
    case submit
  }

  let url: String
  let submits: Bool
  let underlined: Bool
  let redLink: Bool
  let redHover: Bool
  let external: Bool
  let weight: LinkWeight
  let linkHeight: CSS.Length?
  let content: [DOM.Node]
  let `class`: String
  let title: String?
  /// `data-*` attributes on the link, by name without the prefix.
  let data: [(String, String)]

  public init(
    url: String,
    underlined: Bool = false,
    redLink: Bool = false,
    redHover: Bool = false,
    external: Bool = false,
    weight: LinkWeight = .default,
    linkHeight: CSS.Length? = nil,
    class: String = "",
    title: String? = nil,
    data: [(String, String)] = [],
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.url = url
    self.data = data
    self.submits = false
    self.underlined = underlined
    self.redLink = redLink
    self.redHover = redHover
    self.external = external
    self.weight = weight
    self.linkHeight = linkHeight
    self.content = content()
    self.`class` = `class`
    self.title = title
  }

  /// A form's submit control with this link's look: the form posts, the
  /// reader sees a link like those beside it.
  public init(
    _ submit: Submit,
    underlined: Bool = false,
    redLink: Bool = false,
    redHover: Bool = false,
    weight: LinkWeight = .default,
    linkHeight: CSS.Length? = nil,
    class: String = "",
    title: String? = nil,
    data: [(String, String)] = [],
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.url = ""
    self.data = data
    self.submits = true
    self.underlined = underlined
    self.redLink = redLink
    self.redHover = redHover
    self.external = false
    self.weight = weight
    self.linkHeight = linkHeight
    self.content = content()
    self.`class` = `class`
    self.title = title
  }

  public func build() -> DOM.Node {
    if submits {
      var control = button { content }
        .type(.submit)
        .class(linkClasses + " link-submit")
        .data("height", linkHeight?.value ?? "auto")
      if let title { control = control.title(title) }
      for (name, value) in data { control = control.data(name, value) }
      return control.style { linkStyle() }
    }
    var link = a {
      content

      if external {
        span { "↗" }
          .class("link-external-icon")
          .ariaHidden(true)
      }
    }
    .href(url)
    .class(linkClasses)
    .data("height", linkHeight?.value ?? "auto")

    if let title {
      link = link.title(title)
    }
    for (name, value) in data { link = link.data(name, value) }

    if external {
      link =
        link
        .target(.blank)
        .rel(.noopener, .noreferrer)
    }

    return link.style { linkStyle() }
  }

  private var linkClasses: String {
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
    if redHover {
      classes += " link-red-hover"
    }
    if external {
      classes += " link-external"
    }
    if !stringIsEmpty(`class`) {
      classes += " \(`class`)"
    }
    return classes
  }

  @CSSBuilder
  private func linkStyle() -> [CSSOM.CSSRule] {
    selector("&:not(.link-plain)") {
      cursor(cursorBaseHover)
      color(colorLink)
      textDecoration(.none)
    }
    selector("&.link-red:not(.link-plain)") { color(colorRed) }
    selector("&.link-underlined:not(.link-plain)") { textDecoration(.underline) }
    selector("&:not(.link-plain):hover") { color(colorLinkHover).important() }
    selector("&:not(.link-plain):active") { color(colorLinkActive).important() }
    selector("&.link-red:not(.link-plain):hover") { color(colorRedHover).important() }
    selector("&.link-red:not(.link-plain):active") { color(colorRedActive).important() }
    selector("&.link-red:not(.link-plain):visited") { color(colorRed).important() }
    // A link to a destructive action's page: the link color at rest, red
    // (icon too, through currentColor) once hovered or focused, so it says
    // where it leads. The action itself is the red button on that page.
    selector("&.link-red-hover:not(.link-plain):hover", "&.link-red-hover:not(.link-plain):focus-visible") {
      color(colorRed).important()
    }
    selector("&.link-red-hover:not(.link-plain):active") { color(colorRedActive).important() }
    selector("&.link-plain") {
      display(.flex)
      alignItems(.center)
      gap(spacing8)
      height(.auto)
      fontFamily(typographyFontSans)
      fontSize(fontSizeMedium16)
      fontWeight(fontWeightNormal)
      color(colorBase).important()
      textDecoration(.none)
      borderRadius(borderRadiusBase)
      cursor(cursorBaseHover)
    }
    selector("&.link-plain:hover") { color(colorBlue).important() }
    selector("&.link-plain:active") { color(colorBlue).important() }
    // A plain link to a destructive action's page: base color at rest,
    // red once hovered or focused (user, 2026-10-10).
    selector("&.link-plain.link-red-hover:hover", "&.link-plain.link-red-hover:focus-visible") {
      color(colorRed).important()
    }
    selector("&.link-plain.link-red-hover:active") { color(colorRedActive).important() }
    selector("&.scroll-spy-view[data-active='true']") { fontWeight(fontWeightSemiBold) }
    if let linkHeight {
      selector("&.link-plain[data-height='\(linkHeight.value)']") { height(linkHeight) }
    }
    // :focus-visible, not :focus. A plain :focus rule fires on a mouse
    // click as well as on keyboard navigation, so Chromium drew a ring
    // around every link the moment it was clicked. :focus-visible is the
    // selector that means "focused, and the browser judges a ring useful"—keyboard
    // users keep it, mouse users never see it.
    selector("&:focus-visible") {
      outline(borderWidthThick, .solid, borderColorBlue).important()
      outlineOffset(px(-2)).important()
      borderRadius(borderRadiusBase).important()
    }
    descendant(".link-external-icon") {
      display(.inlineBlock)
      width(sizeIconSmall)
      height(sizeIconSmall)
      marginInlineStart(spacing4)
      verticalAlign(.middle)
      fontSize(sizeIconSmall)
    }
    // As a form's submit control, a button wearing the link: no
    // button box of its own, the link's type and color.
    selector("&.link-submit") {
      CSS.Property("appearance", "none")
      backgroundColor(.transparent)
      border(.none)
      padding(0)
      margin(0)
      fontFamily(typographyFontSans)
      fontSize(fontSizeMedium16)
      CSS.Property("line-height", "inherit")
      cursor(cursorBaseHover)
    }
  }
}
