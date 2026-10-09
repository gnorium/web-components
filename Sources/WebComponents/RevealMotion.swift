#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// The height motion an alert opens and closes with (`AlertAPI`), for any
  /// box that comes and goes under what it belongs to (user, 2026-10-09): a
  /// field's validation message, a form's reader. It grows from nothing, top
  /// to bottom, to its measured height, and shrinks back, its overflow
  /// clipped meanwhile, on the alert's duration and easing; with reduced
  /// motion asked for, it is instant.
  public enum RevealMotion {
    /// The alert's: 400ms, ease-in-out.
    public static let duration = 400
    public static let easing = "ease-in-out"

    static var reduced: Bool { window.matchMedia("(prefers-reduced-motion: reduce)") }

    /// `element`, already in the page and shown, grown from no height to
    /// its own.
    public static func reveal(_ element: DOM.Element) {
      if reduced { return }
      let finished = element.offsetHeight
      element.style.setProperty("height", "0px")
      element.style.setProperty("overflow", "clip")
      element.style.setProperty("transition", "height \(duration)ms \(easing)")
      _ = element.offsetHeight
      // A committed closed frame first, as the alert waits for one.
      _ = window.requestAnimationFrame {
        _ = window.requestAnimationFrame {
          element.style.setProperty("height", "\(finished)px")
          _ = setTimeout(duration + 50) {
            _ = element.style.removeProperty("height")
            _ = element.style.removeProperty("overflow")
            _ = element.style.removeProperty("transition")
          }
        }
      }
    }

    /// `element` shrunk to no height, then `then` (which takes it away).
    public static func conceal(_ element: DOM.Element, then: @escaping @Sendable () -> Void) {
      if reduced {
        then()
        return
      }
      element.style.setProperty("height", "\(element.offsetHeight)px")
      element.style.setProperty("overflow", "clip")
      _ = element.offsetHeight
      element.style.setProperty("transition", "height \(duration)ms \(easing)")
      _ = window.requestAnimationFrame {
        element.style.setProperty("height", "0px")
        _ = setTimeout(duration) {
          _ = element.style.removeProperty("height")
          _ = element.style.removeProperty("overflow")
          _ = element.style.removeProperty("transition")
          then()
        }
      }
    }
  }
#endif
