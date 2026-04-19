#if SERVER

import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct BookmarkIconView: HTMLContent {
	let width: Length
	let height: Length
	let `class`: String

	public init(
		width: Length = px(20),
		height: Length = px(20),
		class: String = ""
	) {
		self.width = width
		self.height = height
		self.class = `class`
	}

	public func render() -> DOMNode {
		svg {
			path()
				.d(M(5, 1), a(2, 2, 0, false, false, -2, 2), v(16), l(7, -5), l(7, 5), V(3), a(2, 2, 0, false, false, -2, -2), Z()).render()
		}
		.class(`class`.isEmpty ? "bookmark-icon-view" : "bookmark-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
        .render()
	}
}

#endif
