import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// PopoverView builds on both sides, so a component the client draws (the date
// picker) can carry one: build() stays embedded-safe, and every style that
// varies by instance keys off a data attribute, since all instances share one
// stylesheet.

/// A non-disruptive container that is overlaid on a web page or app, positioned near its trigger.
public struct PopoverView: HTMLContent {
  let id: String
  let open: Bool
  let title: String
  let icon: String?
  let useCloseButton: Bool
  let closeButtonLabel: String
  let primaryAction: PrimaryAction?
  let defaultAction: DefaultAction?
  let stackedActions: Bool
  let renderInPlace: Bool
  let placement: Placement
  let showsArrow: Bool
  let ariaLabel: String
  let headerContent: [DOM.Node]
  let bodyContent: [DOM.Node]
  let footerContent: [DOM.Node]
  let `class`: String

  public enum Placement: String, Sendable {
    case top
    case topStart = "top-start"
    case topEnd = "top-end"
    case bottom
    case bottomStart = "bottom-start"
    case bottomEnd = "bottom-end"
    case left
    case leftStart = "left-start"
    case leftEnd = "left-end"
    case right
    case rightStart = "right-start"
    case rightEnd = "right-end"
  }

  public struct PrimaryAction: Sendable {
    let label: String
    let actionColor: ActionColor

    /// Apple HIG color for the popover action
    public enum ActionColor: String, Sendable {
      case blue
      case red

      // Legacy aliases
      public static let progressive = ActionColor.blue
      public static let destructive = ActionColor.red
    }

    public init(label: String, actionColor: ActionColor = .blue) {
      self.label = label
      self.actionColor = actionColor
    }

    /// Legacy init
    public init(label: String, type: ActionColor) {
      self.label = label
      self.actionColor = type
    }
  }

  public struct DefaultAction: Sendable {
    let label: String

    public init(label: String) {
      self.label = label
    }
  }

  public init(
    id: String = "",
    open: Bool = false,
    title: String = "",
    icon: String? = nil,
    useCloseButton: Bool = false,
    closeButtonLabel: String = "Close",
    primaryAction: PrimaryAction? = nil,
    defaultAction: DefaultAction? = nil,
    stackedActions: Bool = false,
    renderInPlace: Bool = false,
    placement: Placement = .bottom,
    showsArrow: Bool = true,
    ariaLabel: String = "",
    class: String = "",
    @HTMLBuilder header: () -> [DOM.Node] = { [] },
    @HTMLBuilder body: () -> [DOM.Node] = { [] },
    @HTMLBuilder footer: () -> [DOM.Node] = { [] }
  ) {
    self.id = id
    self.open = open
    self.title = title
    self.icon = icon
    self.useCloseButton = useCloseButton
    self.closeButtonLabel = closeButtonLabel
    self.primaryAction = primaryAction
    self.defaultAction = defaultAction
    self.stackedActions = stackedActions
    self.renderInPlace = renderInPlace
    self.placement = placement
    self.showsArrow = showsArrow
    self.ariaLabel = ariaLabel
    self.`class` = `class`
    self.headerContent = header()
    self.bodyContent = body()
    self.footerContent = footer()
  }

  public func build() -> DOM.Node {
    let hasCustomHeader = !headerContent.isEmpty
    let hasIcon = if let _ = icon { true } else { false }
    let hasTitle = !stringIsEmpty(title)
    let hasPrimaryAction = if let _ = primaryAction { true } else { false }
    let hasDefaultAction = if let _ = defaultAction { true } else { false }
    let hasActions = hasPrimaryAction || hasDefaultAction
    let hasFooterContent = !footerContent.isEmpty

    var popover = div {
      if showsArrow {
        div {}
          .class("popover-arrow")
      }

      // Header
      if hasCustomHeader || hasIcon || hasTitle || useCloseButton {
        div {
          if hasCustomHeader {
            headerContent
          } else {
            div {
              if let iconValue = icon {
                span { iconValue }
                  .class("popover-icon")
                  .ariaHidden(true)
              }

              if hasTitle {
                h2 { title }
                  .class("popover-title")
              }
            }
            .class("popover-header-content")
          }

          if useCloseButton {
            button {
              span { "×" }
                .ariaHidden(true)
            }
            .type(.button)
            .class("popover-close-button")
            .ariaLabel(closeButtonLabel)
          }
        }
        .class("popover-header")
      }

      // Body
      div {
        bodyContent
      }
      .class("popover-body")

      // Footer
      if hasActions || hasFooterContent {
        div {
          if hasFooterContent {
            footerContent
          } else {
            if let defAction = defaultAction {
              div {
                ButtonView(
                  label: defAction.label,
                  buttonColor: .gray,
                  weight: .subtle
                )
              }
              .class("popover-default-button")
            }

            if let primAction = primaryAction {
              div {
                ButtonView(
                  label: primAction.label,
                  buttonColor: {
                    switch primAction.actionColor {
                    case .blue: return ButtonView.ButtonColor.blue
                    case .red: return ButtonView.ButtonColor.red
                    }
                  }(),
                  weight: .solid
                )
              }
              .class("popover-primary-button")
            }
          }
        }
        .class("popover-footer")
      }
    }
    .class(stringIsEmpty(`class`) ? "popover-view" : "popover-view \(`class`)")
    .data("open", open)
    .data("placement", placement.rawValue)
    .data("render-in-place", renderInPlace)
    .data("stacked-actions", stackedActions)
    .role(.dialog)
    .ariaModal(false)

    if !stringIsEmpty(id) {
      popover = popover.id(id)
    }
    if !stringIsEmpty(ariaLabel) {
      popover = popover.ariaLabel(ariaLabel)
    }

    return popover.style {
      selector("&") {
        position(.absolute)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorSubtle)
        borderRadius(borderRadiusBase)
        boxShadow(boxShadowOutsetMediumAround)
        zIndex(zIndexPopover)
        minWidth(px(256))
        maxWidth(px(320))
        padding(0)
      }
      selector("&[data-open='false']") { display(.none) }

      descendant(".popover-arrow") {
        position(.absolute)
        width(px(12))
        height(px(12))
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorSubtle)
        transform(rotate(deg(45)))
      }
      // The arrow sits on the side facing the trigger. The square is turned
      // 45deg, so which two of its borders to drop is a physical matter.
      selector("&[data-placement^='top'] .popover-arrow") {
        bottom(px(-7))
        borderTop(.none)
        borderLeft(.none)
      }
      selector("&[data-placement^='bottom'] .popover-arrow") {
        top(px(-7))
        borderBottom(.none)
        borderRight(.none)
      }
      selector("&[data-placement^='left'] .popover-arrow") {
        right(px(-7))
        borderLeft(.none)
        borderBottom(.none)
      }
      selector("&[data-placement^='right'] .popover-arrow") {
        left(px(-7))
        borderTop(.none)
        borderRight(.none)
      }
      selector("&[data-placement='top'] .popover-arrow", "&[data-placement='bottom'] .popover-arrow") {
        left(perc(50))
        marginLeft(px(-6))
      }
      selector("&[data-placement='top-start'] .popover-arrow", "&[data-placement='bottom-start'] .popover-arrow") {
        insetInlineStart(spacing16)
      }
      selector("&[data-placement='top-end'] .popover-arrow", "&[data-placement='bottom-end'] .popover-arrow") {
        insetInlineEnd(spacing16)
      }
      selector("&[data-placement='left'] .popover-arrow", "&[data-placement='right'] .popover-arrow") {
        top(perc(50))
        marginTop(px(-6))
      }
      selector("&[data-placement='left-start'] .popover-arrow", "&[data-placement='right-start'] .popover-arrow") {
        top(spacing16)
      }
      selector("&[data-placement='left-end'] .popover-arrow", "&[data-placement='right-end'] .popover-arrow") {
        bottom(spacing16)
      }

      descendant(".popover-header") {
        display(.flex)
        alignItems(.center)
        justifyContent(.spaceBetween)
        gap(spacing8)
        padding(spacing12)
        borderBottom(borderWidthBase, .solid, borderColorSubtle)
      }

      descendant(".popover-header-content") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        flex(1)
        minWidth(0)
      }

      descendant(".popover-icon") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(sizeIconMedium)
        height(sizeIconMedium)
        flexShrink(0)
        color(colorSubtle)
        fontSize(fontSizeLarge18)
      }

      descendant(".popover-title") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightSemiBold)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        margin(0)
        flex(1)
        minWidth(0)
      }

      descendant(".popover-body") {
        padding(spacing12)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightMedium26)
        color(colorBase)
      }

      descendant(".popover-footer") {
        display(.flex)
        flexDirection(.row)
        justifyContent(.flexStart)
        gap(spacing8)
        padding(spacing12)
        borderTop(borderWidthBase, .solid, borderColorSubtle)
      }
      selector("&[data-stacked-actions='true'] .popover-footer") { flexDirection(.column) }
      selector("&[data-stacked-actions='true'] .popover-primary-button") { order(-1) }
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

  private class PopoverInstance: @unchecked Sendable {
    private var popover: DOM.Element
    private var closeButton: DOM.Element?
    private var primaryButton: DOM.Element?
    private var defaultButton: DOM.Element?
    private var isOpen: Bool = false

    init(popover: DOM.Element) {
      self.popover = popover

      closeButton = popover.querySelector(".popover-close-button")
      primaryButton = popover.querySelector(".popover-primary-button")
      defaultButton = popover.querySelector(".popover-default-button")

      // Get initial open state
      if let openAttr = popover.getAttribute("data-open") {
        isOpen = stringEquals(openAttr, "true")
      }

      bindEvents()
      positionPopover()
    }

    private func bindEvents() {
      // Close button
      if let closeBtn = closeButton {
        _ = closeBtn.addEventListener(.click) { [self] _ in
          self.closePopover()
        }
      }

      // Primary action button
      if let primBtn = primaryButton {
        _ = primBtn.addEventListener(.click) { [self] _ in
          let event = CustomEvent(type: "popover-primary", detail: "")
          self.popover.dispatchEvent(event)
        }
      }

      // Default action button
      if let defBtn = defaultButton {
        _ = defBtn.addEventListener(.click) { [self] _ in
          let event = CustomEvent(type: "popover-default", detail: "")
          self.popover.dispatchEvent(event)
        }
      }

      // Keyboard navigation
      _ = popover.addEventListener(.keydown) { [self] (event: Event) in
        self.handleKeydown(event)
      }

      // Click outside to close
      _ = document.addEventListener(.click) { [self] event in
        guard let target = event.target else { return }

        // Check if click is outside popover
        if self.isOpen && !self.popover.contains(target) {
          self.closePopover()
        }
      }

      // Focus trap - Tab key handling
      _ = popover.addEventListener(.keydown) { [self] (event: Event) in
        if stringEquals(event.key, "Tab") {
          self.handleTabKey(event)
        }
      }
    }

    private func positionPopover() {
      // Position popover relative to anchor
      // This would typically use a positioning library or custom logic
      // For now, CSSContent handles basic positioning
    }

    private func closePopover() {
      popover.dataset["open"] = "false"
      isOpen = false

      // Dispatch close event
      let event = CustomEvent(type: "popover-close", detail: "")
      popover.dispatchEvent(event)
    }

    private func handleKeydown(_ event: Event) {
      if stringEquals(event.key, "Escape") {
        closePopover()
      }
    }

    /// Tab stays inside while the popover is open: past the last control it
    /// comes round to the first, and Shift+Tab the other way.
    private func handleTabKey(_ event: Event) {
      let focusableElements = popover.querySelectorAll(
        "button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex=\"-1\"])"
      )

      guard !focusableElements.isEmpty else { return }

      let firstElement = focusableElements[0]
      let lastElement = focusableElements[focusableElements.count - 1]
      guard let activeElement = document.activeElement else { return }

      if event.shiftKey {
        if activeElement.id == firstElement.id {
          event.preventDefault()
          lastElement.focus()
        }
      } else if activeElement.id == lastElement.id {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }

  public class PopoverHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: PopoverHydration?
    private var instances: [PopoverInstance] = []

    public init() {
      hydrateAllPopovers()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".popover-view") != nil else { return }
      instance = PopoverHydration()
    }

    private func hydrateAllPopovers() {
      let allPopovers = document.querySelectorAll(".popover-view")

      for popover in allPopovers {
        let instance = PopoverInstance(popover: popover)
        instances.append(instance)
      }
    }
  }
#endif
