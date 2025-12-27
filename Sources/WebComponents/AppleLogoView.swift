#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct AppleLogoView: HTML {
	let `class`: String
    let width: Length
    let height: Length
    let fill: SVGPaint

    public init(
		class: String = "",
        width: Length = px(20),
        height: Length = px(20),
		fill: SVGPaint = SVGPaint(extreme)
    ) {
		self.class = `class`
        self.width = width
        self.height = height
        self.fill = fill
    }

    public func render(indent: Int = 0) -> String {
        svg {
			path()
				.d(M(12.152, 6.896), c(-0.948, 0, -2.415, -1.078, -3.96, -1.04), c(-2.04, 0.027, -3.91, 1.183, -4.961, 3.014), c(-2.117, 3.675, -0.546, 9.103, 1.519, 12.09), c(1.013, 1.454, 2.208, 3.09, 3.792, 3.039), c(1.52, -0.065, 2.09, -0.987, 3.935, -0.987), c(1.831, 0, 2.35, 0.987, 3.96, 0.948), c(1.637, -0.026, 2.676, -1.48, 3.676, -2.948), c(1.156, -1.688, 1.636, -3.325, 1.662, -3.415), c(-0.039, -0.013, -3.182, -1.221, -3.22, -4.857), c(-0.026, -3.04, 2.48, -4.494, 2.597, -4.559), c(-1.429, -2.09, -3.623, -2.324, -4.39, -2.376), c(-2, -0.156, -3.675, 1.09, -4.61, 1.09), Z(), M(15.53, 3.83), c(0.843, -1.012, 1.4, -2.427, 1.245, -3.83), c(-1.207, 0.052, -2.662, 0.805, -3.532, 1.818), c(-0.78, 0.896, -1.454, 2.338, -1.273, 3.714), c(1.338, 0.104, 2.715, -0.688, 3.559, -1.701))
				.fill(fill)
        }
		.class(`class`.isEmpty ? "apple-logo-view" : "apple-logo-view \(`class`)")
        .width(width)
        .height(height)
        .viewBox(0, 0, 24, 24)
        .xmlns("http://www.w3.org/2000/svg")
        .xmlnsXlink("http://www.w3.org/1999/xlink")
        .render(indent: indent)
    }
}

#endif
