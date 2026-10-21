  import CSSBuilder
  import DesignTokens
  import CSSOMBuilder
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebTypes

  /// A Dialog is a container that is overlaid on a web page or app in order to present necessary information and tasks.
  public struct DialogView: HTMLContent {
    let open: Bool
    let title: String
    let subtitle: String?
    let hideTitle: Bool
    let hideHeader: Bool
    let useCloseButton: Bool
    let closeButtonLabel: String
    let primaryAction: PrimaryAction?
    let defaultAction: DefaultAction?
    let stackedActions: Bool
    let headerContent: [DOM.Node]
    let bodyContent: [DOM.Node]
    let footerContent: [DOM.Node]
    let footerTextContent: [DOM.Node]
    let `class`: String

    public struct PrimaryAction: Sendable {
      let label: String
      let color: ActionColor
      let disabled: Bool
      /// The mark of its verb, before its label, as the button that opened
      /// the dialog wears it.
      let icon: DOM.Node?

      /// Apple HIG color for the dialog action
      public enum ActionColor: String, Sendable {
        case blue
        case red

        // Legacy aliases
        public static let progressive = ActionColor.blue
        public static let destructive = ActionColor.red
      }
      
      public init(label: String, color: ActionColor = .blue, disabled: Bool = false) {
        self.label = label
        self.color = color
        self.disabled = disabled
      }

      /// Legacy init
      public init(label: String, type: ActionColor, disabled: Bool = false) {
        self.label = label
        self.color = type
        self.disabled = disabled
      }
    }

    public struct DefaultAction: Sendable {
      let label: String
      let disabled: Bool
      /// Wears the x before its label: a Cancel (user, 2026-10-21).
      let cancels: Bool

      public init(label: String, disabled: Bool = false) {
        self.label = label
        self.disabled = disabled
        self.cancels = false
      }

      private init(cancels: Bool) {
        self.label = "Cancel"
        self.disabled = false
        self.cancels = cancels
      }

      /// The dialog's Cancel: the x beside its label, at the label's line,
      /// in the button's own colors.
      public static var cancel: DefaultAction { DefaultAction(cancels: true) }
    }

    public init(
      open: Bool = false,
      title: String,
      subtitle: String? = nil,
      hideTitle: Bool = false,
      hideHeader: Bool = false,
      useCloseButton: Bool = false,
      closeButtonLabel: String = "Close",
      primaryAction: PrimaryAction? = nil,
      defaultAction: DefaultAction? = nil,
      stackedActions: Bool = false,
      class: String = "",
      @HTMLBuilder header: () -> [DOM.Node] = { [] },
      @HTMLBuilder body: () -> [DOM.Node],
      @HTMLBuilder footer: () -> [DOM.Node] = { [] },
      @HTMLBuilder footerText: () -> [DOM.Node] = { [] }
    ) {
      self.open = open
      self.title = title
      self.subtitle = subtitle
      self.hideTitle = hideTitle
      self.hideHeader = hideHeader
      self.useCloseButton = useCloseButton
      self.closeButtonLabel = closeButtonLabel
      self.primaryAction = primaryAction
      self.defaultAction = defaultAction
      self.stackedActions = stackedActions
      self.`class` = `class`
      self.headerContent = header()
      self.bodyContent = body()
      self.footerContent = footer()
      self.footerTextContent = footerText()
    }

    public func build() -> DOM.Node {
      let hasCustomHeader = !headerContent.isEmpty
      let hasCustomFooter = !footerContent.isEmpty
      let hasFooterText = !footerTextContent.isEmpty
      let hasActions = primaryAction != nil || defaultAction != nil

      // Default header (when no custom header provided)
      let defaultHeader: DOM.Node = div {
        div {
          div {
            h2 { title }
              .class("dialog-header-title")
              .id("dialog-title")
              .data("hidden", hideTitle)

            if let subtitleText = subtitle {
              p { subtitleText }
                .class("dialog-header-subtitle")
            }
          }
          .class("dialog-header-text")

          if useCloseButton {
            CloseButtonView(
              ariaLabel: closeButtonLabel,
              class: "dialog-close-button"
            )
          }
        }
        .class("dialog-header-title-group")
      }
      .class("dialog-header")
      .data("default", !hasCustomHeader)

      // Default footer (when no custom footer provided)
      let defaultFooter: DOM.Node = div {
        if hasFooterText {
          div { footerTextContent }
            .class("dialog-footer-text")
        }

        if hasActions {
          div {
            // Default action button (comes second visually, but first in DOM for stacked)
            if let defAction = defaultAction {
              div {
                if defAction.cancels {
                  ButtonView(
                    label: defAction.label,
                    icon: IconView(icon: { s in XIconView(size: s) }, size: ButtonView.ButtonSize.large.labelIconSize),
                    buttonColor: .gray,
                    weight: .subtle, size: .large,
                    disabled: defAction.disabled
                  )
                } else {
                  ButtonView(
                    label: defAction.label,
                    buttonColor: .gray,
                    weight: .subtle, size: .large,
                    disabled: defAction.disabled
                  )
                }
              }
              .class("dialog-default-button")
            }

            // Primary action button (comes first visually, but second in DOM for stacked)
            if let primAction = primaryAction {
              div {
                if let icon = primAction.icon {
                  ButtonView(
                    label: primAction.label,
                    icon: icon,
                    buttonColor: primAction.color == .blue ? .blue : .red,
                    weight: .solid, size: .large,
                    disabled: primAction.disabled
                  )
                } else {
                  ButtonView(
                    label: primAction.label,
                    buttonColor: primAction.color == .blue ? .blue : .red,
                    weight: .solid, size: .large,
                    disabled: primAction.disabled
                  )
                }
              }
              .class("dialog-primary-button")
            }
          }
          .class("dialog-footer-actions")
          .data("stacked", stackedActions)
        }
      }
      .class("dialog-footer")
      .data("default", !hasCustomFooter)
      .data("has-footer-text", hasFooterText)

      // A native dialog, opened modally (`DialogView.showModal` on the
      // client): the top layer holds it over everything on the page,
      // whatever the z-index or stacking context it is drawn in (a sticky
      // sidebar or navbar, an accordion raised around it), its backdrop the
      // scrim and the page behind inert. It is the shell's frame, without
      // padding: a press on it and not on what it holds is on the backdrop.
      return dialog {
        div {
          // Header
          if !hideHeader {
            if hasCustomHeader {
              headerContent
            } else {
              defaultHeader
            }
          }

          // Body
          div { bodyContent }
            .class("dialog-body")

          // Footer
          if hasCustomFooter {
            footerContent
          } else if hasFooterText || hasActions {
            defaultFooter
          }
        }
        .class("dialog-shell")
      }
      .open(open)
      .class(stringIsEmpty(`class`) ? "dialog-view" : stringJoin(["dialog-view ", `class`], separator: ""))
      .ariaLabelledby("dialog-title")
      .style {
        // Centered in the screen (the platform's own auto margins, which the
        // page's reset zeroes), 16 from every edge at most.
        selector("&") {
          margin(.auto)
          padding(0)
          border(.none)
          backgroundColor(backgroundColorTransparent)
          color(colorBase)
          maxWidth(calc(perc(100) - spacing32))
          maxHeight(calc(perc(100) - spacing32))
          overflow(.visible)
        }
        selector("&[open]") {
          display(.flex)
          flexDirection(.column)
        }
        selector("&::backdrop") {
          backgroundColor(backgroundColorBackdropDark)
          backdropFilter(blur(px(16)))
          webkitBackdropFilter(blur(px(16)))
        }
        descendant(".dialog-shell") {
          position(.relative)
          display(.flex)
          flexDirection(.column)
          width(min(calc(vw(100) - px(60)), px(900)))
          minHeight(0)
          backgroundColor(backgroundColorBase)
          borderRadius(borderRadiusBase)
          overflow(.hidden)
        }
        descendant(".dialog-header-title") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeLarge18)
          fontWeight(fontWeightSemiBold)
          lineHeight(lineHeightSmall22)
          color(colorBase)
          margin(0)
          wordWrap(.breakWord)
        }
        descendant(".dialog-header-title[data-hidden='true']") {
          position(.absolute)
          width(px(1))
          height(px(1))
          margin(px(-1))
          padding(0)
          overflow(.hidden)
          clip(rect(0, 0, 0, 0))
          whiteSpace(.nowrap)
          borderWidth(0)
        }
        descendant(".dialog-header-subtitle") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          fontWeight(fontWeightNormal)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          margin(0)
          wordWrap(.breakWord)
        }
        descendant(".dialog-header-text") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          flex(1)
          minWidth(0)
        }
        descendant(".dialog-close-button") {
          flexShrink(0)
        }
        descendant(".dialog-header-title-group") {
          display(.flex)
          alignItems(.center)
          gap(spacing16)
          minWidth(0)
        }
        descendant(".dialog-header[data-default='true']") {
          display(.flex)
          flexDirection(.column)
          gap(spacing4)
          // 16px on every outer edge, shared by header, body and footer so
          // their text lines up; 8px from the title to its text, 16px from
          // the text to the buttons; no dividers between them.
          padding(spacing16, spacing16, px(0))
        }
        descendant(".dialog-footer-text") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(colorSubtle)
          margin(0)
        }
        descendant(".dialog-footer-actions") {
          display(.flex)
          gap(spacing12)
        }
        descendant(".dialog-footer-actions[data-stacked='true']") {
          flexDirection(.columnReverse)
          alignItems(.stretch)
        }
        descendant(".dialog-footer-actions[data-stacked='false']") {
          flexDirection(.rowReverse)
          alignItems(.center)
          justifyContent(.flexStart)
        }
        descendant(".dialog-footer[data-default='true']") {
          display(.flex)
          flexDirection(.column)
          gap(spacing12)
          padding(px(0), spacing16, spacing16)
        }
        descendant(".dialog-footer[data-default='true'][data-has-footer-text='false']") {
          flexDirection(.row)
          alignItems(.center)
          justifyContent(.flexEnd)
        }
        descendant(".dialog-body") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightMedium26)
          color(colorBase)
          padding(spacing8, spacing16, spacing16)
          overflowY(.auto)
          flex(1)
          minHeight(0)
        }
      }
      .style(prefix: false) {
        // The page behind a modal holds still.
        selector("body:has(.dialog-view:modal)") {
          overflow(.hidden)
        }
      }
    }
  }
#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Opening and closing a `DialogView` (`.dialog-view`, a `<dialog>`).
  extension DialogView {
    /// Opens `dialog` as a modal (`showModal()`): the top layer holds it
    /// over everything on the page, whatever the z-index or stacking context
    /// it was drawn in, its backdrop the scrim and the rest of the page inert
    /// (no focus, click or scroll). Escape, its close button or a press on
    /// the backdrop close it. However it closes, `opener` (what opened it)
    /// has the focus again: the platform gives it back only to what had it,
    /// and Safari never focuses a clicked button.
    public static func showModal(_ dialog: DOM.Element, opener: DOM.Element? = nil) {
      if DialogHydration.instance == nil { DialogHydration.instance = DialogHydration() }
      DialogHydration.instance?.instance(of: dialog)?.open(opener: opener)
    }

    /// Closes `dialog` (`close()`, firing `close`).
    public static func close(_ dialog: DOM.Element) {
      (dialog as? HTML.HTMLDialogElement)?.close()
    }
  }

  public class DialogHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: DialogHydration?
    private var instances: [Int32: DialogInstance] = [:]

    public init() {
      hydrateAllDialogs()
      hydrateTriggers()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".dialog-view") != nil else { return }
      if let instance { instance.hydrateAllDialogs(); instance.hydrateTriggers() } else { instance = DialogHydration() }
    }

    public static func hydrateNew() { hydrateIfPresent() }

    /// The bound dialog `dialog` is, binding those drawn since.
    fileprivate func instance(of dialog: DOM.Element) -> DialogInstance? {
      if instances[dialog.id] == nil { hydrateAllDialogs() }
      return instances[dialog.id]
    }

    private func hydrateAllDialogs() {
      let allDialogs = document.querySelectorAll(".dialog-view")

      for dialog in allDialogs {
        if stringEquals(dialog.dataset["dialogHydrated"] ?? "", "true") { continue }
        dialog.dataset["dialogHydrated"] = "true"
        let instance = DialogInstance(dialog: dialog)
        let id = dialog.id
        if id > 0 {
          instances[id] = instance
        }
      }
    }

    private func hydrateTriggers() {
      let triggers = document.querySelectorAll("[data-dialog-trigger]")

      for trigger in triggers {
        if stringEquals(trigger.dataset["dialogTriggerHydrated"] ?? "", "true") { continue }
        trigger.dataset["dialogTriggerHydrated"] = "true"
        _ = trigger.addEventListener(.click) { event in
          // Find the closest element with the data attribute (in case click target is a child span/icon)
          guard let targetElement = event.target?.closest("[data-dialog-trigger]"),
            let dialogIDStr = targetElement.dataset["dialogTrigger"],
            let dialogID = parseInt(dialogIDStr),
            let instance = self.instances[Int32(dialogID)]
          else {
            return
          }

          instance.open(opener: targetElement)
        }
      }
    }
  }

  private class DialogInstance: @unchecked Sendable {
    private let dialog: DOM.Element
    /// What opened it, which has the focus again when it closes.
    private var opener: DOM.Element?
    /// Whether the press a click ends began on the backdrop: a drag from
    /// inside the dialog that ends outside it (an image panned) closes
    /// nothing.
    private var pressedOnBackdrop = false

    init(dialog: DOM.Element) {
      self.dialog = dialog
      bindEvents()
      // Drawn open (`DialogView(open: true)`): shown as every dialog is, a
      // modal.
      if dialog.hasAttribute("open"), let modal = dialog as? HTML.HTMLDialogElement {
        modal.close()
        modal.showModal()
      }
    }

    private func bindEvents() {
      if let closeButton = dialog.querySelector(".dialog-close-button") {
        _ = closeButton.addEventListener(.click) { [self] event in
          event.stopPropagation()
          self.close()
        }
      }

      // A press on the backdrop (`::backdrop`) is the dialog's own, never
      // on what it holds: the dialog is the shell's frame, without padding.
      _ = dialog.addEventListener(.pointerdown) { [self] event in
        self.pressedOnBackdrop = event.target?.id == self.dialog.id
      }
      _ = dialog.addEventListener(.click) { [self] event in
        guard self.pressedOnBackdrop, event.target?.id == self.dialog.id else { return }
        self.close()
      }

      // However it closes (Escape, its close button, the backdrop, the page),
      // what opened it has the focus again.
      _ = dialog.addEventListener(.close) { [self] _ in
        self.pressedOnBackdrop = false
        guard let opener = self.opener else { return }
        self.opener = nil
        opener.focus(DOM.FocusOptions(preventScroll: true))
      }

      if let primaryButton = dialog.querySelector(".dialog-primary-button") {
        _ = primaryButton.addEventListener(.click) { [self] event in
          event.stopPropagation()
          let customEvent = CustomEvent(type: "dialog-primary", detail: "")
          self.dialog.dispatchEvent(customEvent)
        }
      }

      if let defaultButton = dialog.querySelector(".dialog-default-button") {
        _ = defaultButton.addEventListener(.click) { [self] event in
          event.stopPropagation()
          let customEvent = CustomEvent(type: "dialog-default", detail: "")
          self.dialog.dispatchEvent(customEvent)
        }
      }
    }

    private func close() {
      (dialog as? HTML.HTMLDialogElement)?.close()
    }

    /// Opens it as a modal from `opener`; open already, it stays as it is.
    func open(opener: DOM.Element?) {
      guard !dialog.hasAttribute("open"), let modal = dialog as? HTML.HTMLDialogElement else { return }
      self.opener = opener
      modal.showModal()
    }
  }
#endif
