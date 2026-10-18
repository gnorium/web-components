#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes
  import XMLUtilities

  /// A TEI header, rendered (user, 2026-10-18): a read-only box of nested
  /// labelled entries read from official TEI elements (`TEIHeaderRenderer`),
  /// bordered as a definition box is and gray as a read-only field is, with
  /// no heading—the entries' labels say what it holds. Where a testament's
  /// Metadata or a concordance's record shows its header, this is the box;
  /// it describes whatever the header declares, so it has no wording of its
  /// own.
  ///
  /// Under the box's own XML, on its legend at the bottom left, the header's
  /// TEI (`CodeView`), its lines numbered 1, 2 (no prefix): the box is
  /// read-only, never edited. Each box's switch is its own
  /// (`HeaderHydration`).
  public struct HeaderView: HTMLContent {
    let teiHeader: String
    let entries: [TEIHeaderEntry]

    public init(teiHeader: String) {
      self.teiHeader = teiHeader
      self.entries = TEIHeaderRenderer.entries(of: teiHeader)
    }

    public func build() -> DOM.Node {
      fieldset {
        div {
          for entry in entries { HeaderEntryView(entry) }
        }
        .class("header-layer")
        .data("header-layer", "rendered")
        div {
          CodeView(XMLFormatter.prettified(teiHeader), showLineNumbers: true)
        }
        .class("header-layer")
        .data("header-layer", "raw")
        // The legend at the bottom left, on the border: the switch belongs
        // to the text it changes.
        legend {
          XMLToggleButtonView(class: "header-xml-toggle")
        }.class("header-legend")
      }
      .class("header-view")
      .data("raw", false)
      .style {
        selector("&") {
          position(.relative); display(.flex); flexDirection(.column); alignItems(.stretch)
          minInlineSize(0); minWidth(0); width(perc(100)); maxWidth(perc(100)); boxSizing(.borderBox)
          margin(0); padding(spacing16)
          border(borderWidthBase, .solid, borderColorSubtle); borderRadius(borderRadiusBase)
          backgroundColor(backgroundColorNeutralSubtle)
        }
        controlLegendInset("&")
        bottomLegendSpacing("&")
        descendant(".header-legend") {
          position(.absolute); insetBlockEnd(0); insetInlineStart(spacing16)
          transform(translateY(perc(50))); display(.flex); alignItems(.center)
          width(.fitContent); margin(0); padding(0)
        }
        descendant(".header-layer") {
          display(.flex); flexDirection(.column); gap(spacing12); minWidth(0)
        }
        // Capped as a page's markup pane is: the box scrolls, the page not.
        descendant("[data-header-layer='raw']") { display(.none); maxHeight(px(320)); overflow(.auto) }
        selector("&[data-raw='true'] > [data-header-layer='rendered']") { display(.none) }
        selector("&[data-raw='true'] > [data-header-layer='raw']") { display(.flex) }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Each box's XML switch turns that box alone to its TEI and back.
  public enum HeaderHydration {
    public static func hydrateIfPresent() { hydrate(in: document.body) }
    public static func hydrate(in root: DOM.Element) {
      ToggleButtonHydration.hydrate(in: root)
      for view in root.querySelectorAll(".header-view") {
        guard !stringEquals(view.dataset["headerHydrated"] ?? "false", "true"),
          let toggle = view.querySelector(".header-xml-toggle")
        else { continue }
        view.dataset["headerHydrated"] = "true"
        _ = toggle.addEventListener("toggle-button-update") { (event: Event) in
          view.dataset["raw"] = stringEquals(event.detail, "true") ? "true" : "false"
        }
      }
    }
  }
#endif
