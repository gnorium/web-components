#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// One thing over what it covers, alone: a blurred, dimmed backdrop and,
  /// on it, a panel that slides down from the top. The ellipsis menu is one
  /// below the navbar, over the page; a gloss is one over the reader's pane
  /// it was opened in (user, 2026-10-08), whatever the pane's size, and
  /// fullscreen with it.
  ///
  /// It opens and closes by its `data-state` (`SheetMotion` on the client):
  /// closed, opening, open, closing.
  public struct SheetView: HTMLContent {
    public enum Placement: Sendable, Equatable {
      /// Fixed under the navbar, as tall as the rest of the screen; the
      /// panel as tall as what it holds, the backdrop under it.
      case belowNavbar(height: Int)
      /// Over the box it is put in (positioned, never fixed to the
      /// screen): the panel fills it. The box sets where its top is when it
      /// scrolls.
      case pane
      /// Fixed over the whole screen: the panel as tall as what it holds,
      /// the backdrop under it. Where a sheet that would cover a pane has
      /// none to cover (`DialogSheet`).
      case viewport
    }

    let id: String
    let `class`: String
    let placement: Placement
    let content: [DOM.Node]

    public init(
      id: String = "", class: String = "", placement: Placement = .belowNavbar(height: 96),
      @HTMLBuilder content: () -> [DOM.Node]
    ) {
      self.id = id
      self.class = `class`
      self.placement = placement
      self.content = content()
    }

    public func build() -> DOM.Node {
      let navbarHeight: Int
      let placementName: String
      switch placement {
      case .belowNavbar(let height):
        navbarHeight = height
        placementName = "navbar"
      case .pane:
        navbarHeight = 0
        placementName = "pane"
      case .viewport:
        navbarHeight = 0
        placementName = "viewport"
      }
      var sheet = div {
        div {}
          .class("sheet-backdrop")
        div {
          content
        }
        .class("sheet-panel")
      }
      .class(`class`.isEmpty ? "sheet-view" : "sheet-view \(`class`)")
      .data("state", "closed")
      .data("placement", placementName)
      .ariaHidden(true)
      .style {
        selector("&") {
          display(.none)
          insetInlineStart(0)
          width(perc(100))
          zIndex(zIndexOverlay)
          pointerEvents(.none)
          overflow(.hidden)
        }
        selector("&[data-placement='navbar']") {
          position(.fixed)
          top(px(navbarHeight))
          height(calc(dvh(100) - px(navbarHeight)))
        }
        selector("&[data-placement='pane']") {
          position(.absolute)
          top(0)
          height(perc(100))
        }
        selector("&[data-placement='viewport']") {
          position(.fixed)
          top(0)
          height(dvh(100))
        }
        descendant(".sheet-backdrop") {
          position(.absolute)
          inset(0)
          backgroundColor(backgroundColorBackdropDark)
          backdropFilter(blur(rem(1)))
          webkitBackdropFilter(blur(rem(1)))
          opacity(0)
          pointerEvents(.none)
          transition(.opacity, transitionDurationMedium, transitionTimingFunctionSystem)
          zIndex(-1)
        }
        descendant(".sheet-panel") {
          position(.relative)
          width(perc(100))
          maxHeight(perc(100))
          backgroundColor(backgroundColorBase)
          paddingBlockStart(spacing16)
          paddingBlockEnd(spacing16)
          borderBlockEnd(borderWidthBase, .solid, borderColorBase)
          boxSizing(.borderBox)
          overflowY(.auto)
          opacity(0)
          transform(translateY(perc(-100)))
          transition(
            (.opacity, transitionDurationMedium, transitionTimingFunctionSystem),
            (.transform, transitionDurationMedium, transitionTimingFunctionSystem)
          )
          media(minWidth(minWidthBreakpointTablet)) {
            paddingBlockStart(spacing20)
            paddingBlockEnd(spacing20)
          }
        }
        // Over a pane, the panel is the pane: it fills it and what it holds
        // lays itself out in it.
        // Its inset 16 at every width, as the content's at its sides.
        selector("&[data-placement='pane'] .sheet-panel") {
          paddingBlock(spacing16)
          height(perc(100))
          display(.flex)
          flexDirection(.column)
          borderBlockEnd(.none)
        }
        selector("&[data-state='opening']", "&[data-state='open']", "&[data-state='closing']") { display(.block) }
        selector("&[data-state='opening']", "&[data-state='open']") { pointerEvents(.auto) }
        selector("&[data-state='open'] .sheet-backdrop") {
          opacity(1)
          pointerEvents(.auto)
        }
        selector("&[data-state='open'] .sheet-panel") {
          opacity(1)
          transform(translateY(px(0)))
        }
      }
      if !id.isEmpty { sheet = sheet.id(id) }
      return sheet.build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// A `SheetView`'s motion: in on the next frame after it is shown, out
  /// before it is hidden, as the ellipsis menu has always moved.
  public enum SheetMotion {
    /// How long the panel takes to slide (`transitionDurationMedium`).
    public static let duration: Double = 250

    public static func open(_ sheet: DOM.Element) {
      sheet.setAttribute(.ariaHidden, false)
      sheet.setAttribute(data("state"), "opening")
      window.requestAnimationFrame {
        if stringEquals(sheet.getAttribute(data("state")) ?? "", "opening") {
          sheet.setAttribute(data("state"), "open")
        }
      }
    }

    public static func close(_ sheet: DOM.Element) {
      sheet.setAttribute(.ariaHidden, true)
      sheet.setAttribute(data("state"), "closing")
      window.setTimeout(duration) {
        if stringEquals(sheet.getAttribute(data("state")) ?? "", "closing") {
          sheet.setAttribute(data("state"), "closed")
        }
      }
    }

    public static func isOpen(_ sheet: DOM.Element) -> Bool {
      let state = sheet.getAttribute(data("state")) ?? ""
      return stringEquals(state, "open") || stringEquals(state, "opening")
    }
  }
#endif
