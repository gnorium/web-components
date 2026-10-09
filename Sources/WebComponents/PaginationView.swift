import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes
#if SERVER
  import Foundation
#endif

/// Editable page control: previous / `[n]` of `M` / next.
///
/// - ``Size/normal``—table / list footers (44px targets, spaced layout)
/// - ``Size/small``—chrome pagers (session, artifact, attempt switcher):
///   ButtonView's small, 32px targets, 16px text (a field under 16px makes
///   iOS Safari zoom the page as it is focused), 14px chevrons
///
/// URL mode (`previousUrl` / `nextUrl`) is hydrated by
/// ``PaginationHydration``. Query / custom mode sets `kind` and prev/next
/// `data` attributes; the host page binds those (e.g. SessionHydration).
public struct PaginationView: HTMLContent {
  public enum Size: String, Sendable {
    case normal
    case small
  }

  public let currentPage: Int
  public let totalPages: Int
  public let previousUrl: String?
  public let nextUrl: String?
  public let size: Size
  public let showControls: Bool
  public let kind: String
  public let inputID: String?
  public let totalID: String?
  public let totalDisplay: String?
  public let ariaLabel: String
  public let inputAriaLabel: String
  public let previousAriaLabel: String
  public let nextAriaLabel: String
  public let previousDisabled: Bool
  public let nextDisabled: Bool
  public let previousData: [(String, String)]
  public let nextData: [(String, String)]
  let `class`: String

  public init(
    currentPage: Int? = nil,
    totalPages: Int = 0,
    previousUrl: String? = nil,
    nextUrl: String? = nil,
    size: Size = .normal,
    showControls: Bool = true,
    kind: String = "",
    inputID: String? = nil,
    totalID: String? = nil,
    totalDisplay: String? = nil,
    ariaLabel: String = "Pagination",
    inputAriaLabel: String = "Page number",
    previousAriaLabel: String = "Previous page",
    nextAriaLabel: String = "Next page",
    previousDisabled: Bool? = nil,
    nextDisabled: Bool? = nil,
    previousData: [(String, String)] = [],
    nextData: [(String, String)] = [],
    class: String = ""
  ) {
    self.totalPages = max(0, totalPages)
    self.currentPage = max(1, currentPage ?? 1)
    self.previousUrl = previousUrl
    self.nextUrl = nextUrl
    self.size = size
    self.showControls = showControls
    self.kind = kind
    self.inputID = inputID
    self.totalID = totalID
    self.totalDisplay = totalDisplay
    self.ariaLabel = ariaLabel
    self.inputAriaLabel = inputAriaLabel
    self.previousAriaLabel = previousAriaLabel
    self.nextAriaLabel = nextAriaLabel
    self.previousDisabled = previousDisabled ?? stringEquals(previousUrl, nil)
    self.nextDisabled = nextDisabled ?? stringEquals(nextUrl, nil)
    self.previousData = previousData
    self.nextData = nextData
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    let safeTotal = max(1, totalPages)
    let safePage = min(currentPage, safeTotal)
    let totalPagesStr = totalDisplay ?? (totalPages > 0 ? formatNumberWithCommas(totalPages) : "—")
    let digitSource = totalDisplay ?? "\(max(1, totalPages))"
    let digitCount = max(1, digitSource.utf8.count)
    // The chrome size (small) sets "of" and the total apart and keeps its
    // chevrons beside the number.
    let chrome: Bool
    let iconSize: CSS.Length
    switch size {
    case .normal:
      chrome = false
      iconSize = sizeIconSmall
    case .small:
      chrome = true
      // Icon-only chevrons on par with the pager's 16px text ("of 3") take
      // the text's size (user, 2026-10-09); minus 4 is for an icon beside
      // a label. Their buttons stay 32.
      iconSize = sizeIconSmall
    }
    let inputWidth = chrome ? calc(ch(digitCount) + px(10)) : calc(ch(digitCount) + px(20))
    let useButtons = stringEquals(previousUrl, nil) && stringEquals(nextUrl, nil) && showControls

    let sizeClass = "pagination-size-\(size.rawValue)"
    let rootClass = stringIsEmpty(`class`)
      ? stringJoin(["pagination-view", sizeClass], separator: " ")
      : stringJoin(["pagination-view", sizeClass, `class`], separator: " ")

    return section {
      if showControls {
        div {
          if let prevHref = previousUrl {
            var link = a {
              PreviousIconView(size: iconSize)
            }
            .class("pagination-prev")
            .href(prevHref)
            .ariaLabel(previousAriaLabel)
            for (key, value) in previousData {
              link = link.data(key, value)
            }
            link
          } else if useButtons {
            var btn = button {
              PreviousIconView(size: iconSize)
            }
            .type(.button)
            .class(previousDisabled ? "pagination-prev pagination-disabled" : "pagination-prev")
            .disabled(previousDisabled)
            .ariaLabel(previousAriaLabel)
            for (key, value) in previousData {
              btn = btn.data(key, value)
            }
            btn
          } else {
            span {
              PreviousIconView(size: iconSize)
            }
            .class("pagination-prev pagination-disabled")
            .ariaLabel(previousAriaLabel)
          }
        }
        .class("pagination-previous-container")
      }

      div {
        if let inputID {
          input()
            .type(.number)
            .id(inputID)
            .value("\(safePage)")
            .class("page-box")
            .min(1)
            .max(safeTotal)
            .ariaLabel(inputAriaLabel)
            .data("input-width", inputWidth.value)
            .addingAttribute("size", "\(digitCount)")
        } else {
          input()
            .type(.number)
            .value("\(safePage)")
            .class("page-box")
            .min(1)
            .max(safeTotal)
            .ariaLabel(inputAriaLabel)
            .data("input-width", inputWidth.value)
            .addingAttribute("size", "\(digitCount)")
        }

        if chrome {
          span { "of" }
            .class("pagination-term")
          if let totalID {
            span { totalPagesStr }
              .id(totalID)
              .class("pagination-total")
          } else {
            span { totalPagesStr }
              .class("pagination-total")
          }
        } else {
          span { "of \(totalPagesStr)" }
            .class("pagination-total")
        }
      }
      .class("pagination-indicator")

      if showControls {
        div {
          if let nextHref = nextUrl {
            var link = a {
              NextIconView(size: iconSize)
            }
            .class("pagination-next")
            .href(nextHref)
            .ariaLabel(nextAriaLabel)
            for (key, value) in nextData {
              link = link.data(key, value)
            }
            link
          } else if useButtons {
            var btn = button {
              NextIconView(size: iconSize)
            }
            .type(.button)
            .class(nextDisabled ? "pagination-next pagination-disabled" : "pagination-next")
            .disabled(nextDisabled)
            .ariaLabel(nextAriaLabel)
            for (key, value) in nextData {
              btn = btn.data(key, value)
            }
            btn
          } else {
            span {
              NextIconView(size: iconSize)
            }
            .class("pagination-next pagination-disabled")
            .ariaLabel(nextAriaLabel)
          }
        }
        .class("pagination-next-container")
      }
    }
    .class(rootClass)
    .data("size", size.rawValue)
    .data("index", "\(safePage)")
    .data("count", "\(safeTotal)")
    .data("pager-kind", kind)
    .ariaLabel(ariaLabel)
    .style {
      selector("&") {
        display(.flex)
        flexDirection(.row)
        justifyContent(.spaceBetween)
        alignItems(.center)
        maxWidth(px(600))
        margin(0, .auto)
        gap(spacing16)
      }
      // Its text a field's 16px, as the number in its box.
      selector("&.pagination-size-small") {
        justifyContent(.flexStart)
        maxWidth(.none)
        margin(0)
        gap(spacing6)
        flexShrink(0)
        color(colorBase)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
      }
      selector(".pagination-previous-container", ".pagination-next-container") {
        flex(1)
        display(.flex)
      }
      descendant(".pagination-previous-container") { justifyContent(.flexStart) }
      descendant(".pagination-next-container") { justifyContent(.flexEnd) }
      selector(
        "&.pagination-size-small .pagination-previous-container", "&.pagination-size-small .pagination-next-container"
      ) {
        flex(0)
        marginInline(px(-8))
      }
      selector(".pagination-prev", ".pagination-next") {
        display(.flex)
        alignItems(.center)
        justifyContent(.center)
        width(minSizeInteractiveTouch)
        height(minSizeInteractiveTouch)
        padding(0)
        margin(0)
        color(colorBase)
        textDecoration(.none)
        borderRadius(borderRadiusBase)
        border(.none)
        backgroundColor(.transparent)
        cursor(.pointer)
        boxSizing(.borderBox)
      }
      selector("&.pagination-size-small .pagination-prev", "&.pagination-size-small .pagination-next") {
        width(ButtonView.ButtonSize.small.minSize)
        height(ButtonView.ButtonSize.small.minSize)
        borderRadius(0)
      }
      selector(".pagination-prev.pagination-disabled", ".pagination-next.pagination-disabled") {
        color(colorSubtle)
        opacity(0.5)
        pointerEvents(.none)
        cursor(cursorNotAllowed)
      }
      selector(
        "&.pagination-size-small .pagination-prev.pagination-disabled", "&.pagination-size-small .pagination-next.pagination-disabled"
      ) {
        color(colorDisabled)
        opacity(1)
      }
      selector(".pagination-prev:focus", ".pagination-next:focus") {
        outline(borderWidthBase, .solid, colorBlueFocus).important()
        outlineOffset(px(2)).important()
      }
      selector(
        "&.pagination-size-small .pagination-prev:focus", "&.pagination-size-small .pagination-next:focus"
      ) {
        outline(.none).important()
      }
      descendant(".pagination-indicator") {
        display(.flex)
        flexDirection(.row)
        alignItems(.center)
        justifyContent(.center)
        gap(spacing12)
      }
      selector("&.pagination-size-small .pagination-indicator") {
        gap(spacing6)
      }
      descendant(".page-box") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorBase)
        fontWeight(fontWeightNormal)
        padding(spacing0, spacing8)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        backgroundColor(backgroundColorBase)
        height(minSizeInteractiveTouch)
        textAlign(.center)
        display(.inlineBlock)
        transition(.borderColor, s(0.2), .ease)
        outline(.none)
        boxSizing(.borderBox)
        mozAppearance(.textfield)
        webkitAppearance(.none)
        margin(0)
      }
      selector("&.pagination-size-small .page-box") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeMedium16)
        padding(0, spacing4)
        borderColor(borderColorBase)
        height(ButtonView.ButtonSize.small.minSize)
        transition(.none)
      }
      descendant(".page-box[data-input-width='\(inputWidth.value)']") { width(inputWidth) }
      selector(
        "input.page-box[type=number]::-webkit-outer-spin-button",
        "input.page-box[type=number]::-webkit-inner-spin-button"
      ) {
        webkitAppearance(.none).important()
        margin(0).important()
        display(.none).important()
      }
      descendant(".page-box:focus") {
        borderColor(colorBlue).important()
        boxShadow(0, 0, 0, px(2), colorBlueFocus)
      }
      descendant(".page-box:hover") { borderColor(borderColorBase) }
      descendant(".pagination-term") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeXSmall12)
        color(colorBase)
        fontWeight(fontWeightNormal)
        whiteSpace(.nowrap)
      }
      descendant(".pagination-total") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorSubtle)
        fontWeight(fontWeightNormal)
        whiteSpace(.nowrap)
      }
      selector("&.pagination-size-small .pagination-term") { fontSize(fontSizeMedium16) }
      selector("&.pagination-size-small .pagination-total") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeMedium16)
        color(colorBase)
      }
    }
  }
}

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  public class PaginationHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: PaginationHydration?

    public init() {
      hydrate()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".pagination-view") != nil else { return }
      instance = PaginationHydration()
    }

    private func hydrate() {
      let paginationViews = document.querySelectorAll(".pagination-view")
      for view in paginationViews {
        // Host-owned pagers (session / attempt)—skip URL navigation.
        let kind = view.getAttribute("data-pager-kind") ?? ""
        if !stringIsEmpty(kind) { continue }

        let inputEl = view.querySelector(".page-box")
        _ = inputEl?.addEventListener(.keydown) { [self] (event: Event) in
          let key = event.key
          if stringEquals(key, "ArrowUp") {
            event.preventDefault()
            guard let input = inputEl as? HTML.HTMLInputElement else { return }
            let cur = parseInt(input.value) ?? 1
            let maxAttr = input.getAttribute("max") ?? ""
            let maxVal = stringIsEmpty(maxAttr) ? 999999 : (parseInt(maxAttr) ?? 999999)
            let next = min(cur + 1, maxVal)
            input.value = intToString(next)
            return
          }
          if stringEquals(key, "ArrowDown") {
            event.preventDefault()
            guard let input = inputEl as? HTML.HTMLInputElement else { return }
            let cur = parseInt(input.value) ?? 1
            let minAttr = input.getAttribute("min") ?? ""
            let minVal = stringIsEmpty(minAttr) ? 1 : (parseInt(minAttr) ?? 1)
            let next = max(cur - 1, minVal)
            input.value = intToString(next)
            return
          }
          let allowed =
            stringEquals(key, "Enter") || stringEquals(key, "Backspace")
            || stringEquals(key, "Delete") || stringEquals(key, "Tab")
            || stringEquals(key, "ArrowLeft") || stringEquals(key, "ArrowRight")
            || (key.utf8.count == 1 && key.utf8.first.map { $0 >= 48 && $0 <= 57 } ?? false)
          if !allowed {
            event.preventDefault()
            return
          }
          if stringEquals(key, "Enter") {
            event.preventDefault()
            guard let input = (inputEl as? HTML.HTMLInputElement) else { return }
            self.navigateToPage(input.value, in: view)
          }
        }

        _ = inputEl?.addEventListener(.change) { [self] (event: Event) in
          guard let input = (inputEl as? HTML.HTMLInputElement) else { return }
          self.navigateToPage(input.value, in: view)
        }

        _ = inputEl?.addEventListener(.blur) { (event: Event) in
          guard let input = (inputEl as? HTML.HTMLInputElement) else { return }
          if stringIsEmpty(input.value) {
            // Back to the page it stands on, as the server wrote it.
            input.value = input.getAttribute("value") ?? "1"
          }
        }
      }
    }

    private func navigateToPage(_ page: String, in view: DOM.Element) {
      guard !stringIsEmpty(page) else { return }

      let currentUrl = window.location.href

      if stringContains(currentUrl, "page=") {
        window.location.href = self.replacePageNumber(in: currentUrl, with: page)
        return
      }

      let patternLink = view.querySelector("a[href*='page=']")
      if let firstLink = patternLink {
        let pattern = firstLink.getAttribute("href") ?? ""
        if stringContains(pattern, "page=") {
          window.location.href = self.replacePageNumber(in: pattern, with: page)
          return
        }
      }

      if stringContains(currentUrl, "?") {
        window.location.href = "\(currentUrl)&page=\(page)"
      } else {
        window.location.href = "\(currentUrl)?page=\(page)"
      }
    }

    private func replacePageNumber(in url: String, with newPage: String) -> String {
      let key = "page="
      guard let idx = stringIndexOf(url, key) else { return url }

      let prefix = stringSubstring(url, from: 0, to: idx + 5)
      let suffix = stringSubstring(url, from: idx + 5)

      let bytes = Array(suffix.utf8)
      var i = 0
      while i < bytes.count && bytes[i] >= 48 && bytes[i] <= 57 {
        i += 1
      }
      let remaining = stringSubstring(suffix, from: i)

      return "\(prefix)\(newPage)\(remaining)"
    }
  }
#endif
