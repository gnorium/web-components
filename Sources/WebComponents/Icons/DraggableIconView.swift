#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct DraggableIconView: HTMLProtocol {
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
				.d(M(2, 11), h(16), v(2), H(2), Z(), m(0, -4), h(16), v(2), H(2), Z(), m(11, 8), H(7), l(3, 3), Z(), M(7, 5), h(6), l(-3, -3), Z())
		}
		.class(`class`.isEmpty ? "draggable-icon-view" : "draggable-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
