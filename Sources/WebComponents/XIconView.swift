#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct XIconView: HTML {
	let `class`: String
	let width: Length
	let height: Length
	let fill: SVGPaint
	let monochrome: Bool

	public init(
		class: String = "",
		width: Length = px(20),
		height: Length = px(20),
		fill: SVGPaint = SVGPaint(colorBase),
		monochrome: Bool = false
	) {
		self.class = `class`
		self.width = width
		self.height = height
		self.fill = fill
		self.monochrome = monochrome
	}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(M(236, 0), h(46), l(-101, 115), l(118, 156), h(-92.6), l(-72.5, -94.8), l(-83, 94.8), h(-46), l(107, -123), l(-113, -148), h(94.9), l(65.5, 86.6), z(), m(-16.1, 244), h(25.5), l(-165, -218), h(-27.4), z())
				.fill(fill)
		}
		.class(`class`.isEmpty ? "x-icon-view" : "x-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 300, 271)
		.xmlns("http://www.w3.org/2000/svg")
		.xmlnsXlink("http://www.w3.org/1999/xlink")
		.render(indent: indent)
	}
}

#endif
