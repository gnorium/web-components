import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A brief message that shows up when a user hovers over a specific part of the UI.
public struct TooltipView: HTMLContent {
  let tooltipText: String
  let placement: Placement
  let font: Font
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

  public init(
    tooltip: String,
    placement: Placement = .bottom,
    font: Font = .sans,
    class: String = "",
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.tooltipText = tooltip
    self.placement = placement
    self.font = font
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
        tooltipText
      }
      .class("tooltip-content")
      .data("font", font.rawValue)
    }
    .class(stringIsEmpty(`class`) ? "tooltip-view tooltip-trigger" : "tooltip-view tooltip-trigger \(`class`)")
    .data("tooltip", "true")
    .data("placement", placement.rawValue)
    .data("visible", false)
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
        maxWidth(calc("min(256px, 100vw - \(spacing16.value))"))
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
        self.hideTooltip()
      }

      // Focus for keyboard navigation
      _ = trigger.addEventListener(.focus) { [self] _ in
        self.showTooltip()
      }

      _ = trigger.addEventListener(.blur) { [self] _ in
        self.hideTooltip()
      }

      // Long press for touch devices
      _ = trigger.addEventListener(.touchstart) { [self] _ in
        self.touchTimer = setTimeout(500) {
          self.showTooltip()
        }
      }

      _ = trigger.addEventListener(.touchend) { [self] _ in
        if let timer = self.touchTimer {
          clearTimeout(timer)
          self.touchTimer = nil
        }
        self.hideTooltip()
      }

      _ = trigger.addEventListener(.touchmove) { [self] _ in
        if let timer = self.touchTimer {
          clearTimeout(timer)
          self.touchTimer = nil
        }
      }

      // Keyboard: Escape to dismiss
      _ = document.addEventListener(.keydown) { [self] (event: Event) in
        let key = event.key
        if stringEquals(key, "Escape") && self.isVisible {
          self.hideTooltip()
        }
      }

      // The host is fixed to the viewport, not to the page: once the trigger
      // moves under it, the bubble would point at nothing.
      _ = window.addEventListener(.scroll) { [self] _ in
        if self.isVisible { self.hideTooltip() }
      }
      _ = window.addEventListener(.resize) { [self] _ in
        if self.isVisible { self.hideTooltip() }
      }
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
