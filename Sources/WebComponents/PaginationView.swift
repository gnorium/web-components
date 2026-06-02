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

public struct PaginationView: HTMLContent {
  public let previousUrl: String?
  public let nextUrl: String?
  public let pageNumbers: [PageNumber]?
  public let totalPages: Int
  let `class`: String

  public struct PageNumber: Sendable {
    public let label: String
    public let url: String
    public let isActive: Bool

    public init(label: String, url: String, isActive: Bool = false) {
      self.label = label
      self.url = url
      self.isActive = isActive
    }
  }

  public init(
    previousUrl: String? = nil,
    nextUrl: String? = nil,
    pageNumbers: [PageNumber]? = nil,
    totalPages: Int = 0,
    class: String = ""
  ) {
    self.previousUrl = previousUrl
    self.nextUrl = nextUrl
    self.pageNumbers = pageNumbers
    self.totalPages = totalPages
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    let activePage = pageNumbers?.first(where: { $0.isActive })
    let currentPage = activePage.flatMap { Int($0.label) } ?? 1
    let totalPages = totalPages > 0 ? totalPages : (pageNumbers?.count ?? 0)

    // Calculate dynamic width based on total pages digit count
    let totalPagesStr = "\(totalPages)"
    let digitCount = totalPagesStr.utf8.count
    let inputWidth = calc(ch(digitCount) + px(20))  // Buffer for padding and numeric controls

    return section {
      // Previous link
      div {
        if let prevHref = previousUrl {
          a {
            PreviousIconView(width: px(16), height: px(16))
          }
          .class("pagination-prev")
          .href(prevHref)
          .ariaLabel("Previous page")
          .style {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
            width(px(44))
            height(px(44))
            color(colorBase)
            textDecoration(.none)
            borderRadius(borderRadiusBase)
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, colorBlueFocus).important()
              outlineOffset(px(2)).important()
            }
          }
        }
      }
      .style {
        flex(1)
        display(.flex)
        justifyContent(.flexStart)
      }

      // Page Indicator (center)
      div {
        // Current Page Input (Editable)
        input()
          .type(.number)
          .value("\(currentPage)")
          .class("page-box")
          .min(1)
          .max(totalPages)
          .style {
            fontFamily(typographyFontSans)
            fontSize(fontSizeMedium16)
            color(colorBase)
            fontWeight(fontWeightNormal)
            padding(spacing0, spacing8)
            border(borderWidthBase, .solid, borderColorSubtle)
            borderRadius(borderRadiusBase)
            backgroundColor(backgroundColorBase)
            width(inputWidth)
            height(px(44))
            textAlign(.center)
            display(.inlineBlock)
            transition(.borderColor, s(0.2), .ease)
            outline(.none)
            boxSizing(.borderBox)

            // Hide arrows/spinners across all browsers
            webkitAppearance(.none)
            mozAppearance(.textfield)
            margin(0)

            // Handle webkit spinners
            pseudoElement(.webkitOuterSpinButton) {
              webkitAppearance(.none)
              margin(0)
            }
            pseudoElement(.webkitInnerSpinButton) {
              webkitAppearance(.none)
              margin(0)
            }

            pseudoClass(.focus) {
              borderColor(colorBlue).important()
              boxShadow(0, 0, 0, px(2), colorBlueFocus)
            }

            pseudoClass(.hover) {
              borderColor(borderColorBase)
            }
          }

        // "of [Total]"
        span { "of \(formatNumberWithCommas(totalPages))" }
          .style {
            fontFamily(typographyFontSans)
            fontSize(fontSizeMedium16)
            color(colorSubtle)
            fontWeight(fontWeightNormal)
            whiteSpace(.nowrap)
          }

        // Hidden links for hydration mapping (crucial for non-standard paths)
        div {
          for pageNumber in pageNumbers ?? [] {
            a { pageNumber.label }
              .href(pageNumber.url)
              .data("page", pageNumber.label)
          }
        }
        .style { display(.none) }
      }
      .style {
        display(.flex)
        flexDirection(.row)
        alignItems(.center)
        justifyContent(.center)
        gap(spacing12)
      }

      // Next link
      div {
        if let nextHref = nextUrl {
          a {
            NextIconView(width: px(16), height: px(16))
          }
          .class("pagination-next")
          .href(nextHref)
          .ariaLabel("Next page")
          .style {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
            width(px(44))
            height(px(44))
            color(colorBase)
            textDecoration(.none)
            borderRadius(borderRadiusBase)
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, colorBlueFocus).important()
              outlineOffset(px(2)).important()
            }
          }
        }
      }
      .style {
        flex(1)
        display(.flex)
        justifyContent(.flexEnd)
      }
    }
    .class(stringIsEmpty(`class`) ? "pagination-view" : "pagination-view \(`class`)")
    .style {
      display(.flex)
      flexDirection(.row)
      justifyContent(.spaceBetween)
      alignItems(.center)
      maxWidth(px(600))
      margin(0, .auto)
      gap(spacing16)
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
    public init() {
      hydrate()
    }

    private func hydrate() {
      let paginationViews = document.querySelectorAll(".pagination-view")
      for view in paginationViews {
        let inputEl = view.querySelector(".page-box")
        // Change on Enter key
        _ = inputEl?.addEventListener(.keydown) { [self] (event: Event) in
          if stringEquals(event.key, "Enter") {
            event.preventDefault()
            guard let input = (inputEl as? HTML.HTMLInputElement) else { return }
            self.navigateToPage(input.value, in: view)
          }
        }

        // Also handle 'change' event for broader compatibility
        _ = inputEl?.addEventListener(.change) { [self] (event: Event) in
          guard let input = (inputEl as? HTML.HTMLInputElement) else { return }
          self.navigateToPage(input.value, in: view)
        }
      }
    }

    private func navigateToPage(_ page: String, in view: DOM.Element) {
      guard !stringIsEmpty(page) else { return }

      // 1. Try to find a link with matching data-page (robust path-independent matching)
      let allLinks = view.querySelectorAll("a[data-page]")
      for link in allLinks {
        if let dataPage = link.getAttribute("data-page") {
          if stringEquals(dataPage, page) {
            if let href = link.getAttribute("href") {
              window.location.href = href
              return
            }
          }
        }
      }

      let currentUrl = window.location.href

      // 2. If current URL already has page=, just replace it
      if stringContains(currentUrl, "page=") {
        window.location.href = self.replacePageNumber(in: currentUrl, with: page)
        return
      }

      // 3. Try to find any other page link to copy the URL pattern (for tables)
      let patternLink = view.querySelector("a[href*='page=']")
      if let firstLink = patternLink {
        let pattern = firstLink.getAttribute("href") ?? ""
        if stringContains(pattern, "page=") {
          window.location.href = self.replacePageNumber(in: pattern, with: page)
          return
        }
      }

      // 4. Final Fallback: Append page= to current URL
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
      while i < bytes.count && bytes[i] >= 48 && bytes[i] <= 57 {  // ASCII '0'-'9'
        i += 1
      }
      let remaining = stringSubstring(suffix, from: i)

      return "\(prefix)\(newPage)\(remaining)"
    }
  }
#endif
