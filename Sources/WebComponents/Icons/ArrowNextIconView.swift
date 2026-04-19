#if SERVER

import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct ArrowNextIconView: HTMLContent {
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
				.d(M(8.59, 3.42), L(14.17, 9), H(2), v(2), h(12.17), l(-5.58, 5.59), L(10, 18), l(8, -8), l(-8, -8), Z()).render()
		}
		.class(`class`.isEmpty ? "arrow-next-icon-view" : "arrow-next-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
        .render()
	}
}

#endif
