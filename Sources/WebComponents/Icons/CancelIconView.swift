#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CancelIconView: HTMLProtocol {
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
				.d(M(10, 0), a(10, 10, 0, true, false, 10, 10), A(10, 10, 0, false, false, 10, 0), M(2, 10), a(8, 8, 0, false, true, 1.69, -4.9), L(14.9, 16.31), A(8, 8, 0, false, true, 2, 10), m(14.31, 4.9), L(5.1, 3.69), A(8, 8, 0, false, true, 16.31, 14.9))
		}
		.class(`class`.isEmpty ? "cancel-icon-view" : "cancel-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
