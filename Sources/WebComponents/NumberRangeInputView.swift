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

/// A field that holds a range of numbers, picked as a date range is: one
/// field in its place (its words: "1000–5000", "From 1000", "Up to 5000"),
/// opening a dropdown with the range's two ends, one over the other—"Cost
/// start", "Cost end"—each a decimal (a cost to the cent and below), either
/// left empty for an open end (user, 2026-10-15). A hidden input carries the
/// range under `name` as one value (`NumberRangeValue`, `1000..5000`,
/// `..5000`, `1000..`), empty when both ends are; the ends submit nothing of
/// their own.
public struct NumberRangeInputView: HTMLContent {
  let id: String
  let name: String
  /// `start..end`; empty for none.
  let value: String
  /// What the range is of: the field's placeholder ("Cost") and its ends'
  /// labels ("Cost start", "Cost end").
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

  /// The field's words for two typed ends; empty for none.
  static func words(start: String, end: String) -> String {
    NumberRangeValue.from(start: start, end: end)?.label ?? ""
  }

  public func build() -> DOM.Node {
    let range = NumberRangeValue.parse(value)
    let rootClass = stringIsEmpty(`class`)
      ? "number-range-input-view\(fullWidth ? " number-range-input-full-width" : "")"
      : "number-range-input-view\(fullWidth ? " number-range-input-full-width" : "") \(`class`)"
    let named = stringIsEmpty(label) ? "Range" : label

    return div {
      input()
        .type(.hidden)
        .name(name)
        .value(range?.param ?? "")
        .class("number-range-input-value")

      TextInputView(
        id: id,
        name: "",
        placeholder: named,
        value: range?.label ?? "",
        disabled: disabled,
        readonly: true,
        fullWidth: fullWidth,
        class: "number-range-input-field",
        inputMode: HTML.InputMode.none
      )

      // A dropdown's mark, turning as its menu opens.
      AnimatedUpDownChevronView(id: "\(id)-chevron", expanded: false, size: lineHeightSmall22, class: "number-range-input-indicator")

      PopoverView(
        id: "\(id)-popover",
        placement: .bottomStart,
        showsArrow: false,
        ariaLabel: named,
        class: "number-range-input-popover",
        body: {
          // Start over end, one field a row, as a date range's ends.
          div {
            TextInputView(
              id: "\(id)-start", name: "", placeholder: "\(named) start", value: range?.start ?? "",
              type: .number, disabled: disabled, label: "\(named) start", tooltip: "Start of the range, included.",
              fullWidth: true, class: "number-range-input-start", inputMode: .decimal,
              inputAttributes: [("step", "any")])
            TextInputView(
              id: "\(id)-end", name: "", placeholder: "\(named) end", value: range?.end ?? "",
              type: .number, disabled: disabled, label: "\(named) end", tooltip: "End of the range, included.",
              fullWidth: true, class: "number-range-input-end", inputMode: .decimal,
              inputAttributes: [("step", "any")])
          }
          .class("number-range-input-ends")
        }
      )
    }
    .class(rootClass)
    .data("disabled", disabled)
    .style {
      selector("&") {
        position(.relative)
        display(.inlineBlock)
        fontFamily(typographyFontSans)
      }
      selector("&.number-range-input-full-width") { width(perc(100)) }
      // A control, read only: a pointer, the base ground, room for the mark.
      descendant(".number-range-input-field .text-input-input") {
        paddingInlineEnd(calc(spacing12 + lineHeightSmall22 + spacing12)).important()
        backgroundColor(backgroundColorBase).important()
        cursor(.pointer).important()
        userSelect(.none)
      }
      descendant(".number-range-input-field .text-input-input:focus") {
        borderColor(borderColorBlue).important()
        outline(borderWidthBase, .solid, borderColorBlueFocus).important()
        outlineOffset(px(0)).important()
      }
      selector("&[data-open='true'] .number-range-input-field .text-input-input") {
        borderColor(borderColorBlue).important()
        outline(borderWidthBase, .solid, borderColorBlueFocus).important()
        outlineOffset(px(0)).important()
      }
      // Where a select's chevron sits: 12 inside the border, centered.
      descendant(".number-range-input-indicator") {
        position(.absolute)
        insetInlineEnd(calc(borderWidthBase + spacing12))
        top(perc(50))
        transform("translateY(-50%)")
        pointerEvents(.none)
        color(colorBase)
      }
      // Exactly the field's width, as a dropdown's menu is; under it, border
      // only.
      descendant(".number-range-input-popover") {
        insetInlineStart(0).important()
        insetInlineEnd(0).important()
        width(perc(100)).important()
        minWidth(0).important()
        maxWidth(.none).important()
        boxShadow(.none).important()
        boxSizing(.borderBox)
        top(calc("100% + \(spacing4.value)"))
      }
      descendant(".number-range-input-ends") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
      }
      // A phone's controls one size down (`ButtonView.phoneStep`): the ends
      // a medium field's 40, not 48.
      media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
        selector("\(ButtonView.phoneStep) & .number-range-input-ends .text-input-input") {
          padding(spacing8).important()
        }
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  private final class NumberRangeInputInstance: @unchecked Sendable {
    private let root: DOM.Element
    private let valueInput: HTML.HTMLInputElement?
    private let field: HTML.HTMLInputElement?
    private let popover: DOM.Element?
    private let startInput: HTML.HTMLInputElement?
    private let endInput: HTML.HTMLInputElement?
    private let chevron: AnimatedUpDownChevronInstance?
    private var isOpen = false

    init(root: DOM.Element) {
      self.root = root
      valueInput = root.querySelector(".number-range-input-value") as? HTML.HTMLInputElement
      field = root.querySelector(".number-range-input-field .text-input-input") as? HTML.HTMLInputElement
      popover = root.querySelector(".number-range-input-popover")
      startInput = root.querySelector(".number-range-input-start .text-input-input") as? HTML.HTMLInputElement
      endInput = root.querySelector(".number-range-input-end .text-input-input") as? HTML.HTMLInputElement
      chevron = AnimatedUpDownChevronInstance(element: root)
      root.setAttribute(data("hydrated"), true)
      if let field {
        field.setAttribute("aria-haspopup", "dialog")
        field.setAttribute("aria-expanded", "false")
        if let popover, let popoverID = popover.getAttribute("id") { field.setAttribute("aria-controls", popoverID) }
        _ = field.addEventListener(.click) { [self] _ in
          if self.isOpen { self.close(returnFocus: false) } else { self.open() }
        }
        _ = field.addEventListener(.keydown) { [self] event in
          let key = event.key
          if stringEquals(key, "Enter") || stringEquals(key, " ") || stringEquals(key, "ArrowDown") {
            event.preventDefault()
            self.open()
          } else if stringEquals(key, "Backspace") || stringEquals(key, "Delete") {
            event.preventDefault()
            self.startInput?.value = ""
            self.endInput?.value = ""
            self.commit()
          }
        }
      }
      for end in [startInput, endInput] {
        guard let end else { continue }
        _ = end.addEventListener(.input) { [self] _ in self.commit() }
      }
      if let popover {
        _ = popover.addEventListener(.keydown) { [self] event in
          guard stringEquals(event.key, "Escape") else { return }
          event.preventDefault()
          self.close(returnFocus: true)
        }
      }
      // A press anywhere else closes it, as every menu on the page.
      _ = document.addEventListener(.mousedown) { [self] event in
        guard self.isOpen, let target = event.target else { return }
        if !self.root.contains(target) { self.close(returnFocus: false) }
      }
    }

    private func open() {
      guard !isOpen, let popover else { return }
      if stringEquals(root.getAttribute(data("disabled")) ?? "", "true") { return }
      isOpen = true
      popover.setAttribute(data("open"), true)
      popover.setAttribute(data("placement"), "bottom-start")
      root.setAttribute(data("open"), true)
      field?.setAttribute("aria-expanded", "true")
      chevron?.morph(toExpanded: true)
      startInput?.focus(DOM.FocusOptions(preventScroll: true))
    }

    private func close(returnFocus: Bool) {
      guard isOpen else { return }
      isOpen = false
      popover?.setAttribute(data("open"), false)
      root.setAttribute(data("open"), false)
      field?.setAttribute("aria-expanded", "false")
      chevron?.morph(toExpanded: false)
      if returnFocus { field?.focus(DOM.FocusOptions(preventScroll: true)) }
    }

    /// The value and the field's words, from the ends as typed.
    private func commit() {
      let start = startInput?.value ?? ""
      let end = endInput?.value ?? ""
      field?.value = NumberRangeInputView.words(start: start, end: end)
      valueInput?.value = NumberRangeInputView.param(start: start, end: end)
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
