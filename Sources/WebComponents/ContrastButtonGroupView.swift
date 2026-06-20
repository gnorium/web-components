#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A button group for selecting contrast level (Standard / Increased).
  /// Renders two option buttons with icons. Hydrated by ContrastButtonGroupHydration.
  public struct ContrastButtonGroupView: HTMLContent {
    let `class`: String

    public init(class: String = "") {
      self.class = `class`
    }

    public func build() -> DOM.Node {
      ButtonGroupView(
        buttons: [
          .init(
            value: "standard", label: "Standard",
            icon: IconView(icon: { s in LessContrastIconView(width: s, height: s) }, size: .medium).build(),
            weight: .static,
            class: "", fullWidth: true,
            labelFontWeight: fontWeightNormal, contentJustifyContent: .flexStart),
          .init(
            value: "increased", label: "Increased",
            icon: IconView(icon: { s in MoreContrastIconView(width: s, height: s) }, size: .medium).build(),
            weight: .static,
            class: "", fullWidth: true,
            labelFontWeight: fontWeightNormal, contentJustifyContent: .flexStart),
        ],
        shape: .apart,
        direction: .column,
        class: `class`.isEmpty
          ? "contrast-button-group-view" : "contrast-button-group-view \(`class`)",
        ariaLabel: "Contrast",
        style: {
          width(perc(100))
          gap(spacing4)
        }
      )
    }
  }
#endif

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Hydrates all ContrastButtonGroupView instances on the page.
  /// Initializes from localStorage / system preference, binds click events,
  /// and applies contrast changes to the document.
  public class ContrastButtonGroupHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: ContrastButtonGroupHydration?
    nonisolated(unsafe) private var groups: [DOM.Element] = []

    public static func hydrateIfPresent() {
      guard document.querySelector(".contrast-button-group-view") != nil else { return }
      instance = ContrastButtonGroupHydration()
    }

    public init?() {
      let allGroups = document.querySelectorAll(".contrast-button-group-view")
      for group in allGroups {
        groups.append(group)
      }
      guard !groups.isEmpty else { return nil }

      initialize()
      bindEvents()
    }

    private nonisolated func initialize() {
      var contrast: CSS.PrefersContrast = .less
      if let saved = localStorage.getItem("contrast") {
        let isMore = saved.withCString { ptr in
          ptr[0] == 109 && ptr[1] == 111 && ptr[2] == 114 && ptr[3] == 101 && ptr[4] == 0  // "more"
        }
        contrast = isMore ? .more : .less
      } else {
        let prefersMore = window.matchMedia(prefersContrast(.more))
        contrast = prefersMore ? .more : .less
      }
      applyContrast(contrast)
    }

    private nonisolated func bindEvents() {
      for group in groups {
        let buttons = group.querySelectorAll(".button-group-button")
        for button in buttons {
          _ = button.addEventListener("button-group-click") { [self] (event: Event) in
            let detail = event.detail
            // "increased" starts with 'i' (105)
            let isIncreased = detail.withCString { ptr in
              ptr[0] == 105
            }
            self.applyContrast(isIncreased ? .more : .less)
          }
        }
      }
    }

    private nonisolated func applyContrast(_ contrast: CSS.PrefersContrast) {
      let htmlElement = document.querySelector("html")
      switch contrast {
      case .more:
        htmlElement?.dataset.contrast("more")
        localStorage.setItem("contrast", "more")
      case .less:
        htmlElement?.dataset.contrast("less")
        localStorage.setItem("contrast", "less")
      default:
        break
      }

      let selectedValue: String
      switch contrast {
      case .more: selectedValue = "increased"
      case .less: selectedValue = "standard"
      default: selectedValue = "standard"
      }

      for group in groups {
        updateSelection(group, selectedValue: selectedValue)
      }
    }

    private nonisolated func updateSelection(_ group: DOM.Element, selectedValue: String) {
      selectButtonGroupValue(group, selectedValue: selectedValue)
    }
  }
#endif
