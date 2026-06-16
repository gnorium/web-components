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
  let endIcon: String?
  let labelText: String
  let tooltip: String?
  let fullWidth: Bool
  let `class`: String

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
    label: String = "",
    tooltip: String? = nil,
    fullWidth: Bool = true,
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
    self.endIcon = endIcon
    self.labelText = label
    self.tooltip = tooltip
    self.fullWidth = fullWidth
    self.`class` = `class`
  }

  @CSSBuilder
  private func textAreaViewCSS(_ hasStartIcon: Bool, _ hasEndIcon: Bool) -> [CSSOM.CSSRule] {
    position(.relative)
    display(.inlineBlock)
    if fullWidth {
      width(perc(100))
    }

    if hasStartIcon || hasEndIcon {
      display(.flex)
      alignItems(.flexStart)
      gap(spacing8)
    }
  }

  @CSSBuilder
  private func textAreaInputCSS(
    _ disabled: Bool, _ readonly: Bool, _ status: ValidationStatus, _ autosize: Bool,
    _ hasStartIcon: Bool, _ hasEndIcon: Bool
  ) -> [CSSOM.CSSRule] {
    width(perc(100))
    minHeight(px(rows * 22 + 18))
    padding(spacing8, px(15))
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    lineHeight(lineHeightSmall22)
    color(disabled ? colorDisabled : colorBase)
    backgroundColor(disabled ? backgroundColorDisabled : (readonly ? backgroundColorNeutralSubtle : backgroundColorBase))
    border(borderWidthBase, .solid, status == .error ? borderColorRed : (disabled ? borderColorDisabled : borderColorBase))
    borderRadius(borderRadiusBase)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
    outline(.none)
    cursor(disabled ? cursorNotAllowed : cursorText)

    if autosize {
      resize(.none)
      fieldSizing(.content)
      minHeight(em(2.5))
      if disabled {
        overflowY(.hidden)
      } else {
        overflowY(.auto)
        maxHeight(rem(18))
      }
    } else {
      if disabled { resize(.none) } else { resize(.vertical) }
      overflowY(.auto)
    }

    if hasStartIcon {
      paddingInlineStart(calc(px(15) + sizeIconMedium + spacing8)).important()
    }

    if hasEndIcon {
      paddingInlineEnd(calc(px(15) + sizeIconMedium + spacing8)).important()
    }

    pseudoElement(.placeholder) {
      color(colorPlaceholder).important()
      opacity(opacityIconPlaceholder).important()
    }

    pseudoClass(.focus, .not(.disabled), .not(.readOnly)) {
      borderColor(borderColorBlueFocus).important()
      outline(.none).important()
      boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
    }

    pseudoClass(.hover, .focus, .not(.disabled), .not(.readOnly)) {
      borderColor(borderColorBlue).important()
    }
  }

  @CSSBuilder
  private func textAreaIconCSS(_ isStartIcon: Bool) -> [CSSOM.CSSRule] {
    position(.absolute)
    top(spacing12)
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    width(sizeIconMedium)
    height(sizeIconMedium)
    color(colorSubtle)
    pointerEvents(.none)

    if isStartIcon {
      left(px(15))
    } else {
      right(px(15))
    }
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

    var hasStartIcon = false
    var hasEndIcon = false
    if let _ = startIcon { hasStartIcon = true }
    if let _ = endIcon { hasEndIcon = true }

    textAreaInput = textAreaInput.style {
      textAreaInputCSS(disabled, readonly, status, autosize, hasStartIcon, hasEndIcon)
    }

    var container = div {
      if let icon = startIcon {
        span { icon }
          .class("text-area-start-icon")
          .ariaHidden(true)
          .style { textAreaIconCSS(true) }
      }
      textAreaInput
      if let icon = endIcon {
        span { icon }
          .class("text-area-end-icon")
          .ariaHidden(true)
          .style { textAreaIconCSS(false) }
      }
    }
    .class(stringIsEmpty(`class`) ? "text-area-view" : stringJoin(["text-area-view", `class`], separator: " "))

    if status == .error {
      container = container.data("status", "error")
    }

    if stringIsEmpty(labelText) {
      return container.style {
        textAreaViewCSS(hasStartIcon, hasEndIcon)
      }
    }
    return div {
      label {
        span { labelText }
        if let tooltip = tooltip {
          TooltipView(tooltip: tooltip, placement: .bottom) {
            IconView { InfoIconView() }
          }
        }
      }
      .style {
        display(.flex)
        alignItems(.center)
        gap(spacing4)
        fontSize(fontSizeSmall14)
        fontWeight(600)
        color(colorBase)
        marginBlockEnd(spacing4)
        fontFamily(typographyFontSans)
      }
      container.style {
        textAreaViewCSS(hasStartIcon, hasEndIcon)
      }
    }
  }
}

#if CLIENT
  import WebAPIs

  private class TextAreaInstance: @unchecked Sendable {
    private var textArea: DOM.Element
    private var input: DOM.Element?
    private var autosize: Bool = false

    init(textArea: DOM.Element) {
      self.textArea = textArea

      input = textArea.querySelector(".text-area-input")

      // Check if autosize is enabled
      if let autosizeAttr = textArea.querySelector(".text-area-input")?.getAttribute(
        "data-autosize")
      {
        autosize = stringEquals(autosizeAttr, "true")
      }

      // For disabled textareas, CSS fieldSizing:content handles sizing without JS interference.
      // Running resizeToFit() on a disabled element sets an inline height that overrides
      // fieldSizing:content, causing placeholder misalignment until a browser reflow.
      var isDisabled = false
      if let _ = input?.getAttribute("disabled") { isDisabled = true }

      if autosize && !isDisabled {
        bindAutosizeEvents()
        resizeToFit()
      }
    }

    private func bindAutosizeEvents() {
      guard let input else { return }

      // Resize on input
      _ = input.addEventListener(.input) { [self] _ in
        self.resizeToFit()
      }

      // Resize on window resize (in case of layout changes)
      window.addEventListener(.resize) { [self] _ in
        self.resizeToFit()
      }
    }

    private func resizeToFit() {
      guard let input = input else { return }

      // Reset to auto so offsetHeight reflects CSS minHeight as a floor
      input.style.height(.auto)

      // offsetHeight after auto respects CSS minHeight; scrollHeight does not
      let scrollHeight = input.scrollHeight
      let offsetHeight = input.offsetHeight
      let height = scrollHeight > offsetHeight ? scrollHeight : offsetHeight
      input.style.height(px(height))
    }
  }

  public class TextAreaHydration: @unchecked Sendable {
    private var instances: [TextAreaInstance] = []

    public init() {
      hydrateAllTextAreas()
    }

    private func hydrateAllTextAreas() {
      let allTextAreas = document.querySelectorAll(".text-area-view")

      for textArea in allTextAreas {
        let instance = TextAreaInstance(textArea: textArea)
        instances.append(instance)
      }
    }
  }
#endif
