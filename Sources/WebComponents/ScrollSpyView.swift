#if os(WASI)

import WebAPIs
import DesignTokens
import EmbeddedSwiftUtilities

/// Monitors scroll position and highlights the navigation link whose target section
/// is closest to the viewport top. Discovers links via `.scroll-spy-link` class;
/// each link must have `href="#section-id"` pointing to an element with a matching `id`.
public class ScrollSpyHydration: @unchecked Sendable {
	private var ticking: Bool = false
	private let linkSelector = "a.scroll-spy-link"

	public init?() {
		let links = document.querySelectorAll(linkSelector)
		guard links.count > 0 else { return nil }

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
		let links = document.querySelectorAll(linkSelector)
		var activeHref: String = ""

		for link in links {
			let href = link.getAttribute(.href) ?? ""
			let sectionId = stringReplace(href, "#", "")
			guard let section = document.getElementById(sectionId),
			      let rect = section.getBoundingClientRect() else { continue }
			if rect.top <= 0 {
				activeHref = href
			}
		}

		for link in links {
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
