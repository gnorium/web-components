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
    let customIcon: String?
    let fadeIn: Bool
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
      customIcon: String? = nil,
      fadeIn: Bool = false,
      allowUserDismiss: Bool = false,
      dismissButtonLabel: String = "Close",
      autoDismiss: AutoDismiss = .disabled,
      clearQueryParam: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.alertColor = type
      self.inline = inline
      self.customIcon = customIcon
      self.fadeIn = fadeIn
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
      customIcon: String? = nil,
      fadeIn: Bool = false,
      allowUserDismiss: Bool = false,
      dismissButtonLabel: String = "Close",
      autoDismiss: AutoDismiss = .disabled,
      clearQueryParam: String? = nil,
      class: String = "",
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.alertColor = color
      self.inline = inline
      self.customIcon = customIcon
      self.fadeIn = fadeIn
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
      _ = AlertView(color: .gray, inline: true, customIcon: "") { [] }.build()
    }

    public func build() -> DOM.Node {
      let defaultIcon: String = {
        switch alertColor {
        case .gray:
          return "ℹ"
        case .blue:
          // Informational, not a fault: a dropped stream or a stalled worker is
          // recoverable, so it gets the info glyph rather than the cross.
          return "ℹ"
        case .orange:
          return "⚠"
        case .red:
          return "✗"
        case .green:
          return "✓"
        }
      }()

      let displayIcon = customIcon ?? defaultIcon
      let shouldShowIcon = alertColor != .gray || customIcon != nil

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
        let fadePart = fadeIn ? " alert-fade-in" : ""
        let classPart = stringIsEmpty(`class`) ? "" : " \(`class`)"
        return "\(base)\(inlinePart)\(fadePart)\(classPart)"
      }()

      var alert = div {
        if shouldShowIcon {
          span {
            displayIcon
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
              fontSize(sizeIconMedium)
              lineHeight(1)
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
          selector("&.alert-dynamic .alert-dismiss") {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
            minWidth(sizeIconMedium)
            width(sizeIconMedium)
            height(sizeIconMedium)
            marginLeft(spacing8)
            padding(0)
            border(borderTransparent)
            backgroundColor(backgroundColorTransparent)
            color(colorSubtle)
            cursor(cursorBaseHover)
            borderRadius(borderRadiusBase)
            transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            flexShrink(0)
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
      customIcon: String? = nil,
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

      let unicodeInfo = "i"
      let unicodeWarning = "⚠"
      let unicodeCross = "✗"
      let unicodeCheckmark = "✓"

      let defaultIcon: String = {
        switch type {
        case .gray:
          return unicodeInfo
        case .blue:
          return unicodeInfo
        case .orange:
          return unicodeWarning
        case .red:
          return unicodeCross
        case .green:
          return unicodeCheckmark
        }
      }()

      let displayIcon: String
      var shouldShowIcon = type != .gray
      if let custom = customIcon {
        displayIcon = custom
        shouldShowIcon = true
      } else {
        displayIcon = defaultIcon
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
        ? "alert-view \(alertColorClass) alert-inline alert-dynamic alert-fade-in"
        : "alert-view \(alertColorClass) alert-dynamic alert-fade-in"
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

      // Icon
      if shouldShowIcon {
        let icon = document.createElement(.span)
        icon.className = "alert-icon"
        icon.innerHTML = displayIcon
        icon.setAttribute(.ariaHidden, true)
        switch type {
        case .gray: icon.setAttribute(data("color"), "gray")
        case .blue: icon.setAttribute(data("color"), "blue")
        case .orange: icon.setAttribute(data("color"), "orange")
        case .red: icon.setAttribute(data("color"), "red")
        case .green: icon.setAttribute(data("color"), "green")
        }
        motionContent.appendChild(icon)
      }

      // Content
      let content = document.createElement(.div)
      content.className = "alert-content"
      content.innerHTML = text
      motionContent.appendChild(content)

      // Dismiss button
      if allowUserDismiss {
        let dismissBtn = document.createElement(.button)
        dismissBtn.className = "alert-dismiss"
        dismissBtn.innerHTML =
          "<svg width=\"20\" height=\"20\" viewBox=\"0 0 20 20\" xmlns=\"http://www.w3.org/2000/svg\" fill=\"currentColor\"><path d=\"M4.34 2.93l12.73 12.73-1.41 1.41L2.93 4.35Z\"/><path d=\"M17.07 4.34L4.34 17.07l-1.41-1.41L15.66 2.93Z\"/></svg>"
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
      // Use the logical block axis while resolving the token to pixels before
      // the transition, so WebKit has two directly interpolable values.
      let finishedPadding = inline ? "8px" : "12px"
      let finishedMinHeight = inline ? "0px" : "64px"
      // alert-view.css is loaded on demand. Pin the final geometry before
      // measuring so a late stylesheet cannot turn a 28px measurement into
      // the component's actual 64px minimum after the animation completes.
      alertEl.style.setProperty("box-sizing", "border-box")
      alertEl.style.setProperty("min-height", finishedMinHeight)
      alertEl.style.setProperty("padding-block", finishedPadding)
      let finishedHeight = alertEl.offsetHeight
      alertEl.setAttribute(data("motion-padding"), finishedPadding)
      alertEl.style.setProperty("height", "0px")
      alertEl.style.setProperty("min-height", "0")
      alertEl.style.setProperty("padding-block", "0px")
      alertEl.style.setProperty("overflow", "hidden")
      alertEl.style.setProperty("transition", "height 400ms ease, padding-block 400ms ease")
      motionContent.style.setProperty("opacity", "0")
      motionContent.style.setProperty("transition", "opacity 400ms ease")
      _ = alertEl.offsetHeight
      // Let the closed state paint before changing either
      // property. A forced layout alone can still be coalesced into the
      // insertion frame, especially on WebKit.
      _ = window.requestAnimationFrame {
        // A second frame gives Safari a committed collapsed frame before the
        // transition starts, rather than coalescing both states on insertion.
        _ = window.requestAnimationFrame {
          alertEl.style.setProperty("height", "\(finishedHeight)px")
          alertEl.style.setProperty("padding-block", finishedPadding)
          motionContent.style.setProperty("opacity", "1")

          _ = setTimeout(motionDuration + 50) {
            // Restore the final minimum before releasing the explicit height;
            // both are the same measured endpoint, so this is not a new frame.
            alertEl.style.setProperty("min-height", finishedMinHeight)
            _ = alertEl.style.removeProperty("height")
            _ = alertEl.style.removeProperty("overflow")
            _ = alertEl.style.removeProperty("transition")
            _ = motionContent.style.removeProperty("opacity")
            _ = motionContent.style.removeProperty("transition")
          }
        }
      }

      // Auto-dismiss
      if autoDismiss && type != .red {
        _ = setTimeout(autoDismissTime) {
          dismissAlert(alertEl, onDismiss: onDismiss, userInitiated: false)
        }
      }
    }

    private static func dismissAlert(
      _ element: DOM.Element, onDismiss: (@Sendable () -> Void)?, userInitiated: Bool
    ) {
      guard let motionContent = element.querySelector(".alert-motion-content")
      else { return }
      let startHeight = element.offsetHeight
      let finishedPadding = element.getAttribute(data("motion-padding")) ?? "12px"
      element.style.setProperty("height", "\(startHeight)px")
      element.style.setProperty("min-height", "0")
      element.style.setProperty("overflow", "hidden")
      _ = element.offsetHeight
      element.style.setProperty("transition", "height 400ms ease, padding-block 400ms ease")
      element.style.setProperty("padding-block", finishedPadding)
      motionContent.style.setProperty("transition", "opacity 400ms ease")
      _ = window.requestAnimationFrame {
        element.style.setProperty("height", "0px")
        element.style.setProperty("padding-block", "0px")
        motionContent.style.setProperty("opacity", "0")

        _ = setTimeout(motionDuration) {
          element.remove()
          onDismiss?()

          let eventType: String
          if userInitiated {
            eventType = "user_dismissed"
          } else {
            eventType = "auto_dismissed"
          }
          let event = CustomEvent(type: eventType, detail: "")
          element.dispatchEvent(event)
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

      alertElement.classList.remove("alert-fade-in")
      alertElement.classList.add("alert-fade-out")

      _ = setTimeout(300) { [self] in
        self.alertElement.remove()

        let eventType: String
        if userInitiated {
          eventType = "user_dismissed"
        } else {
          eventType = "auto_dismissed"
        }
        let event = CustomEvent(type: eventType, detail: "")
        self.alertElement.dispatchEvent(event)
      }
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

    private func hydrateAllAlerts() {
      let allAlerts = document.querySelectorAll(".alert-view")

      for alert in allAlerts {
        let instance = AlertInstance(alert: alert)
        instances.append(instance)
      }
    }
  }
#endif
