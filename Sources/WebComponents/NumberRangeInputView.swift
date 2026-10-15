import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

// NumberRangeInputView builds on both sides so NumberRangeInputFactory can
// draw one on the client (the filter bar adds fields there). build() stays
// embedded-safe: stringIsEmpty/stringEquals, `if let` rather than `== nil`
// on a String?.

/// A field that holds a range of numbers: two number inputs side by side,
/// Start and End, each a decimal (a cost to the cent and below), either left
/// empty for an open end. A hidden input carries the range under `name` as
/// one value (`NumberRangeValue`, `1000..5000`, `..5000`, `1000..`), empty
/// when both ends are; the two inputs submit nothing of their own.
public struct NumberRangeInputView: HTMLContent {
  let id: String
  let name: String
  /// `start..end`; empty for none.
  let value: String
  /// What the inputs are named for a screen reader: "Tokens" reads as
  /// "Tokens start" and "Tokens end".
  let label: String
  let fullWidth: Bool
  let disabled: Bool
  let `class`: String

  public init(
    id: String,
    name: String,
    value: String = "",
    label: String = "",
    fullWidth: Bool = true,
    disabled: Bool = false,
    class: String = ""
  ) {
    self.id = id
    self.name = name
    self.value = value
    self.label = label
    self.fullWidth = fullWidth
    self.disabled = disabled
    self.`class` = `class`
  }

  /// The value a form submits for two typed ends.
  static func param(start: String, end: String) -> String {
    NumberRangeValue.from(start: start, end: end)?.param ?? ""
  }

  public func build() -> DOM.Node {
    let range = NumberRangeValue.parse(value)
    let rootClass = stringIsEmpty(`class`)
      ? "number-range-input-view\(fullWidth ? " number-range-input-full-width" : "")"
      : "number-range-input-view\(fullWidth ? " number-range-input-full-width" : "") \(`class`)"
    let named = stringIsEmpty(label) ? "" : "\(label) "

    return div {
      input()
        .type(.hidden)
        .name(name)
        .value(range?.param ?? "")
        .class("number-range-input-value")

      div {
        TextInputView(
          id: "\(id)-start",
          name: "",
          placeholder: "Start",
          value: range?.start ?? "",
          type: .number,
          disabled: disabled,
          fullWidth: true,
          class: "number-range-input-start",
          inputMode: .decimal,
          inputAttributes: [("step", "any"), ("aria-label", "\(named)start")]
        )
        TextInputView(
          id: "\(id)-end",
          name: "",
          placeholder: "End",
          value: range?.end ?? "",
          type: .number,
          disabled: disabled,
          fullWidth: true,
          class: "number-range-input-end",
          inputMode: .decimal,
          inputAttributes: [("step", "any"), ("aria-label", "\(named)end")]
        )
      }
      .class("number-range-input-ends")
    }
    .class(rootClass)
    .style {
      selector("&") {
        display(.inlineBlock)
        fontFamily(typographyFontSans)
      }
      selector("&.number-range-input-full-width") { width(perc(100)) }
      descendant(".number-range-input-ends") {
        display(.flex)
        alignItems(.center)
        gap(spacing8)
      }
      descendant(".number-range-input-ends > .text-input-view") {
        flex(1)
        minWidth(0)
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  private final class NumberRangeInputInstance: @unchecked Sendable {
    private let valueInput: HTML.HTMLInputElement?
    private let startInput: HTML.HTMLInputElement?
    private let endInput: HTML.HTMLInputElement?

    init(root: DOM.Element) {
      valueInput = root.querySelector(".number-range-input-value") as? HTML.HTMLInputElement
      startInput = root.querySelector(".number-range-input-start .text-input-input") as? HTML.HTMLInputElement
      endInput = root.querySelector(".number-range-input-end .text-input-input") as? HTML.HTMLInputElement
      root.setAttribute(data("hydrated"), true)
      if let startInput { _ = startInput.addEventListener(.input) { [self] _ in self.commit() } }
      if let endInput { _ = endInput.addEventListener(.input) { [self] _ in self.commit() } }
    }

    /// The value, from the ends as typed.
    private func commit() {
      valueInput?.value = NumberRangeInputView.param(start: startInput?.value ?? "", end: endInput?.value ?? "")
      valueInput?.dispatchEvent(.input)
      valueInput?.dispatchEvent(.change)
    }
  }

  public class NumberRangeInputHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: NumberRangeInputHydration?
    private var instances: [NumberRangeInputInstance] = []

    public init() {
      for root in document.querySelectorAll(".number-range-input-view") {
        hydrate(element: root)
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".number-range-input-view") != nil else { return }
      instance = NumberRangeInputHydration()
    }

    /// Binds one input; one already bound is left as it is.
    public func hydrate(element: DOM.Element) {
      if let _ = element.getAttribute(data("hydrated")) { return }
      instances.append(NumberRangeInputInstance(root: element))
    }
  }

  public enum NumberRangeInputFactory {
    public static func createElement(
      id: String,
      name: String,
      value: String = "",
      label: String = "",
      fullWidth: Bool = true,
      class: String = "",
      hydrator: NumberRangeInputHydration? = nil
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = NumberRangeInputView(
        id: id,
        name: name,
        value: value,
        label: label,
        fullWidth: fullWidth,
        class: `class`
      )
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      hydrator?.hydrate(element: element)
      return element
    }
  }
#endif
