#if !os(WASI)

import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import SVGBuilder
import WebTypes

public struct UserAvatarIconView: HTMLContent {
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
				.d(M(10, 11), c(-5.92, 0, -8, 3, -8, 5), v(3), h(16), v(-3), c(0, -2, -2.08, -5, -8, -5))

			circle()
				.cx(10)
				.cy(5.5)
				.r(4.5)
		}
		.class(`class`.isEmpty ? "user-avatar-icon-view" : "user-avatar-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
	}
}

#endif
