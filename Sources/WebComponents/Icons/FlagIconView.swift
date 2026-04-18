#if !os(WASI)

import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct FlagIconView: HTMLContent {
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

	public func toNode() -> DOMNode {
		svg {
			path()
				.d(M(17, 6), L(3, 1), v(18), h(2), v(-6.87), Z())
		}
		.class(`class`.isEmpty ? "flag-icon-view" : "flag-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
	}
}

#endif
