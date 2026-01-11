#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct ThreadsIconView: HTML {
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
				.d(M(804.6, 960), H(155.4), C(69.58, 960, 0, 890.42, 0, 804.6), V(155.4), C(0, 69.58, 69.58, 0, 155.4, 0), h(649.2), C(890.42, 0, 960, 69.58, 960, 155.4), v(649.2), c(0, 85.82, -69.58, 155.4, -155.4, 155.4), z())
				.fill(monochrome ? fill : SVGPaint(.black))

			// Threads icon
			path()
				.d(M(404.63, 392.13), c(-11.92, -7.93, -51.53, -35.49, -51.53, -35.49), c(33.4, -47.88, 77.46, -66.52, 138.36, -66.52), c(43.07, 0, 79.64, 14.52, 105.75, 42), c(26.12, 27.49, 41.02, 66.8, 44.41, 117.07), c(14.48, 6.07, 27.85, 13.22, 39.99, 21.4), c(48.96, 33, 75.92, 82.34, 75.92, 138.91), c(0, 120.23, -98.34, 224.67, -276.35, 224.67), c(-152.84, 0, -311.63, -89.11, -311.63, -354.45), c(0, -263.83, 153.81, -353.92, 311.2, -353.92), c(72.68, 0, 243.16, 10.76, 307.27, 222.94), l(-60.12, 15.63), C(678.33, 213.2, 574.4, 189.14, 479.11, 189.14), c(-157.52, 0, -246.62, 96.13, -246.62, 300.65), c(0, 183.38, 99.59, 280.8, 248.71, 280.8), c(122.68, 0, 214.15, -63.9, 214.15, -157.44), c(0, -63.66, -53.37, -94.14, -56.1, -94.14), c(-10.42, 54.62, -38.36, 146.5, -161.01, 146.5), c(-71.46, 0, -133.07, -49.47, -133.07, -114.29), c(0, -92.56, 87.61, -126.06, 156.8, -126.06), c(25.91, 0, 57.18, 1.75, 73.46, 5.07), c(0, -28.21, -23.81, -76.49, -83.96, -76.49), c(-55.15, -0.01, -69.14, 17.92, -86.84, 38.39), z(), m(105.8, 96.25), c(-90.13, 0, -101.79, 38.51, -101.79, 62.7), c(0, 38.86, 46.07, 51.74, 70.65, 51.74), c(45.06, 0, 91.35, -12.52, 98.63, -107.31), c(-22.85, -5.14, -39.88, -7.13, -67.49, -7.13), z())
				.fill(monochrome ? SVGPaint(colorInverted) : SVGPaint(.white))
		}
		.class(`class`.isEmpty ? "threads-icon-view" : "threads-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 960, 960)
		.xmlns("http://www.w3.org/2000/svg")
		.xmlnsXlink("http://www.w3.org/1999/xlink")
		.render(indent: indent)
	}
}

#endif
