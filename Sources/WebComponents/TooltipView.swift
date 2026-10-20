import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// A brief message that shows up when a user hovers over a specific part of the UI.
///
/// Hover or focus shows it; a plain click or tap on the trigger opens it
/// and keeps it open until the next click or tap, anywhere, or Escape
/// (user, 2026-10-10). Tooltips sit on icons, never on buttons: an action
/// that cannot be taken now says why when pressed (gnorium-web
/// `ActionGateView`).
///
/// The bubble is a line of text, `tooltip`, or `bubble` markup: several
/// lines, a `LocalTimeView` the client puts in the reader's clock.
///
/// A trigger that holds controls of its own (a reaction pill's buttons)
/// passes `pins: false`: its clicks and taps are its controls', and the
/// tooltip shows on hover and focus alone.
///
/// A bubble of structured content (a session's context bar: its rows and
/// totals) takes the `.popover` appearance: the page's surface, a subtle
/// border and no arrow, opened and placed exactly as a tooltip is.
public struct TooltipView: HTMLContent {
  let bubble: [DOM.Node]
  let placement: Placement
  let font: Font
  let bubbleWidth: Width
  let appearance: Appearance
  let children: [DOM.Node]
  let pins: Bool
  let `class`: String

  /// Typeface of the bubble's text: sans for prose, mono for identifiers,
  /// stamps and other machine-shaped values.
  public enum Font: String, Sendable {
    case sans
    case mono
  }

  public enum Placement: String, Sendable, CaseIterable {
    case top
    case topStart = "top-start"
    case topEnd = "top-end"
    case bottom
    case bottomStart = "bottom-start"
    case bottomEnd = "bottom-end"
    case left
    case leftStart = "left-start"
    case leftEnd = "left-end"
    case right
    case rightStart = "right-start"
    case rightEnd = "right-end"

    public enum Side: Sendable {
      case top, bottom, left, right
    }

    public enum Alignment: Sendable {
      case center, start, end
    }

    public var side: Side {
      switch self {
      case .top, .topStart, .topEnd: .top
      case .bottom, .bottomStart, .bottomEnd: .bottom
      case .left, .leftStart, .leftEnd: .left
      case .right, .rightStart, .rightEnd: .right
      }
    }

    public var alignment: Alignment {
      switch self {
      case .top, .bottom, .left, .right: .center
      case .topStart, .bottomStart, .leftStart, .rightStart: .start
      case .topEnd, .bottomEnd, .leftEnd, .rightEnd: .end
      }
    }

    /// The same alignment on the opposite side—where the bubble goes when
    /// its own side has no room.
    public var opposite: Placement {
      switch self {
      case .top: .bottom
      case .topStart: .bottomStart
      case .topEnd: .bottomEnd
      case .bottom: .top
      case .bottomStart: .topStart
      case .bottomEnd: .topEnd
      case .left: .right
      case .leftStart: .rightStart
      case .leftEnd: .rightEnd
      case .right: .left
      case .rightStart: .leftStart
      case .rightEnd: .leftEnd
      }
    }

    /// The other alignment on the same side—start for end, end for start—
    /// where the bubble goes when shifting it along its edge is not enough,
    /// and what a start or end means once the line runs right to left.
    public var mirrored: Placement {
      switch self {
      case .top, .bottom, .left, .right: self
      case .topStart: .topEnd
      case .topEnd: .topStart
      case .bottomStart: .bottomEnd
      case .bottomEnd: .bottomStart
      case .leftStart: .leftEnd
      case .leftEnd: .leftStart
      case .rightStart: .rightEnd
      case .rightEnd: .rightStart
      }
    }
  }

  /// How wide the bubble may grow. A sentence reads best at the standard
  /// 256px; a list of lines ("By … on … at …") reads best a line each, as
  /// wide as the screen allows. A UUID wraps at the standard width like any
  /// other text (user, 2026-10-16).
  public enum Width: String, Sendable {
    case standard
    case wide
  }

  /// How the bubble looks: the inverted tooltip, or a popover's surface
  /// for rows and columns to read (no arrow, the trigger's cursor a
  /// pointer).
  public enum Appearance: String, Sendable {
    case tooltip
    case popover
  }

  public init(
    tooltip: String,
    placement: Placement = .bottom,
    font: Font = .sans,
    width: Width = .standard,
    appearance: Appearance = .tooltip,
    pins: Bool = true,
    class: String = "",
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.bubble = [DOM.Text(tooltip)]
    self.bubbleWidth = width
    self.appearance = appearance
    self.placement = placement
    self.font = font
    self.children = content()
    self.pins = pins
    self.`class` = `class`
  }

  public init(
    placement: Placement = .bottom,
    font: Font = .sans,
    width: Width = .standard,
    appearance: Appearance = .tooltip,
    pins: Bool = true,
    class: String = "",
    @HTMLBuilder bubble: () -> [DOM.Node],
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.bubble = bubble()
    self.bubbleWidth = width
    self.appearance = appearance
    self.placement = placement
    self.font = font
    self.children = content()
    self.pins = pins
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    return span {
      span {
        children
      }
      .class("tooltip-trigger-content")

      // The font rides on the bubble itself: once portaled to <body> it is no
      // longer inside the trigger, so a page rule scoped to the trigger's
      // ancestors could not reach it.
      span {
        bubble
      }
      .class("tooltip-content")
      .data("font", font.rawValue)
      .data("width", bubbleWidth.rawValue)
      .data("appearance", appearance.rawValue)
    }
    .class(stringIsEmpty(`class`) ? "tooltip-view tooltip-trigger" : "tooltip-view tooltip-trigger \(`class`)")
    .data("tooltip", "true")
    .data("appearance", appearance.rawValue)
    .data("placement", placement.rawValue)
    .data("pins", pins)
    .data("visible", false)
    .style {
      selector("&") {
        position(.relative)
        display(.inlineFlex)
        alignItems(.center)
        verticalAlign(.middle)
        cursor(.help)
        // The room a bubble has: the viewport (less its scrollbar, which the
        // hydration measures; `100vw` counts it) less the page's gutter on
        // both sides.
        CSS.Property("--tooltip-room", "calc(var(--tooltip-viewport-width, 100vw) - 2 * \(pageGutter.value))")
      }
      // Until the hydration moves it to <body>, the bubble sits in its
      // trigger, where even a hidden box widens the page it runs past: it
      // takes no box there until it shows.
      selector("&.tooltip-trigger > .tooltip-content") {
        display(.none)
      }
      selector(
        "&.tooltip-trigger:hover > .tooltip-content", "&.tooltip-trigger:focus-within > .tooltip-content",
        "&.tooltip-trigger[data-visible='true'] > .tooltip-content"
      ) {
        display(.block)
      }
      // Portal host: on hydration the bubble moves into one of these at the
      // end of <body>, a fixed point set from the trigger's rect. Inside the
      // trigger it inherited every ancestor's stacking context and
      // transform—a legend on a fieldset border painted it under the cards
      // below—and could not be pulled back inside the viewport at a screen edge.
      selector("&[data-portal='true']") {
        position(.fixed)
        display(.block)
        width(0)
        height(0)
        margin(0)
        zIndex(zIndexTooltip)
        pointerEvents(.none)
        // Inert on a box no wider than a point; the hydration reads the room
        // back from here, resolved to pixels.
        CSS.Property("max-width", "var(--tooltip-room)")
      }
      selector("& .tooltip-content") {
        position(.absolute)
        padding(spacing8)
        // Sized to its text, not to its containing block: an absolutely
        // positioned box otherwise shrinks to the 20px trigger (or the 0px
        // portal host) and a one-sentence byline wrapped to five lines.
        // No floor: the bubble hugs its content plus its padding, a short
        // one as narrow as its words (user, 2026-10-16), and wraps only at
        // its cap.
        width(.maxContent)
        CSS.Property("max-width", "min(\(px(256).value), var(--tooltip-room))")
        // A word longer than the room (a UUID on a phone) breaks rather
        // than run past the bubble.
        overflowWrap(.anywhere)
        backgroundColor(backgroundColorInverted)
        color(colorInverted)
        fontFamily(typographyFontSans)
        fontSize(fontSizeMedium16)
        fontWeight(fontWeightNormal)
        lineHeight(lineHeightSmall22)
        borderRadius(borderRadiusBase)
        whiteSpace(.normal)
        // The help cursor is the trigger's alone. The bubble is text to read
        // and select, so it takes the browser's own cursor: the text beam
        // over its words, the arrow around them, the hand on a link.
        cursor(.auto)
        opacity(0)
        pointerEvents(.none)
        visibility(.hidden)
        transition(transitionPropertyFade, transitionDurationBase, transitionTimingFunctionSystem)
        zIndex(zIndexTooltip)
        boxShadow(boxShadowMedium)
        textAlign(.start)
        backfaceVisibility(.hidden)
        willChange(.transform, .opacity)
      }
      // A stamp in the bubble (`LocalTimeView`) reads as the bubble's text.
      selector("& .tooltip-content time") {
        color(colorInverted).important()
        fontSize(fontSizeMedium16).important()
      }
      selector("& .tooltip-content[data-width='wide']") {
        CSS.Property("max-width", "var(--tooltip-room)")
      }
      selector("& .tooltip-content[data-font='mono']") {
        fontFamily(typographyFontMono)
      }
      selector("&:hover > .tooltip-content", "&:focus-within > .tooltip-content", "&[data-visible='true'] .tooltip-content") {
        opacity(1)
        visibility(.visible)
        pointerEvents(.auto)
      }
      selector("&[data-placement='bottom'] .tooltip-content", "&[data-placement='bottom-start'] .tooltip-content", "&[data-placement='bottom-end'] .tooltip-content") {
        top(perc(100))
        marginTop(spacing8)
      }
      selector("&[data-placement='top'] .tooltip-content", "&[data-placement='top-start'] .tooltip-content", "&[data-placement='top-end'] .tooltip-content") {
        bottom(perc(100))
        marginBottom(spacing8)
      }
      selector("&[data-placement='left'] .tooltip-content", "&[data-placement='left-start'] .tooltip-content", "&[data-placement='left-end'] .tooltip-content") {
        right(perc(100))
        marginRight(spacing8)
      }
      selector("&[data-placement='right'] .tooltip-content", "&[data-placement='right-start'] .tooltip-content", "&[data-placement='right-end'] .tooltip-content") {
        left(perc(100))
        marginLeft(spacing8)
      }
      selector("&[data-placement='bottom'] .tooltip-content", "&[data-placement='top'] .tooltip-content") {
        left(perc(50))
        transform(translate(perc(-50), perc(0)))
      }
      selector("&[data-placement='bottom-start'] .tooltip-content", "&[data-placement='top-start'] .tooltip-content") {
        left(0)
      }
      selector("&[data-placement='bottom-end'] .tooltip-content", "&[data-placement='top-end'] .tooltip-content") {
        right(0)
      }
      selector("&[data-placement='left'] .tooltip-content", "&[data-placement='right'] .tooltip-content") {
        top(perc(50))
        transform(translate(perc(0), perc(-50)))
      }
      selector("&[data-placement='left-start'] .tooltip-content", "&[data-placement='right-start'] .tooltip-content") {
        top(0)
      }
      selector("&[data-placement='left-end'] .tooltip-content", "&[data-placement='right-end'] .tooltip-content") {
        bottom(0)
      }
      // Until the hydration places it (and wherever it never runs: a page
      // left in a background tab), the bubble shows in its trigger. A start
      // or end bubble begins the arrow's inset before the trigger's center,
      // so its arrow, that far in, points at the trigger as the hydration's
      // would; flush with the trigger's edge, the arrow sat at the bubble's
      // middle, a wrapped UUID's 128px past the trigger. The portal host,
      // a point, keeps the plain edges the hydration measures from.
      selector("&.tooltip-trigger[data-placement='bottom-start'] > .tooltip-content", "&.tooltip-trigger[data-placement='top-start'] > .tooltip-content") {
        CSS.Property("left", Self.inTrigger)
      }
      selector("&.tooltip-trigger[data-placement='bottom-end'] > .tooltip-content", "&.tooltip-trigger[data-placement='top-end'] > .tooltip-content") {
        CSS.Property("right", Self.inTrigger)
      }
      selector("&.tooltip-trigger[data-placement='left-start'] > .tooltip-content", "&.tooltip-trigger[data-placement='right-start'] > .tooltip-content") {
        CSS.Property("top", Self.inTrigger)
      }
      selector("&.tooltip-trigger[data-placement='left-end'] > .tooltip-content", "&.tooltip-trigger[data-placement='right-end'] > .tooltip-content") {
        CSS.Property("bottom", Self.inTrigger)
      }
      // The bubble reaches back across its gap to the trigger: an unseen
      // strip as wide (or tall) as the bubble, so the pointer on its way
      // from the trigger to a link in the bubble never leaves both (WCAG
      // 2.1 SC 1.4.13, hoverable). It takes the bubble's pointer events:
      // none until it shows.
      selector("& .tooltip-content::before") {
        content("\"\"")
        position(.absolute)
      }
      selector("&[data-placement^='bottom'] .tooltip-content::before") {
        bottom(perc(100))
        left(0)
        right(0)
        height(spacing8)
      }
      selector("&[data-placement^='top'] .tooltip-content::before") {
        top(perc(100))
        left(0)
        right(0)
        height(spacing8)
      }
      selector("&[data-placement^='left'] .tooltip-content::before") {
        left(perc(100))
        top(0)
        bottom(0)
        width(spacing8)
      }
      selector("&[data-placement^='right'] .tooltip-content::before") {
        right(perc(100))
        top(0)
        bottom(0)
        width(spacing8)
      }
      selector("& .tooltip-content::after") {
        content("\"\"")
        position(.absolute)
        width(0)
        height(0)
      }
      selector("&[data-placement='bottom'] .tooltip-content::after", "&[data-placement='bottom-start'] .tooltip-content::after", "&[data-placement='bottom-end'] .tooltip-content::after") {
        bottom(perc(100))
        borderLeft(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='top'] .tooltip-content::after", "&[data-placement='top-start'] .tooltip-content::after", "&[data-placement='top-end'] .tooltip-content::after") {
        top(perc(100))
        borderLeft(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorTransparent)
        borderTop(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='left'] .tooltip-content::after", "&[data-placement='left-start'] .tooltip-content::after", "&[data-placement='left-end'] .tooltip-content::after") {
        left(perc(100))
        borderTop(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorTransparent)
        borderLeft(px(6), .solid, backgroundColorInverted)
      }
      selector("&[data-placement='right'] .tooltip-content::after", "&[data-placement='right-start'] .tooltip-content::after", "&[data-placement='right-end'] .tooltip-content::after") {
        right(perc(100))
        borderTop(px(6), .solid, backgroundColorTransparent)
        borderBottom(px(6), .solid, backgroundColorTransparent)
        borderRight(px(6), .solid, backgroundColorInverted)
      }
      // The arrow sits where the hydration puts it—over the trigger's
      // center, clear of the corner radius—and until then where the bubble
      // in its trigger has that center: the middle of a centered bubble,
      // the arrow's inset from a start or end one's edge.
      selector("&[data-placement='bottom'] .tooltip-content::after", "&[data-placement='top'] .tooltip-content::after") {
        CSS.Property("left", "var(--tooltip-arrow-x, 50%)")
      }
      selector("&[data-placement='bottom-start'] .tooltip-content::after", "&[data-placement='top-start'] .tooltip-content::after") {
        CSS.Property("left", "var(--tooltip-arrow-x, \(Self.arrowInset))")
      }
      selector("&[data-placement='bottom-end'] .tooltip-content::after", "&[data-placement='top-end'] .tooltip-content::after") {
        CSS.Property("left", "var(--tooltip-arrow-x, calc(100% - \(Self.arrowInset)))")
      }
      selector("&[data-placement^='bottom'] .tooltip-content::after", "&[data-placement^='top'] .tooltip-content::after") {
        transform(translateX(perc(-50)))
      }
      selector("&[data-placement='left'] .tooltip-content::after", "&[data-placement='right'] .tooltip-content::after") {
        CSS.Property("top", "var(--tooltip-arrow-y, 50%)")
      }
      selector("&[data-placement='left-start'] .tooltip-content::after", "&[data-placement='right-start'] .tooltip-content::after") {
        CSS.Property("top", "var(--tooltip-arrow-y, \(Self.arrowInset))")
      }
      selector("&[data-placement='left-end'] .tooltip-content::after", "&[data-placement='right-end'] .tooltip-content::after") {
        CSS.Property("top", "var(--tooltip-arrow-y, calc(100% - \(Self.arrowInset)))")
      }
      selector("&[data-placement^='left'] .tooltip-content::after", "&[data-placement^='right'] .tooltip-content::after") {
        transform(translateY(perc(-50)))
      }
      // Opened from dimmed content (a hidden locution, to the few who still
      // see it), the bubble is dimmed with it: as if at opacity medium, but
      // over the page's own background rather than over the words beneath
      // it, which would otherwise show through (user, 2026-10-11). Inside
      // the content as the server sends it, or moved out to its portal
      // host, which carries the mark (`data-dimmed`). The content must dim
      // its parts, not a box holding the tooltip (`LocutionView`).
      selector("&[data-dimmed='true'] .tooltip-content", "[data-dimmed='true'] & .tooltip-content") {
        CSS.Property("background-color", Self.dimmed(backgroundColorInverted))
        CSS.Property("color", Self.dimmed(colorInverted))
      }
      selector("&[data-dimmed='true'] .tooltip-content time", "[data-dimmed='true'] & .tooltip-content time") {
        CSS.Property("color", Self.dimmed(colorInverted), isImportant: true)
      }
      selector(
        "&[data-dimmed='true'][data-placement^='bottom'] .tooltip-content::after",
        "[data-dimmed='true'] &[data-placement^='bottom'] .tooltip-content::after"
      ) {
        CSS.Property("border-bottom-color", Self.dimmed(backgroundColorInverted))
      }
      selector(
        "&[data-dimmed='true'][data-placement^='top'] .tooltip-content::after",
        "[data-dimmed='true'] &[data-placement^='top'] .tooltip-content::after"
      ) {
        CSS.Property("border-top-color", Self.dimmed(backgroundColorInverted))
      }
      selector(
        "&[data-dimmed='true'][data-placement^='left'] .tooltip-content::after",
        "[data-dimmed='true'] &[data-placement^='left'] .tooltip-content::after"
      ) {
        CSS.Property("border-left-color", Self.dimmed(backgroundColorInverted))
      }
      selector(
        "&[data-dimmed='true'][data-placement^='right'] .tooltip-content::after",
        "[data-dimmed='true'] &[data-placement^='right'] .tooltip-content::after"
      ) {
        CSS.Property("border-right-color", Self.dimmed(backgroundColorInverted))
      }
      // The popover appearance: the page's surface and text, a subtle
      // border, padding equal on every side, no arrow; its trigger opens
      // it, so it takes the pointer.
      selector("&[data-appearance='popover']") {
        cursor(.pointer)
      }
      selector("& .tooltip-content[data-appearance='popover']") {
        backgroundColor(backgroundColorBase)
        color(colorBase)
        border(borderWidthBase, .solid, borderColorSubtle)
        padding(spacing12)
      }
      selector("& .tooltip-content[data-appearance='popover']::after") {
        display(.none)
      }
      selector("& .tooltip-content[data-appearance='popover'] time") {
        color(colorBase).important()
      }
      selector(
        "&[data-dimmed='true'] .tooltip-content[data-appearance='popover']",
        "[data-dimmed='true'] & .tooltip-content[data-appearance='popover']"
      ) {
        CSS.Property("background-color", Self.dimmed(backgroundColorBase))
        CSS.Property("color", Self.dimmed(colorBase))
      }
    }
  }

  /// `color` as it reads at opacity medium over the page's background:
  /// opaque, so nothing under the bubble shows through it.
  private static func dimmed(_ color: CSS.Color) -> String {
    "color-mix(in srgb, \(color.value) calc(\(opacityMedium.value) * 100%), \(backgroundColorBase.value))"
  }

  /// Nearest the arrow may sit to the bubble's edge: the corner radius plus
  /// half the arrow, so the corner never cuts into it (`Geometry.arrowInset`).
  private static let arrowInset = "calc(\(borderRadiusBase.value) + \(px(6).value))"

  /// A start or end bubble's edge in its trigger: the arrow's inset before
  /// the trigger's center.
  private static let inTrigger = "calc(50% - \(arrowInset))"

  /// Where a bubble goes along the edge of the trigger it grows from: the
  /// horizontal axis above or below it, the vertical one beside it. Pure
  /// arithmetic, shared by the hydration and its tests.
  public enum Geometry {
    /// Nearest the arrow may sit to the bubble's edge: the corner radius
    /// (16px) plus half the arrow (6px).
    public static let arrowInset = 22.0

    /// A box in viewport pixels: a trigger's or a bubble's.
    public struct Box: Sendable {
      public let left: Double
      public let top: Double
      public let right: Double
      public let bottom: Double

      public init(left: Double, top: Double, right: Double, bottom: Double) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
      }

      func contains(_ x: Double, _ y: Double) -> Bool { x >= left && x <= right && y >= top && y <= bottom }
    }

    /// Whether the pointer at (`x`, `y`), having left `trigger` at `from`,
    /// is still on its way to `bubble` (the safe triangle, or menu aim):
    /// over the trigger, over the bubble or the strip that bridges their
    /// `gap`, or inside the triangle from where it left to the bubble's two
    /// corners facing the trigger.
    public static func aims(
      x: Double, y: Double, from: (x: Double, y: Double), trigger: Box, bubble: Box, gap: Double
    ) -> Bool {
      if trigger.contains(x, y) { return true }
      let reach: Box
      let corners: ((Double, Double), (Double, Double))
      if bubble.bottom <= trigger.top {
        reach = Box(left: bubble.left, top: bubble.top, right: bubble.right, bottom: bubble.bottom + gap)
        corners = ((bubble.left, bubble.bottom), (bubble.right, bubble.bottom))
      } else if bubble.top >= trigger.bottom {
        reach = Box(left: bubble.left, top: bubble.top - gap, right: bubble.right, bottom: bubble.bottom)
        corners = ((bubble.left, bubble.top), (bubble.right, bubble.top))
      } else if bubble.right <= trigger.left {
        reach = Box(left: bubble.left, top: bubble.top, right: bubble.right + gap, bottom: bubble.bottom)
        corners = ((bubble.right, bubble.top), (bubble.right, bubble.bottom))
      } else {
        reach = Box(left: bubble.left - gap, top: bubble.top, right: bubble.right, bottom: bubble.bottom)
        corners = ((bubble.left, bubble.top), (bubble.left, bubble.bottom))
      }
      if reach.contains(x, y) { return true }
      // Inside (or on an edge of) the triangle: on no side of one of its
      // edges than of another.
      func side(_ p: (Double, Double), _ q: (Double, Double)) -> Double {
        (q.0 - p.0) * (y - p.1) - (q.1 - p.1) * (x - p.0)
      }
      let apex = (from.x, from.y)
      let sides = [side(apex, corners.0), side(corners.0, corners.1), side(corners.1, apex)]
      return !(sides.contains { $0 < 0 } && sides.contains { $0 > 0 })
    }

    /// Slack for the arrow test: the start is computed from the trigger's
    /// center and the arrow back from the start, and the round trip may
    /// miss the inset by a rounding error.
    static let tolerance = 0.01

    /// Where a bubble `size` long starts along the axis: its alignment's
    /// edge (a start bubble at the trigger's start), moved as little as
    /// keeps the arrow over the trigger's center clear of the corner
    /// radius, then shifted inside `lower`…`upper`.
    public static func start(
      _ alignment: Placement.Alignment, size: Double, triggerStart: Double, triggerEnd: Double, inset: Double,
      lower: Double, upper: Double
    ) -> Double {
      let center = (triggerStart + triggerEnd) / 2
      var start: Double
      switch alignment {
      case .start: start = triggerStart
      case .end: start = triggerEnd - size
      case .center: start = center - size / 2
      }
      start = min(max(start, center - size + inset), center - inset)
      if start + size > upper { start = upper - size }
      if start < lower { start = lower }
      return start
    }

    /// Whether a bubble `size` long from `start` can point its arrow at the
    /// trigger's center, clear of its corners.
    public static func reaches(
      start: Double, size: Double, triggerStart: Double, triggerEnd: Double, inset: Double
    ) -> Bool {
      let arrow = (triggerStart + triggerEnd) / 2 - start
      return arrow >= inset - tolerance && arrow <= size - inset + tolerance
    }

    /// The arrow's offset from the bubble's start: over the trigger's
    /// center, or as near it as the corners allow.
    public static func arrow(
      start: Double, size: Double, triggerStart: Double, triggerEnd: Double, inset: Double
    ) -> Double {
      min(max((triggerStart + triggerEnd) / 2 - start, inset), size - inset)
    }

    /// The point on the axis the placement CSS grows a bubble from, given
    /// where it starts: its start edge, its end edge, or its middle.
    public static func anchor(_ alignment: Placement.Alignment, start: Double, size: Double) -> Double {
      switch alignment {
      case .start: start
      case .end: start + size
      case .center: start + size / 2
      }
    }

    /// The first of `placement` and its mirror, inside the first bound that
    /// lets its arrow reach the trigger (`bounds`: the gutter, then the
    /// viewport's edge), with its start; failing all, `placement` inside
    /// the first bound.
    public static func choose(
      _ placement: Placement, size: Double, triggerStart: Double, triggerEnd: Double, extent: Double,
      bounds: [Double]
    ) -> (placement: Placement, start: Double) {
      let inset = min(arrowInset, size / 2)
      let first = bounds.first ?? 0
      for bound in bounds {
        for candidate in [placement, placement.mirrored] {
          let start = Self.start(
            candidate.alignment, size: size, triggerStart: triggerStart, triggerEnd: triggerEnd, inset: inset,
            lower: bound, upper: extent - bound)
          if reaches(start: start, size: size, triggerStart: triggerStart, triggerEnd: triggerEnd, inset: inset) {
            return (candidate, start)
          }
        }
      }
      return (
        placement,
        start(
          placement.alignment, size: size, triggerStart: triggerStart, triggerEnd: triggerEnd, inset: inset,
          lower: first, upper: extent - first)
      )
    }
  }
}

#if CLIENT
  import WebAPIs

  private class TooltipInstance: @unchecked Sendable {
    private var trigger: DOM.Element
    private var content: DOM.Element?
    private var host: DOM.Element?
    private let placement: TooltipView.Placement
    private var isVisible: Bool = false
    /// Where the pointer left the trigger, while it is on its way to the
    /// bubble (`Geometry.aims`), and the pointermove listener that follows
    /// it there.
    private var aimFrom: (x: Double, y: Double)?
    private var aimListener: Int32?
    /// Opened by a click or tap: leaving the trigger or its focus doesn't
    /// close it; the next click or tap does.
    private var pinned: Bool = false

    /// Distance the bubble keeps from the viewport's top and bottom; at the
    /// sides it keeps the page's gutter (`pageGutter`).
    private static let edgeMargin = 8.0
    /// The bubble's distance from the trigger (`spacing8` in the placement
    /// CSS).
    private static let gap = 8.0

    init(tooltip: DOM.Element) {
      self.trigger = tooltip
      self.content = tooltip.querySelector(".tooltip-content")
      // `TooltipView` always stamps the attribute; the fallback is its own
      // default, so a hand-built trigger without one behaves like the view.
      // Matched with `stringEquals`, not `init(rawValue:)`: the synthesized
      // initializer compares with `==`, which is Unicode normalization the
      // embedded client cannot link.
      let raw = tooltip.dataset["placement"] ?? ""
      self.placement =
        TooltipView.Placement.allCases.first { stringEquals($0.rawValue, raw) } ?? .bottom
      portal()
      bindEvents()
    }

    /// Move the bubble into a fixed host at the end of <body>. The host is a
    /// point; the placement CSS grows the bubble from it exactly as it did
    /// from the trigger, so only the point has to be placed.
    private func portal() {
      guard let content else { return }
      let host = document.createElement(.span)
      host.classList.add("tooltip-view")
      _ = host.dataset["portal"] = "true"
      _ = host.dataset["placement"] = placement.rawValue
      _ = host.dataset["visible"] = "false"
      // Out of the trigger, the bubble no longer inherits a dimmed
      // ancestor's opacity: it carries the dimming itself.
      if trigger.closest("[data-dimmed='true']") != nil { _ = host.dataset["dimmed"] = "true" }
      host.appendChild(content)
      document.body.appendChild(host)
      self.host = host
    }

    /// Anchor the host at the trigger, then keep the bubble inside the
    /// viewport as floating-UI libraries do. Flipped to the other side when
    /// its own has no room; shifted along the trigger's edge, inside the
    /// page's gutter (above or below) or the edge margin (beside), as far as
    /// its arrow can still point at the trigger's center; failing that,
    /// flipped to the other alignment (end for start); failing both, let
    /// into the gutter or margin. Beside the trigger with no room on either
    /// side, shifted back inside across it. Start and end are the trigger's
    /// line's: right to left, a start-aligned bubble above or below grows
    /// leftward from the trigger's right edge.
    private func place() {
      guard let host, let content, let t = trigger.getBoundingClientRect() else { return }
      // The viewport less its scrollbar: `innerWidth` counts the bar, and a
      // bubble run under it was cut off.
      let root = document.documentElement
      let viewportWidth = root.clientWidth
      let viewportHeight = root.clientHeight
      host.setStyleProperty("--tooltip-viewport-width", Self.px(viewportWidth))
      let room = Self.pixels(window.getComputedStyle(host).getPropertyValue("max-width"))
      let gutter = max(0, (viewportWidth - room) / 2)
      let margin = Self.edgeMargin
      let rightToLeft = stringEquals(trigger.closest("[dir]")?.getAttribute("dir") ?? "", "rtl")
      if rightToLeft { host.setAttribute("dir", "rtl") } else { host.removeAttribute("dir") }
      var placement = self.placement
      if rightToLeft && (placement.side == .top || placement.side == .bottom) { placement = placement.mirrored }

      // Measured where the placement CSS first grows it: its size is the
      // same wherever the host goes (it is capped by the viewport, not by
      // the room left beside the trigger).
      let (x, y) = Self.anchor(for: placement, trigger: t)
      _ = host.dataset["placement"] = placement.rawValue
      Self.position(host, x: x, y: y)
      guard let c = content.getBoundingClientRect() else { return }

      // The side: the other one when its own has no room and the other has
      // (the bubble stands its 8px gap off the trigger).
      let gap = Self.gap
      let flips: Bool
      switch placement.side {
      case .bottom: flips = t.bottom + gap + c.height > viewportHeight - margin && t.top - gap - c.height >= margin
      case .top: flips = t.top - gap - c.height < margin && t.bottom + gap + c.height <= viewportHeight - margin
      case .right: flips = t.right + gap + c.width > viewportWidth - gutter && t.left - gap - c.width >= gutter
      case .left: flips = t.left - gap - c.width < gutter && t.right + gap + c.width <= viewportWidth - gutter
      }
      if flips { placement = placement.opposite }

      // Along the trigger's edge: the start whose arrow reaches the
      // trigger's center.
      let horizontal = placement.side == .top || placement.side == .bottom
      let size = horizontal ? c.width : c.height
      let triggerStart = horizontal ? t.left : t.top
      let triggerEnd = horizontal ? t.right : t.bottom
      let (chosen, start) = TooltipView.Geometry.choose(
        placement, size: size, triggerStart: triggerStart, triggerEnd: triggerEnd,
        extent: horizontal ? viewportWidth : viewportHeight, bounds: horizontal ? [gutter, 0.0] : [margin, 0.0])
      let inset = min(TooltipView.Geometry.arrowInset, size / 2)
      let arrow = TooltipView.Geometry.arrow(
        start: start, size: size, triggerStart: triggerStart, triggerEnd: triggerEnd, inset: inset)
      let along = TooltipView.Geometry.anchor(chosen.alignment, start: start, size: size)
      _ = host.dataset["placement"] = chosen.rawValue

      if horizontal {
        Self.position(host, x: along, y: chosen.side == .top ? t.top : t.bottom)
        host.setStyleProperty("--tooltip-arrow-x", Self.px(arrow))
        return
      }
      var across = chosen.side == .left ? t.left : t.right
      Self.position(host, x: across, y: along)
      host.setStyleProperty("--tooltip-arrow-y", Self.px(arrow))
      // No room on either side: back inside, over the trigger.
      guard let placed = content.getBoundingClientRect() else { return }
      if placed.left < gutter {
        across += gutter - placed.left
      } else if placed.right > viewportWidth - gutter {
        across += viewportWidth - gutter - placed.right
      }
      Self.position(host, x: across, y: along)
    }

    private static func pixels(_ value: String) -> Double { parseDouble(stringRemoveSuffix(value, "px")) ?? 0 }

    /// Fractional, not rounded: the bubble's edge and its arrow are each
    /// placed from it, and two roundings put the arrow a pixel off.
    private static func px(_ value: Double) -> String {
      stringJoin([doubleToString(value), "px"], separator: "")
    }

    /// The point on the trigger's box that the placement CSS grows the
    /// bubble away from.
    private static func anchor(
      for placement: TooltipView.Placement, trigger t: DOM.Rect
    ) -> (Double, Double) {
      switch placement.side {
      case .left, .right:
        let x = placement.side == .left ? t.left : t.right
        let y: Double
        switch placement.alignment {
        case .start: y = t.top
        case .end: y = t.bottom
        case .center: y = t.top + t.height / 2
        }
        return (x, y)
      case .top, .bottom:
        let y = placement.side == .top ? t.top : t.bottom
        let x: Double
        switch placement.alignment {
        case .start: x = t.left
        case .end: x = t.right
        case .center: x = t.left + t.width / 2
        }
        return (x, y)
      }
    }

    private static func position(_ host: DOM.Element, x: Double, y: Double) {
      host.setStyleProperty("left", px(x))
      host.setStyleProperty("top", px(y))
    }

    private func bindEvents() {
      guard let content else { return }

      // Hover for desktop
      _ = trigger.addEventListener(.mouseenter) { [self] _ in
        self.stopAiming()
        self.showTooltip()
      }

      // Portaled to <body>, the bubble is no longer inside its trigger.
      // Leaving the trigger, the bubble stays while the pointer heads for
      // it—inside the triangle from where it left to the bubble's near
      // corners, or across the strip that bridges their gap—and hides as
      // soon as it strays; over the bubble it stays, and leaving the
      // bubble hides it (WCAG 2.1 SC 1.4.13, hoverable).
      _ = trigger.addEventListener(.mouseleave) { [self] (event: Event) in
        if !self.pinned { self.aim(from: (event.clientX, event.clientY)) }
      }
      _ = content.addEventListener(.mouseenter) { [self] _ in
        self.stopAiming()
      }
      _ = content.addEventListener(.mouseleave) { [self] _ in
        if !self.pinned { self.hideTooltip() }
      }

      // Focus for keyboard navigation: focusin and focusout bubble up from
      // the control inside the trigger, which is what takes the focus.
      _ = trigger.addEventListener(.focusin) { [self] _ in
        self.showTooltip()
      }

      _ = trigger.addEventListener(.focusout) { [self] _ in
        if !self.pinned { self.hideTooltip() }
      }

      // A click or tap opens it and pins it; the next one closes it. A
      // tap's emulated mouseenter and focus have already shown it by the
      // time its click arrives, so the click only pins. iOS sends no click
      // for a tap on something that isn't clickable, hence touchend too,
      // which then takes the tap whole. A trigger whose clicks are its own
      // controls' (`pins: false`) leaves them be.
      if !stringEquals(trigger.dataset["pins"] ?? "true", "false") {
        _ = trigger.addEventListener(.touchend) { [self] (event: Event) in
          event.preventDefault()
          self.togglePinned()
        }
        _ = trigger.addEventListener(.click) { [self] _ in
          self.togglePinned()
        }
      }

      // A pinned one closes on a click or tap anywhere else. iOS sends no
      // click to the document for a tap on something that isn't clickable,
      // hence the touchstart too.
      _ = document.addEventListener(.click) { [self] event in
        self.dismissUnlessInside(event)
      }
      _ = document.addEventListener(.touchstart) { [self] event in
        self.dismissUnlessInside(event)
      }

      // Keyboard: Escape to dismiss
      _ = document.addEventListener(.keydown) { [self] (event: Event) in
        let key = event.key
        if stringEquals(key, "Escape") && self.isVisible {
          self.dismiss()
        }
      }

      // The host is fixed to the viewport, not to the page: once the trigger
      // moves under it, the bubble would point at nothing.
      _ = window.addEventListener(.scroll) { [self] _ in
        if self.isVisible { self.dismiss() }
      }
      _ = window.addEventListener(.resize) { [self] _ in
        if self.isVisible { self.dismiss() }
      }
    }

    /// Whether its trigger is `root` or inside it.
    func isInside(_ root: DOM.Element) -> Bool {
      root.contains(trigger)
    }

    /// Its bubble, where `element` is its trigger: the same node by the
    /// bridge's id (two queries of a node are never `===`).
    func bubble(of element: DOM.Element) -> DOM.Element? {
      element.id == trigger.id ? content : nil
    }

    /// Its bubble out of the page, for a trigger about to leave it.
    func release() {
      stopAiming()
      pinned = false
      isVisible = false
      host?.remove()
      host = nil
    }

    private func togglePinned() {
      if pinned {
        dismiss()
      } else {
        pinned = true
        showTooltip()
      }
    }

    /// Closes it, pinned or not.
    private func dismiss() {
      pinned = false
      hideTooltip()
    }

    /// Follows the pointer from where it left the trigger, keeping the
    /// bubble while it heads there (`Geometry.aims`). The leave itself
    /// must head there from the trigger's center: a pointer that left
    /// away from the bubble, and moves no further, hides it at once.
    private func aim(from point: (x: Double, y: Double)) {
      stopAiming()
      guard isVisible, let t = trigger.getBoundingClientRect() else { return }
      guard heads(x: point.x, y: point.y, from: (t.left + t.width / 2, t.top + t.height / 2)) else {
        hideTooltip()
        return
      }
      aimFrom = point
      aimListener = document.addEventListener(.pointermove) { [self] (event: Event) in
        guard let from = self.aimFrom, let t = self.trigger.getBoundingClientRect() else { return }
        // From the leave point, or from the trigger's center: a leave
        // reports whole pixels and the next move fractional ones, so the
        // first move can sit a fraction off the leave point's apex.
        let center = (t.left + t.width / 2, t.top + t.height / 2)
        if !self.heads(x: event.clientX, y: event.clientY, from: from)
          && !self.heads(x: event.clientX, y: event.clientY, from: center)
        {
          self.hideTooltip()
        }
      }
    }

    /// Whether the pointer at (`x`, `y`) heads for the bubble from `from`.
    private func heads(x: Double, y: Double, from: (x: Double, y: Double)) -> Bool {
      guard let t = trigger.getBoundingClientRect(), let b = content?.getBoundingClientRect() else { return false }
      return TooltipView.Geometry.aims(
        x: x, y: y, from: from,
        trigger: .init(left: t.left, top: t.top, right: t.right, bottom: t.bottom),
        bubble: .init(left: b.left, top: b.top, right: b.right, bottom: b.bottom), gap: Self.gap)
    }

    private func stopAiming() {
      if let listener = aimListener { document.removeEventListener(.pointermove, listener) }
      aimListener = nil
      aimFrom = nil
    }

    /// Closes a pinned one when `event` happened outside its trigger.
    private func dismissUnlessInside(_ event: Event) {
      guard pinned, let target = event.target else { return }
      if !trigger.contains(target) && !(content?.contains(target) ?? false) { dismiss() }
    }

    private func showTooltip() {
      guard let content else { return }
      // A page that changes what a tooltip says after hydration (the bubble
      // is portaled to <body>, out of its reach) sets the trigger's
      // `data-tooltip-text`; the bubble says it as it shows.
      if let text = trigger.getAttribute("data-tooltip-text") { content.innerHTML = text }

      place()
      host?.setAttribute(data("visible"), true)
      trigger.setAttribute(data("visible"), true)
      isVisible = true

      // Dispatch show event
      let event = CustomEvent(type: "tooltip-show", detail: "")
      trigger.dispatchEvent(event)
    }

    private func hideTooltip() {
      guard content != nil else { return }
      stopAiming()
      host?.setAttribute(data("visible"), false)
      trigger.setAttribute(data("visible"), false)
      isVisible = false

      // Dispatch hide event
      let event = CustomEvent(type: "tooltip-hide", detail: "")
      trigger.dispatchEvent(event)
    }
  }

  public class TooltipHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TooltipHydration?
    private var instances: [TooltipInstance] = []

    public init() {
      bind(in: document.body)
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".tooltip-view") != nil else { return }
      instance = TooltipHydration()
    }

    /// The tooltips under `root`—a fragment fetched into the page after its
    /// own pass. One already bound is left alone.
    public static func hydrate(in root: DOM.Element) {
      guard let instance else {
        instance = TooltipHydration()
        return
      }
      instance.bind(in: root)
    }

    private func bind(in root: DOM.Element) {
      for tooltip in root.querySelectorAll("[data-tooltip=\"true\"]") {
        if tooltip.hasAttribute("data-tooltip-hydrated") { continue }
        tooltip.setAttribute(data("tooltip-hydrated"), "true")
        instances.append(TooltipInstance(tooltip: tooltip))
      }
    }

    /// A trigger's bubble, wherever it is: inside its trigger until the
    /// tooltip is bound, portaled to <body> after. For words that change
    /// while it stands (a session's context line, live).
    public static func bubble(of trigger: DOM.Element) -> DOM.Element? {
      if let inside = trigger.querySelector(".tooltip-content") { return inside }
      guard let instance else { return nil }
      for tooltip in instance.instances {
        if let content = tooltip.bubble(of: trigger) { return content }
      }
      return nil
    }

    /// The tooltips under `root`, about to be taken out of the page (a
    /// fragment replaced in place): their bubbles, portaled to <body>, go
    /// with them, so none is left showing for a trigger that is gone.
    public static func release(in root: DOM.Element) {
      guard let instance else { return }
      var kept: [TooltipInstance] = []
      for tooltip in instance.instances {
        if tooltip.isInside(root) {
          tooltip.release()
        } else {
          kept.append(tooltip)
        }
      }
      instance.instances = kept
    }
  }

  public enum TooltipFactory {
    /// Creates a tooltip trigger element wrapping an info icon, matching TooltipView output.
    public static func createElement(
      text: String,
      placement: TooltipView.Placement = .top,
      font: TooltipView.Font = .sans
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      // Beside 16px text (a session card's title): an info icon is the
      // tooltip's control, as tall as its text's line.
      let view = TooltipView(tooltip: text, placement: placement, font: font) {
        InfoIconView(size: sizeIconSmall)
      }
      wrapper.innerHTML = view.render()
      let element = wrapper.firstElementChild ?? wrapper
      _ = TooltipInstance(tooltip: element)
      return element
    }
  }
#endif
