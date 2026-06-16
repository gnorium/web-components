#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A button group for selecting color scheme (Light / Dark).
  /// Renders two option buttons with icons. Hydrated by ColorSchemeButtonGroupHydration.
  public struct ColorSchemeButtonGroupView: HTMLContent {
    let `class`: String

    public init(class: String = "") {
      self.class = `class`
    }

    public func build() -> DOM.Node {
      ButtonGroupView(
        buttons: [
          .init(
            value: "light", label: "Light",
            icon: IconView(icon: { s in LightModeIconView(width: s, height: s) }, size: .medium)
              .build(),
            class: "", fullWidth: true,
            labelFontWeight: fontWeightNormal, contentJustifyContent: .flexStart),
          .init(
            value: "dark", label: "Dark",
            icon: IconView(icon: { s in DarkModeIconView(width: s, height: s) }, size: .medium)
              .build(),
            class: "", fullWidth: true,
            labelFontWeight: fontWeightNormal, contentJustifyContent: .flexStart),
        ],
        shape: .apart,
        direction: .column,
        class: `class`.isEmpty
          ? "color-scheme-button-group-view" : "color-scheme-button-group-view \(`class`)",
        ariaLabel: "Color scheme",
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

  /// Hydrates all ColorSchemeButtonGroupView instances on the page.
  /// Initializes from localStorage / system preference, binds click events,
  /// and applies color scheme changes to the document.
  public class ColorSchemeButtonGroupHydration: @unchecked Sendable {
    nonisolated(unsafe) private var groups: [DOM.Element] = []

    public init?() {
      let allGroups = document.querySelectorAll(".color-scheme-button-group-view")
      for group in allGroups {
        groups.append(group)
      }
      guard !groups.isEmpty else { return nil }

      initialize()
      bindEvents()
    }

    private nonisolated func initialize() {
      var scheme: CSS.PrefersColorScheme = .light
      if let saved = localStorage.getItem("color-scheme") {
        let isDark = saved.withCString { ptr in
          ptr[0] == 100 && ptr[1] == 97 && ptr[2] == 114 && ptr[3] == 107 && ptr[4] == 0  // "dark"
        }
        scheme = isDark ? .dark : .light
      } else {
        let prefersDark = window.matchMedia(prefersColorScheme(.dark))
        scheme = prefersDark ? .dark : .light
      }
      applyScheme(scheme)
    }

    private nonisolated func bindEvents() {
      for group in groups {
        let buttons = group.querySelectorAll(".button-group-button")
        for button in buttons {
          _ = button.addEventListener("button-group-click") { [self] (event: Event) in
            let detail = event.detail
            let isDark = detail.withCString { ptr in
              ptr[0] == 100 && ptr[1] == 97 && ptr[2] == 114 && ptr[3] == 107  // "dark"
            }
            self.applyScheme(isDark ? .dark : .light)
          }
        }
      }
    }

    private nonisolated func applyScheme(_ scheme: CSS.PrefersColorScheme) {
      let htmlElement = document.querySelector("html")
      switch scheme {
      case .dark:
        htmlElement?.dataset.colorScheme("dark")
        localStorage.setItem("color-scheme", "dark")
      case .light:
        htmlElement?.dataset.colorScheme("light")
        localStorage.setItem("color-scheme", "light")
      }

      let selectedValue: String
      switch scheme {
      case .dark: selectedValue = "dark"
      case .light: selectedValue = "light"
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
