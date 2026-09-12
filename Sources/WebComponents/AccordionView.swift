import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

public enum HeaderDirection: Sendable {
  case column
  case row
}

public enum Separation: Sendable {
  case none
  case minimal
  case divider
  case outline

  public var value: String {
    switch self {
    case .none: return "none"
    case .minimal: return "minimal"
    case .divider: return "divider"
    case .outline: return "outline"
    }
  }
}

public enum HeadingLevel: Sendable {
  case h1
  case h2
  case h3
  case h4
  case h5
  case h6

  public var value: String {
    switch self {
    case .h1: return "h1"
    case .h2: return "h2"
    case .h3: return "h3"
    case .h4: return "h4"
    case .h5: return "h5"
    case .h6: return "h6"
    }
  }
}

public struct AccordionView: HTMLContent {
  let id: String
  let isOpen: Bool
  let actionIcon: String?
  let actionAlwaysVisible: Bool
  let actionButtonLabel: String
  let separation: Separation
  let headingLevel: HeadingLevel
  let headerDirection: HeaderDirection
  let titleFontSize: CSS.Length
  let titleFontWeight: CSS.FontWeight
  let titleContent: [DOM.Node]
  let descriptionContent: [DOM.Node]
  let contentSlot: [DOM.Node]
  let `class`: String

  public init(
    id: String,
    isOpen: Bool = false,
    actionIcon: String? = nil,
    actionAlwaysVisible: Bool = false,
    actionButtonLabel: String = "",
    separation: Separation = .divider,
    headingLevel: HeadingLevel = .h3,
    headerDirection: HeaderDirection = .column,
    titleFontSize: CSS.Length = fontSizeMedium16,
    titleFontWeight: CSS.FontWeight = fontWeightSemiBold,
    class: String = "",
    @HTMLBuilder title: () -> [DOM.Node],
    @HTMLBuilder description: () -> [DOM.Node] = { [] },
    @HTMLBuilder content: () -> [DOM.Node]
  ) {
    self.id = id
    self.isOpen = isOpen
    self.actionIcon = actionIcon
    self.actionAlwaysVisible = actionAlwaysVisible
    self.actionButtonLabel = actionButtonLabel
    self.separation = separation
    self.headingLevel = headingLevel
    self.headerDirection = headerDirection
    self.titleFontSize = titleFontSize
    self.titleFontWeight = titleFontWeight
    self.`class` = `class`
    self.titleContent = title()
    self.descriptionContent = description()
    self.contentSlot = content()
  }

  public func build() -> DOM.Node {
    let hasDescription = !descriptionContent.isEmpty
    // Render heading with appropriate level
    let titleElement: DOM.Node
    switch headingLevel {
    case .h1:
      titleElement = h1 { titleContent }
        .class("accordion-title")

    case .h2:
      titleElement = h2 { titleContent }
        .class("accordion-title")

    case .h3:
      titleElement = h3 { titleContent }
        .class("accordion-title")

    case .h4:
      titleElement = h4 { titleContent }
        .class("accordion-title")

    case .h5:
      titleElement = h5 { titleContent }
        .class("accordion-title")

    case .h6:
      titleElement = h6 { titleContent }
        .class("accordion-title")
    }

    let detailsElement: HTML.HTMLDetailsElement = details {
      summary {
        div {
          titleElement

          if hasDescription {
            div { descriptionContent }
              .class("accordion-description")
          }
        }
        .class("accordion-header-wrapper")
        .data("header-direction", headerDirection == .row ? "row" : "column")
        .data("title-font-size", titleFontSize.value)
        .data("title-font-weight", titleFontWeight.value)
        .style {
          selector("&") {
            display(.flex)
            flex(1)
            minWidth(0)
          }
          selector("&[data-header-direction='row']") {
            flexDirection(.row)
            alignItems(.center)
            gap(spacing8)
          }
          selector("&[data-header-direction='column']") {
            flexDirection(.column)
            gap(spacing4)
          }
          descendant(".accordion-title") {
            fontFamily(typographyFontSans)
            lineHeight(lineHeightSmall22)
            color(colorBase)
            margin(0)
            wordWrap(.breakWord)
          }
          selector("&[data-title-font-size='\(titleFontSize.value)'] .accordion-title") { fontSize(titleFontSize) }
          selector("&[data-title-font-weight='\(titleFontWeight.value)'] .accordion-title") { fontWeight(titleFontWeight) }
          descendant(".accordion-description") {
            fontSize(fontSizeSmall14)
            lineHeight(lineHeightSmall22)
            color(colorSubtle)
            fontWeight(fontWeightNormal)
          }
        }

        if let icon = actionIcon {
          button {
            span { icon }
              .ariaHidden(true)
          }
          .type(.button)
          .class("accordion-action-button")
          .ariaLabel(actionButtonLabel)
          .data("always-visible", actionAlwaysVisible)
          .data("visible", actionAlwaysVisible || isOpen)
          .style {
            selector("&") {
              alignItems(.center)
              justifyContent(.center)
              flexShrink(0)
              width(minSizeInteractivePointer)
              height(minSizeInteractivePointer)
              padding(0)
              backgroundColor(.transparent)
              border(.none)
              borderRadius(borderRadiusBase)
              color(colorSubtle)
              cursor(cursorBase)
              transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
            }
            selector("&[data-always-visible='true']") { display(.inlineFlex) }
            selector("&[data-always-visible='false'][data-visible='true']") { display(.inlineFlex) }
            selector("&[data-always-visible='false'][data-visible='false']") { display(.none) }
            pseudoClass(.hover) {
              backgroundColor(backgroundColorInteractiveSubtleHover).important()
              color(colorBase).important()
            }
            pseudoClass(.active) { backgroundColor(backgroundColorInteractiveSubtleActive).important() }
            pseudoClass(.focus) {
              outline(px(2), .solid, borderColorBlueFocus).important()
              outlineOffset(px(-2)).important()
            }
          }
        }

        // Animated chevron — right (collapsed) to down (open)
        span {
          AnimatedRightDownChevronView(
            id: "accordion-\(id)",
            expanded: isOpen
          )
        }
        .class("accordion-expand-icon")
        .style {
          selector("&") {
            display(.inlineFlex)
            alignItems(.center)
            justifyContent(.center)
            color(colorSubtle)
          }
        }
      }
      .class("accordion-summary")
      .data("separation", separation.value)
      .style {
        selector("&") {
          display(.flex)
          alignItems(.center)
          gap(spacing8)
          cursor(cursorBaseHover)
          listStyle(.none)
          userSelect(.none)
          position(.relative)
          zIndex(1)
          outline(.none).important()
          boxShadow(.none).important()
        }
        selector("&[data-separation='minimal']") {
          minHeight(minSizeInteractivePointer)
          padding(spacing4, spacing0)
        }
        selector("&:not([data-separation='minimal'])") { padding(spacing12, spacing16) }
        selector("&[data-separation='outline']") { borderRadius(borderRadiusBase) }
        pseudoElement(.marker) { display(.none).important() }
        pseudoElement(.webkitDetailsMarker) { display(.none).important() }
        pseudoClass(.focusVisible) {
          outline(.none).important()
          boxShadow(.none).important()
        }
        pseudoClass(.focus) {
          outline(.none).important()
          boxShadow(.none).important()
        }
      }

      // Height is animated with inline pixel rows (see AccordionInstance).
      // 0fr ↔ 1fr is not interpolable in WebKit, so it jumps at both ends.
      div {
        div { contentSlot }
          .class("accordion-content")
          .data("separation", separation.value)
          .style {
            selector("&") {
              fontFamily(typographyFontSans)
              fontSize(fontSizeMedium16)
              lineHeight(lineHeightSmall22)
              color(colorBase)
              minHeight(0)
              overflow(.hidden)
              opacity(1)
              // Fade leads the height so glyphs are gone before the last pixels clip.
              transition(
                "opacity \(transitionDurationBase.value) \(transitionTimingFunctionSystem.value)"
              )
            }
            selector("&[data-separation='minimal']") { padding(spacing12, spacing0) }
            selector("&:not([data-separation='minimal'])") { padding(spacing16) }
          }
      }
      .class("accordion-content-clip")
      .style {
        selector("&") {
          display(.grid)
          gridTemplateRows(fr(0))
          overflow(.hidden)
          transition(
            "grid-template-rows \(transitionDurationMedium.value) \(transitionTimingFunctionSystem.value)"
          )
        }
        selector("& > *") {
          minHeight(0)
        }
        selector(
          ".accordion-details[data-expanded='true']:not([data-motion='enter-from']):not([data-motion='closing']) &"
        ) {
          gridTemplateRows(fr(1))
        }
        selector(".accordion-details[data-motion='enter-from'] &") {
          transition(.none)
          gridTemplateRows("0px")
        }
        selector(".accordion-details[data-motion='closing'] &") {
          gridTemplateRows("0px")
        }
      }
    }
    .open(isOpen)
    .data("expanded", isOpen ? "true" : "false")
    .data("open-finished", isOpen ? "true" : "false")
    .data("motion", "idle")
    .class("accordion-details")
    .id(id)
    .style {
      selector("&[data-motion='closing'] .accordion-content", "&[data-motion='enter-from'] .accordion-content") {
        opacity(0)
        pointerEvents(.none)
      }
    }
    return div {
      detailsElement
      if separation == .divider {
        hr()
          .class("accordion-divider")
          .ariaHidden(true)
          .style {
            selector("&") {
              height(borderWidthBase)
              backgroundColor(borderColorBase)
              margin(spacing0)
              border(.none)
            }
          }
      }
    }
    .class(stringIsEmpty(`class`) ? "accordion-view" : "accordion-view \(`class`)")
    .data("separation", separation.value)
    .style {
      selector("&") {
        display(.block)
        position(.relative)
      }
      selector("&[data-separation='outline']") {
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        padding(spacing4)
      }
      pseudoClass(.hover) { zIndex(zIndexToolbar).important() }
      pseudoClass(.focusWithin) { zIndex(zIndexToolbar).important() }
    }
  }
}

#if CLIENT
  import WebAPIs

  private class AccordionInstance: @unchecked Sendable {
    private var accordion: DOM.Element
    private var details: DOM.Element?
    private var summary: DOM.Element?
    private var clip: DOM.Element?
    private var actionButton: DOM.Element?
    private var chevronEl: DOM.Element?
    private var isOpen: Bool

    init(accordion: DOM.Element) {
      self.accordion = accordion

      details = accordion.querySelector(".accordion-details")
      summary = accordion.querySelector(".accordion-summary")
      clip = accordion.querySelector(".accordion-content-clip")
      actionButton = accordion.querySelector(".accordion-action-button")
      chevronEl = accordion.querySelector(".animated-right-down-chevron-view")
      if let d = details {
        isOpen = d.hasAttribute(.open)
      } else {
        isOpen = false
      }

      bindEvents()
    }

    private func bindEvents() {
      guard let summary = summary, details != nil else { return }

      _ = summary.addEventListener(.click) { [self] event in
        guard let details = self.details else { return }
        // Keep <details> open for the whole motion; native toggle would
        // display:none the panel before the height transition can run.
        event.preventDefault()

        let motion = details.dataset["motion"] ?? "idle"
        if !stringEquals(motion, "idle") { return }

        if self.isOpen {
          self.beginClose(details)
        } else {
          self.beginOpen(details)
        }
      }

      if let actionButton = actionButton {
        _ = actionButton.addEventListener(.click) { [self] event in
          event.stopPropagation()
          let clickEvent = CustomEvent(type: "accordion-action-click", detail: "")
          self.accordion.dispatchEvent(clickEvent)
        }
      }
    }

    private func pixelRows(_ height: Double) -> String {
      stringJoin([intToString(Int(height.rounded())), "px"], separator: "")
    }

    private func lockClipRows(_ value: String, animate: Bool) {
      guard let clip = clip else { return }
      if !animate {
        clip.style.setProperty("transition", "none")
      } else {
        _ = clip.style.removeProperty("transition")
      }
      clip.style.setProperty("grid-template-rows", value)
      _ = clip.offsetHeight
      if !animate {
        _ = clip.style.removeProperty("transition")
      }
    }

    private func clearClipRows() {
      _ = clip?.style.removeProperty("grid-template-rows")
      _ = clip?.style.removeProperty("transition")
    }

    private func beginClose(_ details: DOM.Element) {
      self.isOpen = false
      chevronEl?.setAttribute(data("expanded"), "false")
      if let actionButton = self.actionButton {
        actionButton.setAttribute(data("visible"), "false")
      }

      // Pin current pixel height *before* dropping expanded, or CSS 0px snaps.
      let startHeight = clip?.getBoundingClientRect()?.height ?? 0
      lockClipRows(pixelRows(startHeight), animate: false)
      details.setAttribute(data("open-finished"), "false")
      details.setAttribute(data("expanded"), "false")
      details.setAttribute(data("motion"), "closing")
      lockClipRows("0px", animate: true)

      let closeEvent = CustomEvent(type: "accordion-toggle", detail: "false")
      self.accordion.dispatchEvent(closeEvent)

      if let clip = clip {
        _ = clip.addEventListener(.transitionend) { [self] event in
          guard let target = event.target, target.id == clip.id else { return }
          self.completeClose(details)
        }
      }
      window.setTimeout(400) { [self] in
        self.completeClose(details)
      }
    }

    private func completeClose(_ details: DOM.Element) {
      let motion = details.dataset["motion"] ?? ""
      guard stringEquals(motion, "closing") else { return }
      clearClipRows()
      details.removeAttribute(.open)
      details.setAttribute(data("motion"), "idle")
    }

    private func beginOpen(_ details: DOM.Element) {
      self.isOpen = true
      details.setAttribute(.open, "open")
      details.setAttribute(data("expanded"), "true")
      details.setAttribute(data("open-finished"), "false")
      chevronEl?.setAttribute(data("expanded"), "true")
      if let actionButton = self.actionButton {
        actionButton.setAttribute(data("visible"), "true")
      }

      let inner = clip?.querySelector(".accordion-content")
      let endHeight = inner?.scrollHeight ?? clip?.scrollHeight ?? 0
      details.setAttribute(data("motion"), "enter-from")
      lockClipRows("0px", animate: false)
      details.setAttribute(data("motion"), "enter-to")
      lockClipRows(pixelRows(endHeight), animate: true)

      let openEvent = CustomEvent(type: "accordion-toggle", detail: "true")
      self.accordion.dispatchEvent(openEvent)

      if let clip = clip {
        _ = clip.addEventListener(.transitionend) { [self] event in
          guard let target = event.target, target.id == clip.id else { return }
          self.completeOpen(details)
        }
      }
      window.setTimeout(400) { [self] in
        self.completeOpen(details)
      }
    }

    private func completeOpen(_ details: DOM.Element) {
      guard self.isOpen else { return }
      let motion = details.dataset["motion"] ?? ""
      guard stringEquals(motion, "enter-to") else { return }
      clearClipRows()
      details.setAttribute(data("open-finished"), "true")
      details.setAttribute(data("motion"), "idle")
    }
  }

  public class AccordionHydration: @unchecked Sendable {
    /// The active instance, set automatically on init. Accessible from any module that imports WebComponents.
    public static nonisolated(unsafe) var current: AccordionHydration?

    private var instances: [AccordionInstance] = []

    public init() {
      hydrateAllAccordions()
      AccordionHydration.current = self
    }

    public static func hydrateIfPresent() {
      guard document.querySelector(".accordion-view") != nil else { return }
      current = AccordionHydration()
    }

    private func hydrateAllAccordions() {
      let allAccordions = document.querySelectorAll(".accordion-view")

      for accordion in allAccordions {
        let instance = AccordionInstance(accordion: accordion)
        instances.append(instance)
      }
    }

    /// Hydrates a dynamically created accordion element (e.g. from AccordionFactory).
    public func hydrate(_ element: DOM.Element) {
      let instance = AccordionInstance(accordion: element)
      instances.append(instance)
    }
  }

  /// CLIENT factory for creating AccordionView DOM elements dynamically.
  /// Produces the same structure as the server-rendered AccordionView.
  public enum AccordionFactory {
    /// Creates an AccordionView DOM element matching the server-rendered structure.
    ///
    /// - Parameters:
    ///   - id: Unique ID for the accordion (used on the `<details>` element)
    ///   - open: Whether the accordion starts expanded
    ///   - separation: Visual separation style (.none, .minimal, .divider, .outline)
    ///   - title: DOM.Text content for the accordion title
    ///   - titleFontSize: Title type scale. Defaults to the body size the
    ///     server-rendered accordions use, so a client-built card is not quietly
    ///     larger and heavier than the same card from SSR.
    ///   - titleFontWeight: Title weight. Same reasoning as `titleFontSize`.
    ///   - headingLevel: Heading level (e.g. .h3, .h5). Default .h3
    ///   - content: Closure that returns the content element to place inside `.accordion-content`
    /// - Returns: The root `.accordion-view` div element (call AccordionHydration.hydrate to bind animations)
    public static func createElement(
      id: String,
      isOpen: Bool = false,
      separation: Separation = .outline,
      title: String,
      titleFontSize: CSS.Length = fontSizeSmall14,
      titleFontWeight: CSS.FontWeight = fontWeightNormal,
      headingLevel: HeadingLevel = .h3,
      headerDirection: HeaderDirection = .column,
      @HTMLBuilder description: () -> [DOM.Node] = { [] },
      content: () -> DOM.Element
    ) -> DOM.Element {
      createElement(
        id: id,
        isOpen: isOpen,
        separation: separation,
        headingLevel: headingLevel,
        headerDirection: headerDirection,
        titleFontSize: titleFontSize,
        titleFontWeight: titleFontWeight,
        title: { title },
        description: description,
        content: { content() }
      )
    }

    /// The same card, with the title given as content rather than as text, and
    /// with the root class the server's initialiser takes.
    ///
    /// A header that carries more than a word — an outcome mark beside a tool
    /// name, a path, a line range — cannot be expressed as `title: String`, and
    /// building it as `description` puts it in a second box with its own type
    /// and colour. This mirrors `AccordionView.init`, so a client-built card is
    /// the server-rendered card, node for node. Build the title and content with
    /// the DSL: `render()` serialises `DOM.Element.children`, which only the
    /// builder fills, so a node taken from the live document — a factory's
    /// `firstElementChild`, say — serialises as an empty tag.
    public static func createElement(
      id: String,
      isOpen: Bool = false,
      separation: Separation = .outline,
      headingLevel: HeadingLevel = .h3,
      headerDirection: HeaderDirection = .column,
      titleFontSize: CSS.Length = fontSizeSmall14,
      titleFontWeight: CSS.FontWeight = fontWeightNormal,
      class: String = "",
      @HTMLBuilder title: () -> [DOM.Node],
      @HTMLBuilder description: () -> [DOM.Node] = { [] },
      @HTMLBuilder content: () -> [DOM.Node]
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = AccordionView(
        id: id,
        isOpen: isOpen,
        separation: separation,
        headingLevel: headingLevel,
        headerDirection: headerDirection,
        titleFontSize: titleFontSize,
        titleFontWeight: titleFontWeight,
        class: `class`,
        title: title,
        description: description,
        content: content
      )
      wrapper.innerHTML = view.render()

      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
