import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import DesignTokens
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// Button—triggers an action when the user clicks or taps on it.
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
  let contentJustifyContent: CSS.JustifyContent
  let buttonBorderRadius: ButtonRadius
  var dataAttributes: [(String, String)]
  /// The id of the form this submits with, when it sits outside that form.
  var formID: String? = nil
  var downloadFilename: String? = nil
  var popoverTargetID: String? = nil
  var expanded: Bool? = nil
  var pressed: Bool? = nil
  var controlsID: String? = nil
  var submitName: String? = nil
  var submitValue: String? = nil
  /// The standard `title` attribute: the button's native tooltip.
  var titleText: String? = nil
  /// Whether the content is the caller's own, placed as given (never
  /// wrapped as an icon), icon-only or not.
  var customContent = false

  /// Button type attribute
  public enum ButtonType: String, Sendable {
    case button
    case submit
    case reset
  }

  /// Button color—Apple HIG color for the button's action identity
  public enum ButtonColor: String, Sendable, CaseIterable {
    case gray, red, orange, yellow, lime, green, mint, cyan, blue, indigo, violet, magenta, pink
  }

  /// Button weight (visual prominence)
  public enum ButtonWeight: String, Sendable, CaseIterable {
    /// Solid buttons signal the main action—filled background, inverted text
    case solid
    /// Subtle buttons are the default—light background, colored text, border
    case subtle
    /// Static buttons—no interactive feedback at all (for structured controls like dropdowns)
    case `static`
    /// Quiet buttons—transparent, no border, hover shows subtle background
    case quiet
    /// Plain buttons—transparent, no background change on hover
    case plain
  }

  /// Button corner radius—one of the design system's radius tokens, named
  /// after it, so the button's class reads `button-radius-base` etc.
  public enum ButtonRadius: String, Sendable, CaseIterable {
    case minimal, base, sharp, pill, circle

    /// The semantic class keyed on this radius.
    public var className: String { "button-radius-\(rawValue)" }
  }

  /// Button sizes
  public enum ButtonSize: String, Sendable {
    /// Medium: furniture only (user, 2026-10-10)—the markup pane's header
    /// and footer bars (and its find bar's field), legends, pagers, the
    /// apparatus rule's switches, menus, picker popovers and inline row
    /// controls (a comment's Edit/Nullify).
    case medium
    /// Small: a locution's reaction pills (user, 2026-10-12)—the step a
    /// medium button takes on a phone (`phoneStep`), its inset 4 on every
    /// side of the 22px line, inside its 1px border: 32; its type 14px. On
    /// a phone it steps to mini.
    case small
    /// Mini: the step a small button takes on a phone (user, 2026-10-12),
    /// no inset around the 22px line, inside its 1px border: 24, WCAG 2.2's
    /// least target (2.5.8); its type 12px. The floor: nothing steps below.
    case mini
    /// Large: everything else (user, 2026-10-10)—page, card and accordion
    /// headers, a page's standalone and row actions, a form's buttons and
    /// its "+ Genre"/"− Testament" controls, filter and query bars (their
    /// fields 48 too), empty-state and dialog actions, and the navbar's
    /// icon buttons (large tap targets on a phone).
    case large

    /// A control's one inset, inside its 1px border on every side (user,
    /// 2026-10-10): mini 0, small 4, medium 8, large 12.
    public var padding: CSS.Length {
      switch self {
      case .mini: return ButtonView.miniPadding
      case .small: return ButtonView.smallPadding
      case .medium: return spacing8
      case .large: return spacing12
      }
    }

    /// Public so adjacent controls can share the same height. Every control
    /// is its inset on every side, the standard 22px line and a 1px border:
    /// mini 24, small 32, medium 40, large 48—a large button, a field, a select and a date
    /// picker align in a row. Each size sets its own type (user,
    /// 2026-10-10): mini 12px, small 14px, medium 16px, large 18px, all on
    /// the 22px line.
    public var minSize: CSS.Length {
      padding * 2 + lineHeightSmall22 + borderWidthBase * 2
    }

    /// The size of an icon-only button's icon: the button's line, 22px at
    /// every size (user, 2026-10-21; was its type size)—the icon fills the
    /// line box and never grows the button.
    public var iconSize: CSS.Length {
      lineHeightSmall22
    }

    /// The size of an icon beside this button's label: the label's line
    /// height, as an icon alone—22px.
    public var labelIconSize: CSS.Length {
      iconSize
    }
  }

  /// Option B (user, 2026-10-12, under comparison): on a phone (below
  /// 480px), with `data-phone-step="down"` on the root element, every
  /// sized control drops one step—a large button medium, a medium one
  /// small (its inset 4 on every side of the 22px line, inside its 1px
  /// border: 32; its type 14px), a small one mini (no inset: 24; its type
  /// 12px), a medium pager small. One switch: the attribute.
  public static let phoneStep = ":root[data-phone-step='down']"
  public static let smallPadding: CSS.Length = spacing4
  public static var smallMinSize: CSS.Length { smallPadding * 2 + lineHeightSmall22 + borderWidthBase * 2 }
  public static let miniPadding: CSS.Length = spacing0
  public static var miniMinSize: CSS.Length { miniPadding * 2 + lineHeightSmall22 + borderWidthBase * 2 }

  /// A button one size smaller under `phoneStep` below 480px.
  @CSSBuilder
  static func phoneStepDownCSS() -> [CSSOM.CSSRule] {
    media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
      selector("\(phoneStep) &[data-size='small']") {
        minHeight(miniMinSize).important()
        fontSize(fontSizeXSmall12).important()
      }
      selector("\(phoneStep) &[data-full-width='false'][data-size='small']") { minWidth(miniMinSize).important() }
      selector("\(phoneStep) &[data-icon-only='true'][data-size='small']") {
        width(miniMinSize).important()
        height(miniMinSize).important()
      }
      selector("\(phoneStep) &[data-icon-only='false'][data-size='small']") { padding(miniPadding).important() }
      selector("\(phoneStep) &[data-size='medium']") {
        minHeight(smallMinSize).important()
        fontSize(fontSizeSmall14).important()
      }
      selector("\(phoneStep) &[data-full-width='false'][data-size='medium']") { minWidth(smallMinSize).important() }
      selector("\(phoneStep) &[data-icon-only='true'][data-size='medium']") {
        width(smallMinSize).important()
        height(smallMinSize).important()
      }
      selector("\(phoneStep) &[data-icon-only='false'][data-size='medium']") { padding(smallPadding).important() }
      selector("\(phoneStep) &[data-size='large']") {
        minHeight(ButtonSize.medium.minSize).important()
        fontSize(fontSizeMedium16).important()
      }
      selector("\(phoneStep) &[data-full-width='false'][data-size='large']") {
        minWidth(ButtonSize.medium.minSize).important()
      }
      selector("\(phoneStep) &[data-icon-only='true'][data-size='large']") {
        width(ButtonSize.medium.minSize).important()
        height(ButtonSize.medium.minSize).important()
      }
      selector("\(phoneStep) &[data-icon-only='false'][data-size='large']") {
        padding(ButtonSize.medium.padding).important()
      }
      // A medium button that holds its size (`data-phone-floor`): a target
      // a thumb is asked to hit stays 40 on a phone, the step down
      // above set aside.
      selector("\(phoneStep) &[data-phone-floor='true'][data-size='medium']") {
        minHeight(ButtonSize.medium.minSize).important()
        fontSize(fontSizeMedium16).important()
      }
      selector("\(phoneStep) &[data-phone-floor='true'][data-icon-only='true'][data-size='medium']") {
        width(ButtonSize.medium.minSize).important()
        height(ButtonSize.medium.minSize).important()
      }
    }
  }

  /// A popup row hanging from a large control (a dropdown's or combobox's
  /// option and note, a time part's or a day's cell) is that control's
  /// height—48—and steps down with it under `phoneStep`: 40 on a phone
  /// (user, 2026-10-21). `rows` is the row's selector inside the view
  /// (`.combobox-option`), or several; `fixed` sets their block size
  /// instead of their least.
  @CSSBuilder
  static func phoneStepRowCSS(_ rows: String..., fixed: Bool = false) -> [CSSOM.CSSRule] {
    media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
      selector(rows.map { "\(phoneStep) & \($0)" }.joined(separator: ", ")) {
        if fixed {
          blockSize(ButtonSize.medium.minSize).important()
        } else {
          minHeight(ButtonSize.medium.minSize).important()
        }
      }
    }
  }

  /// A field (a text input's box, a select's handle) is the large control's
  /// height—48—and steps down with it under `phoneStep`: 40 on a phone
  /// (user, 2026-10-21), so a text input, a select, a date and a time
  /// field end the same height as the dropdown trigger beside them. Its
  /// block inset drops to the medium control's; the inline inset, and the
  /// room an icon takes, stay. `fields` is each field's selector inside
  /// the view.
  @CSSBuilder
  static func phoneStepFieldCSS(_ fields: String...) -> [CSSOM.CSSRule] {
    media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
      selector(fields.map { "\(phoneStep) & \($0)" }.joined(separator: ", ")) {
        paddingBlock(ButtonSize.medium.padding).important()
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
    labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: ButtonRadius = .pill,
    data: [(String, String)] = []
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
    self.contentJustifyContent = contentJustifyContent
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
    labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: ButtonRadius = .pill,
    data: [(String, String)] = []
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
    self.contentJustifyContent = contentJustifyContent
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
    labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: ButtonRadius = .pill,
    data: [(String, String)] = []
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
    self.contentJustifyContent = contentJustifyContent
    self.buttonBorderRadius = borderRadius
    self.dataAttributes = data
  }

  /// Create a button with custom content. `iconOnly` when the content is
  /// an icon alone (a toggle's), for the square an icon-only button is.
  public init(
    label: String = "",
    buttonColor: ButtonColor = .gray,
    weight: ButtonWeight = .subtle,
    size: ButtonSize = .medium,
    disabled: Bool = false,
    iconOnly: Bool = false,
    url: String? = nil,
    type: ButtonType = .button,
    ariaLabel: String? = nil,
    onClick: String? = nil,
    fullWidth: Bool = false,
    class: String = "",
    labelFontWeight: CSS.FontWeight = fontWeightSemiBold,
    contentJustifyContent: CSS.JustifyContent = .center,
    borderRadius: ButtonRadius = .pill,
    data: [(String, String)] = [],
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.label = label
    self.buttonColor = buttonColor
    self.weight = weight
    self.size = size
    self.icon = .fragment { content() }
    self.iconOnly = iconOnly
    self.customContent = true
    self.disabled = disabled
    self.ariaLabel = ariaLabel
    self.url = url
    self.onClick = onClick
    self.type = type
    self.fullWidth = fullWidth
    self.class = `class`
    self.labelFontWeight = labelFontWeight
    self.contentJustifyContent = contentJustifyContent
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

  /// The standard `download` attribute of a link-button: the link saves its
  /// target as a file of this name instead of opening it. A button that is
  /// not a link has nothing to download.
  public func download(_ filename: String) -> Self {
    var copy = self
    copy.downloadFilename = filename
    return copy
  }

  /// The standard `name` and `value` attributes of a submit button: the
  /// pair it adds to its form's data, where the form's other fields are,
  /// when it is the button submitting. A link-button submits nothing.
  public func submits(name: String, value: String) -> Self {
    var copy = self
    copy.submitName = name
    copy.submitValue = value
    return copy
  }

  /// The standard `title` attribute: the native tooltip, which a disabled
  /// button keeps to say why it is disabled.
  public func title(_ text: String) -> Self {
    var copy = self
    copy.titleText = text
    return copy
  }

  /// The standard `popovertarget` attribute: the popover this button opens
  /// and closes, with no script—and which the popover is then anchored to.
  public func popoverTarget(_ id: String) -> Self {
    var copy = self
    copy.popoverTargetID = id
    return copy
  }

  /// The standard `aria-expanded` attribute: whether the region this button
  /// shows and hides is open.
  public func ariaExpanded(_ value: Bool) -> Self {
    var copy = self
    copy.expanded = value
    return copy
  }

  /// The standard `aria-pressed` attribute: whether a toggle button is on.
  /// A quiet button on shows its weight's pressed look, its `:active` fill
  /// held (a reaction the reader made, user 2026-10-12).
  public func ariaPressed(_ value: Bool) -> Self {
    var copy = self
    copy.pressed = value
    return copy
  }

  /// The standard `aria-controls` attribute: the element this button shows
  /// and hides.
  public func ariaControls(_ id: String) -> Self {
    var copy = self
    copy.controlsID = id
    return copy
  }

  public func build() -> DOM.Node {
    let baseClasses = "button-view button-color-\(buttonColor.rawValue) button-weight-\(weight.rawValue) button-size-\(size.rawValue) \(buttonBorderRadius.className)\(iconOnly ? " button-icon-only" : "")"
    let fullClass = stringIsEmpty(`class`) ? baseClasses : "\(baseClasses) \(`class`)"

    @HTMLBuilder
    func renderContent() -> [DOM.Node] {
      if let icon = icon {
        if stringIsEmpty(label) && iconOnly && !customContent {
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
            // Base—common props only—fontWeight/color via data-attributes below (cacheable)
            alignItems(.center)
            // Icon to label: icons are drawn tight, with no room of their
            // own around the glyph, so this gap is all the room between them.
            gap(spacing8)
            fontFamily(typographyFontSans)
            fontSize(fontSizeMedium16)
            // The standard line at every size: the height is the inset,
            // this line and the border (ButtonSize.minSize).
            lineHeight(lineHeightSmall22)
            // An icon fills the line: the icon token, here, is the 22px
            // line's (ButtonSize.iconSize), so an icon a caller sized with
            // it never grows the button.
            customProperty("--size-icon-small", lineHeightSmall22.value)
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
            // then faded it out over 100ms—the black ring that flashed on
            // every close button.
            transition("background-color 0.1s ease, border-color 0.1s ease, color 0.1s ease")

            // A mouse click focuses a button but should not ring it. Keyboard
            // focus does: `:focus-visible` is the browser's own judgment of
            // when a ring is useful, and it gets the focus ring every control
            // wears—the browser's own was left to show through, in whatever
            // accent the system happened to have.
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, borderColorTransparent).important()
            }
            pseudoClass(.focusVisible) {
              outline(borderWidthThick, .solid, borderColorBlueFocus).important()
              outlineOffset(borderWidthBase).important()
            }

            // Disabled state—static via data-attributes (cacheable)
            pseudoClass(.disabled) {
              color(colorDisabled).important()
              cursor(cursorNotAllowed).important()
            }

            // Disabled icons keep the same muted color under the pointer.
            // Include the wrapper: toggle styles otherwise give it an active
            // foreground until the pointer reaches the inner icon.
            selector("&:disabled .button-icon", "&:disabled .button-label", "&:disabled .icon-view") {
              color(colorDisabled).important()
            }
          }

          selector("&[data-font-weight='normal']") {
            fontWeight(fontWeightNormal)
          }
          selector("&[data-font-weight='semibold']") {
            fontWeight(fontWeightSemiBold)
          }
          // Radius—static superset keyed on the token's class (cacheable);
          // pill is the base rule's own.
          selector("&.button-radius-minimal") { borderRadius(borderRadiusMinimal) }
          selector("&.button-radius-base") { borderRadius(borderRadiusBase) }
          selector("&.button-radius-sharp") { borderRadius(borderRadiusSharp) }
          selector("&.button-radius-circle") { borderRadius(borderRadiusCircle) }
          // Variant—static superset via data-attributes (one instance emits all)
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
          selector("&[data-icon-only='false'][data-size='mini']") { padding(ButtonSize.mini.padding) }
          selector("&[data-icon-only='false'][data-size='small']") { padding(ButtonSize.small.padding) }
          selector("&[data-icon-only='false'][data-size='medium']") { padding(ButtonSize.medium.padding) }
          selector("&[data-icon-only='false'][data-size='large']") { padding(ButtonSize.large.padding) }

          // Quiet/Plain—opaque base bg + transparent border (not see-through on borders/surfaces)
          selector("&[data-weight='quiet'], &[data-weight='plain']") {
            backgroundColor(backgroundColorTransparent).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray'], &[data-weight='plain'][data-color='gray']") {
            color(colorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='red'], &[data-weight='plain'][data-color='red']") { color(`var`("--color-red")).important() }
          selector("&[data-weight='quiet'][data-color='orange'], &[data-weight='plain'][data-color='orange']") { color(`var`("--color-orange")).important() }
          selector("&[data-weight='quiet'][data-color='yellow'], &[data-weight='plain'][data-color='yellow']") { color(`var`("--color-yellow")).important() }
          selector("&[data-weight='quiet'][data-color='lime'], &[data-weight='plain'][data-color='lime']") { color(`var`("--color-lime")).important() }
          selector("&[data-weight='quiet'][data-color='green'], &[data-weight='plain'][data-color='green']") { color(`var`("--color-green")).important() }
          selector("&[data-weight='quiet'][data-color='mint'], &[data-weight='plain'][data-color='mint']") { color(`var`("--color-mint")).important() }
          selector("&[data-weight='quiet'][data-color='cyan'], &[data-weight='plain'][data-color='cyan']") { color(`var`("--color-cyan")).important() }
          selector("&[data-weight='quiet'][data-color='blue'], &[data-weight='plain'][data-color='blue']") { color(`var`("--color-blue")).important() }
          selector("&[data-weight='quiet'][data-color='indigo'], &[data-weight='plain'][data-color='indigo']") { color(`var`("--color-indigo")).important() }
          selector("&[data-weight='quiet'][data-color='violet'], &[data-weight='plain'][data-color='violet']") { color(`var`("--color-violet")).important() }
          selector("&[data-weight='quiet'][data-color='magenta'], &[data-weight='plain'][data-color='magenta']") { color(`var`("--color-magenta")).important() }
          selector("&[data-weight='quiet'][data-color='pink'], &[data-weight='plain'][data-color='pink']") { color(`var`("--color-pink")).important() }
          // A link can't be `disabled`; a disabled link-button is marked
          // `aria-disabled` and looks as a disabled button does. It still
          // follows its link, for a page that explains why it can't be used.
          selector("&[aria-disabled='true']") {
            color(colorDisabled).important()
            cursor(cursorNotAllowed).important()
          }
          selector("&[data-weight='quiet'][aria-disabled='true'], &[data-weight='plain'][aria-disabled='true']") {
            backgroundColor(backgroundColorTransparent).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='subtle'][aria-disabled='true'], &[data-weight='solid'][aria-disabled='true'], &[data-weight='static'][aria-disabled='true']") {
            backgroundColor(backgroundColorDisabled).important()
            borderColor(borderColorDisabled).important()
          }
          selector("&[data-weight='quiet']:disabled, &[data-weight='plain']:disabled") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='subtle']:disabled, &[data-weight='solid']:disabled, &[data-weight='static']:disabled") {
            backgroundColor(backgroundColorDisabled).important()
            borderColor(borderColorDisabled).important()
          }
          // Solid / Subtle / Static superset—cacheable overrides for per-instance base (fixes Mission Control blue vs white)
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
          selector("&[data-weight='subtle'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange-subtle"))
            color(`var`("--color-orange"))
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='subtle'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow-subtle"))
            color(`var`("--color-yellow"))
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='subtle'][data-color='lime']") {
            backgroundColor(`var`("--background-color-lime-subtle"))
            color(`var`("--color-lime"))
            borderColor(`var`("--border-color-lime"))
          }
          selector("&[data-weight='subtle'][data-color='green']") {
            backgroundColor(`var`("--background-color-green-subtle"))
            color(`var`("--color-green"))
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='subtle'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint-subtle"))
            color(`var`("--color-mint"))
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='subtle'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan-subtle"))
            color(`var`("--color-cyan"))
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='subtle'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue-subtle"))
            color(`var`("--color-blue"))
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='subtle'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo-subtle"))
            color(`var`("--color-indigo"))
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='subtle'][data-color='violet']") {
            backgroundColor(`var`("--background-color-violet-subtle"))
            color(`var`("--color-violet"))
            borderColor(`var`("--border-color-violet"))
          }
          selector("&[data-weight='subtle'][data-color='magenta']") {
            backgroundColor(`var`("--background-color-magenta-subtle"))
            color(`var`("--color-magenta"))
            borderColor(`var`("--border-color-magenta"))
          }
          selector("&[data-weight='subtle'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink-subtle"))
            color(`var`("--color-pink"))
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='solid'][data-color='red']") {
            backgroundColor(`var`("--background-color-red"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-red"))
          }
          selector("&[data-weight='solid'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-orange"))
          }
          selector("&[data-weight='solid'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-yellow"))
          }
          selector("&[data-weight='solid'][data-color='lime']") {
            backgroundColor(`var`("--background-color-lime"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-lime"))
          }
          selector("&[data-weight='solid'][data-color='green']") {
            backgroundColor(`var`("--background-color-green"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-green"))
          }
          selector("&[data-weight='solid'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-mint"))
          }
          selector("&[data-weight='solid'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-cyan"))
          }
          selector("&[data-weight='solid'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-blue"))
          }
          selector("&[data-weight='solid'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-indigo"))
          }
          selector("&[data-weight='solid'][data-color='violet']") {
            backgroundColor(`var`("--background-color-violet"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-violet"))
          }
          selector("&[data-weight='solid'][data-color='magenta']") {
            backgroundColor(`var`("--background-color-magenta"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-magenta"))
          }
          selector("&[data-weight='solid'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-pink"))
          }
          selector("&[data-weight='static'][data-color='red']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='static'][data-color='orange']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='static'][data-color='yellow']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='static'][data-color='lime']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-lime"))
          }
          selector("&[data-weight='static'][data-color='green']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='static'][data-color='mint']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='static'][data-color='cyan']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='static'][data-color='blue']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='static'][data-color='indigo']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='static'][data-color='violet']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-violet"))
          }
          selector("&[data-weight='static'][data-color='magenta']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-magenta"))
          }
          selector("&[data-weight='static'][data-color='pink']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-pink"))
          }

          // Hover / Active—cacheable via data-attributes (covers all solid/subtle/quiet/plain)
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
          selector("&[data-weight='quiet'][data-color='gray']:active:not(:disabled)", "&[data-weight='quiet'][data-color='gray'][aria-pressed='true']") {
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
          selector("&[data-weight='subtle'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle-hover")).important()
            borderColor(`var`("--border-color-lime-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle-hover")).important()
            borderColor(`var`("--border-color-violet-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle-hover")).important()
            borderColor(`var`("--border-color-magenta-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='lime']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle-active")).important()
            borderColor(`var`("--border-color-lime-active")).important()
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='violet']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle-active")).important()
            borderColor(`var`("--border-color-violet-active")).important()
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='magenta']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle-active")).important()
            borderColor(`var`("--border-color-magenta-active")).important()
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-hover")).important()
            borderColor(`var`("--border-color-lime-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-hover")).important()
            borderColor(`var`("--border-color-violet-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-hover")).important()
            borderColor(`var`("--border-color-magenta-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
          }
          selector("&[data-weight='solid'][data-color='lime']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-active")).important()
            borderColor(`var`("--border-color-lime-active")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
          }
          selector("&[data-weight='solid'][data-color='violet']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-active")).important()
            borderColor(`var`("--border-color-violet-active")).important()
          }
          selector("&[data-weight='solid'][data-color='magenta']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-active")).important()
            borderColor(`var`("--border-color-magenta-active")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:active:not(:disabled)", "&[data-weight='quiet'][data-color='red'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:active:not(:disabled)", "&[data-weight='quiet'][data-color='orange'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:active:not(:disabled)", "&[data-weight='quiet'][data-color='yellow'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='lime']:active:not(:disabled)", "&[data-weight='quiet'][data-color='lime'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-lime-subtle-active")).important()
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:active:not(:disabled)", "&[data-weight='quiet'][data-color='green'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:active:not(:disabled)", "&[data-weight='quiet'][data-color='mint'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:active:not(:disabled)", "&[data-weight='quiet'][data-color='cyan'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:active:not(:disabled)", "&[data-weight='quiet'][data-color='blue'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:active:not(:disabled)", "&[data-weight='quiet'][data-color='indigo'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='violet']:active:not(:disabled)", "&[data-weight='quiet'][data-color='violet'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-violet-subtle-active")).important()
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='magenta']:active:not(:disabled)", "&[data-weight='quiet'][data-color='magenta'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-magenta-subtle-active")).important()
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:active:not(:disabled)", "&[data-weight='quiet'][data-color='pink'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='plain'][data-color='red']:hover:not(:disabled)") {
            color(colorRedHover).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:hover:not(:disabled)") {
            color(colorOrangeHover).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:hover:not(:disabled)") {
            color(colorYellowHover).important()
          }
          selector("&[data-weight='plain'][data-color='lime']:hover:not(:disabled)") {
            color(colorLimeHover).important()
          }
          selector("&[data-weight='plain'][data-color='green']:hover:not(:disabled)") {
            color(colorGreenHover).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:hover:not(:disabled)") {
            color(colorMintHover).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:hover:not(:disabled)") {
            color(colorCyanHover).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:hover:not(:disabled)") {
            color(colorBlueHover).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:hover:not(:disabled)") {
            color(colorIndigoHover).important()
          }
          selector("&[data-weight='plain'][data-color='violet']:hover:not(:disabled)") {
            color(colorVioletHover).important()
          }
          selector("&[data-weight='plain'][data-color='magenta']:hover:not(:disabled)") {
            color(colorMagentaHover).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:hover:not(:disabled)") {
            color(colorPinkHover).important()
          }
          selector("&[data-weight='plain'][data-color='red']:active:not(:disabled)") {
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:active:not(:disabled)") {
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:active:not(:disabled)") {
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='plain'][data-color='lime']:active:not(:disabled)") {
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='plain'][data-color='green']:active:not(:disabled)") {
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:active:not(:disabled)") {
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:active:not(:disabled)") {
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:active:not(:disabled)") {
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:active:not(:disabled)") {
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='plain'][data-color='violet']:active:not(:disabled)") {
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='plain'][data-color='magenta']:active:not(:disabled)") {
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:active:not(:disabled)") {
            color(`var`("--color-pink-active")).important()
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
          // The box is as wide as its icon and as tall as the button's
          // line (ButtonSize.iconSize), so the icon fills the label's line.
          descendant(".button-icon") { height(ButtonSize.medium.iconSize) }
          ButtonView.phoneStepDownCSS()
        }

      // `aria-disabled`, not a class: `.class` would replace the button's
      // own classes, and a disabled link lost all its styles with them.
      if disabled {
        aBtn = aBtn.ariaDisabled(true)
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

      if let downloadFilename {
        aBtn = aBtn.download(downloadFilename)
      }

      if let titleText {
        aBtn = aBtn.title(titleText)
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
            // Base—common per-instance props (static superset via data-attributes below)
            alignItems(.center)
            // Icon to label: icons are drawn tight, with no room of their
            // own around the glyph, so this gap is all the room between them.
            gap(spacing8)
            fontFamily(typographyFontSans)
            fontSize(fontSizeMedium16)
            // The standard line at every size: the height is the inset,
            // this line and the border (ButtonSize.minSize).
            lineHeight(lineHeightSmall22)
            // An icon fills the line: the icon token, here, is the 22px
            // line's (ButtonSize.iconSize), so an icon a caller sized with
            // it never grows the button.
            customProperty("--size-icon-small", lineHeightSmall22.value)
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
            // then faded it out over 100ms—the black ring that flashed on
            // every close button.
            transition("background-color 0.1s ease, border-color 0.1s ease, color 0.1s ease")

            // A mouse click focuses a button but should not ring it. Keyboard
            // focus does: `:focus-visible` is the browser's own judgment of
            // when a ring is useful, and it gets the focus ring every control
            // wears—the browser's own was left to show through, in whatever
            // accent the system happened to have.
            pseudoClass(.focus) {
              outline(borderWidthBase, .solid, borderColorTransparent).important()
            }
            pseudoClass(.focusVisible) {
              outline(borderWidthThick, .solid, borderColorBlueFocus).important()
              outlineOffset(borderWidthBase).important()
            }

            // Disabled state—static via data-attributes (cacheable)
            pseudoClass(.disabled) {
              color(colorDisabled).important()
              cursor(cursorNotAllowed).important()
            }

            // Disabled icons keep the same muted color under the pointer.
            // Include the wrapper: toggle styles otherwise give it an active
            // foreground until the pointer reaches the inner icon.
            selector("&:disabled .button-icon", "&:disabled .button-label", "&:disabled .icon-view") {
              color(colorDisabled).important()
            }
          }

          selector("&[data-font-weight='normal']") {
            fontWeight(fontWeightNormal)
          }
          selector("&[data-font-weight='semibold']") {
            fontWeight(fontWeightSemiBold)
          }
          // Radius—static superset keyed on the token's class (cacheable);
          // pill is the base rule's own.
          selector("&.button-radius-minimal") { borderRadius(borderRadiusMinimal) }
          selector("&.button-radius-base") { borderRadius(borderRadiusBase) }
          selector("&.button-radius-sharp") { borderRadius(borderRadiusSharp) }
          selector("&.button-radius-circle") { borderRadius(borderRadiusCircle) }
          // Variant—static superset via data-attributes (one instance emits all)
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
          selector("&[data-icon-only='false'][data-size='mini']") { padding(ButtonSize.mini.padding) }
          selector("&[data-icon-only='false'][data-size='small']") { padding(ButtonSize.small.padding) }
          selector("&[data-icon-only='false'][data-size='medium']") { padding(ButtonSize.medium.padding) }
          selector("&[data-icon-only='false'][data-size='large']") { padding(ButtonSize.large.padding) }

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
          // The box is as wide as its icon and as tall as the button's
          // line (ButtonSize.iconSize), so the icon fills the label's line.
          descendant(".button-icon") { height(ButtonSize.medium.iconSize) }
          ButtonView.phoneStepDownCSS()

          // Quiet/Plain—opaque base bg + transparent border (mirrors <a> branch)
          selector("&[data-weight='quiet'], &[data-weight='plain']") {
            backgroundColor(backgroundColorTransparent).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='quiet'][data-color='gray'], &[data-weight='plain'][data-color='gray']") {
            color(colorBase).important()
          }
          selector("&[data-weight='quiet'][data-color='red'], &[data-weight='plain'][data-color='red']") { color(`var`("--color-red")).important() }
          selector("&[data-weight='quiet'][data-color='orange'], &[data-weight='plain'][data-color='orange']") { color(`var`("--color-orange")).important() }
          selector("&[data-weight='quiet'][data-color='yellow'], &[data-weight='plain'][data-color='yellow']") { color(`var`("--color-yellow")).important() }
          selector("&[data-weight='quiet'][data-color='lime'], &[data-weight='plain'][data-color='lime']") { color(`var`("--color-lime")).important() }
          selector("&[data-weight='quiet'][data-color='green'], &[data-weight='plain'][data-color='green']") { color(`var`("--color-green")).important() }
          selector("&[data-weight='quiet'][data-color='mint'], &[data-weight='plain'][data-color='mint']") { color(`var`("--color-mint")).important() }
          selector("&[data-weight='quiet'][data-color='cyan'], &[data-weight='plain'][data-color='cyan']") { color(`var`("--color-cyan")).important() }
          selector("&[data-weight='quiet'][data-color='blue'], &[data-weight='plain'][data-color='blue']") { color(`var`("--color-blue")).important() }
          selector("&[data-weight='quiet'][data-color='indigo'], &[data-weight='plain'][data-color='indigo']") { color(`var`("--color-indigo")).important() }
          selector("&[data-weight='quiet'][data-color='violet'], &[data-weight='plain'][data-color='violet']") { color(`var`("--color-violet")).important() }
          selector("&[data-weight='quiet'][data-color='magenta'], &[data-weight='plain'][data-color='magenta']") { color(`var`("--color-magenta")).important() }
          selector("&[data-weight='quiet'][data-color='pink'], &[data-weight='plain'][data-color='pink']") { color(`var`("--color-pink")).important() }
          selector("&[data-weight='quiet']:disabled, &[data-weight='plain']:disabled") {
            backgroundColor(backgroundColorBase).important()
            borderColor(.transparent).important()
          }
          selector("&[data-weight='subtle']:disabled, &[data-weight='solid']:disabled, &[data-weight='static']:disabled") {
            backgroundColor(backgroundColorDisabled).important()
            borderColor(borderColorDisabled).important()
          }
          // Solid / Subtle / Static superset—mirrors aBtn branch (fixes solid blue)
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
          selector("&[data-weight='subtle'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange-subtle"))
            color(`var`("--color-orange"))
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='subtle'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow-subtle"))
            color(`var`("--color-yellow"))
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='subtle'][data-color='lime']") {
            backgroundColor(`var`("--background-color-lime-subtle"))
            color(`var`("--color-lime"))
            borderColor(`var`("--border-color-lime"))
          }
          selector("&[data-weight='subtle'][data-color='green']") {
            backgroundColor(`var`("--background-color-green-subtle"))
            color(`var`("--color-green"))
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='subtle'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint-subtle"))
            color(`var`("--color-mint"))
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='subtle'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan-subtle"))
            color(`var`("--color-cyan"))
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='subtle'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue-subtle"))
            color(`var`("--color-blue"))
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='subtle'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo-subtle"))
            color(`var`("--color-indigo"))
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='subtle'][data-color='violet']") {
            backgroundColor(`var`("--background-color-violet-subtle"))
            color(`var`("--color-violet"))
            borderColor(`var`("--border-color-violet"))
          }
          selector("&[data-weight='subtle'][data-color='magenta']") {
            backgroundColor(`var`("--background-color-magenta-subtle"))
            color(`var`("--color-magenta"))
            borderColor(`var`("--border-color-magenta"))
          }
          selector("&[data-weight='subtle'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink-subtle"))
            color(`var`("--color-pink"))
            borderColor(`var`("--border-color-pink"))
          }
          selector("&[data-weight='solid'][data-color='red']") {
            backgroundColor(`var`("--background-color-red"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-red"))
          }
          selector("&[data-weight='solid'][data-color='orange']") {
            backgroundColor(`var`("--background-color-orange"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-orange"))
          }
          selector("&[data-weight='solid'][data-color='yellow']") {
            backgroundColor(`var`("--background-color-yellow"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-yellow"))
          }
          selector("&[data-weight='solid'][data-color='lime']") {
            backgroundColor(`var`("--background-color-lime"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-lime"))
          }
          selector("&[data-weight='solid'][data-color='green']") {
            backgroundColor(`var`("--background-color-green"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-green"))
          }
          selector("&[data-weight='solid'][data-color='mint']") {
            backgroundColor(`var`("--background-color-mint"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-mint"))
          }
          selector("&[data-weight='solid'][data-color='cyan']") {
            backgroundColor(`var`("--background-color-cyan"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-cyan"))
          }
          selector("&[data-weight='solid'][data-color='blue']") {
            backgroundColor(`var`("--background-color-blue"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-blue"))
          }
          selector("&[data-weight='solid'][data-color='indigo']") {
            backgroundColor(`var`("--background-color-indigo"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-indigo"))
          }
          selector("&[data-weight='solid'][data-color='violet']") {
            backgroundColor(`var`("--background-color-violet"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-violet"))
          }
          selector("&[data-weight='solid'][data-color='magenta']") {
            backgroundColor(`var`("--background-color-magenta"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-magenta"))
          }
          selector("&[data-weight='solid'][data-color='pink']") {
            backgroundColor(`var`("--background-color-pink"))
            color(colorOnSolid)
            borderColor(`var`("--background-color-pink"))
          }
          selector("&[data-weight='static'][data-color='red']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-red"))
          }
          selector("&[data-weight='static'][data-color='orange']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-orange"))
          }
          selector("&[data-weight='static'][data-color='yellow']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-yellow"))
          }
          selector("&[data-weight='static'][data-color='lime']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-lime"))
          }
          selector("&[data-weight='static'][data-color='green']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-green"))
          }
          selector("&[data-weight='static'][data-color='mint']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-mint"))
          }
          selector("&[data-weight='static'][data-color='cyan']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-cyan"))
          }
          selector("&[data-weight='static'][data-color='blue']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-blue"))
          }
          selector("&[data-weight='static'][data-color='indigo']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-indigo"))
          }
          selector("&[data-weight='static'][data-color='violet']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-violet"))
          }
          selector("&[data-weight='static'][data-color='magenta']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-magenta"))
          }
          selector("&[data-weight='static'][data-color='pink']") {
            backgroundColor(backgroundColorBase)
            color(colorBase)
            borderColor(`var`("--border-color-pink"))
          }

          // Hover / Active—cacheable via data-attributes (covers all solid/subtle/quiet/plain)
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
          selector("&[data-weight='quiet'][data-color='gray']:active:not(:disabled)", "&[data-weight='quiet'][data-color='gray'][aria-pressed='true']") {
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
          selector("&[data-weight='subtle'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle-hover")).important()
            borderColor(`var`("--border-color-lime-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle-hover")).important()
            borderColor(`var`("--border-color-violet-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle-hover")).important()
            borderColor(`var`("--border-color-magenta-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='subtle'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='lime']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle-active")).important()
            borderColor(`var`("--border-color-lime-active")).important()
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='violet']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle-active")).important()
            borderColor(`var`("--border-color-violet-active")).important()
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='magenta']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle-active")).important()
            borderColor(`var`("--border-color-magenta-active")).important()
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='subtle'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-hover")).important()
            borderColor(`var`("--border-color-red-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-hover")).important()
            borderColor(`var`("--border-color-orange-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-hover")).important()
            borderColor(`var`("--border-color-yellow-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-hover")).important()
            borderColor(`var`("--border-color-lime-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-hover")).important()
            borderColor(`var`("--border-color-green-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-hover")).important()
            borderColor(`var`("--border-color-mint-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-hover")).important()
            borderColor(`var`("--border-color-cyan-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-hover")).important()
            borderColor(`var`("--border-color-blue-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-hover")).important()
            borderColor(`var`("--border-color-indigo-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-hover")).important()
            borderColor(`var`("--border-color-violet-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-hover")).important()
            borderColor(`var`("--border-color-magenta-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-hover")).important()
            borderColor(`var`("--border-color-pink-hover")).important()
          }
          selector("&[data-weight='solid'][data-color='red']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-active")).important()
            borderColor(`var`("--border-color-red-active")).important()
          }
          selector("&[data-weight='solid'][data-color='orange']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-active")).important()
            borderColor(`var`("--border-color-orange-active")).important()
          }
          selector("&[data-weight='solid'][data-color='yellow']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-active")).important()
            borderColor(`var`("--border-color-yellow-active")).important()
          }
          selector("&[data-weight='solid'][data-color='lime']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-active")).important()
            borderColor(`var`("--border-color-lime-active")).important()
          }
          selector("&[data-weight='solid'][data-color='green']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-active")).important()
            borderColor(`var`("--border-color-green-active")).important()
          }
          selector("&[data-weight='solid'][data-color='mint']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-active")).important()
            borderColor(`var`("--border-color-mint-active")).important()
          }
          selector("&[data-weight='solid'][data-color='cyan']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-active")).important()
            borderColor(`var`("--border-color-cyan-active")).important()
          }
          selector("&[data-weight='solid'][data-color='blue']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-active")).important()
            borderColor(`var`("--border-color-blue-active")).important()
          }
          selector("&[data-weight='solid'][data-color='indigo']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-active")).important()
            borderColor(`var`("--border-color-indigo-active")).important()
          }
          selector("&[data-weight='solid'][data-color='violet']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-active")).important()
            borderColor(`var`("--border-color-violet-active")).important()
          }
          selector("&[data-weight='solid'][data-color='magenta']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-active")).important()
            borderColor(`var`("--border-color-magenta-active")).important()
          }
          selector("&[data-weight='solid'][data-color='pink']:active:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-active")).important()
            borderColor(`var`("--border-color-pink-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-red-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-orange-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-yellow-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='lime']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-lime-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-green-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-mint-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-cyan-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-blue-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-indigo-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='violet']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-violet-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='magenta']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-magenta-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:hover:not(:disabled)") {
            backgroundColor(`var`("--background-color-pink-subtle")).important()
          }
          selector("&[data-weight='quiet'][data-color='red']:active:not(:disabled)", "&[data-weight='quiet'][data-color='red'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-red-subtle-active")).important()
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='orange']:active:not(:disabled)", "&[data-weight='quiet'][data-color='orange'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-orange-subtle-active")).important()
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='yellow']:active:not(:disabled)", "&[data-weight='quiet'][data-color='yellow'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-yellow-subtle-active")).important()
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='lime']:active:not(:disabled)", "&[data-weight='quiet'][data-color='lime'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-lime-subtle-active")).important()
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='green']:active:not(:disabled)", "&[data-weight='quiet'][data-color='green'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-green-subtle-active")).important()
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='mint']:active:not(:disabled)", "&[data-weight='quiet'][data-color='mint'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-mint-subtle-active")).important()
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='cyan']:active:not(:disabled)", "&[data-weight='quiet'][data-color='cyan'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-cyan-subtle-active")).important()
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='blue']:active:not(:disabled)", "&[data-weight='quiet'][data-color='blue'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-blue-subtle-active")).important()
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='indigo']:active:not(:disabled)", "&[data-weight='quiet'][data-color='indigo'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-indigo-subtle-active")).important()
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='violet']:active:not(:disabled)", "&[data-weight='quiet'][data-color='violet'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-violet-subtle-active")).important()
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='magenta']:active:not(:disabled)", "&[data-weight='quiet'][data-color='magenta'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-magenta-subtle-active")).important()
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='quiet'][data-color='pink']:active:not(:disabled)", "&[data-weight='quiet'][data-color='pink'][aria-pressed='true']") {
            backgroundColor(`var`("--background-color-pink-subtle-active")).important()
            color(`var`("--color-pink-active")).important()
          }
          selector("&[data-weight='plain'][data-color='red']:hover:not(:disabled)") {
            color(colorRedHover).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:hover:not(:disabled)") {
            color(colorOrangeHover).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:hover:not(:disabled)") {
            color(colorYellowHover).important()
          }
          selector("&[data-weight='plain'][data-color='lime']:hover:not(:disabled)") {
            color(colorLimeHover).important()
          }
          selector("&[data-weight='plain'][data-color='green']:hover:not(:disabled)") {
            color(colorGreenHover).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:hover:not(:disabled)") {
            color(colorMintHover).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:hover:not(:disabled)") {
            color(colorCyanHover).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:hover:not(:disabled)") {
            color(colorBlueHover).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:hover:not(:disabled)") {
            color(colorIndigoHover).important()
          }
          selector("&[data-weight='plain'][data-color='violet']:hover:not(:disabled)") {
            color(colorVioletHover).important()
          }
          selector("&[data-weight='plain'][data-color='magenta']:hover:not(:disabled)") {
            color(colorMagentaHover).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:hover:not(:disabled)") {
            color(colorPinkHover).important()
          }
          selector("&[data-weight='plain'][data-color='red']:active:not(:disabled)") {
            color(`var`("--color-red-active")).important()
          }
          selector("&[data-weight='plain'][data-color='orange']:active:not(:disabled)") {
            color(`var`("--color-orange-active")).important()
          }
          selector("&[data-weight='plain'][data-color='yellow']:active:not(:disabled)") {
            color(`var`("--color-yellow-active")).important()
          }
          selector("&[data-weight='plain'][data-color='lime']:active:not(:disabled)") {
            color(`var`("--color-lime-active")).important()
          }
          selector("&[data-weight='plain'][data-color='green']:active:not(:disabled)") {
            color(`var`("--color-green-active")).important()
          }
          selector("&[data-weight='plain'][data-color='mint']:active:not(:disabled)") {
            color(`var`("--color-mint-active")).important()
          }
          selector("&[data-weight='plain'][data-color='cyan']:active:not(:disabled)") {
            color(`var`("--color-cyan-active")).important()
          }
          selector("&[data-weight='plain'][data-color='blue']:active:not(:disabled)") {
            color(`var`("--color-blue-active")).important()
          }
          selector("&[data-weight='plain'][data-color='indigo']:active:not(:disabled)") {
            color(`var`("--color-indigo-active")).important()
          }
          selector("&[data-weight='plain'][data-color='violet']:active:not(:disabled)") {
            color(`var`("--color-violet-active")).important()
          }
          selector("&[data-weight='plain'][data-color='magenta']:active:not(:disabled)") {
            color(`var`("--color-magenta-active")).important()
          }
          selector("&[data-weight='plain'][data-color='pink']:active:not(:disabled)") {
            color(`var`("--color-pink-active")).important()
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

      // Native disabled already supplies the accessibility state and tracks
      // later property changes. A static aria-disabled would stay true when
      // hydration enables the button, preserving its gray text and blocked cursor.

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

      if let titleText {
        bBtn = bBtn.title(titleText)
      }

      if let popoverTargetID {
        bBtn = bBtn.addingAttribute("popovertarget", popoverTargetID)
      }

      if let expanded {
        bBtn = bBtn.ariaExpanded(expanded)
      }

      if let pressed {
        bBtn = bBtn.ariaPressed(pressed)
      }

      if let controlsID {
        bBtn = bBtn.ariaControls(controlsID)
      }

      if let submitName, let submitValue {
        bBtn = bBtn.addingAttribute("name", submitName).addingAttribute("value", submitValue)
      }

      return bBtn
    }
  }

  private var fontWeightKey: String {
    if stringEquals(labelFontWeight.value, fontWeightNormal.value) { return "normal" }
    return "semibold"
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

    /// A button with an icon before its label, or the icon alone when the
    /// label is empty (then `ariaLabel` names it): a filter row's −.
    public static func createElement<T: HTMLContent>(
      label: String,
      icon: T,
      buttonColor: ButtonView.ButtonColor = .gray,
      weight: ButtonView.ButtonWeight = .subtle,
      size: ButtonView.ButtonSize = .medium,
      type: ButtonView.ButtonType = .button,
      ariaLabel: String? = nil,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = ButtonView(
        label: label,
        icon: icon,
        buttonColor: buttonColor,
        weight: weight,
        size: size,
        type: type,
        ariaLabel: ariaLabel,
        class: `class`,
        labelFontWeight: fontWeightSemiBold
      )
      wrapper.innerHTML = view.render()
      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
