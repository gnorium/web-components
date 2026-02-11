#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct ChevronDownIconView: HTMLProtocol {
	let width: Length
	let height: Length
	let `class`: String

	public init(
		width: Length = px(12),
		height: Length = px(12),
		class: String = ""
	) {
		self.width = width
		self.height = height
		self.class = `class`
	}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(M(6, 9), L(1, 4), h(10), Z())
		}
		.class(`class`.isEmpty ? "chevron-down-icon-view" : "chevron-down-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 12, 12)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.ariaHidden(true)
		.render(indent: indent)
	}
}

#endif
