#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebTypes

  /// A slider: one value on a horizontal track, chosen by dragging its
  /// handle, by a click or a tap anywhere on the track, or from the
  /// keyboard—the arrows a `step`, Page Up and Page Down a `pageStep`, Home
  /// and End the ends. The WAI-ARIA slider pattern: the root is the focusable
  /// `role="slider"`, its value in `aria-valuenow` and, when the number alone
  /// says too little (a time, a size), in words in `aria-valuetext`.
  ///
  /// A medium control's height (40px) on every side of its thin track, so
  /// the whole box is the touch target. The fill runs from the track's start
  /// to the handle, both placed by `--slider-fraction` (0 to 1) on the root,
  /// logical edges throughout, so right-to-left mirrors it. Optional `ticks`
  /// mark values along the track—small gaps cut into it, as a video's
  /// chapters are.
  ///
  /// The client (`Slider`) moves it and tells its host: `slider-input` as the
  /// value changes (a drag, each move), `slider-change` once it is chosen (a
  /// drag let go, a click, a key), each carrying the value in its detail. A
  /// drag holds `data-dragging="true"` on the root, so a host updating the
  /// value itself (a playing position) leaves the reader's hand alone.
  public struct SliderView: HTMLContent {
    let value: Int
    let min: Int
    let max: Int
    let step: Int
    let pageStep: Int
    let valueText: String?
    let ticks: [Int]
    let disabled: Bool
    let ariaLabel: String?
    let `class`: String

    public init(
      value: Int = 0,
      min: Int = 0,
      max: Int = 100,
      step: Int = 1,
      pageStep: Int? = nil,
      valueText: String? = nil,
      ticks: [Int] = [],
      disabled: Bool = false,
      ariaLabel: String? = nil,
      class: String = ""
    ) {
      self.min = min
      self.max = Swift.max(min, max)
      self.value = Swift.min(Swift.max(value, min), Swift.max(min, max))
      self.step = Swift.max(1, step)
      self.pageStep = Swift.max(1, pageStep ?? Swift.max(1, step) * 10)
      self.valueText = valueText
      self.ticks = ticks
      self.disabled = disabled
      self.ariaLabel = ariaLabel
      self.`class` = `class`
    }

    /// Where `value` stands between the ends, 0 to 1.
    static func fraction(_ value: Int, min: Int, max: Int) -> Double {
      guard max > min else { return 0 }
      return Double(Swift.min(Swift.max(value, min), max) - min) / Double(max - min)
    }

    public func build() -> DOM.Node {
      var slider = div {
        div {
          div {}
            .class("slider-fill")
          div {
            for tick in ticks.filter({ $0 > min && $0 < max }) {
              span {}
                .class("slider-tick")
                .setAttribute("style", "--slider-tick: \(Self.fraction(tick, min: min, max: max))")
            }
          }
          .class("slider-ticks")
        }
        .class("slider-track")
        div {}
          .class("slider-handle")
      }
      .class(`class`.isEmpty ? "slider-view" : "slider-view \(`class`)")
      .role(.slider)
      .tabindex(disabled ? -1 : 0)
      .setAttribute("aria-orientation", "horizontal")
      .ariaValueMin(min)
      .ariaValueMax(max)
      .ariaValueNow(value)
      .ariaDisabled(disabled)
      .data("step", step)
      .data("page-step", pageStep)
      .data("disabled", disabled)
      .data("dragging", false)
      .setAttribute("style", "--slider-fraction: \(Self.fraction(value, min: min, max: max))")
      if let valueText { slider = slider.setAttribute("aria-valuetext", valueText) }
      if let ariaLabel { slider = slider.ariaLabel(ariaLabel) }

      return slider.style {
        selector("&") {
          position(.relative)
          display(.flex)
          alignItems(.center)
          flexGrow(1)
          minWidth(spacing48)
          height(ButtonView.ButtonSize.medium.minSize)
          cursor(.pointer)
          // The track is the slider's own: a touch drag moves the handle, it
          // never scrolls the page.
          CSS.Property("touch-action", "none")
          CSS.Property("user-select", "none")
          CSS.Property("-webkit-user-select", "none")
          outline(borderWidthBase, .solid, borderColorTransparent)
        }
        descendant(".slider-track") {
          position(.relative)
          flexGrow(1)
          height(spacing4)
          borderRadius(borderRadiusPill)
          backgroundColor(backgroundColorBlueSubtle)
          overflow(.hidden)
        }
        descendant(".slider-fill") {
          position(.absolute)
          insetBlockStart(0)
          insetBlockEnd(0)
          insetInlineStart(0)
          CSS.Property("inline-size", "calc(var(--slider-fraction, 0) * 100%)")
          backgroundColor(backgroundColorBlue)
        }
        descendant(".slider-ticks") {
          position(.absolute)
          inset(0)
          pointerEvents(.none)
        }
        // A tick is a gap cut into the track, the page's surface showing
        // through: one look on the fill and off it.
        descendant(".slider-tick") {
          position(.absolute)
          insetBlockStart(0)
          insetBlockEnd(0)
          CSS.Property("inset-inline-start", "calc(var(--slider-tick, 0) * 100%)")
          width(borderWidthThick)
          marginInlineStart(calc("-1 * \(borderWidthBase.value)"))
          backgroundColor(backgroundColorBase)
        }
        descendant(".slider-handle") {
          position(.absolute)
          insetBlockStart(calc("50% - \(spacing8.value)"))
          CSS.Property("inset-inline-start", "calc(var(--slider-fraction, 0) * 100%)")
          marginInlineStart(calc("-1 * \(spacing8.value)"))
          width(spacing16)
          height(spacing16)
          boxSizing(.borderBox)
          borderRadius(borderRadiusCircle)
          backgroundColor(backgroundColorBlue)
          border(borderWidthBase, .solid, backgroundColorBlue)
          pointerEvents(.none)
        }
        // Keyboard focus rings the handle, as every control is ringed.
        selector("&:focus-visible .slider-handle") {
          outline(borderWidthThick, .solid, borderColorBlueFocus)
          outlineOffset(borderWidthBase)
        }
        selector("&[data-disabled='true']") {
          cursor(cursorNotAllowed).important()
        }
        selector("&[data-disabled='true'] .slider-track") {
          backgroundColor(backgroundColorDisabled)
        }
        selector("&[data-disabled='true'] .slider-fill", "&[data-disabled='true'] .slider-handle") {
          backgroundColor(colorDisabled)
          borderColor(colorDisabled)
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

  /// Moves every SliderView (see the view) and lets its host move it.
  public enum Slider {
    /// The drag under way: its slider, and the document's listeners that
    /// follow it until it is let go.
    nonisolated(unsafe) static var dragged: DOM.Element? = nil
    nonisolated(unsafe) static var moveListener: Int32 = -1
    nonisolated(unsafe) static var upListener: Int32 = -1
    nonisolated(unsafe) static var cancelListener: Int32 = -1

    public static func hydrateIfPresent() {
      guard document.querySelector(".slider-view") != nil else { return }
      hydrate(in: document.body)
    }

    /// The sliders under `root`—a fragment drawn after the page's own
    /// pass—each bound once.
    public static func hydrate(in root: DOM.Element) {
      if root.classList.contains("slider-view") { bind(root) }
      for slider in root.querySelectorAll(".slider-view") { bind(slider) }
    }

    static func attribute(_ slider: DOM.Element, _ name: String, _ fallback: Int) -> Int {
      Int(slider.getAttribute(name) ?? "") ?? fallback
    }

    /// The slider's value, its least and its greatest.
    public static func value(of slider: DOM.Element) -> Int { attribute(slider, "aria-valuenow", 0) }
    public static func minimum(of slider: DOM.Element) -> Int { attribute(slider, "aria-valuemin", 0) }
    public static func maximum(of slider: DOM.Element) -> Int { attribute(slider, "aria-valuemax", 0) }

    static func isDisabled(_ slider: DOM.Element) -> Bool {
      stringEquals(slider.getAttribute(data("disabled")) ?? "", "true")
    }

    /// Whether the reader is dragging it.
    public static func isDragging(_ slider: DOM.Element) -> Bool {
      stringEquals(slider.getAttribute(data("dragging")) ?? "", "true")
    }

    /// Its value set to `value` (held between its ends) and said as
    /// `valueText` where given; no event—the host moved it.
    public static func set(_ slider: DOM.Element, value: Int, valueText: String? = nil) {
      let low = minimum(of: slider)
      let high = max(low, maximum(of: slider))
      let held = min(max(value, low), high)
      slider.setAttribute("aria-valuenow", intToString(held))
      if let valueText { slider.setAttribute("aria-valuetext", valueText) }
      let fraction = high > low ? Double(held - low) / Double(high - low) : 0
      slider.style.setProperty("--slider-fraction", doubleToString(fraction))
    }

    /// Its ends set to `min` and `max`, its value held between them.
    public static func setRange(_ slider: DOM.Element, min low: Int, max high: Int) {
      slider.setAttribute("aria-valuemin", intToString(low))
      slider.setAttribute("aria-valuemax", intToString(max(low, high)))
      set(slider, value: value(of: slider))
    }

    /// Its ticks: a mark at each of `values` strictly between its ends.
    public static func setTicks(_ slider: DOM.Element, _ values: [Int]) {
      guard let layer = slider.querySelector(".slider-ticks") else { return }
      for tick in layer.querySelectorAll(".slider-tick") { tick.remove() }
      let low = minimum(of: slider)
      let high = maximum(of: slider)
      guard high > low else { return }
      for value in values where value > low && value < high {
        let tick = document.createElement(.span)
        tick.className = "slider-tick"
        tick.style.setProperty("--slider-tick", doubleToString(Double(value - low) / Double(high - low)))
        layer.appendChild(tick)
      }
    }

    static func tell(_ slider: DOM.Element, _ type: String) {
      slider.dispatchEvent(CustomEvent(type: type, detail: intToString(value(of: slider))))
    }

    /// The value under the pointer at `x`: the track's start edge its least,
    /// its end edge its greatest, mirrored right to left.
    static func value(of slider: DOM.Element, atX x: Double) -> Int? {
      guard let track = slider.querySelector(".slider-track"), let box = track.getBoundingClientRect(), box.width > 0
      else { return nil }
      var fraction = (x - box.left) / box.width
      if let _ = slider.closest("[dir='rtl']") { fraction = 1 - fraction }
      fraction = min(max(fraction, 0), 1)
      let low = minimum(of: slider)
      let high = maximum(of: slider)
      return low + Int((Double(high - low) * fraction).rounded())
    }

    /// Moved to `value` by the reader: set, and told as an input.
    static func move(_ slider: DOM.Element, to value: Int) {
      guard value != Self.value(of: slider) else { return }
      set(slider, value: value)
      tell(slider, "slider-input")
    }

    static func endDrag(commit: Bool) {
      guard let slider = dragged else { return }
      dragged = nil
      if moveListener >= 0 { document.removeEventListener(.pointermove, moveListener) }
      if upListener >= 0 { document.removeEventListener(.pointerup, upListener) }
      if cancelListener >= 0 { document.removeEventListener(.pointercancel, cancelListener) }
      moveListener = -1
      upListener = -1
      cancelListener = -1
      slider.setAttribute(data("dragging"), "false")
      if commit { tell(slider, "slider-change") }
    }

    static func bind(_ slider: DOM.Element) {
      guard !stringEquals(slider.getAttribute(data("hydrated")) ?? "", "true") else { return }
      slider.setAttribute(data("hydrated"), "true")
      // A press anywhere on it: the handle there at once, then following
      // the pointer until it is let go, wherever it goes.
      _ = slider.addEventListener(.pointerdown) { (event: Event) in
        guard !isDisabled(slider), event.button == 0 else { return }
        event.preventDefault()
        slider.focus()
        endDrag(commit: false)
        dragged = slider
        slider.setAttribute(data("dragging"), "true")
        if let picked = value(of: slider, atX: event.clientX) { move(slider, to: picked) }
        moveListener = document.addEventListener(.pointermove) { (event: Event) in
          guard let slider = dragged, let picked = value(of: slider, atX: event.clientX) else { return }
          move(slider, to: picked)
        }
        upListener = document.addEventListener(.pointerup) { (_: Event) in endDrag(commit: true) }
        cancelListener = document.addEventListener(.pointercancel) { (_: Event) in endDrag(commit: true) }
      }
      _ = slider.addEventListener(.keydown) { (event: Event) in
        guard !isDisabled(slider) else { return }
        let key = event.key
        let step = max(1, attribute(slider, data("step"), 1))
        let page = max(1, attribute(slider, data("page-step"), step * 10))
        // Right and Up are forward, mirrored right to left for the arrows
        // along the track.
        let rtl: Bool = {
          if let _ = slider.closest("[dir='rtl']") { return true }
          return false
        }()
        let now = value(of: slider)
        let next: Int
        if stringEquals(key, "ArrowRight") {
          next = rtl ? now - step : now + step
        } else if stringEquals(key, "ArrowLeft") {
          next = rtl ? now + step : now - step
        } else if stringEquals(key, "ArrowUp") {
          next = now + step
        } else if stringEquals(key, "ArrowDown") {
          next = now - step
        } else if stringEquals(key, "PageUp") {
          next = now + page
        } else if stringEquals(key, "PageDown") {
          next = now - page
        } else if stringEquals(key, "Home") {
          next = minimum(of: slider)
        } else if stringEquals(key, "End") {
          next = maximum(of: slider)
        } else {
          return
        }
        event.preventDefault()
        let held = min(max(next, minimum(of: slider)), maximum(of: slider))
        guard held != now else { return }
        set(slider, value: held)
        tell(slider, "slider-input")
        tell(slider, "slider-change")
      }
    }
  }
#endif
