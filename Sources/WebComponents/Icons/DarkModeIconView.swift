#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct DarkModeIconView: HTML {
	let `class`: String
	let width: Length
	let height: Length
	let stroke: SVGPaint
	let strokeWidth: Length

	public init(
		class: String = "",
		width: Length = px(16),
		height: Length = px(16),
		stroke: SVGPaint = .currentColor,
		strokeWidth: Length = 1.5
	) {
		self.class = `class`
		self.width = width
		self.height = height
		self.stroke = stroke
		self.strokeWidth = strokeWidth
	}

	public func render(indent: Int = 0) -> String {
		svg {
			path()
				.d(M(8, 2), a(4, 4, 0, false, false, 6, 6), a(6, 6, 0, true, true, -6, -6), Z())
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)
		}
		.class(`class`.isEmpty ? "dark-mode-icon-view" : "dark-mode-icon-view \(`class`)")
		.xmlns("http://www.w3.org/2000/svg")
		.width(width)
		.height(height)
		.viewBox(0, 0, 16, 16)
		.fill(.none)
		.stroke(stroke)
		.render(indent: indent)
	}
}

#endif
