#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct LogOutIconView: HTMLProtocol {
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
				.d(M(3, 3), h(8), V(1), H(3), a(2, 2, 0, false, false, -2, 2), v(14), a(2, 2, 0, false, false, 2, 2), h(8), v(-2), H(3), Z())

			path()
				.d(M(13, 5), v(4), H(5), v(2), h(8), v(4), l(6, -5), Z())
		}
		.class(`class`.isEmpty ? "log-out-icon-view" : "log-out-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
