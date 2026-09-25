#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import EmbeddedSwiftUtilities
  import WebTypes

  public struct AlertView: HTMLContent {
    let alertColor: AlertColor
    let inline: Bool
    let icon: StatusIconView.Status?
    let animatesIn: Bool
    let allowUserDismiss: Bool
    let dismissButtonLabel: String
    let autoDismiss: AutoDismiss
    let clearQueryParam: String?
    let content: [DOM.Node]
    let `class`: String

    /// Apple HIG color for the alert
    public enum AlertColor: String, Sendable {
      case gray
      case blue
      case orange
      case red
      case green

      // Legacy aliases
      public static let notice = AlertColor.gray
      public static let warning = AlertColor.orange
      public static let error = AlertColor.red
      public static let success = AlertColor.green
    }
    
    public enum AutoDismiss: Sendable {
      case disabled
      case `default`  // 10000ms
      case custom(Int)  // milliseconds
    }

    /// Legacy init
    public init(
      type: AlertColor,
      inline: Bool = false,
      icon: StatusIconView.Status? = nil,
      animatesIn: Bool = false,
      allowUserDismiss: Bool = false,
      dismissButtonLabel: String = "Close",
      autoDismiss: AutoDismiss = .disabled,
      clearQueryParam: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.alertColor = type
      self.inline = inline
      self.icon = icon
      self.animatesIn = animatesIn
      self.allowUserDismiss = allowUserDismiss
      self.dismissButtonLabel = dismissButtonLabel
      self.autoDismiss = autoDismiss
      self.clearQueryParam = clearQueryParam
      self.content = content()
      self.`class` = `class`
    }

    public init(
      color: AlertColor = .gray,
      inline: Bool = false,
      icon: StatusIconView.Status? = nil,
      animatesIn: Bool = false,
      allowUserDismiss: Bool = false,
      dismissButtonLabel: String = "Close",
      autoDismiss: AutoDismiss = .disabled,
      clearQueryParam: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.alertColor = color
      self.inline = inline
      self.icon = icon
      self.animatesIn = animatesIn
      self.allowUserDismiss = allowUserDismiss
      self.dismissButtonLabel = dismissButtonLabel
      self.autoDismiss = autoDismiss
      self.clearQueryParam = clearQueryParam
      self.content = content()
      self.`class` = `class`
    }

    /// Registers the component stylesheet when client code may create alerts on
    /// a page that has no server-rendered `AlertView` instance.
    public static func preloadStyleSheet() {
      _ = AlertView(color: .gray, inline: true) { [] }.build()
    }

    public func build() -> DOM.Node {
      // The colour gives the icon; `icon` overrides it (a blue alert that
      // reports a recoverable failure draws the error icon).
      let displayIcon: StatusIconView.Status = {
        if let icon { return icon }
        switch alertColor {
        case .gray, .blue:
          return .info
        case .orange:
          return .warning
        case .red:
          return .error
        case .green:
          return .success
        }
      }()

      let ariaLive: String = {
        switch alertColor {
        case .red: return "assertive"
        default: return "polite"
        }
      }()

      let role: String? = alertColor == .red ? "alert" : nil

      let autoDismissValue: Int? = {
        switch autoDismiss {
        case .disabled:
          return nil
        case .default:
          // Red and blue both persist: red because it needs a person, blue
          // because the condition it reports — a dropped stream, a stalled
          // worker — outlives any 10s timeout. Vanishing while the run is still
          // stopped is worse than not appearing at all.
          return alertColor == .red || alertColor == .blue ? nil : 10000
        case .custom(let ms):
          return alertColor == .red || alertColor == .blue ? nil : ms
        }
      }()

      let alertClasses: String = {
        let base = "alert-view alert-\(alertColor.rawValue)"
        let inlinePart = inline ? " alert-inline" : ""
        // Opens as an AlertAPI alert does, once hydrated (AlertAPI.open);
        // until then it waits closed, but only where script runs.
        let motionPart = animatesIn ? " alert-motion alert-motion-pending" : ""
        let classPart = stringIsEmpty(`class`) ? "" : " \(`class`)"
        return "\(base)\(inlinePart)\(motionPart)\(classPart)"
      }()

      var alert = div {
        // The panel AlertAPI opens and closes. A static alert lays it out as
        // if it weren't there (`display: contents`).
        div {
          span {
            StatusIconView(displayIcon)
          }
          .class("alert-icon")
          .ariaHidden(true)
          .data("color", alertColor.rawValue)
          .style {
            selector("&") {
              display(.flex)
              alignItems(.center)
              justifyContent(.center)
              minWidth(sizeIconMedium)
              width(sizeIconMedium)
              height(sizeIconMedium)
              flexShrink(0)
            }
            selector("& svg") {
              display(.block)
              flexShrink(0)
              width(sizeIconMedium)
              height(sizeIconMedium)
            }
            // Every case of AlertColor, or the missing one silently falls back
            // to the body colour — as blue did, in the only place it was used.
            selector("&[data-color='gray']") { color(colorGray) }
            selector("&[data-color='blue']") { color(colorBlue) }
            selector("&[data-color='orange']") { color(colorOrange) }
            selector("&[data-color='red']") { color(colorRed) }
            selector("&[data-color='green']") { color(colorGreen) }
          }

          div {
            content
          }
          .class("alert-content")
          .style {
            selector("&") {
              display(.flex)
              flexDirection(.column)
              flexGrow(1)
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              fontWeight(fontWeightNormal)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              justifyContent(.center)
            }
          }

          if allowUserDismiss {
            CloseButtonView(ariaLabel: dismissButtonLabel, class: "alert-dismiss")
          }
        }
        .class("alert-motion-content")
      }
      .class(alertClasses)
      .ariaLive(ariaLive)

      if let role = role {
        alert = alert.role(role)
      }

      if let autoDismissValue = autoDismissValue {
        alert = alert.data("auto-dismiss", "\(autoDismissValue)")
      }

      if let param = clearQueryParam {
        alert = alert.data("clear-param", param)
      }

      return
        alert
        .style {
          selector("&") {
            display(.flex)
            alignItems(.center)
            gap(spacing8)
            boxSizing(.borderBox)
          }
          selector("&:not(.alert-inline)") {
            minHeight(px(64))
            padding(spacing12, spacing16)
            borderWidth(borderWidthBase)
            borderStyle(.solid)
            borderRadius(borderRadiusBase)
          }
          selector("&.alert-inline") { padding(spacing8) }
          // A moving alert's padding is its panel's, so the shell can close to
          // nothing while the panel's spacing closes with it.
          selector("&.alert-motion") { padding(0) }
          selector("& .alert-motion-content") { display(.contents) }
          selector("&.alert-motion .alert-motion-content") {
            display(.flex)
            alignItems(.center)
            gap(spacing8)
            width(perc(100))
            minWidth(0)
            boxSizing(.borderBox)
            paddingBlock(spacing12)
            paddingInline(spacing16)
          }
          selector("&.alert-motion.alert-inline .alert-motion-content") { padding(spacing8) }
          // A server-rendered moving alert waits closed until it hydrates, so
          // it never shows open and then snaps shut to open again. Only where
          // script runs (the layout marks <html data-js>); should hydration
          // never come, it shows anyway after 3s.
          selector("[data-js] &.alert-motion-pending") {
            height(0)
            minHeight(0)
            overflow(.hidden)
            animation("alert-motion-unblock 0s linear 3s 1 forwards")
          }
          selector("[data-js] &.alert-motion-pending .alert-motion-content") {
            opacity(0)
            paddingBlock(0)
            animation("alert-motion-unblock 0s linear 3s 1 forwards")
          }
          keyframes("alert-motion-unblock") {
            to {
              height(.auto)
              overflow(.visible)
              opacity(1)
            }
          }
          selector("&.alert-gray:not(.alert-inline)") {
            backgroundColor(backgroundColorGraySubtle)
            borderColor(borderColorGray)
          }
          // Informational rather than a failure: nothing is broken and nothing is
          // asked of the reader. Used for recoverable conditions — a dropped
          // stream, a stalled worker — so red keeps meaning "this needs a person".
          selector("&.alert-blue:not(.alert-inline)") {
            backgroundColor(backgroundColorBlueSubtle)
            borderColor(borderColorBlue)
          }
          selector("&.alert-orange:not(.alert-inline)") {
            backgroundColor(backgroundColorOrangeSubtle)
            borderColor(borderColorOrange)
          }
          selector("&.alert-red:not(.alert-inline)") {
            backgroundColor(backgroundColorRedSubtle)
            borderColor(borderColorRed)
          }
          selector("&.alert-green:not(.alert-inline)") {
            backgroundColor(backgroundColorGreenSubtle)
            borderColor(borderColorGreen)
          }
          selector("&.alert-dynamic") {
            pointerEvents(.auto)
            boxShadow((px(0), px(2), px(8), rgba(0, 0, 0, 0.1)))
          }
          descendant(".alert-motion-content-entering") {
            animation(
              duration: .time(s(0.4)),
              easingFunction: .ease,
              iterationCount: 1,
              fillMode: .both,
              name: .name("alert-motion-content-enter")
            )
          }
          // The dismiss button, server-rendered or built by AlertAPI: no fill
          // of its own on the alert's background, the ✕ in the alert's text
          // colour at the status icon's size, a 40px target, and a tint of
          // the alert's own colour on hover and focus. `.important()` beats
          // ButtonView's plain-weight fill, and `button.` outranks its
          // `.button-view[data-weight]`, which loads later.
          selector("& button.alert-dismiss") {
            display(.flex).important()
            alignItems(.center).important()
            justifyContent(.center).important()
            flexShrink(0)
            alignSelf(.center)
            minWidth(minSizeInteractiveTouch).important()
            minHeight(minSizeInteractiveTouch).important()
            width(minSizeInteractiveTouch).important()
            height(minSizeInteractiveTouch).important()
            padding(0).important()
            border(borderTransparent).important()
            borderRadius(borderRadiusCircle).important()
            backgroundColor(backgroundColorTransparent).important()
            color(colorBase).important()
            cursor(cursorBaseHover)
            transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
          }
          selector("& .alert-dismiss svg") {
            display(.block)
            width(sizeIconMedium).important()
            height(sizeIconMedium).important()
          }
          selector("&.alert-gray .alert-dismiss:hover", "&.alert-gray .alert-dismiss:focus-visible") {
            backgroundColor(backgroundColorGraySubtleHover).important()
          }
          selector("&.alert-gray .alert-dismiss:active") {
            backgroundColor(backgroundColorGraySubtleActive).important()
          }
          selector("&.alert-blue .alert-dismiss:hover", "&.alert-blue .alert-dismiss:focus-visible") {
            backgroundColor(backgroundColorBlueSubtleHover).important()
          }
          selector("&.alert-blue .alert-dismiss:active") {
            backgroundColor(backgroundColorBlueSubtleActive).important()
          }
          selector("&.alert-orange .alert-dismiss:hover", "&.alert-orange .alert-dismiss:focus-visible") {
            backgroundColor(backgroundColorOrangeSubtleHover).important()
          }
          selector("&.alert-orange .alert-dismiss:active") {
            backgroundColor(backgroundColorOrangeSubtleActive).important()
          }
          selector("&.alert-red .alert-dismiss:hover", "&.alert-red .alert-dismiss:focus-visible") {
            backgroundColor(backgroundColorRedSubtleHover).important()
          }
          selector("&.alert-red .alert-dismiss:active") {
            backgroundColor(backgroundColorRedSubtleActive).important()
          }
          selector("&.alert-green .alert-dismiss:hover", "&.alert-green .alert-dismiss:focus-visible") {
            backgroundColor(backgroundColorGreenSubtleHover).important()
          }
          selector("&.alert-green .alert-dismiss:active") {
            backgroundColor(backgroundColorGreenSubtleActive).important()
          }
          keyframes("alert-motion-content-enter") {
            from { opacity(0) }
            to { opacity(1) }
          }
        }

    }
  }
#endif

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  // Remove a single query parameter from a URL search string (e.g. "?error=foo&x=1" → "?x=1")
  private func removeQueryParam(_ search: String, _ param: String) -> String {
    let searchBytes = Array(search.utf8)
    let paramBytes = Array(param.utf8)
    guard !searchBytes.isEmpty, searchBytes[0] == 0x3F else { return search }  // must start with '?'

    // Parse params from after the '?'
    var kept: [[UInt8]] = []
    var i = 1  // skip '?'
    while i < searchBytes.count {
      var j = i
      while j < searchBytes.count && searchBytes[j] != 0x26 { j += 1 }  // find '&'
      // param segment is searchBytes[i..<j]
      // Check if it starts with param=
      let segLen = j - i
      if segLen > paramBytes.count && searchBytes[i + paramBytes.count] == 0x3D {  // '='
        var matches = true
        for k in 0..<paramBytes.count {
          if searchBytes[i + k] != paramBytes[k] {
            matches = false
            break
          }
        }
        if !matches {
          kept.append(Array(searchBytes[i..<j]))
        }
      } else if segLen == paramBytes.count {
        // param with no value (just "error" with no =)
        var matches = true
        for k in 0..<paramBytes.count {
          if searchBytes[i + k] != paramBytes[k] {
            matches = false
            break
          }
        }
        if !matches {
          kept.append(Array(searchBytes[i..<j]))
        }
      } else {
        kept.append(Array(searchBytes[i..<j]))
      }
      i = j + 1  // skip '&'
    }
    if kept.isEmpty { return "" }
    var result: [UInt8] = [0x3F]  // '?'
    for (idx, seg) in kept.enumerated() {
      if idx > 0 { result.append(0x26) }  // '&'
      result.append(contentsOf: seg)
    }
    return String(decoding: result, as: UTF8.self)
  }

  // Helper for parsing Int from String safely
  private func localParseInt(_ str: String) -> Int? {
    var result = 0
    var isNegative = false
    var hasDigits = false
    for byte in str.utf8 {
      if byte == 45 {  // '-'
        if hasDigits { return nil }
        isNegative = true
      } else if byte >= 48 && byte <= 57 {  // 0-9
        result = result * 10 + Int(byte - 48)
        hasDigits = true
      } else {
        return nil
      }
    }
    return hasDigits ? (isNegative ? -result : result) : nil
  }

  /// Dynamic alert creation functions
  public enum AlertAPI {
    private static let motionDuration = 400
    // Safari can paint a flex shell's first text line before resolving its
    // block padding. Keep the shell's padding at zero and animate spacing on
    // its child instead, so both the spacing and content can fade in from the
    // first frame without a flex-shell relayout.
    private static let openingContentDuration = motionDuration

    /// Alert color for dynamic alerts
    public enum AlertColor: Sendable {
      case gray
      case blue
      case orange
      case red
      case green

      // Legacy aliases
      public static let notice = AlertColor.gray
      public static let warning = AlertColor.orange
      public static let error = AlertColor.red
      public static let success = AlertColor.green
    }

    /// Show a dynamic alert without page reload
    public static func show(
      _ text: String,
      type: AlertColor = .gray,
      inline: Bool = false,
      icon: StatusIconView.Status? = nil,
      allowUserDismiss: Bool = true,
      autoDismiss: Bool = false,
      autoDismissTime: Int = 10000,
      container: DOM.Element? = nil,
      onDismiss: (@Sendable () -> Void)? = nil
    ) {

      let alertContainer: DOM.Element

      if let providedContainer = container {
        alertContainer = providedContainer
      } else if let pageAlerts = document.querySelector(".page-alerts") {
        alertContainer = pageAlerts
      } else {
        var existingContainer = document.querySelector(".alert-container")
        if existingContainer == nil {
          let newContainer = document.createElement(.div)
          newContainer.className = "alert-container"
          document.body.appendChild(newContainer)
          existingContainer = newContainer
        }
        guard let c = existingContainer else { return }
        alertContainer = c
      }

      // The same icons as the server's AlertView: the colour gives the icon,
      // `icon` overrides it.
      let displayIcon: StatusIconView.Status
      if let icon {
        displayIcon = icon
      } else {
        switch type {
        case .gray, .blue: displayIcon = .info
        case .orange: displayIcon = .warning
        case .red: displayIcon = .error
        case .green: displayIcon = .success
        }
      }

      let ariaLive: ARIA.Live
      switch type {
      case .red:
        ariaLive = .assertive
      default:
        ariaLive = .polite
      }

      // Create alert element
      // The page could not have linked these: an alert is raised because
      // something happened, long after the render.
      StyleSheetLoader.ensure("alert-view")
      let alertEl = document.createElement(.div)
      let alertColorClass: String
      switch type {
      case .gray:
        alertColorClass = "alert-gray"
      case .blue:
        alertColorClass = "alert-blue"
      case .orange:
        alertColorClass = "alert-orange"
      case .red:
        alertColorClass = "alert-red"
      case .green:
        alertColorClass = "alert-green"
      }
      alertEl.className = inline
        ? "alert-view \(alertColorClass) alert-inline alert-dynamic alert-motion"
        : "alert-view \(alertColorClass) alert-dynamic alert-motion"
      alertEl.setAttribute(.ariaLive, ariaLive)
      if type == .red {
        alertEl.setAttribute(.role, .alert)
      }

      // The shell owns geometry. Giving this inner panel a second height
      // transition makes Safari sequence it after the shell's padding, which
      // produces the visible late jump. It only fades while the shell reveals
      // its natural height through overflow clipping.
      let motionContent = document.createElement(.div)
      motionContent.className = "alert-motion-content"
      motionContent.style.setProperty("display", "flex")
      motionContent.style.setProperty("align-items", "center")
      motionContent.style.setProperty("gap", "var(--spacing-8)")
      motionContent.style.setProperty("width", "100%")
      motionContent.style.setProperty("min-width", "0")
      motionContent.style.setProperty("min-height", "0")
      motionContent.style.setProperty("box-sizing", "border-box")

      // Icon
      let iconElement = document.createElement(.span)
      iconElement.className = "alert-icon"
      iconElement.innerHTML = StatusIconView(displayIcon).render()
      iconElement.setAttribute(.ariaHidden, true)
      switch type {
      case .gray: iconElement.setAttribute(data("color"), "gray")
      case .blue: iconElement.setAttribute(data("color"), "blue")
      case .orange: iconElement.setAttribute(data("color"), "orange")
      case .red: iconElement.setAttribute(data("color"), "red")
      case .green: iconElement.setAttribute(data("color"), "green")
      }
      motionContent.appendChild(iconElement)

      // Content
      let content = document.createElement(.div)
      content.className = "alert-content"
      content.innerHTML = text
      motionContent.appendChild(content)

      // Dismiss button
      if allowUserDismiss {
        let dismissBtn = document.createElement(.button)
        dismissBtn.className = "alert-dismiss"
        dismissBtn.innerHTML = CloseIconView().render()
        // Sized inline as well: the opening measures the alert's height at
        // once, before a just-requested alert-view.css may have arrived, and
        // a button measured at its unstyled size makes the alert jump 2px
        // taller when the motion ends.
        dismissBtn.style.setProperty("width", "var(--min-size-interactive-touch)")
        dismissBtn.style.setProperty("height", "var(--min-size-interactive-touch)")
        dismissBtn.style.setProperty("flex-shrink", "0")
        let buttonType: HTML.Button.`Type` = .button
        dismissBtn.setAttribute(.type, buttonType)
        dismissBtn.setAttribute(.ariaLabel, "Close")

        _ = dismissBtn.addEventListener(.click) { _ in
          dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: true)
        }

        motionContent.appendChild(dismissBtn)
      }

      alertEl.appendChild(motionContent)
      alertContainer.appendChild(alertEl)
      open(alertEl)

      // Auto-dismiss
      if autoDismiss && type != .red {
        _ = setTimeout(autoDismissTime) {
          dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: false)
        }
      }
    }

    /// The one motion every alert opens with: AlertAPI's own, and a
    /// server-rendered one (`AlertView(animatesIn: true)`) when it hydrates.
    /// The alert is in the page, its panel `.alert-motion-content`.
    static func open(_ alertEl: DOM.Element) {
      guard let motionContent = alertEl.querySelector(".alert-motion-content") else { return }
      let inline = alertEl.classList.contains("alert-inline")
      let finishedPadding = inline ? "8px" : "12px"
      let finishedInlinePadding = inline ? "8px" : "16px"
      let finishedMinHeight = inline ? "0px" : "64px"
      // The stylesheet normally puts padding on .alert-view. Safari resolves
      // that flex shell as a line-height box before it applies the padding, so
      // dynamic alerts hold the shell's padding at zero and give it to the
      // inner panel. This keeps one stable outer height timeline.
      alertEl.style.setProperty("box-sizing", "border-box")
      alertEl.style.setProperty("min-height", finishedMinHeight)
      alertEl.style.setProperty("padding", "0px")
      motionContent.style.setProperty("padding-inline", finishedInlinePadding)
      motionContent.style.setProperty("padding-block", finishedPadding)
      // A server-rendered alert waits closed (`alert-motion-pending`) until
      // now; measured open in the same task, it never paints open first.
      alertEl.classList.remove("alert-motion-pending")
      let finishedHeight = alertEl.offsetHeight
      alertEl.setAttribute(data("motion-padding"), finishedPadding)
      if window.matchMedia("(prefers-reduced-motion: reduce)") { return }
      alertEl.style.setProperty("height", "0px")
      alertEl.style.setProperty("min-height", "0")
      motionContent.style.setProperty("padding-block", "0px")
      alertEl.style.setProperty("overflow", "hidden")
      alertEl.style.setProperty(
        "transition", "height \(motionDuration)ms ease-in-out")
      motionContent.style.setProperty("opacity", "0")
      motionContent.style.setProperty(
        "transition",
        "padding-block \(motionDuration)ms ease-in-out")
      _ = alertEl.offsetHeight
      _ = motionContent.offsetHeight
      // Let the closed state paint before changing either
      // property. A forced layout alone can still be coalesced into the
      // insertion frame, especially on WebKit.
      _ = window.requestAnimationFrame {
        // A second frame gives Safari a committed collapsed frame before the
        // transition starts, rather than coalescing both states on insertion.
        _ = window.requestAnimationFrame {
          alertEl.style.setProperty("height", "\(finishedHeight)px")
          motionContent.style.setProperty("padding-block", finishedPadding)
          // A keyframe gives WebKit a concrete transparent first frame. Its
          // transition path can otherwise coalesce with the parent becoming
          // visible and paint this panel at full opacity.
          _ = window.requestAnimationFrame {
            motionContent.classList.add("alert-motion-content-entering")
          }

          _ = setTimeout(motionDuration + 50) {
            // Restore the final minimum before releasing the explicit height;
            // both are the same measured endpoint, so this is not a new frame.
            alertEl.style.setProperty("min-height", finishedMinHeight)
            _ = alertEl.style.removeProperty("height")
            _ = alertEl.style.removeProperty("overflow")
            _ = alertEl.style.removeProperty("transition")
            motionContent.style.setProperty("opacity", "1")
            motionContent.classList.remove("alert-motion-content-entering")
            _ = motionContent.style.removeProperty("transition")
          }
        }
      }
    }

    /// The one motion every alert closes with, then its removal and a
    /// `user_dismissed` or `auto_dismissed` event.
    static func dismissAlert(
      _ element: DOM.Element, onDismiss: (@Sendable () -> Void)?, userInitiated: Bool
    ) {
      let eventType: String
      if userInitiated {
        eventType = "user_dismissed"
      } else {
        eventType = "auto_dismissed"
      }
      guard let motionContent = element.querySelector(".alert-motion-content"),
        !window.matchMedia("(prefers-reduced-motion: reduce)")
      else {
        element.remove()
        onDismiss?()
        element.dispatchEvent(CustomEvent(type: eventType, detail: ""))
        return
      }
      // A static server alert's panel is `display: contents` and its padding
      // the shell's; moving makes the panel the padded box, at the same size.
      element.classList.add("alert-motion")
      let startHeight = element.offsetHeight
      let finishedPadding = element.getAttribute(data("motion-padding")) ?? "12px"
      motionContent.style.setProperty("opacity", "1")
      motionContent.classList.remove("alert-motion-content-entering")
      element.style.setProperty("height", "\(startHeight)px")
      element.style.setProperty("min-height", "0")
      element.style.setProperty("overflow", "hidden")
      _ = element.offsetHeight
      element.style.setProperty(
        "transition", "height \(motionDuration)ms ease-in-out")
      motionContent.style.setProperty("padding-block", finishedPadding)
      motionContent.style.setProperty(
        "transition", "padding-block \(motionDuration)ms ease-in-out, opacity \(motionDuration)ms ease")
      _ = window.requestAnimationFrame {
        element.style.setProperty("height", "0px")
        motionContent.style.setProperty("padding-block", "0px")
        motionContent.style.setProperty("opacity", "0")

        _ = setTimeout(motionDuration) {
          element.remove()
          onDismiss?()
          element.dispatchEvent(CustomEvent(type: eventType, detail: ""))
        }
      }
    }

    /// Convenience methods
    public static func showNotice(
      _ text: String, container: DOM.Element? = nil, onDismiss: (@Sendable () -> Void)? = nil
    ) {
      show(text, type: .gray, container: container, onDismiss: onDismiss)
    }

    public static func showWarning(
      _ text: String, container: DOM.Element? = nil, onDismiss: (@Sendable () -> Void)? = nil
    ) {
      show(text, type: .orange, container: container, onDismiss: onDismiss)
    }

    public static func showError(
      _ text: String, container: DOM.Element? = nil, onDismiss: (@Sendable () -> Void)? = nil
    ) {
      show(text, type: .red, container: container, onDismiss: onDismiss)
    }

    public static func showSuccess(
      _ text: String, container: DOM.Element? = nil, onDismiss: (@Sendable () -> Void)? = nil
    ) {
      show(text, type: .green, autoDismiss: true, container: container, onDismiss: onDismiss)
    }
  }

  private class AlertInstance: @unchecked Sendable {
    private var alertElement: DOM.Element
    private var dismissButton: DOM.Element?
    private var autoDismissTimer: Int32?

    init(alert: DOM.Element) {
      self.alertElement = alert
      self.dismissButton = alert.querySelector(".alert-dismiss")

      bindEvents()
      setupAutoDismiss()
      if alert.classList.contains("alert-motion-pending") {
        AlertAPI.open(alert)
      }
    }

    private func bindEvents() {
      guard let button = dismissButton else { return }

      _ = button.addEventListener(.click) { [self] _ in
        self.dismissAlert(userInitiated: true)
      }
    }

    private func setupAutoDismiss() {
      let autoDismissAttr = alertElement.getAttribute(data("auto-dismiss")) ?? ""
      if !stringEquals(autoDismissAttr, ""), let ms = localParseInt(autoDismissAttr) {
        autoDismissTimer = setTimeout(ms) { [self] in
          self.dismissAlert(userInitiated: false)
        }
      }
    }

    private func dismissAlert(userInitiated: Bool) {
      if let timer = autoDismissTimer {
        clearTimeout(timer)
        autoDismissTimer = nil
      }

      // Clear query param from URL if specified (prevents alert returning on refresh)
      let paramName = alertElement.getAttribute(data("clear-param")) ?? ""
      if !stringEquals(paramName, "") {
        let pathname = window.location.pathname
        let search = window.location.search
        let cleaned = removeQueryParam(search, paramName)
        window.replaceURL("\(pathname)\(cleaned)")
      }

      AlertAPI.dismissAlert(alertElement, onDismiss: nil, userInitiated: userInitiated)
    }
  }

  /// Hydration for server-rendered alerts
  public class AlertHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: AlertHydration?
    private var instances: [AlertInstance] = []

    public init() {
      hydrateAllAlerts()
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".alert-view") != nil else { return }
      instance = AlertHydration()
    }

    /// An alert put on the page after its own pass — one cloned from a
    /// rendered `AlertView` to say something that has just happened.
    public static func hydrate(alert: DOM.Element) {
      guard let instance else {
        instance = AlertHydration()
        return
      }
      instance.instances.append(AlertInstance(alert: alert))
    }

    private func hydrateAllAlerts() {
      let allAlerts = document.querySelectorAll(".alert-view")

      for alert in allAlerts {
        let instance = AlertInstance(alert: alert)
        instances.append(instance)
      }
    }
  }
#endif
