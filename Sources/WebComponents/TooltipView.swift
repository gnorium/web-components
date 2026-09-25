import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A brief message that shows up when a user hovers over a specific part of the UI.
///
/// On a touch screen, which has no hover, a long press (half a second) opens
/// it and keeps it open until the next tap, and the click that the press
/// would otherwise end in is not sent: a long press on a button reads it and
/// doesn't press it.
///
/// With `opensOnClick` it is also a toggletip: a click or tap on the trigger
/// opens it and keeps it open until the next click or tap, anywhere, or
/// Escape. Use it where the words matter on a touch screen; the trigger
/// should then be a button, so it is focusable too.
///
/// The bubble is a line of text, `tooltip`, or `bubble` markup: several
/// lines, a `LocalTimeView` the client puts in the reader's clock.
public struct TooltipView: HTMLContent {
  let bubble: [DOM.Node]
  let placement: Placement
  let font: Font
  let opensOnClick: Bool
  let bubbleWidth: Width
  let children: [DOM.Node]
  let `class`: String

  /// Typeface of the bubble's text: sans for prose, mono for identifiers,
  /// stamps and other machine-shaped values.
  public enum Font: String, Sendable {
    case sans
    case mono
  }

  public enum Placement: String, Sendable, CaseIterable {
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

    public enum Side: Sendable {
      case top, bottom, left, right
    }

    public enum Alignment: Sendable {
      case center, start, end
    }

    public var side: Side {
      switch self {
      case .top, .topStart, .topEnd: .top
      case .bottom, .bottomStart, .bottomEnd: .bottom
      case .left, .leftStart, .leftEnd: .left
      case .right, .rightStart, .rightEnd: .right
      }
    }

    public var alignment: Alignment {
      switch self {
      case .top, .bottom, .left, .right: .center
      case .topStart, .bottomStart, .leftStart, .rightStart: .start
      case .topEnd, .bottomEnd, .leftEnd, .rightEnd: .end
      }
    }

    /// The same alignment on the opposite side — where the bubble goes when
    /// its own side has no room.
    public var opposite: Placement {
      switch self {
      case .top: .bottom
      case .topStart: .bottomStart
      case .topEnd: .bottomEnd
      case .bottom: .top
      case .bottomStart: .topStart
      case .bottomEnd: .topEnd
      case .left: .right
      case .leftStart: .rightStart
      case .leftEnd: .rightEnd
      case .right: .left
      case .rightStart: .leftStart
      case .rightEnd: .leftEnd
      }
    }
  }

  /// How wide the bubble may grow. A sentence reads best at the standard
  /// 256px; a list of lines ("By … on … at …") reads best a line each, as
  /// wide as the screen allows.
  public enum Width: String, Sendable {
    case standard
    case wide
  }

  public init(
    tooltip: String,
    placement: Placement = .bottom,
    font: Font = .sans,
    opensOnClick: Bool = false,
    width: Width = .standard,
    class: String = "",
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.bubble = [DOM.Text(tooltip)]
    self.bubbleWidth = width
    self.placement = placement
    self.font = font
    self.opensOnClick = opensOnClick
    self.children = content()
    self.`class` = `class`
  }

  public init(
    placement: Placement = .bottom,
    font: Font = .sans,
    opensOnClick: Bool = false,
    width: Width = .standard,
    class: String = "",
    @HTMLBuilder bubble: () -> [DOM.Node],
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.bubble = bubble()
    self.bubbleWidth = width
    self.placement = placement
    self.font = font
    self.opensOnClick = opensOnClick
    self.children = content()
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    return span {
      span {
        children
      }
      .class("tooltip-trigger-content")

      // The font rides on the bubble itself: once portaled to <body> it is no
      // longer inside the trigger, so a page rule scoped to the trigger's
      // ancestors could not reach it.
      span {
        bubble
      }
      .class("tooltip-content")
      .data("font", font.rawValue)
      .data("width", bubbleWidth.rawValue)
    }
    .class(stringIsEmpty(`class`) ? "tooltip-view tooltip-trigger" : "tooltip-view tooltip-trigger \(`class`)")
    .data("tooltip", "true")
    .data("placement", placement.rawValue)
    .data("visible", false)
    .data("opens-on-click", opensOnClick)
    .style {
      selector("&") {
        position(.relative)
        display(.inlineFlex)
        alignItems(.center)
        verticalAlign(.middle)
        cursor(.help)
        marginInlineStart(spacing4)
      }
      // Portal host: on hydration the bubble moves into one of these at the
      // end of <body>, a fixed point set from the trigger's rect. Inside the
      // trigger it inherited every ancestor's stacking context and transform
      // — a legend on a fieldset border painted it under the cards below —
      // and could not be pulled back inside the viewport at a screen edge.
      selector("&[data-portal='true']") {
        position(.fixed)
        display(.block)
        width(0)
        height(0)
        margin(0)
        zIndex(zIndexTooltip)
        pointerEvents(.none)
      }
      selector("& .tooltip-content") {
        position(.absolute)
        padding(spacing8, spacing12)
        // Sized to its text, not to its containing block: an absolutely
        // positioned box otherwise shrinks to the 20px trigger (or the 0px
        // portal host) and a one-sentence byline wrapped to five lines.
        width(.maxContent)
        minWidth(px(256))
        maxWidth(min(px(256), vw(100) - spacing16))
        backgroundColor(backgroundColorInverted)
        color(colorInverted)
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        fontWeight(fontWeightNormal)
        lineHeight(lineHeightSmall22)
        borderRadius(borderRadiusBase)
        whiteSpace(.normal)
        opacity(0)
        pointerEvents(.none)
        visibility(.hidden)
        transition(transitionPropertyFade, transitionDurationBase, transitionTimingFunctionSystem)
        zIndex(zIndexTooltip)
        boxShadow(boxShadowOutsetSmall)
        textAlign(.start)
        backfaceVisibility(.hidden)
        willChange(.transform, .opacity)
      }
      // A stamp in the bubble (`LocalTimeView`) reads as the bubble's text.
      selector("& .tooltip-content time") {
        color(colorInverted).important()
        fontSize(fontSizeSmall14).important()
      }
      selector("& .tooltip-content[data-width='wide']") {
        maxWidth(calc("100vw - \(spacing16.value)"))
        overflowWrap(.anywhere)
      }
      selector("& .tooltip-content[data-font='mono']") {
        fontFamily(typographyFontMono)
      }
      selector("&:hover > .tooltip-content", "&:focus-within > .tooltip-content", "&[data-visible='true'] .tooltip-content") {
        opacity(1)
        visibility(.visible)
        pointerEvents(.auto)
      }
      selector("&[data-placement='bottom'] .tooltip-content", "&[data-placement='bottom-start'] .tooltip-content", "&[data-placement='bottom-end'] .tooltip-content") {
        top(perc(100))
        marginTop(spacing8)
      }
      selector("&[data-placement='top'] .tooltip-content", "&[data-placement='top-start'] .tooltip-content", "&[data-placement='top-end'] .tooltip-content") {
        bottom(perc(100))
        marginBottom(spacing8)
      }
      selector("&[data-placement='left'] .tooltip-content", "&[data-placement='left-start'] .tooltip-content", "&[data-placement='left-end'] .tooltip-content") {
        right(perc(100))
        marginRight(spacing8)
      }
      selector("&[data-placement='right'] .tooltip-content", "&[data-placement='right-start'] .tooltip-content", "&[data-placement='right-end'] .tooltip-content") {
        left(perc(100))
        marginLeft(spacing8)
      }
      selector("&[data-placement='bottom'] .tooltip-content", "&[data-placement='top'] .tooltip-content") {
        left(perc(50))
        transform(translate(perc(-50), perc(0)))
      }
      selector("&[data-placement='bottom-start'] .tooltip-content", "&[data-placement='top-start'] .tooltip-content") {
        left(0)
      }
      selector("&[data-placement='bottom-end'] .tooltip-content", "&[data-placement='top-end'] .tooltip-content") {
        right(0)
      }
      selector("&[data-placement='left'] .tooltip-content", "&[data-placement='right'] .tooltip-content") {
        top(perc(50))
        transform(translate(perc(0), perc(-50)))
      }
      selector("&[data-placement='left-start'] .tooltip-content", "&[data-placement='right-start'] .tooltip-content") {
        top(0)
      }
      selector("&[data-placement='left-end'] .tooltip-content", "&[data-placement='right-end'] .tooltip-content") {
        bottom(0)
      }
      selector("& .tooltip-content::after") {
        content("\"\"")
        position(.absolute)
        width(0)
        height(0)
      }
      selector("&[data-placement='bottom'] .tooltip-content::after", "&[data-placement='bottom-start'] .tooltip-content::after", "&[data-placement='bottom-end'] .tooltip-content::after") {
        bottom(perc(100))
        borderLeft(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='top'] .tooltip-content::after", "&[data-placement='top-start'] .tooltip-content::after", "&[data-placement='top-end'] .tooltip-content::after") {
        top(perc(100))
        borderLeft(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorTransparent)
        borderTop(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='left'] .tooltip-content::after", "&[data-placement='left-start'] .tooltip-content::after", "&[data-placement='left-end'] .tooltip-content::after") {
        left(perc(100))
        borderTop(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorTransparent)
        borderLeft(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='right'] .tooltip-content::after", "&[data-placement='right-start'] .tooltip-content::after", "&[data-placement='right-end'] .tooltip-content::after") {
        right(perc(100))
        borderTop(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorInverted)
      }
      // Above or below, the arrow sits where the hydration puts it — over the
      // trigger's centre, clear of the corner radius — and at the middle
      // until then.
      selector(
        "&[data-placement='bottom'] .tooltip-content::after", "&[data-placement='top'] .tooltip-content::after",
        "&[data-placement='bottom-start'] .tooltip-content::after", "&[data-placement='top-start'] .tooltip-content::after",
        "&[data-placement='bottom-end'] .tooltip-content::after", "&[data-placement='top-end'] .tooltip-content::after"
      ) {
        CSS.Property("left", "var(--tooltip-arrow-x, 50%)")
        transform(translateX(perc(-50)))
      }
      selector("&[data-placement='left'] .tooltip-content::after", "&[data-placement='right'] .tooltip-content::after") {
        top(perc(50))
        transform(translateY(perc(-50)))
      }
      selector("&[data-placement='left-start'] .tooltip-content::after", "&[data-placement='right-start'] .tooltip-content::after") {
        top(spacing12)
      }
      selector("&[data-placement='left-end'] .tooltip-content::after", "&[data-placement='right-end'] .tooltip-content::after") {
        bottom(spacing12)
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  private class TooltipInstance: @unchecked Sendable {
    private var trigger: DOM.Element
    private var content: DOM.Element?
    private var host: DOM.Element?
    private let placement: TooltipView.Placement
    private var isVisible: Bool = false
    private var hideTimeout: Int32?
    private var touchTimer: Int32?
    /// Opened by a click or tap (`opensOnClick`) or a long press: leaving
    /// the trigger or its focus doesn't close it; the next click or tap does.
    private var pinned: Bool = false
    /// The touch that just ended was a long press, whose click is dropped.
    private var longPressed: Bool = false

    /// Distance the bubble keeps from the viewport's edges.
    private static let edgeMargin = 8.0
    /// Nearest the arrow may sit to the bubble's edge: the corner radius
    /// (16px) plus half the arrow (6px), so the corner never cuts into it.
    private static let arrowInset = 22.0

    init(tooltip: DOM.Element) {
      self.trigger = tooltip
      self.content = tooltip.querySelector(".tooltip-content")
      // `TooltipView` always stamps the attribute; the fallback is its own
      // default, so a hand-built trigger without one behaves like the view.
      // Matched with `stringEquals`, not `init(rawValue:)`: the synthesized
      // initializer compares with `==`, which is Unicode normalization the
      // embedded client cannot link.
      let raw = tooltip.dataset["placement"] ?? ""
      self.placement =
        TooltipView.Placement.allCases.first { stringEquals($0.rawValue, raw) } ?? .bottom

      portal()
      bindEvents()
    }

    /// Move the bubble into a fixed host at the end of <body>. The host is a
    /// point; the placement CSS grows the bubble from it exactly as it did
    /// from the trigger, so only the point has to be placed.
    private func portal() {
      guard let content else { return }
      let host = document.createElement(.span)
      host.classList.add("tooltip-view")
      _ = host.dataset["portal"] = "true"
      _ = host.dataset["placement"] = placement.rawValue
      _ = host.dataset["visible"] = "false"
      host.appendChild(content)
      document.body.appendChild(host)
      self.host = host
    }

    /// Anchor the host at the trigger for the requested placement, then pull
    /// the bubble back inside the viewport: flipped to the other side when
    /// there is no room above or below, shifted along an edge it crosses.
    private func place() {
      guard let host, let content, let t = trigger.getBoundingClientRect() else { return }
      let margin = Self.edgeMargin
      var placement = self.placement
      var (x, y) = Self.anchor(for: placement, trigger: t)
      _ = host.dataset["placement"] = placement.rawValue
      Self.position(host, x: x, y: y)
      guard let c = content.getBoundingClientRect() else { return }

      switch placement.side {
      case .top, .bottom:
        let overflows: Bool
        let roomOpposite: Bool
        if placement.side == .bottom {
          overflows = c.bottom > window.innerHeight - margin
          roomOpposite = t.top - c.height - margin > 0
        } else {
          overflows = c.top < margin
          roomOpposite = t.bottom + c.height + margin < window.innerHeight
        }
        if overflows && roomOpposite {
          placement = placement.opposite
          (x, y) = Self.anchor(for: placement, trigger: t)
          _ = host.dataset["placement"] = placement.rawValue
          Self.position(host, x: x, y: y)
        }
      case .left, .right:
        break
      }

      guard let placed = content.getBoundingClientRect() else { return }
      var shiftX = 0.0
      var shiftY = 0.0
      if placed.left < margin {
        shiftX = margin - placed.left
      } else if placed.right > window.innerWidth - margin {
        shiftX = window.innerWidth - margin - placed.right
      }
      switch placement.side {
      case .left, .right:
        if placed.top < margin {
          shiftY = margin - placed.top
        } else if placed.bottom > window.innerHeight - margin {
          shiftY = window.innerHeight - margin - placed.bottom
        }
      case .top, .bottom:
        break
      }
      var hostX = x + shiftX
      let hostY = y + shiftY
      if shiftX != 0 || shiftY != 0 {
        Self.position(host, x: hostX, y: hostY)
      }

      // Point the arrow at the trigger's centre. If that centre lies inside
      // the bubble's corner zone, slide the bubble — as far as the viewport
      // allows — so the arrow sits just clear of the radius, over the trigger.
      switch placement.side {
      case .top, .bottom:
        guard let bubble = content.getBoundingClientRect() else { return }
        var arrowX = t.left + t.width / 2 - bubble.left
        let inset = Self.arrowInset
        if arrowX < inset {
          let dx = min(inset - arrowX, max(0, bubble.left - margin))
          hostX -= dx
          arrowX += dx
          Self.position(host, x: hostX, y: hostY)
        } else if arrowX > bubble.width - inset {
          let dx = min(arrowX - (bubble.width - inset), max(0, window.innerWidth - margin - bubble.right))
          hostX += dx
          arrowX -= dx
          Self.position(host, x: hostX, y: hostY)
        }
        host.setStyleProperty("--tooltip-arrow-x", Self.px(arrowX))
      case .left, .right:
        break
      }
    }

    private static func px(_ value: Double) -> String {
      stringJoin([intToString(Int(value)), "px"], separator: "")
    }

    /// The point on the trigger's box that the placement CSS grows the
    /// bubble away from.
    private static func anchor(
      for placement: TooltipView.Placement, trigger t: DOM.Rect
    ) -> (Double, Double) {
      switch placement.side {
      case .left, .right:
        let x = placement.side == .left ? t.left : t.right
        let y: Double
        switch placement.alignment {
        case .start: y = t.top
        case .end: y = t.bottom
        case .center: y = t.top + t.height / 2
        }
        return (x, y)
      case .top, .bottom:
        let y = placement.side == .top ? t.top : t.bottom
        let x: Double
        switch placement.alignment {
        case .start: x = t.left
        case .end: x = t.right
        case .center: x = t.left + t.width / 2
        }
        return (x, y)
      }
    }

    private static func position(_ host: DOM.Element, x: Double, y: Double) {
      host.setStyleProperty("left", px(x))
      host.setStyleProperty("top", px(y))
    }

    private func bindEvents() {
      guard let _ = content else { return }

      // Hover for desktop
      _ = trigger.addEventListener(.mouseenter) { [self] _ in
        self.showTooltip()
      }

      _ = trigger.addEventListener(.mouseleave) { [self] _ in
        if !self.pinned { self.hideTooltip() }
      }

      // Focus for keyboard navigation: focusin and focusout bubble up from
      // the control inside the trigger, which is what takes the focus.
      _ = trigger.addEventListener(.focusin) { [self] _ in
        self.showTooltip()
      }

      _ = trigger.addEventListener(.focusout) { [self] _ in
        if !self.pinned { self.hideTooltip() }
      }

      if let opensOnClick = trigger.dataset["opens-on-click"], stringEquals(opensOnClick, "true") {
        // A click or tap opens it and pins it; the next one closes it. A
        // tap's emulated mouseenter and focus have already shown it by the
        // time its click arrives, so the click only pins.
        _ = trigger.addEventListener(.click) { [self] _ in
          if self.pinned {
            self.dismiss()
          } else {
            self.pinned = true
            self.showTooltip()
          }
        }
      } else {
        // A long press opens it and pins it, and the click the press ends
        // in is not sent: reading a button's tooltip doesn't press it.
        _ = trigger.addEventListener(.touchstart) { [self] _ in
          self.longPressed = false
          self.touchTimer = setTimeout(500) {
            self.touchTimer = nil
            self.longPressed = true
            self.pinned = true
            self.showTooltip()
          }
        }

        _ = trigger.addEventListener(.touchend) { [self] (event: Event) in
          if let timer = self.touchTimer {
            clearTimeout(timer)
            self.touchTimer = nil
          }
          if self.longPressed {
            // No click after it; and should a browser send one anyway, the
            // click listener below drops it.
            event.preventDefault()
          } else if !self.pinned {
            self.hideTooltip()
          }
        }

        _ = trigger.addEventListener(.touchmove) { [self] _ in
          if let timer = self.touchTimer {
            clearTimeout(timer)
            self.touchTimer = nil
          }
        }

        _ = trigger.addEventListener(.click) { [self] (event: Event) in
          if self.longPressed {
            self.longPressed = false
            event.preventDefault()
          }
        }
      }

      // A pinned one closes on a click or tap anywhere else. iOS sends no
      // click to the document for a tap on something that isn't clickable,
      // hence the touchstart too.
      _ = document.addEventListener(.click) { [self] event in
        self.dismissUnlessInside(event)
      }
      _ = document.addEventListener(.touchstart) { [self] event in
        self.dismissUnlessInside(event)
      }

      // Keyboard: Escape to dismiss
      _ = document.addEventListener(.keydown) { [self] (event: Event) in
        let key = event.key
        if stringEquals(key, "Escape") && self.isVisible {
          self.dismiss()
        }
      }

      // The host is fixed to the viewport, not to the page: once the trigger
      // moves under it, the bubble would point at nothing.
      _ = window.addEventListener(.scroll) { [self] _ in
        if self.isVisible { self.dismiss() }
      }
      _ = window.addEventListener(.resize) { [self] _ in
        if self.isVisible { self.dismiss() }
      }
    }

    /// Closes it, pinned or not.
    private func dismiss() {
      pinned = false
      hideTooltip()
    }

    /// Closes a pinned one when `event` happened outside its trigger.
    private func dismissUnlessInside(_ event: Event) {
      guard pinned, let target = event.target else { return }
      if !trigger.contains(target) { dismiss() }
    }

    private func showTooltip() {
      guard content != nil else { return }

      // Cancel any pending hide
      if let timer = hideTimeout {
        clearTimeout(timer)
        hideTimeout = nil
      }

      place()
      host?.setAttribute(data("visible"), true)
      trigger.setAttribute(data("visible"), true)
      isVisible = true

      // Dispatch show event
      let event = CustomEvent(type: "tooltip-show", detail: "")
      trigger.dispatchEvent(event)
    }

    private func hideTooltip() {
      guard content != nil else { return }

      // Small delay before hiding
      hideTimeout = setTimeout(100) { [self] in
        self.host?.setAttribute(data("visible"), false)
        self.trigger.setAttribute(data("visible"), false)
        self.isVisible = false

        // Dispatch hide event
        let event = CustomEvent(type: "tooltip-hide", detail: "")
        self.trigger.dispatchEvent(event)
      }
    }
  }

  public class TooltipHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TooltipHydration?
    private var instances: [TooltipInstance] = []

    public init() {
      bind(in: document.body)
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".tooltip-view") != nil else { return }
      instance = TooltipHydration()
    }

    /// The tooltips under `root` — a fragment fetched into the page after its
    /// own pass. One already bound is left alone.
    public static func hydrate(in root: DOM.Element) {
      guard let instance else {
        instance = TooltipHydration()
        return
      }
      instance.bind(in: root)
    }

    private func bind(in root: DOM.Element) {
      for tooltip in root.querySelectorAll("[data-tooltip=\"true\"]") {
        if tooltip.hasAttribute("data-tooltip-hydrated") { continue }
        tooltip.setAttribute(data("tooltip-hydrated"), "true")
        instances.append(TooltipInstance(tooltip: tooltip))
      }
    }
  }

  public enum TooltipFactory {
    /// Creates a tooltip trigger element wrapping an info icon, matching TooltipView output.
    public static func createElement(
      text: String,
      placement: TooltipView.Placement = .top,
      font: TooltipView.Font = .sans
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = TooltipView(tooltip: text, placement: placement, font: font) {
        InfoIconView(width: px(20), height: px(20))
      }
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      _ = TooltipInstance(tooltip: element)
      return element
    }
  }
#endif
