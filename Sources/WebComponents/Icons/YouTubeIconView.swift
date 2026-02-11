#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct YouTubeIconView: HTMLProtocol {
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
			// YouTube rounded rectangle background
			path()
				.d(M(27.9727, 3.12324), C(27.6435, 1.89323, 26.6768, 0.926623, 25.4468, 0.597366), C(23.2197, 2.24288e-07, 14.285, 0, 14.285, 0), C(14.285, 0, 5.35042, 2.24288e-07, 3.12323, 0.597366), C(1.89323, 0.926623, 0.926623, 1.89323, 0.597366, 3.12324), C(2.24288e-07, 5.35042, 0, 10, 0, 10), C(0, 10, 2.24288e-07, 14.6496, 0.597366, 16.8768), C(0.926623, 18.1068, 1.89323, 19.0734, 3.12323, 19.4026), C(5.35042, 20, 14.285, 20, 14.285, 20), C(14.285, 20, 23.2197, 20, 25.4468, 19.4026), C(26.6768, 19.0734, 27.6435, 18.1068, 27.9727, 16.8768), C(28.5701, 14.6496, 28.5701, 10, 28.5701, 10), C(28.5701, 10, 28.5677, 5.35042, 27.9727, 3.12324), Z())
				.fill(monochrome ? fill : SVGPaint(hex(0xFF0000)))

			// Play button
			path()
				.d(M(11.4253, 14.2854), L(18.8477, 10.0004), L(11.4253, 5.71533), Z())
				.fill(monochrome ? SVGPaint(colorInverted) : SVGPaint(.white))
		}
		.class(`class`.isEmpty ? "youtube-icon-view" : "youtube-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 28.57, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.render(indent: indent)
	}
}

#endif
