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
/// - ``Size/medium``—chrome pagers (session, artifact, instance switcher,
///   legends): ButtonView's medium, 40px targets, 16px text, 16px chevrons;
///   on a phone small, as every control (`ButtonView.phoneStep`): 32px
///   targets, 14px text
///
/// URL mode (`previousUrl` / `nextUrl`) is hydrated by
/// ``PaginationHydration``. Query / custom mode sets `kind` and prev/next
/// `data` attributes; the host page binds those (e.g. SessionHydration).
public struct PaginationView: HTMLContent {
  public enum Size: String, Sendable {
    case normal
    case medium
    /// A dialog's table's pager (user, 2026-10-12): its text a large
    /// control's 18px, its targets and number box 48; on a phone, medium
    /// (`ButtonView.phoneStep`).
    case large
  }

  /// Rows a page, every paged list and table on the site alike (user,
  /// 2026-10-11): the one number each pages by.
  public static let perPage = 100

  /// Options a dropdown or combobox lists at most, every option list on
  /// the site alike: as many as a page's rows (user, 2026-11-05). A list
  /// cut short ends in a note ("Showing the first 100.").
  public static let perList = perPage

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
  /// What stands between the chevrons in place of the page number and its
  /// total, itself and unwrapped: a stepper's own control (a tree's "+
  /// Testament 1.2." button, user 2026-11-03). Empty draws the page number.
  let indicator: [DOM.Node]
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
    class: String = "",
    @HTMLBuilder indicator: () -> [DOM.Node] = { [] }
  ) {
    self.indicator = indicator()
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
    // The chrome size (medium) sets "of" and the total apart and keeps its
    // chevrons beside the number.
    let chrome: Bool
    switch size {
    case .normal: chrome = false
    case .medium, .large: chrome = true
    }
    // The number box's inset: its control size's.
    let inset: CSS.Length
    switch size {
    case .large: inset = ButtonView.ButtonSize.large.padding
    default: inset = spacing8
    }
    // The number, the box's inset at both sides (a medium control's 8)
    // and its border; a sans number's figures run a little wider than a
    // mono `ch`.
    let inputWidth = chrome
      ? calc("\(ch(digitCount).value) + \(inset.value) * 2 + \(borderWidthBase.value) * 2")
      : calc("\(ch(digitCount).value) + \(spacing8.value) * 2 + \(borderWidthBase.value) * 2 + \(spacing4.value)")
    let useButtons = stringEquals(previousUrl, nil) && stringEquals(nextUrl, nil) && showControls
    // Its chevrons (user, 2026-11-03): subtle icon-only circles one size
    // smaller than the control between them—a large one's medium, a
    // medium one's small—stepping down with it on a phone
    // (`ButtonView.phoneStep`): a link where it pages by URL, a button
    // where its page binds it, disabled where there is no page that way.
    // `pagination-prev` / `pagination-next` name them for the pages that
    // bind them, `pagination-disabled` marks one disabled.
    let chevronSize: ButtonView.ButtonSize
    switch size {
    case .large: chevronSize = .medium
    case .medium, .normal: chevronSize = .small
    }
    func chevron(next: Bool) -> DOM.Node {
      let url = next ? nextUrl : previousUrl
      let disabled = stringEquals(url, nil) && (!useButtons || (next ? nextDisabled : previousDisabled))
      let base = next ? "pagination-next" : "pagination-prev"
      let classes = disabled ? stringJoin([base, "pagination-disabled"], separator: " ") : base
      if next {
        return ButtonView(
          icon: ChevronRightIconView(size: chevronSize.iconSize), weight: .subtle, size: chevronSize,
          disabled: disabled, url: url, ariaLabel: nextAriaLabel, class: classes, borderRadius: .circle,
          data: nextData
        ).build()
      }
      return ButtonView(
        icon: ChevronLeftIconView(size: chevronSize.iconSize), weight: .subtle, size: chevronSize,
        disabled: disabled, url: url, ariaLabel: previousAriaLabel, class: classes, borderRadius: .circle,
        data: previousData
      ).build()
    }

    let sizeClass = "pagination-size-\(size.rawValue)"
    let rootClass = stringIsEmpty(`class`)
      ? stringJoin(["pagination-view", sizeClass], separator: " ")
      : stringJoin(["pagination-view", sizeClass, `class`], separator: " ")

    return section {
      if showControls {
        div {
          chevron(next: false)
        }
        .class("pagination-previous-container")
      }

      if !indicator.isEmpty {
        // A stepper's own control, itself between the chevrons.
        indicator
      } else {
        div {
          if let inputID {
            input()
              .type(.number)
              .id(inputID)
              .name("page")
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
              .name("page")
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
      }

      if showControls {
        div {
          chevron(next: true)
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
        // Its parts (chevron, indicator, chevron) apart by half its size
        // step's (user, 2026-11-03): 8 round a large control (48), 4 round
        // a medium one (40), 2 round a small one (32), on a phone too.
        gap(spacing4)
      }
      // Every pager medium (user, 2026-10-10): its text a medium
      // control's 16px, its targets and number box 40.
      selector("&.pagination-size-medium") {
        justifyContent(.flexStart)
        maxWidth(.none)
        margin(0)
        gap(spacing4)
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
        "&.pagination-size-medium .pagination-previous-container", "&.pagination-size-medium .pagination-next-container",
        "&.pagination-size-large .pagination-previous-container", "&.pagination-size-large .pagination-next-container"
      ) {
        flex(0)
      }
      descendant(".pagination-indicator") {
        display(.flex)
        flexDirection(.row)
        alignItems(.center)
        justifyContent(.center)
        gap(spacing8)
      }
      descendant(".page-box") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        color(colorBase)
        fontWeight(fontWeightNormal)
        // A medium control: 8 on every side of the 22px line, 40.
        padding(ButtonView.ButtonSize.medium.padding)
        lineHeight(lineHeightSmall22)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        backgroundColor(backgroundColorBase)
        textAlign(.center)
        display(.inlineBlock)
        transition(.borderColor, s(0.2), .ease)
        outline(.none)
        boxSizing(.borderBox)
        mozAppearance(.textfield)
        webkitAppearance(.none)
        margin(0)
      }
      // 16, as the pager's text (and iOS Safari zooms the page into an
      // input under 16 as it takes focus): 8 + 22 + 8 + the border, 40.
      selector("&.pagination-size-medium .page-box") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeMedium16)
        // A medium control: 8 on every side, 40.
        padding(ButtonView.ButtonSize.medium.padding)
        borderColor(borderColorBase)
        transition(.none)
      }
      descendant(".page-box[data-input-width='\(inputWidth.value)']") { width(inputWidth) }
      // In a part drawn disabled (`DisabledRegion`), its page box a
      // disabled field: the disabled ground and border, its number in the
      // base color; its chevrons disabled buttons (`ButtonView`).
      selector(":where([data-disabled-region='true']) & .page-box") {
        backgroundColor(backgroundColorDisabled).important()
        borderColor(borderColorDisabled).important()
        cursor(cursorNotAllowed)
      }
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
        outline(borderWidthBase, .solid, borderColorBlueFocus)
        outlineOffset(px(0))
      }
      descendant(".page-box:hover") { borderColor(borderColorBase) }
      descendant(".pagination-term") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
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
      selector("&.pagination-size-medium .pagination-term") { fontSize(fontSizeMedium16) }
      selector("&.pagination-size-medium .pagination-total") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeMedium16)
        color(colorBase)
      }
      // Large: 18px text, 48 targets and number box, 12 inside it.
      selector("&.pagination-size-large") {
        justifyContent(.flexStart)
        maxWidth(.none)
        margin(0)
        gap(spacing8)
        flexShrink(0)
        color(colorBase)
        fontFamily(typographyFontSans)
        fontSize(fontSizeLarge18)
        lineHeight(lineHeightSmall22)
      }
      selector("&.pagination-size-large .page-box") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeLarge18)
        padding(ButtonView.ButtonSize.large.padding)
        borderColor(borderColorBase)
        transition(.none)
      }
      selector("&.pagination-size-large .pagination-term") { fontSize(fontSizeLarge18) }
      selector("&.pagination-size-large .pagination-total") {
        fontFamily(typographyFontMono)
        fontSize(fontSizeLarge18)
        color(colorBase)
      }
      // Option B (`ButtonView.phoneStep`): on a phone every pager steps
      // one size down, as every control does—large to medium, medium to
      // small (32, its text 14px)—its buttons, its number box and its gap
      // together.
      media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
        selector("\(ButtonView.phoneStep) &.pagination-size-large") {
          gap(spacing4).important()
        }
        selector("\(ButtonView.phoneStep) &.pagination-size-medium", "\(ButtonView.phoneStep) &.pagination-size-normal") {
          gap(spacing2).important()
        }
        selector("\(ButtonView.phoneStep) &.pagination-size-normal .page-box") {
          padding(ButtonView.ButtonSize.small.padding).important()
          fontSize(fontSizeSmall14).important()
        }
        selector("\(ButtonView.phoneStep) &.pagination-size-normal .pagination-total") {
          fontSize(fontSizeSmall14).important()
        }
        selector("\(ButtonView.phoneStep) &.pagination-size-large .page-box") {
          padding(ButtonView.ButtonSize.medium.padding).important()
          fontSize(fontSizeMedium16).important()
        }
        selector(
          "\(ButtonView.phoneStep) &.pagination-size-large .pagination-term",
          "\(ButtonView.phoneStep) &.pagination-size-large .pagination-total"
        ) {
          fontSize(fontSizeMedium16).important()
        }
        selector("\(ButtonView.phoneStep) &.pagination-size-medium .page-box") {
          padding(ButtonView.ButtonSize.small.padding).important()
          fontSize(fontSizeSmall14).important()
        }
        selector(
          "\(ButtonView.phoneStep) &.pagination-size-medium .pagination-term",
          "\(ButtonView.phoneStep) &.pagination-size-medium .pagination-total"
        ) {
          fontSize(fontSizeSmall14).important()
        }
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
      hydrate(in: document.body)
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".pagination-view") != nil else { return }
      instance = PaginationHydration()
    }

    /// The pagers a fragment brought in after the page was hydrated
    /// (`FragmentHostView`), each bound once.
    public static func hydrate(in root: DOM.Element) {
      if let instance { instance.hydrate(in: root) } else { instance = PaginationHydration() }
    }

    private func hydrate(in root: DOM.Element) {
      let paginationViews = root.querySelectorAll(".pagination-view")
      for view in paginationViews {
        if stringEquals(view.dataset["paginationHydrated"] ?? "", "true") { continue }
        view.dataset["paginationHydrated"] = "true"
        // Host-owned pagers (session / instance)—skip URL navigation.
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

      // A list held in a fragment host (a dialog's table) asks the page
      // into the host, from the list it holds; any other, the page.
      if let host = view.closest("[data-fragment-host-view]") {
        FragmentHostView.load(
          host, url: ViewerZone.zonedIfCounting(PaginationURL.settingPage(page, in: FragmentHostView.url(of: host))))
        return
      }
      // A list counting the reader's days asks again with their zone.
      window.location.href = ViewerZone.zonedIfCounting(PaginationURL.settingPage(page, in: window.location.href))
    }
  }
#endif
