#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct HistoryIconView: HTMLProtocol {
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
				.d(M(9, 6), v(5), h(0.06), l(2.48, 2.47), l(1.41, -1.41), L(11, 10.11), V(6), Z())

			path()
				.d(M(10, 1), a(9, 9, 0, false, false, -7.85, 13.35), L(0.5, 16), H(6), v(-5.5), l(-2.38, 2.38), A(7, 7, 0, true, true, 10, 17), v(2), a(9, 9, 0, false, false, 0, -18))
		}
		.class(`class`.isEmpty ? "history-icon-view" : "history-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
