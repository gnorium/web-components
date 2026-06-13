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
    var hasAction = false
    if let _ = actionIcon {
      hasAction = true
    }

    // Render heading with appropriate level
    let titleElement: DOM.Node
    switch headingLevel {
    case .h1:
      titleElement = h1 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }

    case .h2:
      titleElement = h2 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }

    case .h3:
      titleElement = h3 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }

    case .h4:
      titleElement = h4 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }

    case .h5:
      titleElement = h5 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }

    case .h6:
      titleElement = h6 { titleContent }
        .class("accordion-title")
        .style { accordionTitleCSS() }
    }

    let detailsElement: HTML.HTMLDetailsElement = details {
      summary {
        div {
          titleElement

          if hasDescription {
            div { descriptionContent }
              .class("accordion-description")
              .style {
                accordionDescriptionCSS()
              }
          }
        }
        .class("accordion-header-wrapper")
        .style {
          accordionHeaderWrapperCSS()
        }

        if let icon = actionIcon {
          button {
            span { icon }
              .ariaHidden(true)
          }
          .type(.button)
          .class("accordion-action-button")
          .ariaLabel(actionButtonLabel)
          .style {
            accordionActionButtonCSS(actionAlwaysVisible)
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
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
          color(colorSubtle)
        }
      }
      .class("accordion-summary")
      .style {
        accordionSummaryCSS(separation, hasAction)
      }

      // Clip wrapper sits BELOW the summary so the content's translateY slide is
      // masked at the title's bottom edge (slides under the title, not over it).
      div {
        div { contentSlot }
          .class("accordion-content")
          .style {
            accordionContentCSS(separation)
          }
      }
      .class("accordion-content-clip")
      .style { overflow(.hidden) }
    }
    .open(isOpen)
    .data("open-finished", isOpen ? "true" : "false")
    .class("accordion-details")
    .id(id)
    .style {
      attribute(data("open-finished"), "true") {
        descendant(".accordion-content-clip") {
          overflow(.visible).important()
        }
      }
    }

    if separation == .divider {
      return div {
        detailsElement

        hr()
          .class("accordion-divider")
          .ariaHidden(true)
          .style {
            accordionDividerCSS()
          }
      }
      .class(stringIsEmpty(`class`) ? "accordion-view" : "accordion-view \(`class`)")
      .data("separation", separation.value)
      .style {
        accordionViewCSS(separation)
      }

    } else {
      return div {
        detailsElement
      }
      .class(stringIsEmpty(`class`) ? "accordion-view" : "accordion-view \(`class`)")
      .data("separation", separation.value)
      .style {
        accordionViewCSS(separation)
      }

    }
  }

  @CSSBuilder
  private func accordionViewCSS(_ separation: Separation) -> [CSSOM.CSSRule] {
    display(.block)
    position(.relative)

    pseudoClass(.hover) {
      zIndex(zIndexToolbar).important()
    }

    pseudoClass(.focusWithin) {
      zIndex(zIndexToolbar).important()
    }

    if separation == .outline {
      border(borderWidthBase, .solid, borderColorBase)
      borderRadius(borderRadiusBase)
      padding(spacing4)
    }
  }

  @CSSBuilder
  private func accordionSummaryCSS(_ separation: Separation, _ hasAction: Bool) -> [CSSOM.CSSRule] {
    display(.flex)
    alignItems(.center)
    gap(spacing8)
    cursor(cursorBaseHover)
    listStyle(.none)
    userSelect(.none)
    position(.relative)
    zIndex(1)

    if separation == .minimal {
      minHeight(minSizeInteractivePointer)
      padding(spacing4, spacing0)
    } else {
      padding(spacing12, spacing16)
    }

    if separation == .outline {
      borderRadius(borderRadiusBase)
    }

    pseudoElement(.marker) {
      display(.none).important()
    }

    pseudoElement(.webkitDetailsMarker) {
      display(.none).important()
    }

    pseudoClass(.focusVisible) {
      outline(px(2), .solid, borderColorBlueFocus).important()
      outlineOffset(px(1)).important()
    }

    pseudoClass(.focus) {
      outline(.none).important()
    }
  }

  @CSSBuilder
  private func accordionExpandIconCSS() -> [CSSOM.CSSRule] {
    display(.inlineFlex)
    alignItems(.center)
    justifyContent(.center)
    flexShrink(0)
    width(sizeIconMedium)
    height(sizeIconMedium)
    color(colorSubtle)
    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
  }

  @CSSBuilder
  private func accordionHeaderWrapperCSS() -> [CSSOM.CSSRule] {
    display(.flex)
    if headerDirection == .row {
      flexDirection(.row)
      alignItems(.center)
      gap(spacing8)
    } else {
      flexDirection(.column)
      gap(spacing4)
    }
    flex(1)
    minWidth(0)
  }

  @CSSBuilder
  private func accordionTitleCSS() -> [CSSOM.CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(titleFontSize)
    fontWeight(titleFontWeight)
    lineHeight(lineHeightSmall22)
    color(colorBase)
    margin(0)
    wordWrap(.breakWord)
  }

  @CSSBuilder
  private func accordionDescriptionCSS() -> [CSSOM.CSSRule] {
    fontSize(fontSizeSmall14)
    lineHeight(lineHeightSmall22)
    color(colorSubtle)
    fontWeight(fontWeightNormal)
  }

  @CSSBuilder
  private func accordionActionButtonCSS(_ actionAlwaysVisible: Bool) -> [CSSOM.CSSRule] {
    if actionAlwaysVisible {
      display(.inlineFlex)
    } else {
      display(.none)
    }

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

    pseudoClass(.hover) {
      backgroundColor(backgroundColorInteractiveSubtleHover).important()
      color(colorBase).important()
    }

    pseudoClass(.active) {
      backgroundColor(backgroundColorInteractiveSubtleActive).important()
    }

    pseudoClass(.focus) {
      outline(px(2), .solid, borderColorBlueFocus).important()
      outlineOffset(px(-2)).important()
    }
  }

  @CSSBuilder
  private func accordionContentCSS(_ separation: Separation) -> [CSSOM.CSSRule] {
    fontFamily(typographyFontSans)
    fontSize(fontSizeMedium16)
    lineHeight(lineHeightSmall22)
    color(colorBase)
    transition(transitionPropertyBase, transitionDurationMedium, transitionTimingFunctionSystem)

    if separation == .minimal {
      padding(spacing12, spacing0)
    } else {
      padding(spacing16)
    }
  }

  @CSSBuilder
  private func accordionDividerCSS() -> [CSSOM.CSSRule] {
    height(borderWidthBase)
    backgroundColor(borderColorBase)
    margin(spacing0)
    border(.none)
  }
}

#if CLIENT
  import WebAPIs

  private class AccordionInstance: @unchecked Sendable {
    private var accordion: DOM.Element
    private var details: DOM.Element?
    private var summary: DOM.Element?
    private var actionButton: DOM.Element?
    private var chevronEl: DOM.Element?
    private var isOpen: Bool

    init(accordion: DOM.Element) {
      self.accordion = accordion

      details = accordion.querySelector(".accordion-details")
      summary = accordion.querySelector(".accordion-summary")
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

      // Handle click on summary — we track state ourselves
      _ = summary.addEventListener(.click) { [self] event in
        guard let details = self.details else { return }

        if self.isOpen {
          // --- CLOSING ---
          // Prevent native close so we can animate first
          event.preventDefault()
          self.isOpen = false
          details.setAttribute(data("open-finished"), "false")

          chevronEl?.style.transform(rotate(deg(-90)))
          chevronEl?.setAttribute(data("expanded"), "false")

          // Animate content sliding up, then manually close
          if let content = details.querySelector(".accordion-content") {
            content.style.setProperty(.transition, (.transform, transitionDurationMedium, .ease))
            content.style.setProperty(.transform, translateY(perc(-100)))
          }
          window.setTimeout(250) {
            details.removeAttribute(.open)
          }

          // Hide action button
          if let actionButton = self.actionButton {
            let displayValue = actionButton.getAttribute(.style) ?? ""
            let alwaysVisible = !stringContains(displayValue, "display: none")
            if !alwaysVisible {
              actionButton.style.display(.none)
            }
          }

          // Dispatch custom event
          let closeEvent = CustomEvent(type: "accordion-toggle", detail: "false")
          self.accordion.dispatchEvent(closeEvent)
        } else {
          // --- OPENING ---
          // Let browser add [open] natively, then animate content in
          self.isOpen = true

          chevronEl?.style.transform(rotate(deg(0)))
          chevronEl?.setAttribute(data("expanded"), "true")

          // Wait for browser to add [open], then animate content slide-in
          window.requestAnimationFrame {
            if let content = details.querySelector(".accordion-content") {
              content.style.setProperty(.transition, .none)
              content.style.setProperty(.transform, translateY(perc(-100)))
              window.requestAnimationFrame {
                content.style.setProperty(.transition, (.transform, transitionDurationMedium, .ease))
                content.style.setProperty(.transform, translateY(0))
              }
            }
          }

          // Show action button
          if let actionButton = self.actionButton {
            let displayValue = actionButton.getAttribute(.style) ?? ""
            let alwaysVisible = !stringContains(displayValue, "display: none")
            if !alwaysVisible {
              actionButton.style.display(.inlineFlex)
            }
          }

          // Dispatch custom event
          let openEvent = CustomEvent(type: "accordion-toggle", detail: "true")
          self.accordion.dispatchEvent(openEvent)

          window.setTimeout(250) { [self] in
            if self.isOpen {
              details.setAttribute(data("open-finished"), "true")
              if let content = details.querySelector(".accordion-content") {
                content.style.removeProperty(.transform)
                content.style.removeProperty(.transition)
              }
            }
          }
        }
      }

      // Handle action button click
      if let actionButton = actionButton {
        _ = actionButton.addEventListener(.click) { [self] event in
          event.stopPropagation()
          let clickEvent = CustomEvent(type: "accordion-action-click", detail: "")
          self.accordion.dispatchEvent(clickEvent)
        }
      }
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
    ///   - headingLevel: Heading level (e.g. .h3, .h5). Default .h3
    ///   - content: Closure that returns the content element to place inside `.accordion-content`
    /// - Returns: The root `.accordion-view` div element (call AccordionHydration.hydrate to bind animations)
    public static func createElement(
      id: String,
      isOpen: Bool = false,
      separation: Separation = .outline,
      title: String,
      headingLevel: HeadingLevel = .h3,
      headerDirection: HeaderDirection = .column,
      @HTMLBuilder description: () -> [DOM.Node] = { [] },
      content: () -> DOM.Element
    ) -> DOM.Element {
      let wrapper = document.createElement(.div)
      let view = AccordionView(
        id: id,
        isOpen: isOpen,
        separation: separation,
        headingLevel: headingLevel,
        headerDirection: headerDirection,
        title: { title },
        description: description,
        content: { content() }
      )
      wrapper.innerHTML = renderHTML { view.render() }

      return wrapper.firstElementChild ?? wrapper
    }
  }
#endif
