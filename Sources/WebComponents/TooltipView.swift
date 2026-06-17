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
  let children: [DOM.Node]
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

  public init(
    tooltip: String,
    placement: Placement = .bottom,
    class: String = "",
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.tooltipText = tooltip
    self.placement = placement
    self.children = content()
    self.`class` = `class`
  }

  @CSSBuilder
  private func tooltipTriggerCSS() -> [CSSOM.CSSRule] {
    position(.relative)
    display(.inlineFlex)
    alignItems(.center)
    verticalAlign(.middle)
    cursor(.help)
    marginInlineStart(spacing4)

    // CSS hover fallback — works without CLIENT hydration.
    // NOTE: .tooltip-content carries an inline `opacity:0; visibility:hidden`,
    // which outranks a plain stylesheet rule, so these MUST be !important to win.
    pseudoClass(.hover) {
      child(".tooltip-content") {
        opacity(1).important()
        visibility(.visible).important()
        pointerEvents(.auto).important()
      }
    }

    // Focus fallback for keyboard navigation
    pseudoClass(.focusWithin) {
      child(".tooltip-content") {
        opacity(1).important()
        visibility(.visible).important()
        pointerEvents(.auto).important()
      }
    }
  }

  @CSSBuilder
  private func tooltipContentCSS(_ placement: Placement) -> [CSSOM.CSSRule] {
    position(.absolute)
    padding(spacing8, spacing12)
    minWidth(px(150))
    maxWidth(px(320))
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
    // Force GPU acceleration to prevent horizontal subpixel rendering jitter on hover
    // Position based on placement
    switch placement {
    case .bottom, .bottomStart, .bottomEnd:
      top(perc(100))
      marginTop(spacing8)
    case .top, .topStart, .topEnd:
      bottom(perc(100))
      marginBottom(spacing8)
    case .left, .leftStart, .leftEnd:
      right(perc(100))
      marginRight(spacing8)
    case .right, .rightStart, .rightEnd:
      left(perc(100))
      marginLeft(spacing8)
    }

    switch placement {
    case .bottom, .top:
      left(perc(50))
      transform(translate(perc(-50), perc(0)))
    case .bottomStart, .topStart:
      left(0)
    case .bottomEnd, .topEnd:
      right(0)
    case .left, .right:
      top(perc(50))
      transform(translate(perc(0), perc(-50)))
    case .leftStart, .rightStart:
      top(0)
    case .leftEnd, .rightEnd:
      bottom(0)
    }
  }

  @CSSBuilder
  private func tooltipArrowCSS(_ placement: Placement) -> [CSSOM.CSSRule] {
    content("\"\"")
    position(.absolute)
    width(0)
    height(0)

    // Arrow position and direction based on placement
    switch placement {
    case .bottom, .bottomStart, .bottomEnd:
      bottom(perc(100))
      borderLeft(px(6), .solid, backgroundColorTransparent)
      borderRight(px(6), .solid, backgroundColorTransparent)
      borderBottom(px(6), .solid, backgroundColorInverted)
    case .top, .topStart, .topEnd:
      top(perc(100))
      borderLeft(px(6), .solid, backgroundColorTransparent)
      borderRight(px(6), .solid, backgroundColorTransparent)
      borderTop(px(6), .solid, backgroundColorInverted)
    case .left, .leftStart, .leftEnd:
      left(perc(100))
      borderTop(px(6), .solid, backgroundColorTransparent)
      borderBottom(px(6), .solid, backgroundColorTransparent)
      borderLeft(px(6), .solid, backgroundColorInverted)
    case .right, .rightStart, .rightEnd:
      right(perc(100))
      borderTop(px(6), .solid, backgroundColorTransparent)
      borderBottom(px(6), .solid, backgroundColorTransparent)
      borderRight(px(6), .solid, backgroundColorInverted)
    }

    // Arrow horizontal/vertical positioning
    switch placement {
    case .bottom, .top:
      left(perc(50))
      transform(translateX(perc(-50)))
    case .bottomStart, .topStart:
      left(spacing12)
    case .bottomEnd, .topEnd:
      right(spacing12)
    case .left, .right:
      top(perc(50))
      transform(translateY(perc(-50)))
    case .leftStart, .rightStart:
      top(spacing12)
    case .leftEnd, .rightEnd:
      bottom(spacing12)
    }
  }

  public func build() -> DOM.Node {
    return span {
      span {
        children
      }
      .class("tooltip-trigger-content")

      span {
        tooltipText
      }
      .class("tooltip-content")
      .style {
        tooltipContentCSS(placement)

        pseudoElement(.after) {
          tooltipArrowCSS(placement)
        }
      }
    }
    .class(stringIsEmpty(`class`) ? "tooltip-view tooltip-trigger" : "tooltip-view tooltip-trigger \(`class`)")
    .data("tooltip", "true")
    .data("placement", placement.rawValue)
    .style {
      tooltipTriggerCSS()
    }
  }
}

#if CLIENT
  import WebAPIs

  private class TooltipInstance: @unchecked Sendable {
    private var trigger: DOM.Element
    private var content: DOM.Element?
    private var isVisible: Bool = false
    private var hideTimeout: Int32?
    private var touchTimer: Int32?

    init(tooltip: DOM.Element) {
      self.trigger = tooltip
      self.content = tooltip.querySelector(".tooltip-content")

      bindEvents()
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
    }

    private func showTooltip() {
      guard let content = content else { return }

      // Cancel any pending hide
      if let timer = hideTimeout {
        clearTimeout(timer)
        hideTimeout = nil
      }

      content.style.opacity(1)
      content.style.visibility(.visible)
      content.style.pointerEvents(.auto)
      isVisible = true

      // Dispatch show event
      let event = CustomEvent(type: "tooltip-show", detail: "")
      trigger.dispatchEvent(event)
    }

    private func hideTooltip() {
      guard let content = content else { return }

      // Small delay before hiding
      hideTimeout = setTimeout(100) { [self] in
        content.style.opacity(0)
        content.style.visibility(.hidden)
        content.style.pointerEvents(.none)
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
      hydrateAllTooltips()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".tooltip-view") != nil else { return }
      instance = TooltipHydration()
    }

    private func hydrateAllTooltips() {
      let allTooltips = document.querySelectorAll("[data-tooltip=\"true\"]")

      for tooltip in allTooltips {
        let instance = TooltipInstance(tooltip: tooltip)
        instances.append(instance)
      }
    }
  }

  public enum TooltipFactory {
    /// Creates a tooltip trigger element wrapping an info icon, matching TooltipView output.
    public static func createElement(
      text: String,
      placement: TooltipView.Placement = .top
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = TooltipView(tooltip: text, placement: placement) {
        InfoIconView(width: px(20), height: px(20))
      }
      wrapper.innerHTML = renderHTML { view.render() }
      let element = wrapper.firstElementChild ?? wrapper
      _ = TooltipInstance(tooltip: element)
      return element
    }
  }
#endif
