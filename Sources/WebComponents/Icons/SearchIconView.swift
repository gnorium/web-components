#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct SearchIconView: HTML {
	public init() {}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
			.d(M(11, 3), a(8, 8, 0, true, false, 0, 16), a(8, 8, 0, false, false, 0, -16), Z())

			path()
			.d(m(21, 21), l(-4.35, -4.35))
		}
		.class("search-bar-icon-view")
		.xmlns("http://www.w3.org/2000/svg")
		.viewBox(0, 0, 24, 24)
		.fill(.none)
		.stroke(.currentColor)
		.strokeWidth(2)
		.strokeLinecap(.round)
		.strokeLinejoin(.round)
		.render(indent: indent)
	}
}

#endif
