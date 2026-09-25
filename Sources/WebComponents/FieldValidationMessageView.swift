import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// The message under a field's control: a status icon and the words, in the
/// status colour. `FieldView` draws it on the server; `FieldValidationHydration`
/// draws the same view on the client when a form validates itself.
public struct FieldValidationMessageView: HTMLContent {
  let id: String
  let status: Status
  let message: String

  public enum Status: Sendable {
    case error
    case warning
    case success
  }

  public init(id: String = "", status: Status, message: String) {
    self.id = id
    self.status = status
    self.message = message
  }

  /// Builds the view once so a page links its stylesheet: the client may draw
  /// a message on a page whose server render had none.
  public static func preloadStyleSheet() {
    _ = FieldValidationMessageView(status: .error, message: "").build()
  }

  public func build() -> DOM.Node {
    let iconStatus: StatusIconView.Status
    let statusName: String
    switch status {
    case .error:
      iconStatus = .error
      statusName = "error"
    case .warning:
      iconStatus = .warning
      statusName = "warning"
    case .success:
      iconStatus = .success
      statusName = "success"
    }

    var message = div {
      span { IconView(icon: { s in StatusIconView(iconStatus, width: s, height: s) }, size: .small) }
        .class("field-validation-message-icon")
        .ariaHidden(true)

      span { self.message }
        .class("field-validation-message-text")
    }
    .class("field-validation-message-view")
    .data("status", statusName)

    if !stringIsEmpty(id) {
      message = message.id(id)
    }

    return message.style {
      selector("&") {
        display(.flex)
        alignItems(.flexStart)
        gap(spacing4)
        fontSize(fontSizeSmall14)
        lineHeight(lineHeightSmall22)
      }
      selector("&[data-status='error']") { color(colorRed) }
      selector("&[data-status='warning']") { color(colorOrange) }
      selector("&[data-status='success']") { color(colorGreen) }
      // As tall as the message's first line, so the icon centres on it.
      descendant(".field-validation-message-icon") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
        height(lineHeightSmall22)
      }
      descendant(".field-validation-message-text") { flex(1) }
    }
  }
}

/// What a control's own validation says when a constraint fails, one message
/// per failure. A control carries them as `data-` attributes; any that is
/// missing falls back to a plain default. Match the server's words where it
/// has them.
public struct ConstraintMessages: Sendable {
  public let valueMissing: String?
  public let typeMismatch: String?
  public let patternMismatch: String?
  /// Shorter than `minlength` or longer than `maxlength`.
  public let length: String?
  /// Differs from the control named by `matches` (a confirmation).
  public let mismatch: String?

  public init(
    valueMissing: String? = nil,
    typeMismatch: String? = nil,
    patternMismatch: String? = nil,
    length: String? = nil,
    mismatch: String? = nil
  ) {
    self.valueMissing = valueMissing
    self.typeMismatch = typeMismatch
    self.patternMismatch = patternMismatch
    self.length = length
    self.mismatch = mismatch
  }

  /// The `data-` attributes a control carries, name then value.
  public var dataAttributes: [(String, String)] {
    var attributes: [(String, String)] = []
    if let valueMissing { attributes.append(("value-missing", valueMissing)) }
    if let typeMismatch { attributes.append(("type-mismatch", typeMismatch)) }
    if let patternMismatch { attributes.append(("pattern-mismatch", patternMismatch)) }
    if let length { attributes.append(("length-mismatch", length)) }
    if let mismatch { attributes.append(("mismatch", mismatch)) }
    return attributes
  }
}

#if CLIENT
  import WebAPIs

  /// Inline field errors for every form with `novalidate`: the browser's own
  /// bubbles never show, and our messages sit under each control instead.
  ///
  /// A form opts in with `novalidate` alone; its controls keep `required`,
  /// `minlength`, `maxlength`, `pattern` and their `type`, which the browser
  /// still evaluates (`validity`) and autofill and mobile keyboards still
  /// read. A confirmation names the control it repeats with `data-matches`.
  /// The words come from `ConstraintMessages` (`data-value-missing`, …).
  ///
  /// On submit every control is checked; an invalid form is neither sent nor
  /// handed to the page's own submit handler (this listens in the capture
  /// phase on the document, ahead of them), and the first invalid control
  /// takes the focus. From then on the form's controls are checked as the
  /// reader types, so a message goes the moment its field is fixed, and a
  /// confirmation follows the field it repeats.
  public class FieldValidationHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: FieldValidationHydration?

    static let controls =
      "input[required], input[minlength], input[maxlength], input[pattern], input[type='email'], input[type='url'], input[data-matches], textarea[required], textarea[minlength], textarea[maxlength]"

    public static func hydrateIfPresent() {
      guard let _ = document.querySelector("form[novalidate]") else { return }
      guard instance == nil else { return }
      instance = FieldValidationHydration()
    }

    init() {
      _ = document.addEventListener(
        .submit,
        { event in
          guard let form = event.target, let _ = form.getAttribute("novalidate") else { return }
          guard let firstInvalid = FieldValidationHydration.check(form: form) else { return }
          firstInvalid.focus()
          event.preventDefault()
          event.stopPropagation()
        },
        capture: true)

      // Not on blur: a message drawn as a field loses focus moves the
      // button under the pointer, and the click that blurred it misses.
      _ = document.addEventListener(.input) { event in
        guard let control = FieldValidationHydration.control(event.target) else { return }
        guard let form = control.closest("form") else { return }
        FieldValidationHydration.revalidateTouched(in: form)
      }
    }

    /// The event's target when it is a constrained control of a form that
    /// validates itself.
    static func control(_ target: DOM.Element?) -> DOM.Element? {
      guard let target, let _ = target.closest("form[novalidate]") else { return nil }
      guard let form = target.closest("form") else { return nil }
      for control in form.querySelectorAll(controls) where control.id == target.id {
        return control
      }
      return nil
    }

    /// Checks every control, shows or clears each message, and focuses the
    /// first invalid one. True when the form may be sent.
    public static func validate(form: DOM.Element) -> Bool {
      guard let firstInvalid = check(form: form) else { return true }
      firstInvalid.focus()
      return false
    }

    /// Checks every control and shows or clears each message; the first
    /// invalid control, if any.
    static func check(form: DOM.Element) -> DOM.Element? {
      var firstInvalid: DOM.Element?
      for control in form.querySelectorAll(controls) {
        guard isLive(control) else {
          clear(control)
          continue
        }
        _ = control.setAttribute("data-validation-touched", "true")
        if let message = message(for: control) {
          show(message, on: control)
          if firstInvalid == nil { firstInvalid = control }
        } else {
          clear(control)
        }
      }
      return firstInvalid
    }

    /// Re-checks the controls already touched: a confirmation follows the
    /// field it repeats.
    static func revalidateTouched(in form: DOM.Element) {
      for control in form.querySelectorAll(controls) {
        guard let _ = control.getAttribute("data-validation-touched") else { continue }
        guard isLive(control) else {
          clear(control)
          continue
        }
        if let message = message(for: control) {
          show(message, on: control)
        } else {
          clear(control)
        }
      }
    }

    /// Enabled and drawn: a control in a collapsed or hidden section is not
    /// the reader's to fill, so it neither blocks the form nor takes focus.
    static func isLive(_ control: DOM.Element) -> Bool {
      if let _ = control.getAttribute("disabled") { return false }
      guard let rect = control.getBoundingClientRect() else { return false }
      return rect.width > 0 || rect.height > 0
    }

    /// The first constraint the control's value breaks, in words.
    static func message(for control: DOM.Element) -> String? {
      let value: String
      let validity: HTML.ValidityState
      var isCheckbox = false
      if let input = control as? HTML.HTMLInputElement {
        value = input.value
        validity = input.validity
        isCheckbox = stringEquals(control.getAttribute("type") ?? "", "checkbox")
      } else if let textArea = control as? HTML.HTMLTextAreaElement {
        value = textArea.value
        validity = textArea.validity
      } else {
        return nil
      }

      if validity.valueMissing {
        return said(control, "data-value-missing", isCheckbox ? "Check this box to continue." : "Fill in this field.")
      }
      if validity.typeMismatch {
        let type = control.getAttribute("type") ?? ""
        let fallback = stringEquals(type, "url") ? "Enter a valid URL." : "Enter a valid email address."
        return said(control, "data-type-mismatch", fallback)
      }
      // Counted here, not read from `validity`: the browser flags a length
      // only after the reader has typed, not for a value the page filled.
      let length = value.utf16.count
      if length > 0 {
        if let minimum = parseInt(control.getAttribute("minlength") ?? ""), length < minimum {
          return said(control, "data-length-mismatch", "Use at least \(minimum) characters.")
        }
        if let maximum = parseInt(control.getAttribute("maxlength") ?? ""), length > maximum {
          return said(control, "data-length-mismatch", "Use at most \(maximum) characters.")
        }
      }
      if validity.patternMismatch {
        return said(control, "data-pattern-mismatch", "Match the format asked for.")
      }
      if let otherID = control.getAttribute("data-matches"), !stringIsEmpty(value),
        let other = document.querySelector("#\(otherID)") as? HTML.HTMLInputElement,
        !stringEquals(value, other.value)
      {
        return said(control, "data-mismatch", "The two entries don't match.")
      }
      return nil
    }

    static func said(_ control: DOM.Element, _ attribute: String, _ fallback: String) -> String {
      if let message = control.getAttribute(attribute), !stringIsEmpty(message) { return message }
      return fallback
    }

    static func messageID(_ control: DOM.Element) -> String {
      "\(control.getAttribute("id") ?? "field")-validation-message"
    }

    /// The control's error state, the message under it, and the ARIA that
    /// ties the two together.
    static func show(_ text: String, on control: DOM.Element) {
      let id = messageID(control)
      if let existing = document.querySelector("#\(id)") {
        if let words = existing.querySelector(".field-validation-message-text") {
          words.textContent = text
        }
      } else {
        let html = FieldValidationMessageView(id: id, status: .error, message: text).render()
        if let field = control.closest(".field-view") {
          field.insertAdjacentHTML(.beforeend, html)
        } else if let anchor = control.closest(".checkbox-view") ?? control.closest(".text-input-view")
          ?? control.closest(".text-area-view")
        {
          anchor.insertAdjacentHTML(.afterend, html)
        } else {
          control.insertAdjacentHTML(.afterend, html)
        }
      }

      _ = control.setAttribute("aria-invalid", "true")
      let describedBy = control.getAttribute("aria-describedby") ?? ""
      var tokens: [String] = []
      var present = false
      for token in stringSplit(describedBy, separator: " ") where !stringIsEmpty(token) {
        tokens.append(token)
        if stringEquals(token, id) { present = true }
      }
      if !present {
        tokens.append(id)
        _ = control.setAttribute("aria-describedby", stringJoin(tokens, separator: " "))
      }
      setErrorState(true, on: control)
    }

    static func clear(_ control: DOM.Element) {
      let id = messageID(control)
      if let existing = document.querySelector("#\(id)") {
        existing.remove()
      }
      control.removeAttribute("aria-invalid")
      if let describedBy = control.getAttribute("aria-describedby") {
        var kept: [String] = []
        for token in stringSplit(describedBy, separator: " ") where !stringEquals(token, id) && !stringIsEmpty(token) {
          kept.append(token)
        }
        if kept.isEmpty {
          control.removeAttribute("aria-describedby")
        } else {
          _ = control.setAttribute("aria-describedby", stringJoin(kept, separator: " "))
        }
      }
      setErrorState(false, on: control)
    }

    /// The Codex error state of whichever control this is: a red border.
    static func setErrorState(_ on: Bool, on control: DOM.Element) {
      if let textInput = control.closest(".text-input-view") {
        if on {
          _ = textInput.classList.add("text-input-error")
          _ = textInput.setAttribute("data-status", "error")
        } else {
          _ = textInput.classList.remove("text-input-error")
          textInput.removeAttribute("data-status")
        }
      } else if let textArea = control.closest(".text-area-view") {
        if on {
          _ = textArea.classList.add("text-area-error")
          _ = textArea.setAttribute("data-status", "error")
        } else {
          _ = textArea.classList.remove("text-area-error")
          textArea.removeAttribute("data-status")
        }
      } else if let checkbox = control.closest(".checkbox-view"),
        let icon = checkbox.querySelector(".checkbox-icon")
      {
        _ = icon.setAttribute("data-status", on ? "error" : "default")
      }
    }
  }
#endif
