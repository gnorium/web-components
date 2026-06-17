#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Monitors scroll position and highlights the navigation link whose target section
  /// is closest to the viewport top. Discovers links via `.scroll-spy-view` class;
  /// each link must have `href="#section-id"` pointing to an element with a matching `id`.
  public class ScrollSpyHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: ScrollSpyHydration?
    private var ticking: Bool = false
    private let linkSelector = "a.scroll-spy-view"
    private var cachedLinks: [DOM.Element] = []

    public static func hydrateIfPresent() {
      guard document.querySelector("a.scroll-spy-view") != nil else { return }
      instance = ScrollSpyHydration()
    }

    public init?() {
      let links = document.querySelectorAll(linkSelector)
      guard links.count > 0 else { return nil }
      
      self.cachedLinks = links

      updateActiveLink()

      window.addEventListener(.scroll) { [self] _ in
        if !self.ticking {
          self.ticking = true
          window.requestAnimationFrame {
            self.updateActiveLink()
            self.ticking = false
          }
        }
      }
    }

    private func updateActiveLink() {
      var activeHref: String = ""

      for link in cachedLinks {
        let href = link.getAttribute(.href) ?? ""
        if !stringStartsWith(href, "#") { continue }
        
        let sectionID = stringReplace(href, "#", "")
        if stringIsEmpty(sectionID) { continue }
        
        guard let section = document.getElementById(sectionID),
          let rect = section.getBoundingClientRect()
        else { continue }
        
        if rect.top <= 0 {
          activeHref = href
        }
      }

      for link in cachedLinks {
        let href = link.getAttribute(.href) ?? ""
        if stringEquals(href, activeHref) {
          link.style.fontWeight(fontWeightBold)
        } else {
          link.style.fontWeight(fontWeightNormal)
        }
      }
    }
  }
#endif
