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
  var dataAttributes: [(String, String)]
  /// The id of the form this submits with, when it sits outside that form.
  var formID: String? = nil

  /// Button type attribute
  public enum ButtonType: String, Sendable {
    case button
    case submit
    case reset
  }

  /// Button color — Apple HIG color for the button's action identity
  public enum ButtonColor: String, Sendable, CaseIterable {
    case gray, red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown
  }

  /// Button weight (visual prominence)
  public enum ButtonWeight: String, Sendable, CaseIterable {
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
    /// Mini: chrome strips (session legend Raw toggle); same height as PaginationView.mini (24).
    case mini
    /// Small: Use only when space is tight (inline with text, compact layouts). Avoid on touchscreens.
    case small
    /// Medium: the standard button, sharing its minimum height with form fields.
    case medium
    /// Larger text at the standard control height.
    case large

    /// Public so adjacent controls can share the same minimum size.
    /// Medium and large use the standard interactive height; large differs
    /// through its 18px type, while medium uses 16px.
    public var minSize: CSS.Length {
      switch self {
      case .mini: return px(24)
      case .small: return minSizeInteractivePointer
      case .medium: return minSizeInteractiveTouch
      case .large: return minSizeInteractiveTouch
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
    data: [(String, String)] = [],
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
    self.dataAttributes = data
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
    data: [(String, String)] = [],
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
    self.dataAttributes = data
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
    data: [(String, String)] = [],
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
    self.dataAttributes = data
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
    data: [(String, String)] = [],
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
    self.dataAttributes = data
  }

  public func data(_ key: String, _ value: String) -> Self {
    var copy = self
    copy.dataAttributes.append((key, value))
    return copy
  }

  public func data(_ key: String, _ value: Bool) -> Self {
    data(key, value ? "true" : "false")
  }

  /// The standard `form` attribute: the form this button submits, when the
  /// button is not inside it. A link-button has no form to name.
  public func form(_ id: String) -> Self {
    var copy = self
    copy.formID = id
    return copy
  }

  public func build() -> DOM.Node {
    let baseClasses = "button-view button-color-\(buttonColor.rawValue) button-weight-\(weight.rawValue) button-size-\(size.rawValue) \(borderRadiusClass)\(iconOnly ? " button-icon-only" : "")"
    let fullClass = stringIsEmpty(`class`) ? baseClasses : "\(baseClasses) \(`class`)"

    @HTMLBuilder
    func renderContent() -> [DOM.Node] {
      if let icon = icon {
        if stringIsEmpty(label) && iconOnly {
          span { icon }
            .class("button-icon")
            .ariaHidden(true)
        } else {
          // Either custom content or icon+label
          icon
        }
      }

      if !stringIsEmpty(label) {
        span { label }
          .class("button-label")
      }
    }

    if let url = url {
      var aBtn = a { renderContent() }
        .href(url)
        .class(fullClass)
        .data("color", buttonColor.rawValue)
        .data("weight", weight.rawValue)
        .data("size", size.rawValue)
        .data("icon-only", iconOnly ? "true" : "false")
        .data("full-width", fullWidth ? "true" : "false")
        .data("justify-content", contentJustifyContent.rawValue)
        .data("font-weight", fontWeightKey)
        .style {
          selector("&") {
            // Base — common props only — fontWeight/color via data-attributes below (cacheable)
            alignItems(.center)
            gap(spacingHorizontalButton)
            fontFamily(labelFontFamily)
            fontSize(fontSizeMedium16)
            textDecoration(.none)
            textAlign(.center)
            verticalAlign(.middle)
            whiteSpace(.nowrap)
            userSelect(.none)
            boxSizing(.borderBox)
            borderWidth(borderWidthBase)
            borderStyle(.solid)
            borderRadius(borderRadiusPill)
            cursor(.pointer)
            // Named properties, not `all`. `all` included outline-color, so a
            // mouse click painted the browser's own focus ring for a frame and
            // then faded it out over 100ms — the black ring that flashed on
            // every close button.
            transition("background-color 0.1s ease, border-color 0.1s ease, color 0.1s ease")

            // A mouse click focuses a button but should not ring it. Keyboard
            // focus still does: `:focus-visible` is the browser's own judgement
            // of when a ring is useful, and it is the only place the ring is
            // suppressed from.
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, borderColorTransparent).important()
            }

            // Disabled state — static via data-attributes (cacheable)
            pseudoClass(.disabled) {
              color(colorDisabled).important()
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

            // Apply custom styles block
            style()
          }

          selector("&[data-font-weight='bold']") {
            fontWeight(fontWeightBold)
          }
          selector("&[data-font-weight='normal']") {
            fontWeight(fontWeightNormal)
          }
          selector("&[data-font-weight='semibold']") {
            fontWeight(fontWeightSemiBold)
          }
          if !stringEquals(buttonBorderRadius.value, borderRadiusPill.value) {
            selector("&.\(borderRadiusClass)") { borderRadius(buttonBorderRadius) }
          }
          // Variant — static superset via data-attributes (one instance emits all)
          selector("&[data-icon-only='true']") {
            display(.flex)
            justifyContent(.center)
            alignSelf(.flexStart)
            padding(0)
          }
          selector("&[data-justify-content='flex-start']") { justifyContent(.flexStart) }
          selector("&[data-justify-content='center']") { justifyContent(.center) }
          selector("&[data-justify-content='flex-end']") { justifyContent(.flexEnd) }
          selector("&[data-justify-content='space-between']") { justifyContent(.spaceBetween) }
          selector("&[data-justify-content='space-around']") { justifyContent(.spaceAround) }
          selector("&[data-justify-content='space-evenly']") { justifyContent(.spaceEvenly) }
          // iconOnly always center overrides justify
          selector("&[data-icon-only='true']") { justifyContent(.center).important() }
          selector("&[data-icon-only='false'][data-full-width='true']") {
            display(.flex)
            width(perc(100))
            alignSelf(.flexStart)
          }
          selector("&[data-icon-only='false'][data-full-width='false']") {
            display(.inlineFlex)
            alignSelf(.flexStart)
          }
          selector("&[data-size='mini']") {
            minHeight(ButtonSize.mini.minSize)
            fontSize(fontSizeXSmall12)
          }
          selector("&[data-size='small']") {
            minHeight(ButtonSize.small.minSize)
            fontSize(fontSizeSmall14)
          }
          selector("&[data-size='medium']") { minHeight(ButtonSize.medium.minSize) }
          selector("&[data-size='large']") {
            minHeight(ButtonSize.large.minSize)
            fontSize(fontSizeLarge18)
          }
          selector("&[data-full-width='false'][data-size='mini']") { minWidth(ButtonSize.mini.minSize) }
          selector("&[data-full-width='false'][data-size='small']") { minWidth(ButtonSize.small.minSize) }
          selector("&[data-full-width='false'][data-size='medium']") { minWidth(ButtonSize.medium.minSize) }
          selector("&[data-full-width='false'][data-size='large']") { minWidth(ButtonSize.large.minSize) }
          selector("&[data-full-width='true']") { width(perc(100)) }
          selector("&[data-icon-only='true'][data-size='mini']") {
            width(ButtonSize.mini.minSize)
            height(ButtonSize.mini.minSize)
          }
          selector("&[data-icon-only='true'][data-size='small']") {
            width(ButtonSize.small.minSize)
            height(ButtonSize.small.minSize)
          }
          selector("&[data-icon-only='true'][data-size='medium']") {
            width(ButtonSize.medium.minSize)
            height(ButtonSize.medium.minSize)
          }
          selector("&[data-icon-only='true'][data-size='large']") {
            width(ButtonSize.large.minSize)
            height(ButtonSize.large.minSize)
          }
          selector("&[data-icon-only='false'][data-size='mini']") { padding(0, spacing8) }
          selector("&[data-icon-only='false'][data-size='small']") { padding(0, spacingHorizontalButtonSmall) }
          selector("&[data-icon-only='false'][data-size='medium']") { padding(0, spacingHorizontalButton) }
          selector("&[data-icon-only='false'][data-size='large']") { padding(0, spacingHorizontalButtonLarge) }

          // Quiet/Plain — opaque base bg + transparent border (not see-through on borders/surfaces)
          selector("&[data-weight='quiet'], &[data-weight='plain']") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray'], &[data-weight='plain'][data-color='gray']") {
            color(colorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='red'], &[data-weight='plain'][data-color='red']") { color(`var`("--color-red")).important() }
          selector("&[data-weight='quiet'][data-color='orange'], &[data-weight='plain'][data-color='orange']") { color(`var`("--color-orange")).important() }
          selector("&[data-weight='quiet'][data-color='yellow'], &[data-weight='plain'][data-color='yellow']") { color(`var`("--color-yellow")).important() }
          selector("&[data-weight='quiet'][data-color='green'], &[data-weight='plain'][data-color='green']") { color(`var`("--color-green")).important() }
          selector("&[data-weight='quiet'][data-color='mint'], &[data-weight='plain'][data-color='mint']") { color(`var`("--color-mint")).important() }
          selector("&[data-weight='quiet'][data-color='teal'], &[data-weight='plain'][data-color='teal']") { color(`var`("--color-teal")).important() }
          selector("&[data-weight='quiet'][data-color='cyan'], &[data-weight='plain'][data-color='cyan']") { color(`var`("--color-cyan")).important() }
          selector("&[data-weight='quiet'][data-color='blue'], &[data-weight='plain'][data-color='blue']") { color(`var`("--color-blue")).important() }
          selector("&[data-weight='quiet'][data-color='indigo'], &[data-weight='plain'][data-color='indigo']") { color(`var`("--color-indigo")).important() }
          selector("&[data-weight='quiet'][data-color='purple'], &[data-weight='plain'][data-color='purple']") { color(`var`("--color-purple")).important() }
          selector("&[data-weight='quiet'][data-color='pink'], &[data-weight='plain'][data-color='pink']") { color(`var`("--color-pink")).important() }
          selector("&[data-weight='quiet'][data-color='brown'], &[data-weight='plain'][data-color='brown']") { color(`var`("--color-brown")).important() }
          selector("&[data-weight='quiet']:disabled, &[data-weight='plain']:disabled") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='subtle']:disabled, &[data-weight='solid']:disabled, &[data-weight='static']:disabled") {
            backgroundColor(backgroundColorDisabled).important()
            borderColor(borderColorDisabled).important()
          }
          // Solid / Subtle / Static superset — cacheable overrides for per-instance base (fixes Mission Control blue vs white)
          selector("&[data-weight='solid'][data-color='gray']") {
            backgroundColor(backgroundColorInteractive)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='subtle'][data-color='gray']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='static'][data-color='gray']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='subtle'][data-color='red']") {
            backgroundColor(`var`("--background-color-red-subtle"))
            color(`var`("--color-red"))
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='solid'][data-color='red']") {
            backgroundColor(`var`("--background-color-red"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-red"))
          }
          selector("&[data-weight='static'][data-color='red']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='subtle'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange-subtle"))
            color(`var`("--color-orange"))
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='solid'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-orange"))
          }
          selector("&[data-weight='static'][data-color='orange']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='subtle'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow-subtle"))
            color(`var`("--color-yellow"))
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='solid'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-yellow"))
          }
          selector("&[data-weight='static'][data-color='yellow']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='subtle'][data-color='green']") {
            backgroundColor(`var`("--background-color-green-subtle"))
            color(`var`("--color-green"))
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='solid'][data-color='green']") {
            backgroundColor(`var`("--background-color-green"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-green"))
          }
          selector("&[data-weight='static'][data-color='green']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='subtle'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint-subtle"))
            color(`var`("--color-mint"))
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='solid'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-mint"))
          }
          selector("&[data-weight='static'][data-color='mint']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='subtle'][data-color='teal']") {
            backgroundColor(`var`("--background-color-teal-subtle"))
            color(`var`("--color-teal"))
            borderColor(`var`("--border-color-teal"))
          }
          selector("&[data-weight='solid'][data-color='teal']") {
            backgroundColor(`var`("--background-color-teal"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-teal"))
          }
          selector("&[data-weight='static'][data-color='teal']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-teal"))
          }
          selector("&[data-weight='subtle'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan-subtle"))
            color(`var`("--color-cyan"))
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='solid'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-cyan"))
          }
          selector("&[data-weight='static'][data-color='cyan']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='subtle'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue-subtle"))
            color(`var`("--color-blue"))
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='solid'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-blue"))
          }
          selector("&[data-weight='static'][data-color='blue']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='subtle'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo-subtle"))
            color(`var`("--color-indigo"))
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='solid'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-indigo"))
          }
          selector("&[data-weight='static'][data-color='indigo']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='subtle'][data-color='purple']") {
            backgroundColor(`var`("--background-color-purple-subtle"))
            color(`var`("--color-purple"))
            borderColor(`var`("--border-color-purple"))
          }
          selector("&[data-weight='solid'][data-color='purple']") {
            backgroundColor(`var`("--background-color-purple"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-purple"))
          }
          selector("&[data-weight='static'][data-color='purple']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-purple"))
          }
          selector("&[data-weight='subtle'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink-subtle"))
            color(`var`("--color-pink"))
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='solid'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-pink"))
          }
          selector("&[data-weight='static'][data-color='pink']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='subtle'][data-color='brown']") {
            backgroundColor(`var`("--background-color-brown-subtle"))
            color(`var`("--color-brown"))
            borderColor(`var`("--border-color-brown"))
          }
          selector("&[data-weight='solid'][data-color='brown']") {
            backgroundColor(`var`("--background-color-brown"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-brown"))
          }
          selector("&[data-weight='static'][data-color='brown']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-brown"))
          }

          // Hover / Active — cacheable via data-attributes (covers all solid/subtle/quiet/plain)
          selector("&[data-weight='subtle'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveSubtleHover).important()
          }
          selector("&[data-weight='subtle'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveSubtleActive).important()
            color(colorEmphasized).important()
            borderColor(borderColorBase).important()
          }
          selector("&[data-weight='solid'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveHover).important()
          }
          selector("&[data-weight='solid'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveActive).important()
            color(colorEmphasized).important()
            borderColor(borderColorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorBaseHover).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorBaseActive).important()
            color(colorEmphasized).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='plain'][data-color='gray']:hover:not(:disabled)") {
            color(colorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='plain'][data-color='gray']:active:not(:disabled)") {
            color(colorEmphasized).important()
            borderColor(.transparent).important()
          }

          selector("&[data-weight='subtle'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='plain'][data-color='red']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='red']:active:not(:disabled)") {
            color(`var`("--color-red-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:active:not(:disabled)") {
            color(`var`("--color-orange-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:active:not(:disabled)") {
            color(`var`("--color-yellow-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='plain'][data-color='green']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='green']:active:not(:disabled)") {
            color(`var`("--color-green-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:active:not(:disabled)") {
            color(`var`("--color-mint-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-hover")).important()
            borderColor(`var`("--border-color-teal-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-active")).important()
            borderColor(`var`("--border-color-teal-active")).important()
            color(`var`("--color-teal-active")).important()
          }
          selector("&[data-weight='solid'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-hover")).important()
            borderColor(`var`("--border-color-teal-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-active")).important()
            borderColor(`var`("--border-color-teal-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-active")).important()
            color(`var`("--color-teal-active")).important()
          }
          selector("&[data-weight='plain'][data-color='teal']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='teal']:active:not(:disabled)") {
            color(`var`("--color-teal-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:active:not(:disabled)") {
            color(`var`("--color-cyan-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:active:not(:disabled)") {
            color(`var`("--color-blue-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:active:not(:disabled)") {
            color(`var`("--color-indigo-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-hover")).important()
            borderColor(`var`("--border-color-purple-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-active")).important()
            borderColor(`var`("--border-color-purple-active")).important()
            color(`var`("--color-purple-active")).important()
          }
          selector("&[data-weight='solid'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-hover")).important()
            borderColor(`var`("--border-color-purple-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-active")).important()
            borderColor(`var`("--border-color-purple-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-active")).important()
            color(`var`("--color-purple-active")).important()
          }
          selector("&[data-weight='plain'][data-color='purple']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='purple']:active:not(:disabled)") {
            color(`var`("--color-purple-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:active:not(:disabled)") {
            color(`var`("--color-pink-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-hover")).important()
            borderColor(`var`("--border-color-brown-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-active")).important()
            borderColor(`var`("--border-color-brown-active")).important()
            color(`var`("--color-brown-active")).important()
          }
          selector("&[data-weight='solid'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-hover")).important()
            borderColor(`var`("--border-color-brown-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-active")).important()
            borderColor(`var`("--border-color-brown-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-active")).important()
            color(`var`("--color-brown-active")).important()
          }
          selector("&[data-weight='plain'][data-color='brown']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='brown']:active:not(:disabled)") {
            color(`var`("--color-brown-active")).important()
          }

          selector("&[data-weight='quiet']:focus") {
            borderColor(.transparent).important()
            boxShadow(.none).important()
          }
          selector("&[data-weight='plain']:focus") {
            borderColor(.transparent).important()
            boxShadow(.none).important()
          }


          descendant(".button-label") {
            padding(0)
            overflow(.hidden)
            whiteSpace(.nowrap)
            borderWidth(0)
          }

          descendant(".button-icon") {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
          }
          selector("&[data-size='mini'] .button-icon", "&[data-size='small'] .button-icon") {
            width(sizeIconXSmall)
            height(sizeIconXSmall)
          }
          selector("&[data-size='medium'] .button-icon") {
            width(sizeIconSmall)
            height(sizeIconSmall)
          }
          selector("&[data-size='large'] .button-icon") {
            width(sizeIconMedium)
            height(sizeIconMedium)
          }
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

      for (key, value) in dataAttributes {
        aBtn = aBtn.data(key, value)
      }

      return aBtn
    } else {
      var bBtn = button { renderContent() }
        .type(type == .submit ? .submit : type == .reset ? .reset : .button)
        .class(fullClass)
        .data("color", buttonColor.rawValue)
        .data("weight", weight.rawValue)
        .data("size", size.rawValue)
        .data("icon-only", iconOnly ? "true" : "false")
        .data("full-width", fullWidth ? "true" : "false")
        .data("justify-content", contentJustifyContent.rawValue)
        .data("font-weight", fontWeightKey)
        .disabled(disabled)
        .style {
          selector("&") {
            // Base — common per-instance props (static superset via data-attributes below)
            alignItems(.center)
            gap(spacingHorizontalButton)
            fontFamily(labelFontFamily)
            fontSize(fontSizeMedium16)
            textDecoration(.none)
            textAlign(.center)
            verticalAlign(.middle)
            whiteSpace(.nowrap)
            userSelect(.none)
            boxSizing(.borderBox)
            borderWidth(borderWidthBase)
            borderStyle(.solid)
            borderRadius(borderRadiusPill)
            cursor(.pointer)
            // Named properties, not `all`. `all` included outline-color, so a
            // mouse click painted the browser's own focus ring for a frame and
            // then faded it out over 100ms — the black ring that flashed on
            // every close button.
            transition("background-color 0.1s ease, border-color 0.1s ease, color 0.1s ease")

            // A mouse click focuses a button but should not ring it. Keyboard
            // focus still does: `:focus-visible` is the browser's own judgement
            // of when a ring is useful, and it is the only place the ring is
            // suppressed from.
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, borderColorTransparent).important()
            }

            // Disabled state — static via data-attributes (cacheable)
            pseudoClass(.disabled) {
              color(colorDisabled).important()
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

            // Apply custom styles block
            style()
          }

          selector("&[data-font-weight='bold']") {
            fontWeight(fontWeightBold)
          }
          selector("&[data-font-weight='normal']") {
            fontWeight(fontWeightNormal)
          }
          selector("&[data-font-weight='semibold']") {
            fontWeight(fontWeightSemiBold)
          }
          if !stringEquals(buttonBorderRadius.value, borderRadiusPill.value) {
            selector("&.\(borderRadiusClass)") { borderRadius(buttonBorderRadius) }
          }
          // Variant — static superset via data-attributes (one instance emits all)
          selector("&[data-icon-only='true']") {
            display(.flex)
            justifyContent(.center)
            alignSelf(.flexStart)
            padding(0)
          }
          selector("&[data-justify-content='flex-start']") { justifyContent(.flexStart) }
          selector("&[data-justify-content='center']") { justifyContent(.center) }
          selector("&[data-justify-content='flex-end']") { justifyContent(.flexEnd) }
          selector("&[data-justify-content='space-between']") { justifyContent(.spaceBetween) }
          selector("&[data-justify-content='space-around']") { justifyContent(.spaceAround) }
          selector("&[data-justify-content='space-evenly']") { justifyContent(.spaceEvenly) }
          // iconOnly always center overrides justify
          selector("&[data-icon-only='true']") { justifyContent(.center).important() }
          selector("&[data-icon-only='false'][data-full-width='true']") {
            display(.flex)
            width(perc(100))
            alignSelf(.flexStart)
          }
          selector("&[data-icon-only='false'][data-full-width='false']") {
            display(.inlineFlex)
            alignSelf(.flexStart)
          }
          selector("&[data-size='mini']") {
            minHeight(ButtonSize.mini.minSize)
            fontSize(fontSizeXSmall12)
          }
          selector("&[data-size='small']") {
            minHeight(ButtonSize.small.minSize)
            fontSize(fontSizeSmall14)
          }
          selector("&[data-size='medium']") { minHeight(ButtonSize.medium.minSize) }
          selector("&[data-size='large']") {
            minHeight(ButtonSize.large.minSize)
            fontSize(fontSizeLarge18)
          }
          selector("&[data-full-width='false'][data-size='mini']") { minWidth(ButtonSize.mini.minSize) }
          selector("&[data-full-width='false'][data-size='small']") { minWidth(ButtonSize.small.minSize) }
          selector("&[data-full-width='false'][data-size='medium']") { minWidth(ButtonSize.medium.minSize) }
          selector("&[data-full-width='false'][data-size='large']") { minWidth(ButtonSize.large.minSize) }
          selector("&[data-full-width='true']") { width(perc(100)) }
          selector("&[data-icon-only='true'][data-size='mini']") {
            width(ButtonSize.mini.minSize)
            height(ButtonSize.mini.minSize)
          }
          selector("&[data-icon-only='true'][data-size='small']") {
            width(ButtonSize.small.minSize)
            height(ButtonSize.small.minSize)
          }
          selector("&[data-icon-only='true'][data-size='medium']") {
            width(ButtonSize.medium.minSize)
            height(ButtonSize.medium.minSize)
          }
          selector("&[data-icon-only='true'][data-size='large']") {
            width(ButtonSize.large.minSize)
            height(ButtonSize.large.minSize)
          }
          selector("&[data-icon-only='false'][data-size='mini']") { padding(0, spacing8) }
          selector("&[data-icon-only='false'][data-size='small']") { padding(0, spacingHorizontalButtonSmall) }
          selector("&[data-icon-only='false'][data-size='medium']") { padding(0, spacingHorizontalButton) }
          selector("&[data-icon-only='false'][data-size='large']") { padding(0, spacingHorizontalButtonLarge) }

          descendant(".button-label") {
            padding(0)
            overflow(.hidden)
            whiteSpace(.nowrap)
            borderWidth(0)
          }

          descendant(".button-icon") {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
          }
          selector("&[data-size='mini'] .button-icon", "&[data-size='small'] .button-icon") {
            width(sizeIconXSmall)
            height(sizeIconXSmall)
          }
          selector("&[data-size='medium'] .button-icon") {
            width(sizeIconSmall)
            height(sizeIconSmall)
          }
          selector("&[data-size='large'] .button-icon") {
            width(sizeIconMedium)
            height(sizeIconMedium)
          }

          // Quiet/Plain — opaque base bg + transparent border (mirrors <a> branch)
          selector("&[data-weight='quiet'], &[data-weight='plain']") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray'], &[data-weight='plain'][data-color='gray']") {
            color(colorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='red'], &[data-weight='plain'][data-color='red']") { color(`var`("--color-red")).important() }
          selector("&[data-weight='quiet'][data-color='orange'], &[data-weight='plain'][data-color='orange']") { color(`var`("--color-orange")).important() }
          selector("&[data-weight='quiet'][data-color='yellow'], &[data-weight='plain'][data-color='yellow']") { color(`var`("--color-yellow")).important() }
          selector("&[data-weight='quiet'][data-color='green'], &[data-weight='plain'][data-color='green']") { color(`var`("--color-green")).important() }
          selector("&[data-weight='quiet'][data-color='mint'], &[data-weight='plain'][data-color='mint']") { color(`var`("--color-mint")).important() }
          selector("&[data-weight='quiet'][data-color='teal'], &[data-weight='plain'][data-color='teal']") { color(`var`("--color-teal")).important() }
          selector("&[data-weight='quiet'][data-color='cyan'], &[data-weight='plain'][data-color='cyan']") { color(`var`("--color-cyan")).important() }
          selector("&[data-weight='quiet'][data-color='blue'], &[data-weight='plain'][data-color='blue']") { color(`var`("--color-blue")).important() }
          selector("&[data-weight='quiet'][data-color='indigo'], &[data-weight='plain'][data-color='indigo']") { color(`var`("--color-indigo")).important() }
          selector("&[data-weight='quiet'][data-color='purple'], &[data-weight='plain'][data-color='purple']") { color(`var`("--color-purple")).important() }
          selector("&[data-weight='quiet'][data-color='pink'], &[data-weight='plain'][data-color='pink']") { color(`var`("--color-pink")).important() }
          selector("&[data-weight='quiet'][data-color='brown'], &[data-weight='plain'][data-color='brown']") { color(`var`("--color-brown")).important() }
          selector("&[data-weight='quiet']:disabled, &[data-weight='plain']:disabled") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='subtle']:disabled, &[data-weight='solid']:disabled, &[data-weight='static']:disabled") {
            backgroundColor(backgroundColorDisabled).important()
            borderColor(borderColorDisabled).important()
          }
          // Solid / Subtle / Static superset — mirrors aBtn branch (fixes solid blue)
          selector("&[data-weight='solid'][data-color='gray']") {
            backgroundColor(backgroundColorInteractive)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='subtle'][data-color='gray']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='static'][data-color='gray']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(borderColorBase)
          }
          selector("&[data-weight='subtle'][data-color='red']") {
            backgroundColor(`var`("--background-color-red-subtle"))
            color(`var`("--color-red"))
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='solid'][data-color='red']") {
            backgroundColor(`var`("--background-color-red"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-red"))
          }
          selector("&[data-weight='static'][data-color='red']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='subtle'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange-subtle"))
            color(`var`("--color-orange"))
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='solid'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-orange"))
          }
          selector("&[data-weight='static'][data-color='orange']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='subtle'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow-subtle"))
            color(`var`("--color-yellow"))
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='solid'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-yellow"))
          }
          selector("&[data-weight='static'][data-color='yellow']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='subtle'][data-color='green']") {
            backgroundColor(`var`("--background-color-green-subtle"))
            color(`var`("--color-green"))
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='solid'][data-color='green']") {
            backgroundColor(`var`("--background-color-green"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-green"))
          }
          selector("&[data-weight='static'][data-color='green']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='subtle'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint-subtle"))
            color(`var`("--color-mint"))
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='solid'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-mint"))
          }
          selector("&[data-weight='static'][data-color='mint']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='subtle'][data-color='teal']") {
            backgroundColor(`var`("--background-color-teal-subtle"))
            color(`var`("--color-teal"))
            borderColor(`var`("--border-color-teal"))
          }
          selector("&[data-weight='solid'][data-color='teal']") {
            backgroundColor(`var`("--background-color-teal"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-teal"))
          }
          selector("&[data-weight='static'][data-color='teal']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-teal"))
          }
          selector("&[data-weight='subtle'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan-subtle"))
            color(`var`("--color-cyan"))
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='solid'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-cyan"))
          }
          selector("&[data-weight='static'][data-color='cyan']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='subtle'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue-subtle"))
            color(`var`("--color-blue"))
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='solid'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-blue"))
          }
          selector("&[data-weight='static'][data-color='blue']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='subtle'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo-subtle"))
            color(`var`("--color-indigo"))
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='solid'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-indigo"))
          }
          selector("&[data-weight='static'][data-color='indigo']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='subtle'][data-color='purple']") {
            backgroundColor(`var`("--background-color-purple-subtle"))
            color(`var`("--color-purple"))
            borderColor(`var`("--border-color-purple"))
          }
          selector("&[data-weight='solid'][data-color='purple']") {
            backgroundColor(`var`("--background-color-purple"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-purple"))
          }
          selector("&[data-weight='static'][data-color='purple']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-purple"))
          }
          selector("&[data-weight='subtle'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink-subtle"))
            color(`var`("--color-pink"))
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='solid'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-pink"))
          }
          selector("&[data-weight='static'][data-color='pink']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='subtle'][data-color='brown']") {
            backgroundColor(`var`("--background-color-brown-subtle"))
            color(`var`("--color-brown"))
            borderColor(`var`("--border-color-brown"))
          }
          selector("&[data-weight='solid'][data-color='brown']") {
            backgroundColor(`var`("--background-color-brown"))
            color(colorInvertedFixed)
            borderColor(`var`("--background-color-brown"))
          }
          selector("&[data-weight='static'][data-color='brown']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-brown"))
          }

          // Hover / Active — cacheable via data-attributes (covers all solid/subtle/quiet/plain)
          selector("&[data-weight='subtle'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveSubtleHover).important()
          }
          selector("&[data-weight='subtle'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveSubtleActive).important()
            color(colorEmphasized).important()
            borderColor(borderColorBase).important()
          }
          selector("&[data-weight='solid'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveHover).important()
          }
          selector("&[data-weight='solid'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorInteractiveActive).important()
            color(colorEmphasized).important()
            borderColor(borderColorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='gray']:hover:not(:disabled)") {
            backgroundColor(backgroundColorBaseHover).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray']:active:not(:disabled)") {
            backgroundColor(backgroundColorBaseActive).important()
            color(colorEmphasized).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='plain'][data-color='gray']:hover:not(:disabled)") {
            color(colorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='plain'][data-color='gray']:active:not(:disabled)") {
            color(colorEmphasized).important()
            borderColor(.transparent).important()
          }

          selector("&[data-weight='subtle'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='plain'][data-color='red']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='red']:active:not(:disabled)") {
            color(`var`("--color-red-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:active:not(:disabled)") {
            color(`var`("--color-orange-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:active:not(:disabled)") {
            color(`var`("--color-yellow-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='plain'][data-color='green']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='green']:active:not(:disabled)") {
            color(`var`("--color-green-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:active:not(:disabled)") {
            color(`var`("--color-mint-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-hover")).important()
            borderColor(`var`("--border-color-teal-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-active")).important()
            borderColor(`var`("--border-color-teal-active")).important()
            color(`var`("--color-teal-active")).important()
          }
          selector("&[data-weight='solid'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-hover")).important()
            borderColor(`var`("--border-color-teal-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-active")).important()
            borderColor(`var`("--border-color-teal-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='teal']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='teal']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-teal-subtle-active")).important()
            color(`var`("--color-teal-active")).important()
          }
          selector("&[data-weight='plain'][data-color='teal']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='teal']:active:not(:disabled)") {
            color(`var`("--color-teal-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:active:not(:disabled)") {
            color(`var`("--color-cyan-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:active:not(:disabled)") {
            color(`var`("--color-blue-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:active:not(:disabled)") {
            color(`var`("--color-indigo-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-hover")).important()
            borderColor(`var`("--border-color-purple-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-active")).important()
            borderColor(`var`("--border-color-purple-active")).important()
            color(`var`("--color-purple-active")).important()
          }
          selector("&[data-weight='solid'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-hover")).important()
            borderColor(`var`("--border-color-purple-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-active")).important()
            borderColor(`var`("--border-color-purple-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='purple']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='purple']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-purple-subtle-active")).important()
            color(`var`("--color-purple-active")).important()
          }
          selector("&[data-weight='plain'][data-color='purple']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='purple']:active:not(:disabled)") {
            color(`var`("--color-purple-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:active:not(:disabled)") {
            color(`var`("--color-pink-active")).important()
          }

          selector("&[data-weight='subtle'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-hover")).important()
            borderColor(`var`("--border-color-brown-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-active")).important()
            borderColor(`var`("--border-color-brown-active")).important()
            color(`var`("--color-brown-active")).important()
          }
          selector("&[data-weight='solid'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-hover")).important()
            borderColor(`var`("--border-color-brown-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-active")).important()
            borderColor(`var`("--border-color-brown-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='brown']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='brown']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-brown-subtle-active")).important()
            color(`var`("--color-brown-active")).important()
          }
          selector("&[data-weight='plain'][data-color='brown']:hover:not(:disabled)") {
            color(colorBase).important()
          }
          selector("&[data-weight='plain'][data-color='brown']:active:not(:disabled)") {
            color(`var`("--color-brown-active")).important()
          }

          selector("&[data-weight='quiet']:focus") {
            borderColor(.transparent).important()
            boxShadow(.none).important()
          }
          selector("&[data-weight='plain']:focus") {
            borderColor(.transparent).important()
            boxShadow(.none).important()
          }

        }

      if let ariaLbl = effectiveAriaLabel {
        bBtn = bBtn.ariaLabel(ariaLbl)
      }

      if let click = onClick {
        bBtn = bBtn.onclick(click)
      }

      for (key, value) in dataAttributes {
        bBtn = bBtn.data(key, value)
      }

      if let formID {
        bBtn = bBtn.form(formID)
      }

      return bBtn
    }
  }

  private var fontWeightKey: String {
    if stringEquals(labelFontWeight.value, fontWeightBold.value) { return "bold" }
    if stringEquals(labelFontWeight.value, fontWeightNormal.value) { return "normal" }
    if stringEquals(labelFontWeight.value, fontWeightSemiBold.value) { return "semibold" }
    return "bold"
  }

  /// A stable CSS-safe identity lets any `CSS.Length` become a scoped,
  /// cacheable selector instead of overwriting the shared `.button-view` rule.
  private var borderRadiusClass: String {
    var hash: UInt32 = 2_166_136_261
    for byte in buttonBorderRadius.value.utf8 {
      hash ^= UInt32(byte)
      hash &*= 16_777_619
    }
    return "button-radius-\(int64ToString(Int64(hash), radix: 16))"
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
      wrapper.innerHTML = view.render()
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
