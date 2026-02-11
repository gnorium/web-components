#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CloseIconView: HTMLProtocol {
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
				.d(m(4.34, 2.93), l(12.73, 12.73), l(-1.41, 1.41), L(2.93, 4.35), Z())

			path()
				.d(M(17.07, 4.34), L(4.34, 17.07), l(-1.41, -1.41), L(15.66, 2.93), Z())
		}
		.class(`class`.isEmpty ? "close-icon-view" : "close-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
