#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct LinkedInIconView: HTMLProtocol {
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
			// Background rounded square
			path()
				.d(M(8, 72), L(64, 72), C(68.418278, 72, 72, 68.418278, 72, 64), L(72, 8), C(72, 3.581722, 68.418278, -8.11624501e-16, 64, 0), L(8, 0), C(3.581722, 8.11624501e-16, -5.41083001e-16, 3.581722, 0, 8), L(0, 64), C(5.41083001e-16, 68.418278, 3.581722, 72, 8, 72), Z())
				.fill(monochrome ? fill : SVGPaint(hex(0x007EBB)))

			// LinkedIn "in" mark
			path()
				.d(M(62, 62), L(51.315625, 62), L(51.315625, 43.8021149), C(51.315625, 38.8127542, 49.4197917, 36.0245323, 45.4707031, 36.0245323), C(41.1746094, 36.0245323, 38.9300781, 38.9261103, 38.9300781, 43.8021149), L(38.9300781, 62), L(28.6333333, 62), L(28.6333333, 27.3333333), L(38.9300781, 27.3333333), L(38.9300781, 32.0029283), C(38.9300781, 32.0029283, 42.0260417, 26.2742151, 49.3825521, 26.2742151), C(56.7356771, 26.2742151, 62, 30.7644705, 62, 40.051212), L(62, 62), Z(), M(16.349349, 22.7940133), C(12.8420573, 22.7940133, 10, 19.9296567, 10, 16.3970067), C(10, 12.8643566, 12.8420573, 10, 16.349349, 10), C(19.8566406, 10, 22.6970052, 12.8643566, 22.6970052, 16.3970067), C(22.6970052, 19.9296567, 19.8566406, 22.7940133, 16.349349, 22.7940133), Z(), M(11.0325521, 62), L(21.769401, 62), L(21.769401, 27.3333333), L(11.0325521, 27.3333333), L(11.0325521, 62), Z())
				.fill(monochrome ? SVGPaint(colorInverted) : SVGPaint(.white))
		}
		.class(`class`.isEmpty ? "linkedin-icon-view" : "linkedin-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 72, 72)
		.xmlns("http://www.w3.org/2000/svg")
		.xmlnsXlink("http://www.w3.org/1999/xlink")
		.render(indent: indent)
	}
}

#endif
