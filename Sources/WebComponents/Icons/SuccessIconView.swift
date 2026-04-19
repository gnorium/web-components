#if SERVER

import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct SuccessIconView: HTMLContent {
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
			.d(M(10, 20), a(10, 10, 0, false, true, 0, -20), a(10, 10, 0, true, true, 0, 20), m(-2, -5), l(9, -8.5), L(15.5, 5), L(8, 12), L(4.5, 8.5), L(3, 10), Z()).render()
		}
		.class(`class`.isEmpty ? "success-icon-view" : "success-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
        .render()
	}
}

#endif
