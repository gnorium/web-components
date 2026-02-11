#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct EditIconView: HTMLProtocol {
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

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(m(16.77, 8), l(1.94, -2), a(1, 1, 0, false, false, 0, -1.41), l(-3.34, -3.3), a(1, 1, 0, false, false, -1.41, 0), L(12, 3.23), Z(), M(1, 14.25), V(19), h(4.75), l(9.96, -9.96), l(-4.75, -4.75), Z())
		}
		.class(`class`.isEmpty ? "edit-icon-view" : "edit-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
