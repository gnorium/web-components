import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A multi-line text input that allows manual resizing if needed.
public struct TextAreaView: HTMLContent {
  let id: String
  let name: String
  let placeholder: String
  let value: String
  let status: ValidationStatus
  let disabled: Bool
  let readonly: Bool
  let required: Bool
  let rows: Int
  let autosize: Bool
  let startIcon: String?
  /// Text that stands at the start of the field, inside it and never part
  /// of its value, as TextInputView's `prefix`: a tree row's number, "1.1"
  /// (user, 2026-11-03), sans and subtle, the "." after it, on the first
  /// line; its own column, every line of the value after it. Nil for none.
  let prefix: String?
  /// More classes on the prefix: what the page reads it as (a tree row's
  /// `record-node-number`, which its outline writes again as it moves).
  let prefixClass: String
  /// Text that stands at the end of the field, inside it and never part of
  /// its value, as `prefix` stands at its start: a tree row's date, "AD
  /// 1603" (user, 2026-11-03), sans and subtle, on the first line; its own
  /// column, no line of the value under it, the value kept clear of it by
  /// its advance in the sans (`SansAdvance`). Nil for none.
  let suffix: String?
  /// More classes on the suffix: what the page reads it as.
  let suffixClass: String
  /// A control at the very end of the field, inside it and after its
  /// suffix, on its first line: a tree row's info (user, 2026-11-03), a
  /// line high and a line wide. Its own control: its own cursor and its
  /// own click, which never focuses the field; the value kept clear of it
  /// as of an end icon. Empty for none.
  let endControl: [DOM.Node]
  let endIcon: String?
  let labelText: String
  let tooltip: String?
  let fullWidth: Bool
  /// The id of the form this submits with, when it sits outside that form.
  let form: String?
  /// Its accessible name where no label is drawn: a field that stands
  /// in a heading.
  let ariaLabel: String?
  let `class`: String
  /// Whether the label carries the lighter "(optional)" aside after its
  /// text, as LabelView draws it: not part of the label text.
  let optional: Bool
  let optionalFlag: String
  /// What stands after the label's text (and its "(optional)"), before
  /// its tooltip: a record page's reference marks. Not label text.
  let labelMarks: [DOM.Node]

  public enum ValidationStatus: String, Sendable {
    case `default`
    case error
  }

  public init(
    id: String,
    name: String,
    placeholder: String = "",
    value: String = "",
    status: ValidationStatus = .default,
    disabled: Bool = false,
    readonly: Bool = false,
    required: Bool = false,
    rows: Int = 4,
    autosize: Bool = false,
    startIcon: String? = nil,
    endIcon: String? = nil,
    prefix: String? = nil,
    prefixClass: String = "",
    suffix: String? = nil,
    suffixClass: String = "",
    endControl: [DOM.Node] = [],
    label: String = "",
    optional: Bool = false,
    optionalFlag: String = "(optional)",
    labelMarks: [DOM.Node] = [],
    tooltip: String? = nil,
    fullWidth: Bool = true,
    form: String? = nil,
    ariaLabel: String? = nil,
    class: String = ""
  ) {
    self.id = id
    self.name = name
    self.placeholder = placeholder
    self.value = value
    self.status = status
    self.disabled = disabled
    self.readonly = readonly
    self.required = required
    self.rows = rows
    self.autosize = autosize
    self.startIcon = startIcon
    self.prefix = prefix
    self.prefixClass = prefixClass
    self.suffix = suffix
    self.suffixClass = suffixClass
    self.endControl = endControl
    self.endIcon = endIcon
    self.labelText = label
    self.tooltip = tooltip
    self.fullWidth = fullWidth
    self.form = form
    self.ariaLabel = ariaLabel
    self.`class` = `class`
    self.optional = optional
    self.optionalFlag = optionalFlag
    self.labelMarks = labelMarks
  }

  public func build() -> DOM.Node {
    var textAreaInput = textarea(value)
      .id(id)
      .name(name)
      .placeholder(placeholder)
      .disabled(disabled)
      .readonly(readonly)
      .required(required)
      .rows(rows)
      .class("text-area-input")

    if autosize {
      textAreaInput = textAreaInput.data("autosize", "true")
    }
    if let form {
      textAreaInput = textAreaInput.form(form)
    }
    // Named for assistive technology where no label is drawn.
    if let ariaLabel {
      textAreaInput = textAreaInput.ariaLabel(ariaLabel)
    }

    var hasStartIcon = false
    var hasEndIcon = false
    if let _ = startIcon { hasStartIcon = true }
    if let _ = endIcon { hasEndIcon = true }
    let hasPrefix = if let _ = prefix { true } else { false }
    let hasSuffix = if let _ = suffix { true } else { false }
    let hasEndControl = !endControl.isEmpty
    let stateClass = "\(fullWidth ? "text-area-full-width " : "")\(disabled ? "text-area-disabled " : "")\(readonly ? "text-area-read-only " : "")\(status == .error ? "text-area-error " : "")\(autosize ? "text-area-autosize " : "")\(hasStartIcon ? "text-area-has-start-icon " : "")\(hasEndIcon ? "text-area-has-end-icon " : "")\(hasPrefix ? "text-area-has-prefix " : "")\(hasSuffix ? "text-area-has-suffix " : "")\(hasEndControl ? "text-area-has-end-control" : "")"
    let textAreaClass = stringIsEmpty(`class`)
      ? "text-area-view \(stateClass)"
      : "text-area-view \(stateClass) \(`class`)"

    var container = div {
      if let icon = startIcon {
        span { icon }
          .class("text-area-start-icon")
          .ariaHidden(true)
      }
      if let prefix {
        span { prefix }
          .class(stringIsEmpty(prefixClass) ? "text-area-prefix" : "text-area-prefix \(prefixClass)")
          .ariaHidden(true)
      }
      textAreaInput
      if let suffix {
        span { suffix }
          .class(stringIsEmpty(suffixClass) ? "text-area-suffix" : "text-area-suffix \(suffixClass)")
      }
      if let icon = endIcon {
        span { icon }
          .class("text-area-end-icon")
          .ariaHidden(true)
      }
      if hasEndControl {
        span { endControl }
          .class("text-area-end-control")
      }
    }
    .class(textAreaClass)

    if status == .error {
      container = container.data("status", "error")
    }

    let styledContainer = container.style {
      // A prefix's width: as far as the number runs in the sans, its "."
      // after it (`OutlineNumberAdvance`, thousandths of the em), as
      // TextInputView's; written again as it changes (`setPrefix`).
      if let prefix {
        customProperty("--text-area-prefix-width", Self.prefixWidth(prefix))
      }
      // A suffix's width: as far as its text runs in the sans
      // (`SansAdvance`).
      if let suffix {
        customProperty("--text-area-suffix-width", SansAdvance.length(suffix))
      }
      selector("&") {
        position(.relative)
        display(.inlineBlock)
      }
      selector("&.text-area-full-width") { width(perc(100)) }
      selector("&.text-area-has-start-icon", "&.text-area-has-end-icon") {
        display(.flex)
        alignItems(.flexStart)
        gap(spacing8)
      }
      descendant(".text-area-input") {
        // A block: inline, it would sit on the line's baseline with a
        // descender's gap under it.
        display(.block)
        width(perc(100))
        // Inset 12 inside the border on every side, as TextInputView's.
        padding(spacing12)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        lineHeight(lineHeightSmall22)
        color(colorBase)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        outline(.none)
        cursor(cursorText)
        resize(.vertical)
        overflowY(.auto)
      }
      // A disabled field's value reads in the base color on the disabled
      // ground, as every disabled field's does; its placeholder stays the
      // placeholder's. So does a field in a part drawn disabled
      // (`DisabledRegion`).
      selector("&.text-area-disabled .text-area-input", ":where([data-disabled-region='true']) & .text-area-input") {
        color(colorBase)
        customProperty("-webkit-text-fill-color", colorBase)
        backgroundColor(backgroundColorDisabled)
        borderColor(borderColorDisabled)
        cursor(cursorNotAllowed)
        resize(.none)
      }
      selector("&.text-area-read-only .text-area-input") {
        backgroundColor(backgroundColorNeutralSubtle)
      }
      // In error, the field's ring in red, as TextInputView's is drawn.
      selector("&.text-area-error .text-area-input") {
        borderColor(borderColorRed)
        outline(borderWidthBase, .solid, borderColorRed)
        outlineOffset(px(0))
      }
      selector("&.text-area-autosize .text-area-input") {
        resize(.none)
        fieldSizing(.content)
        maxHeight(rem(18))
      }
      selector("&.text-area-autosize.text-area-disabled .text-area-input", ":where([data-disabled-region='true']) &.text-area-autosize .text-area-input") {
        overflowY(.hidden)
      }
      selector("&.text-area-has-start-icon .text-area-input") {
        paddingInlineStart(calc(spacing12 + lineHeightSmall22 + spacing8)).important()
      }
      selector("&.text-area-has-end-icon .text-area-input") {
        paddingInlineEnd(calc(spacing12 + lineHeightSmall22 + spacing8)).important()
      }
      // The value starts after its prefix, 8 from it, on every line: the
      // prefix a column of its own, which no wrapped line runs under.
      selector("&.text-area-has-prefix .text-area-input") {
        paddingInlineStart(calc(spacing12 + (`var`("--text-area-prefix-width") as CSS.Length) + spacing8)).important()
      }
      // The value ends before its end control and its suffix, 8 from
      // each, on every line: each a column of its own, which no wrapped
      // line runs under.
      selector("&.text-area-has-end-control .text-area-input") {
        paddingInlineEnd(calc(spacing12 + lineHeightSmall22 + spacing8)).important()
      }
      selector("&.text-area-has-suffix .text-area-input") {
        paddingInlineEnd(calc(spacing12 + (`var`("--text-area-suffix-width") as CSS.Length) + spacing8)).important()
      }
      selector("&.text-area-has-suffix.text-area-has-end-control .text-area-input") {
        paddingInlineEnd(
          calc(spacing12 + (`var`("--text-area-suffix-width") as CSS.Length) + spacing8 + lineHeightSmall22 + spacing8)
        ).important()
      }
      // As TextInputView's prefix, a tree row's number and a dropdown
      // option's: sans, subtle, a "." after it; on the first line, as
      // tall as it, where a start icon stands.
      descendant(".text-area-prefix") {
        position(.absolute)
        top(calc(borderWidthBase + spacing12))
        insetInlineStart(calc(borderWidthBase + spacing12))
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        lineHeight(lineHeightSmall22)
        color(colorSubtle)
        whiteSpace(.nowrap)
        pointerEvents(.none)
      }
      descendant(".text-area-prefix::after") {
        content("\".\"")
      }
      // Its suffix as its prefix, at its end: sans, subtle, on the first
      // line; before its end control, where it has one.
      descendant(".text-area-suffix") {
        position(.absolute)
        top(calc(borderWidthBase + spacing12))
        insetInlineEnd(calc(borderWidthBase + spacing12))
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        lineHeight(lineHeightSmall22)
        color(colorSubtle)
        whiteSpace(.nowrap)
        pointerEvents(.none)
      }
      selector("&.text-area-has-end-control .text-area-suffix") {
        insetInlineEnd(calc(borderWidthBase + spacing12 + lineHeightSmall22 + spacing8))
      }
      // Its end control where an end icon stands, a line high and wide,
      // taking its own pointer.
      descendant(".text-area-end-control") {
        position(.absolute)
        top(calc(borderWidthBase + spacing12))
        insetInlineEnd(calc(borderWidthBase + spacing12))
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        minWidth(lineHeightSmall22)
        height(lineHeightSmall22)
        customProperty("--size-icon-small", lineHeightSmall22.value)
      }
      // The same rule as TextInputView's: color only. An opacity on top of
      // the color made a textarea's placeholder read as a different grey
      // from the input beside it, and WebKit ignored the color altogether.
      selector("& .text-area-input::placeholder") {
        color(colorPlaceholder).important()
        customProperty("-webkit-text-fill-color", colorPlaceholder).important()
      }
      selector("&:not(.text-area-disabled):not(.text-area-read-only) .text-area-input:focus") {
        borderColor(borderColorBlueFocus).important()
        outline(borderWidthBase, .solid, borderColorBlueFocus).important()
        outlineOffset(px(0)).important()
      }
      // No hover state: a field's border says where the field is, and focus
      // says where the keyboard is. A third state between them only makes the
      // field under the pointer look like the field being typed in. The search
      // bar has none either.
      selector("& .text-area-start-icon", "& .text-area-end-icon") {
        position(.absolute)
        // On the first line, as tall as it: the border, then the inset.
        top(calc(borderWidthBase + spacing12))
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        width(lineHeightSmall22)
        height(lineHeightSmall22)
        // The field's line: an icon a caller sized with the icon token
        // fills it.
        customProperty("--size-icon-small", lineHeightSmall22.value)
        color(colorSubtle)
        pointerEvents(.none)
      }
      descendant(".text-area-start-icon") { left(calc(borderWidthBase + spacing12)) }
      descendant(".text-area-end-icon") { right(calc(borderWidthBase + spacing12)) }
    }

    if stringIsEmpty(labelText) { return styledContainer }

    return div {
      label {
        span { labelText }
          .class("text-area-label")
        if optional {
          span { optionalFlag }
            .class("text-area-optional-flag")
            .data("optional-flag", true)
        }
        labelMarks
        if let tooltip = tooltip {
          TooltipView(tooltip: tooltip, placement: .bottom) {
            IconView(icon: { size in InfoIconView(size: size) }, size: lineHeightSmall22)
          }
        }
      }
      .class("text-area-label-row")
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          fontSize(fontSizeMedium16)
          fontWeight(600)
          color(colorBase)
          fontFamily(typographyFontSans)
        }
        // An aside affixed to the label, not label text: LabelView's
        // `.label-optional-flag`.
        descendant(".text-area-optional-flag") {
          fontWeight(fontWeightNormal)
          color(colorSubtle)
        }
      }
      styledContainer
    }
    .class("text-area-field")
    .style {
      // The label row and the box in a column, 8px apart as every field's
      // label and control (FieldView, DropdownView, TextInputView): the gap,
      // never a margin on the label. Start-aligned, so a box that is not
      // full width keeps its own width.
      selector("&") {
        display(.flex)
        flexDirection(.column)
        alignItems(.flexStart)
        gap(spacing8)
      }
    }
  }
}

extension TextAreaView {
  /// A prefix's width, `--text-area-prefix-width`: its number's advance in
  /// the sans with the "." after it (`OutlineNumberAdvance`).
  static func prefixWidth(_ prefix: String) -> String {
    stringJoin(["calc(", intToString(OutlineNumberAdvance.of(prefix)), " * 0.001em)"], separator: "")
  }
}

#if CLIENT
  import WebAPIs

  extension TextAreaView {
    /// A field's prefix (`prefix`) written anew—a tree row's number as its
    /// outline renumbers it—and its width with it, so its value still
    /// starts 8 after it.
    public static func setPrefix(_ prefix: DOM.Element, _ text: String) {
      prefix.textContent = text
      if let view = prefix.closest(".text-area-view") {
        view.style.setProperty("--text-area-prefix-width", prefixWidth(text))
      }
    }
  }

  public class TextAreaHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TextAreaHydration?
    public init() {
      // A right-click should land the paste that follows it; Safari does not
      // focus on the click, so focus when the context menu opens.
      for area in document.querySelectorAll(".text-area-input") {
        _ = area.addEventListener(.contextmenu) { _ in
          area.focus()
        }
      }
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".text-area-view") != nil else { return }
      instance = TextAreaHydration()
    }

  }
#endif
