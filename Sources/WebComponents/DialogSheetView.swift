#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A dialog in a sheet (`SheetView`): its title and a close button in a
  /// header that stays, what it holds under them, scrolling (user,
  /// 2026-10-08). A gloss is one (`GlossSheetView`), over the reader's pane
  /// it was opened in; a faded value shown whole is one (`EdgeFadeSheetView`),
  /// over the pane that holds it, or the screen.
  ///
  /// What it covers is the nearest box marked `data-sheet-host` around what
  /// opened it, or, with none, the screen: `DialogSheet` on the client moves
  /// it there, opens and closes it, takes Esc, the close button and the
  /// backdrop, keeps Tab inside it while it is open, and gives the focus back
  /// to what opened it.
  public struct DialogSheetView: HTMLContent {
    let `class`: String
    let ariaLabel: String
    let title: [DOM.Node]
    let content: [DOM.Node]

    /// `class` goes on the sheet (`.sheet-view`), so a page's rules and its
    /// client find this one dialog among others.
    public init(
      class: String, ariaLabel: String,
      @HTMLBuilder title: () -> [DOM.Node] = { [] },
      @HTMLBuilder content: () -> [DOM.Node] = { [] }
    ) {
      self.class = `class`
      self.ariaLabel = ariaLabel
      self.title = title()
      self.content = content()
    }

    public func build() -> DOM.Node {
      div {
        SheetView(class: "dialog-sheet \(`class`)", placement: .pane) {
          div {
            div {
              div { title }
                .class("dialog-sheet-title")
              CloseButtonView(ariaLabel: "Close", class: "dialog-sheet-close")
            }
            .class("dialog-sheet-header")
            div { content }
              .class("dialog-sheet-body")
          }
          .class("dialog-sheet-content")
          .role("dialog")
          .ariaModal(true)
          .ariaLabel(ariaLabel)
        }
      }
      .class("dialog-sheet-view")
      .style {
        selector("&") {
          display(.contents)
        }
        // Over a pane, the panel is the pane: its header stays, its body
        // scrolls.
        descendant(".dialog-sheet-content") {
          display(.flex)
          flexDirection(.column)
          gap(spacing16)
          flex(1)
          minHeight(0)
          paddingInline(spacing16)
        }
        descendant(".dialog-sheet-header") {
          display(.flex)
          alignItems(.flexStart)
          justifyContent(.spaceBetween)
          gap(spacing12)
          flexShrink(0)
        }
        descendant(".dialog-sheet-title") {
          flex(1)
          minWidth(0)
        }
        descendant(".dialog-sheet-body") {
          flex(1)
          minHeight(0)
          overflowY(.auto)
        }
        descendant(".dialog-sheet-body:empty") {
          display(.none)
        }
      }
      .style(prefix: false) {
        // The pane a sheet covers holds still under it: the sheet sits over
        // what the pane shows, from where it had scrolled to.
        selector("[data-sheet-covered='true']") {
          position(.relative).important()
          overflow(.hidden).important()
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// A `DialogSheetView` on the client: opened over what it covers, closed
  /// by Esc, its close button or its backdrop, Tab kept inside it while it
  /// is open, the focus given back to what opened it. Its listeners are the
  /// document's, and act only while it is open.
  public final class DialogSheet: @unchecked Sendable {
    /// The view (`.dialog-sheet-view`).
    public let view: DOM.Element
    /// What moves to the host: the view, or the component wrapping it, whose
    /// rules hold only inside it.
    private let moving: DOM.Element
    /// The sheet in it (`.sheet-view`).
    public let sheet: DOM.Element
    /// Called as it closes.
    public var onClose: (() -> Void)?
    /// What it covers; nil for the screen.
    private var host: DOM.Element?
    /// What opened it, which has the focus again when it closes.
    public private(set) var opener: DOM.Element?

    /// The dialog of `view` (`.dialog-sheet-view`), moved to its host with
    /// `moving` (a component wrapping it), else alone; nil when it holds
    /// none.
    public init?(view: DOM.Element, moving: DOM.Element? = nil) {
      guard let sheet = view.querySelector(".dialog-sheet") else { return nil }
      self.view = view
      self.moving = moving ?? view
      self.sheet = sheet
      _ = document.addEventListener(.click) { [self] event in
        self.click(event)
      }
      _ = document.addEventListener(.keydown) { [self] event in
        self.key(event)
      }
      // One thing at a time: a menu over the page closes it.
      _ = document.addEventListener("ellipsis-menu-opened") { [self] _ in
        if self.isOpen { self.close(fromKeyboard: false) }
      }
      _ = document.addEventListener("search-menu-opened") { [self] _ in
        if self.isOpen { self.close(fromKeyboard: false) }
      }
    }

    public var isOpen: Bool { SheetMotion.isOpen(sheet) }

    /// Its title (`.dialog-sheet-title`), its body (`.dialog-sheet-body`)
    /// and the dialog itself (`.dialog-sheet-content`).
    public var title: DOM.Element? { sheet.querySelector(".dialog-sheet-title") }
    public var body: DOM.Element? { sheet.querySelector(".dialog-sheet-body") }
    public var content: DOM.Element? { sheet.querySelector(".dialog-sheet-content") }

    /// Where a sheet opened from `element` goes: the nearest box around it
    /// marked `data-sheet-host`; nil for the screen.
    public static func host(of element: DOM.Element) -> DOM.Element? {
      element.closest("[data-sheet-host]")
    }

    /// Opens it over `host` (nil: the screen), from where the host had
    /// scrolled to, from `opener`, and puts the focus on its close button,
    /// its ring shown when it was opened from the keyboard. Open already, it
    /// moves.
    public func open(over host: DOM.Element?, opener: DOM.Element?, fromKeyboard: Bool = false) {
      if let previous = self.host {
        var same = false
        if let host { same = previous.id == host.id }
        if !same { previous.removeAttribute(data("sheet-covered")) }
      }
      self.host = host
      if let host {
        if !host.contains(moving) { host.appendChild(moving) }
        host.setAttribute(data("sheet-covered"), "true")
        sheet.setAttribute(data("placement"), "pane")
        sheet.style.setProperty("top", "\(Int(host.scrollTop))px")
      } else {
        if let _ = moving.closest("[data-sheet-host]") { document.body.appendChild(moving) }
        sheet.setAttribute(data("placement"), "viewport")
        sheet.style.setProperty("top", "0px")
      }
      self.opener?.setAttribute("aria-expanded", "false")
      self.opener = opener
      opener?.setAttribute("aria-expanded", "true")
      if !isOpen { SheetMotion.open(sheet) }
      // Without a scroll: the panel slides in from above its host, and the
      // page would jump up to where it starts.
      sheet.querySelector(".dialog-sheet-close")?.focus(DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard))
    }

    /// What opened it has the focus again; its focus ring shows only when
    /// it was closed from the keyboard.
    public func close(fromKeyboard: Bool) {
      SheetMotion.close(sheet)
      host?.removeAttribute(data("sheet-covered"))
      opener?.setAttribute("aria-expanded", "false")
      opener?.focus(DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard))
      onClose?()
    }

    private func click(_ event: Event) {
      guard isOpen, let target = event.target, let inside = target.closest(".dialog-sheet") else { return }
      guard inside.id == sheet.id else { return }
      if let _ = target.closest(".dialog-sheet-close") {
        close(fromKeyboard: false)
      } else if target.classList.contains("sheet-backdrop") {
        close(fromKeyboard: false)
      }
    }

    private func key(_ event: Event) {
      guard isOpen else { return }
      let key = event.key
      if stringEquals(key, "Escape") {
        event.preventDefault()
        close(fromKeyboard: true)
      } else if stringEquals(key, "Tab") {
        trapTab(event)
      } else if stringEquals(key, "ArrowLeft") || stringEquals(key, "ArrowRight") {
        // A reader under it pages on these.
        event.stopPropagation()
      }
    }

    /// Tab stays in the dialog while it is open, coming round at either end.
    private func trapTab(_ event: Event) {
      guard let content else { return }
      let focusable = content.querySelectorAll(
        "button:not([disabled]), [href], summary, [tabindex]:not([tabindex=\"-1\"])")
      guard !focusable.isEmpty, let active = document.activeElement else { return }
      let first = focusable[0]
      let last = focusable[focusable.count - 1]
      guard let inside = active.closest(".dialog-sheet-content"), inside.id == content.id else {
        event.preventDefault()
        first.focus()
        return
      }
      if event.shiftKey {
        if active.id == first.id {
          event.preventDefault()
          last.focus()
        }
      } else if active.id == last.id {
        event.preventDefault()
        first.focus()
      }
    }
  }
#endif
