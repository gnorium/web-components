import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Button — triggers an action when the user clicks or taps on it.
public struct ButtonView: HTMLContent {
  let label: String
  let buttonColor: ButtonColor
  let weight: ButtonWeight
  let size: ButtonSize
  let icon: DOM.Node?
  let iconOnly: Bool
  let disabled: Bool
  let ariaLabel: String?
  let url: String?
  let onClick: String?
  let type: ButtonType
  let fullWidth: Bool
  var `class`: String
  let labelFontWeight: CSS.FontWeight
  let labelFontFamily: CSS.FontFamily
  let contentJustifyContent: CSS.JustifyContent
  let style: @Sendable () -> [CSSOM.CSSRule]
  let buttonBorderRadius: CSS.Length

  /// Button type attribute
  public enum ButtonType: String, Sendable {
    case button
    case submit
    case reset
  }

  /// Button color — Apple HIG color for the button's action identity
  public enum ButtonColor: String, Sendable {
    case gray, red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown
  }

  /// Button weight (visual prominence)
  public enum ButtonWeight: String, Sendable {
    /// Solid buttons signal the main action — filled background, inverted text
    case solid
    /// Subtle buttons are the default — light background, colored text, border
    case subtle
    /// Static buttons — no interactive feedback at all (for structured controls like dropdowns)
    case `static`
    /// Quiet buttons — transparent, no border, hover shows subtle background
    case quiet
    /// Plain buttons — transparent, no background change on hover
    case plain
  }

  /// Button sizes
  public enum ButtonSize: String, Sendable {
    /// Small: Use only when space is tight (inline with text, compact layouts). Avoid on touchscreens.
    case small
    /// Medium: Standard button size (default)
    case medium
    /// Large: For accessibility on touchscreens (increases touch area)
    case large

    var minSize: CSS.Length {
      switch self {
      case .small: return px(24)
      case .medium: return px(32)
      case .large: return px(44)
      }
    }
  }

  // MARK: - Initialization

  public init(
    label: String,
    buttonColor: ButtonColor = .gray,
    weight: ButtonWeight = .subtle,
    size: ButtonSize = .medium,
    disabled: Bool = false,
    url: String? = nil,
    type: ButtonType = .button,
    ariaLabel: String? = nil,
    onClick: String? = nil,
    fullWidth: Bool = false,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightBold,
    labelFontFamily: CSS.FontFamily = typographyFontSans,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: CSS.Length = borderRadiusPill,
    @CSSBuilder style: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] }
  ) {
    self.label = label
    self.buttonColor = buttonColor
    self.weight = weight
    self.size = size
    self.icon = nil
    self.iconOnly = false
    self.disabled = disabled
    self.ariaLabel = ariaLabel
    self.url = url
    self.onClick = onClick
    self.type = type
    self.fullWidth = fullWidth
    self.class = `class`
    self.labelFontWeight = labelFontWeight
    self.labelFontFamily = labelFontFamily
    self.contentJustifyContent = contentJustifyContent
    self.style = style
    self.buttonBorderRadius = borderRadius
  }

  public init<T: HTMLContent>(
    label: String,
    icon: T,
    buttonColor: ButtonColor = .gray,
    weight: ButtonWeight = .subtle,
    size: ButtonSize = .medium,
    disabled: Bool = false,
    url: String? = nil,
    type: ButtonType = .button,
    ariaLabel: String? = nil,
    onClick: String? = nil,
    fullWidth: Bool = false,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightBold,
    labelFontFamily: CSS.FontFamily = typographyFontSans,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: CSS.Length = borderRadiusPill,
    @CSSBuilder style: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] }
  ) {
    self.label = label
    self.buttonColor = buttonColor
    self.weight = weight
    self.size = size
    self.icon = icon.build()
    self.iconOnly = false
    self.disabled = disabled
    self.ariaLabel = ariaLabel
    self.url = url
    self.onClick = onClick
    self.type = type
    self.fullWidth = fullWidth
    self.class = `class`
    self.labelFontWeight = labelFontWeight
    self.labelFontFamily = labelFontFamily
    self.contentJustifyContent = contentJustifyContent
    self.style = style
    self.buttonBorderRadius = borderRadius
  }

  /// Create an icon-only button
  /// WARNING: Icon-only buttons require aria-label for accessibility
  public init<T: HTMLContent>(
    icon: T,
    buttonColor: ButtonColor = .gray,
    weight: ButtonWeight = .subtle,
    size: ButtonSize = .medium,
    disabled: Bool = false,
    url: String? = nil,
    type: ButtonType = .button,
    ariaLabel: String,
    onClick: String? = nil,
    fullWidth: Bool = false,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightBold,
    labelFontFamily: CSS.FontFamily = typographyFontSans,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: CSS.Length = borderRadiusPill,
    @CSSBuilder style: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] }
  ) {
    self.label = ""
    self.buttonColor = buttonColor
    self.weight = weight
    self.size = size
    self.icon = icon.build()
    self.iconOnly = true
    self.disabled = disabled
    self.ariaLabel = ariaLabel
    self.url = url
    self.onClick = onClick
    self.type = type
    self.fullWidth = fullWidth
    self.class = `class`
    self.labelFontWeight = labelFontWeight
    self.labelFontFamily = labelFontFamily
    self.contentJustifyContent = contentJustifyContent
    self.style = style
    self.buttonBorderRadius = borderRadius
  }

  /// Create a button with custom content
  public init(
    label: String = "",
    buttonColor: ButtonColor = .gray,
    weight: ButtonWeight = .subtle,
    size: ButtonSize = .medium,
    disabled: Bool = false,
    url: String? = nil,
    type: ButtonType = .button,
    ariaLabel: String? = nil,
    onClick: String? = nil,
    fullWidth: Bool = false,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightBold,
    labelFontFamily: CSS.FontFamily = typographyFontSans,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: CSS.Length = borderRadiusPill,
    @CSSBuilder style: @escaping @Sendable () -> [CSSOM.CSSRule] = { [] },
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.label = label
    self.buttonColor = buttonColor
    self.weight = weight
    self.size = size
    self.icon = .fragment { content() }
    self.iconOnly = false  // Custom content is treated as the full body
    self.disabled = disabled
    self.ariaLabel = ariaLabel
    self.url = url
    self.onClick = onClick
    self.type = type
    self.fullWidth = fullWidth
    self.class = `class`
    self.labelFontWeight = labelFontWeight
    self.labelFontFamily = labelFontFamily
    self.contentJustifyContent = contentJustifyContent
    self.style = style
    self.buttonBorderRadius = borderRadius
  }

  public func build() -> DOM.Node {
    let baseClasses = "button-view button-color-\(buttonColor.rawValue) button-weight-\(weight.rawValue) button-size-\(size.rawValue)\(iconOnly ? " button-icon-only" : "")"
    let fullClass = stringIsEmpty(`class`) ? baseClasses : "\(baseClasses) \(`class`)"

    @HTMLBuilder
    func renderContent() -> [DOM.Node] {
      if let icon = icon {
        if stringIsEmpty(label) && iconOnly {
          span { icon }
            .class("button-icon")
            .ariaHidden(true)
            .style {
              buttonIconCSS()
            }
        } else {
          // Either custom content or icon+label
          icon
        }
      }

      if !stringIsEmpty(label) {
        span { label }
          .class("button-label")
          .style {
            padding(0)
            overflow(.hidden)
            whiteSpace(.nowrap)
            borderWidth(0)
          }
      }
    }

    if let url = url {
      var aBtn = a { renderContent() }
        .href(url)
        .class(fullClass)
        .data("color", buttonColor.rawValue)
        .data("weight", weight.rawValue)
        .data("size", size.rawValue)
        .style {
          buttonViewCSS()
        }

      if disabled {
        aBtn = aBtn.ariaDisabled(true).class("disabled")
      }

      if let ariaLbl = effectiveAriaLabel {
        aBtn = aBtn.ariaLabel(ariaLbl)
      }

      if let click = onClick {
        aBtn = aBtn.onclick(click)
      }

      return aBtn
    } else {
      var bBtn = button { renderContent() }
        .type(type == .submit ? .submit : type == .reset ? .reset : .button)
        .class(fullClass)
        .data("color", buttonColor.rawValue)
        .data("weight", weight.rawValue)
        .data("size", size.rawValue)
        .disabled(disabled)
        .style {
          buttonViewCSS()
        }

      if let ariaLbl = effectiveAriaLabel {
        bBtn = bBtn.ariaLabel(ariaLbl)
      }

      if let click = onClick {
        bBtn = bBtn.onclick(click)
      }

      return bBtn
    }
  }

  @CSSBuilder
  private func buttonViewCSS() -> [CSSOM.CSSRule] {
    // Base button styles
    if iconOnly {
      display(.flex)
      justifyContent(.center)
      alignSelf(.flexStart)
    } else {
      if fullWidth {
        display(.flex)
      } else {
        display(.inlineFlex)
        alignSelf(.flexStart)
      }
    }
    alignItems(.center)
    justifyContent(contentJustifyContent)
    gap(spacingHorizontalButton)
    fontFamily(labelFontFamily)
    fontSize(fontSizeMedium16)
    fontWeight(labelFontWeight)
    textDecoration(.none)
    textAlign(.center)
    verticalAlign(.middle)
    whiteSpace(.nowrap)
    userSelect(.none)
    boxSizing(.borderBox)

    // Size
    if fullWidth {
      width(perc(100))
    } else {
      minWidth(size.minSize)
      media(maxWidth(maxWidthBreakpointMobile)) {
        width(perc(100)).important()
        display(.flex).important()
      }
    }
    minHeight(size.minSize)

    if size == .large {
      let isNavbarBtn = stringContains(self.class, "navbar-ellipsis-btn") || stringContains(self.class, "navbar-sidebar-btn") || stringContains(self.class, "navbar-search-btn")
      if isNavbarBtn {
        let ms = ButtonSize.medium.minSize
        media(maxWidth(maxWidthBreakpointMobile)) {
          height(ms).important()
          minHeight(ms).important()
          if iconOnly {
            width(ms).important()
            minWidth(ms).important()
          }
        }
      }
    }

    // Border
    borderWidth(borderWidthBase)
    borderStyle(.solid)
    borderRadius(buttonBorderRadius)

    // Interaction
    cursor(.pointer)
    transition(.all, s(0.1), .ease)

    // Padding based on size and icon-only state
    if iconOnly {
      padding(0)
      width(size.minSize)
      height(size.minSize)
    } else {
      switch size {
      case .small:
        padding(0, spacingHorizontalButtonSmall)
      case .medium:
        padding(0, spacingHorizontalButton)
      case .large:
        padding(0, spacingHorizontalButtonLarge)
        media(maxWidth(maxWidthBreakpointMobile)) {
          padding(0, spacingHorizontalButton).important()
        }
      }
    }

    // Color + Weight — base styles inline, interactive states via pseudo-class
    applyColorBaseCSS()
    if weight != .`static` { applyColorInteractiveCSS() }

    // Focus state
    pseudoClass(.focus) {
      outline(borderWidthBase, .solid, borderColorTransparent).important()
    }

    // Disabled state
    pseudoClass(.disabled) {
      color(colorDisabled).important()
      if weight == .quiet {
        backgroundColor(.transparent).important()
        borderColor(.transparent).important()
      } else {
        backgroundColor(backgroundColorDisabled).important()
        borderColor(borderColorDisabled).important()
      }
      cursor(cursorNotAllowed).important()
    }

    // Icon hover color when button is disabled
    pseudoClass(.disabled) {
      descendant(".icon-view") {
        pseudoClass(.hover) {
          color(colorDisabled).important()
        }
      }
    }

    // Custom styles
    style()
  }

  @CSSBuilder
  private func buttonIconCSS() -> [CSSOM.CSSRule] {
    display(.flex)
    alignItems(.center)
    justifyContent(.center)

    if size == .small {
      width(sizeIconXSmall)
      height(sizeIconXSmall)
    } else if size == .medium {
      width(sizeIconSmall)
      height(sizeIconSmall)
    } else if size == .large {
      width(sizeIconMedium)
      height(sizeIconMedium)
    }
  }

  private var effectiveAriaLabel: String? {
    if let ariaLabel = ariaLabel {
      return ariaLabel
    } else if !stringIsEmpty(label) {
      return label
    } else {
      return nil
    }
  }

  @CSSBuilder
  private func applyColorBaseCSS() -> [CSSOM.CSSRule] {
    let c = stringLowercased(buttonColor.rawValue)

    switch (buttonColor, weight) {
    case (.gray, .subtle):
      backgroundColor(backgroundColorBase)
      color(colorBase)
      borderColor(borderColorBase)
    case (.gray, .solid):
      backgroundColor(backgroundColorInteractive)
      color(colorBase)
      borderColor(borderColorBase)
    case (.gray, .quiet):
      backgroundColor(.transparent)
      color(colorBase)
      borderColor(.transparent)
    case (.gray, .plain):
      backgroundColor(.transparent)
      color(colorBase)
      borderColor(.transparent)
    case (.gray, .`static`):
      backgroundColor(.transparent)
      color(colorBase)
      borderColor(.transparent)
    case (_, .subtle):
      backgroundColor(`var`("--background-color-\(c)-subtle"))
      color(`var`("--color-\(c)"))
      borderColor(`var`("--border-color-\(c)"))
    case (_, .solid):
      backgroundColor(`var`("--background-color-\(c)"))
      color(colorInvertedFixed)
      borderColor(`var`("--background-color-\(c)"))
    case (_, .quiet):
      backgroundColor(.transparent)
      color(`var`("--color-\(c)"))
      borderColor(.transparent)
    case (_, .plain):
      backgroundColor(.transparent)
      color(`var`("--color-\(c)"))
      borderColor(.transparent)
    case (_, .`static`):
      backgroundColor(.transparent)
      color(colorBase)
      borderColor(.transparent)
    }
  }

  @CSSBuilder
  private func applyColorInteractiveCSS() -> [CSSOM.CSSRule] {
    let c = stringLowercased(buttonColor.rawValue)

    switch (buttonColor, weight) {
    case (.gray, .subtle):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(backgroundColorInteractiveSubtleHover).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(backgroundColorInteractiveSubtleActive).important(); color(colorEmphasized).important(); borderColor(borderColorBase).important() }
    case (.gray, .solid):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(backgroundColorInteractiveHover).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(backgroundColorInteractiveActive).important(); color(colorEmphasized).important(); borderColor(borderColorBase).important() }
    case (.gray, .quiet):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(backgroundColorBaseHover).important(); borderColor(.transparent).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(backgroundColorBaseActive).important(); color(colorEmphasized).important(); borderColor(.transparent).important() }
      pseudoClass(.focus) { borderColor(.transparent).important(); boxShadow(.none).important() }
    case (.gray, .plain):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(.transparent).important(); color(colorBase).important(); borderColor(.transparent).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(.transparent).important(); color(colorEmphasized).important(); borderColor(.transparent).important() }
      pseudoClass(.focus) { borderColor(.transparent).important(); boxShadow(.none).important() }
    case (_, .subtle):
      pseudoClass(.hover, .not(.disabled)) {
        backgroundColor(`var`("--background-color-\(c)-subtle-hover")).important()
        borderColor(`var`("--border-color-\(c)-hover")).important()
      }
      pseudoClass(.active, .not(.disabled)) {
        backgroundColor(`var`("--background-color-\(c)-subtle-active")).important()
        borderColor(`var`("--border-color-\(c)-active")).important()
        color(`var`("--color-\(c)-active")).important()
      }
      pseudoClass(.focus) { borderColor(`var`("--border-color-\(c)-focus")).important() }
    case (_, .solid):
      pseudoClass(.hover, .not(.disabled)) {
        backgroundColor(`var`("--background-color-\(c)-hover")).important()
        borderColor(`var`("--background-color-\(c)-hover")).important()
      }
      pseudoClass(.active, .not(.disabled)) {
        backgroundColor(`var`("--background-color-\(c)-active")).important()
        borderColor(`var`("--background-color-\(c)-active")).important()
      }
      pseudoClass(.focus) { borderColor(`var`("--border-color-\(c)-focus")).important() }
    case (_, .quiet):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(`var`("--background-color-\(c)-subtle")).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(`var`("--background-color-\(c)-subtle-active")).important(); color(`var`("--color-\(c)-active")).important() }
      pseudoClass(.focus) { borderColor(.transparent).important(); boxShadow(.none).important() }
    case (_, .plain):
      pseudoClass(.hover, .not(.disabled)) { backgroundColor(.transparent).important(); color(colorBase).important() }
      pseudoClass(.active, .not(.disabled)) { backgroundColor(.transparent).important(); color(`var`("--color-\(c)-active")).important() }
      pseudoClass(.focus) { borderColor(.transparent).important(); boxShadow(.none).important() }
    case (_, .static):
      // Static weight is non-interactive — no hover/active/focus styling.
      if false { color(colorBase) }
    }
  }
}

#if CLIENT
  import WebAPIs

  public enum ButtonViewFactory {
    public static func createElement(
      label: String,
      buttonColor: ButtonView.ButtonColor = .gray,
      weight: ButtonView.ButtonWeight = .subtle,
      size: ButtonView.ButtonSize = .medium,
      type: ButtonView.ButtonType = .button,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = ButtonView(
        label: label,
        buttonColor: buttonColor,
        weight: weight,
        size: size,
        type: type,
        class: `class`,
        labelFontWeight: fontWeightSemiBold
      )
      wrapper.innerHTML = renderHTML { view.render() }
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
