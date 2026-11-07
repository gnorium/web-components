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
  /// opened it (a positioned box), or, with none, the screen: `DialogSheet` on the client moves
  /// it there, opens and closes it, takes Esc, the close button and the
  /// backdrop, keeps Tab inside it while it is open, and gives the focus back
  /// to what opened it. On a wide screen it may open as a popover instead
  /// (user, 2026-11-01: `DialogSheet.pop`), anchored beside what opened it,
  /// with no backdrop: Esc, its close button or a click outside closes it.
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
        // what the pane shows, from where it had scrolled to. A host is
        // positioned itself (relative, or absolute as a reader's pane frame
        // is laid beside its image): forced relative here, a reader's
        // absolute frame fell into the flow and grew over the image pane
        // (user, 2026-10-14).
        // A marked host (`data-sheet-host`, a reader's pane frame) neither
        // scrolls nor zooms and clips (`overflow: clip`): made hidden here it
        // became a box a focus could scroll sideways, its pane left cut off
        // at its start (user, 2026-11-05). It is left as it is.
        selector("[data-sheet-covered='true']:not([data-sheet-host])") {
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
    /// Where a popover stands beside: the box it was anchored to, kept so it
    /// can be placed again once what it holds has grown; nil while it is a
    /// sheet.
    private var anchor: DOM.Rect?
    /// Whether its popover follows its opener as the page scrolls (it was
    /// anchored to it); else a scroll closes it.
    private var followsOpener = false
    /// Whether the click that opened the popover is still on its way up:
    /// that click is never one outside it.
    private var opening = false

    /// Whether a sheet opened here opens as a popover: on a wide screen,
    /// past the tablet breakpoint (`minWidthBreakpointTablet`); a narrow one
    /// keeps the sheet (user, 2026-11-01).
    public static var popsOver: Bool { window.matchMedia("(min-width: 769px)") }

    /// Whether it is open as a popover.
    public var isPopover: Bool {
      guard isOpen, let _ = anchor else { return false }
      return true
    }

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
      // A popover stays by what it stands beside: placed again as the page
      // or a pane scrolls (closed when it stood by a point), never on a
      // scroll inside it.
      _ = document.addEventListener(.scroll, { [self] event in
        guard self.isPopover else { return }
        if let target = event.target, let _ = target.closest(".dialog-sheet") { return }
        if self.followsOpener, let opener = self.opener, let box = opener.getBoundingClientRect() {
          self.anchor = box
          self.place()
        } else {
          self.close(fromKeyboard: false)
        }
      }, capture: true)
      _ = window.addEventListener(.resize) { [self] _ in
        if self.isPopover { self.place() }
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
      anchor = nil
      _ = sheet.style.removeProperty("left")
      _ = sheet.style.removeProperty("right")
      content?.setAttribute("aria-modal", "true")
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

    /// Opens it as a popover (user, 2026-11-01), over the page with no
    /// backdrop, beside `box` (what opened it, or the point it was opened
    /// at): below it where there is room, else above, its start edge at the
    /// box's start (its end in right-to-left text), kept inside the screen.
    /// `follows`: the box is `opener`'s, which it stays by as the page
    /// scrolls. The focus goes to its close button, as a sheet's does
    /// (only a click, a tap or a key opens one, user, 2026-11-01). Open
    /// already, it moves.
    public func pop(at box: DOM.Rect, opener: DOM.Element?, follows: Bool, fromKeyboard: Bool = false) {
      if let previous = host { previous.removeAttribute(data("sheet-covered")) }
      host = nil
      if let _ = moving.closest("[data-sheet-host]") { document.body.appendChild(moving) }
      sheet.setAttribute(data("placement"), "popover")
      content?.setAttribute("aria-modal", "false")
      anchor = box
      followsOpener = follows
      opening = true
      _ = window.setTimeout(0) { [self] in self.opening = false }
      self.opener?.setAttribute("aria-expanded", "false")
      self.opener = opener
      opener?.setAttribute("aria-expanded", "true")
      if !isOpen { SheetMotion.open(sheet) }
      place()
      sheet.querySelector(".dialog-sheet-close")?.focus(
        DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard))
    }

    /// Places a popover again beside its box, as large as it now is (what
    /// it holds may have arrived since it opened).
    public func place() {
      guard let box = anchor, let panel = sheet.querySelector(".sheet-panel"),
        let size = panel.getBoundingClientRect()
      else { return }
      let gutter = 16.0
      let gap = 8.0
      let width = window.innerWidth
      let height = window.innerHeight
      let rightToLeft: Bool = {
        if let opener, let _ = opener.closest("[dir='rtl']") { return true }
        return false
      }()
      var left = rightToLeft ? box.right - size.width : box.left
      left = Swift.max(gutter, Swift.min(left, width - size.width - gutter))
      var top = box.bottom + gap
      if top + size.height > height - gutter {
        let above = box.top - gap - size.height
        if above >= gutter {
          top = above
        } else {
          // Room on neither side: where there is more, kept on the screen.
          top = box.top > height - box.bottom ? gutter : Swift.max(gutter, height - gutter - size.height)
        }
      }
      sheet.style.setProperty("left", "\(Int(left))px")
      sheet.style.setProperty("right", "auto")
      sheet.style.setProperty("top", "\(Int(top))px")
    }

    /// What opened it has the focus again; its focus ring shows only when
    /// it was closed from the keyboard.
    public func close(fromKeyboard: Bool) {
      SheetMotion.close(sheet)
      host?.removeAttribute(data("sheet-covered"))
      opener?.setAttribute("aria-expanded", "false")
      // A popover the focus never entered leaves it where it is.
      var refocuses = true
      if let _ = anchor {
        refocuses = false
        if let active = document.activeElement, let inside = active.closest(".dialog-sheet"), inside.id == sheet.id {
          refocuses = true
        }
      }
      if refocuses { opener?.focus(DOM.FocusOptions(preventScroll: true, focusVisible: fromKeyboard)) }
      anchor = nil
      onClose?()
    }

    private func click(_ event: Event) {
      guard isOpen, let target = event.target else { return }
      // A popover closes on a click outside it and what opened it.
      guard let inside = target.closest(".dialog-sheet") else {
        if isPopover, !opening {
          if let opener, opener.contains(target) { return }
          close(fromKeyboard: false)
        }
        return
      }
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
        // A popover holds nothing modal: Tab moves on.
        if !isPopover { trapTab(event) }
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
        focusInside(first)
        return
      }
      if event.shiftKey {
        if active.id == first.id {
          event.preventDefault()
          focusInside(last)
        }
      } else if active.id == last.id {
        event.preventDefault()
        focusInside(first)
      }
    }

    /// `element` focused from the keyboard, its ring shown, and brought into
    /// view in the dialog's body alone (`ScrollPort.reveal`): a focus that
    /// scrolls its own way scrolls every box around the dialog too, the
    /// pane and the page under it among them (user, 2026-11-05).
    private func focusInside(_ element: DOM.Element) {
      element.focus(DOM.FocusOptions(preventScroll: true, focusVisible: true))
      if let body { ScrollPort.reveal(element, in: body) }
    }
  }
#endif
