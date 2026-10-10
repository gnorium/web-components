#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The selection pill that glides between the items of a one-of-many
  /// control: a single-select ToggleButtonGroupView (a segmented slider) and
  /// the solid TabsView. Its host draws it behind its items, as the host's
  /// first child, and moves it with `SlidingPill` on the client.
  ///
  /// It is a layer over the host's padding box (`inset: 0`), holding the
  /// thumb—the pill itself—so the thumb is measured from the layer's own
  /// corner, whatever border the host draws. The thumb is placed by
  /// measurement, so it lands under its item in either direction (LTR or
  /// RTL) and wherever a wrapped row put it.
  ///
  /// Until it is placed the thumb is invisible and the host styles its
  /// selected item itself, so the page reads right before any script runs;
  /// once placed (`data-sliding-pill="ready"` on the host) the host leaves
  /// the fill to the thumb. Placed on load and on resize without moving;
  /// moved by a selection with the slide transition. A reader who prefers
  /// reduced motion gets the thumb too, never moving: it jumps to the new
  /// item at once, the item's label with it (user, 2026-10-08).
  public struct SlidingPillView: HTMLContent {
    public init() {}

    public func build() -> DOM.Node {
      span {
        span {}
          .class("sliding-pill-thumb")
          .data("placed", false)
          .data("animate", false)
      }
      .class("sliding-pill-view")
      .ariaHidden(true)
      .style {
        selector("&") {
          position(.absolute)
          inset(0)
          zIndex(0)
          pointerEvents(.none)
        }
        descendant(".sliding-pill-thumb") {
          position(.absolute)
          top(0)
          left(0)
          display(.block)
          width(`var`("--sliding-pill-width") as CSS.Length)
          height(`var`("--sliding-pill-height") as CSS.Length)
          CSS.Property("transform", "translate(var(--sliding-pill-x, 0px), var(--sliding-pill-y, 0px))")
          borderRadius(borderRadiusPill)
          backgroundColor(backgroundColorBlue)
          opacity(0)
        }
        descendant(".sliding-pill-thumb[data-placed='true']") {
          opacity(1)
        }
        descendant(".sliding-pill-thumb[data-animate='true']") {
          // The slide (user, 2026-10-10): 300ms on the decelerate curve, a
          // quick start and a gentle settle—the tabs' and every segmented
          // control's alike.
          transition(
            "transform \(transitionDurationMedium.value) \(transitionTimingFunctionDecelerate.value), "
              + "width \(transitionDurationMedium.value) \(transitionTimingFunctionDecelerate.value), "
              + "height \(transitionDurationMedium.value) \(transitionTimingFunctionDecelerate.value)")
          // Reduced motion: no slide, the thumb at its item at once.
          media(prefersReducedMotion(.reduce)) { transition(.none).important() }
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Moves a `SlidingPillView`'s thumb under its host's selected item.
  public enum SlidingPill {
    /// Place the thumb under `current()` now, without moving, mark the host
    /// ready, and place it again whenever the host changes size.
    public static func attach(
      _ layer: DOM.Element, in host: DOM.Element, current: @escaping @Sendable () -> DOM.Element?
    ) {
      place(layer, in: host, under: current(), animate: false)
      host.observeResize { _, _ in
        place(layer, in: host, under: current(), animate: false)
      }
    }

    /// The thumb under `item`, gliding there when `animate`; hidden, and
    /// the host's own selected styling back, when there is no item.
    public static func place(_ layer: DOM.Element, in host: DOM.Element, under item: DOM.Element?, animate: Bool) {
      guard let thumb = layer.querySelector(".sliding-pill-thumb") else { return }
      guard let item, let origin = layer.getBoundingClientRect(), let box = item.getBoundingClientRect(),
        box.width > 0, box.height > 0
      else {
        thumb.setAttribute(data("placed"), "false")
        host.setAttribute(data("sliding-pill"), "pending")
        return
      }
      // A first placement is never a move: it would glide in from the corner.
      // Reduced motion: never a move, the thumb jumps (user, 2026-10-08).
      let wasPlaced = stringEquals(thumb.getAttribute(data("placed")) ?? "", "true")
      let moves = animate && wasPlaced && !window.matchMedia("(prefers-reduced-motion: reduce)")
      thumb.setAttribute(data("animate"), moves ? "true" : "false")
      thumb.style.setProperty("--sliding-pill-x", doubleToString(box.left - origin.left) + "px")
      thumb.style.setProperty("--sliding-pill-y", doubleToString(box.top - origin.top) + "px")
      thumb.style.setProperty("--sliding-pill-width", doubleToString(box.width) + "px")
      thumb.style.setProperty("--sliding-pill-height", doubleToString(box.height) + "px")
      thumb.setAttribute(data("placed"), "true")
      host.setAttribute(data("sliding-pill"), "ready")
    }
  }
#endif
