#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct GitHubIconView: HTML {
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
				.fillRule(.evenodd)
				.clipRule(.evenodd)
				.d(M(512, 0), C(229.12, 0, 0, 229.12, 0, 512), C(0, 738.56, 146.56, 930.56, 350.08, 998.4), C(375.68, 1002.24, 385.28, 986.88, 385.28, 973.44), C(385.28, 961.28, 384.64, 921.6, 384.64, 878.08), C(256, 902.4, 222.72, 846.72, 212.48, 817.92), C(206.72, 803.2, 181.76, 757.76, 160, 746.56), C(142.08, 736, 116.48, 712.32, 159.36, 711.68), C(199.68, 711.04, 228.48, 748.8, 238.08, 764.16), C(284.16, 841.6, 357.76, 820.16, 387.2, 806.4), C(391.68, 773.12, 405.12, 750.72, 419.84, 737.92), C(306.24, 725.12, 186.88, 680.96, 186.88, 485.12), C(186.88, 429.44, 206.72, 383.36, 239.36, 347.52), C(234.24, 334.72, 216.32, 282.24, 244.48, 211.84), C(244.48, 211.84, 287.36, 198.4, 385.28, 264.32), C(426.24, 252.8, 469.76, 247.04, 513.28, 247.04), C(556.8, 247.04, 600.32, 252.8, 641.28, 264.32), C(739.2, 197.76, 782.08, 211.84, 782.08, 211.84), C(810.24, 282.24, 792.32, 334.72, 787.2, 347.52), C(819.84, 383.36, 839.68, 428.8, 839.68, 485.12), C(839.68, 681.6, 720, 725.12, 606.08, 737.92), C(624.64, 753.92, 640.64, 784.64, 640.64, 832.64), C(640.64, 901.12, 640, 956.16, 640, 973.44), C(640, 986.88, 649.6, 1002.88, 675.2, 998.4), C(877.44, 930.56, 1024, 738.56, 1024, 512), C(1024, 229.12, 794.88, 0, 512, 0), Z())
				.fill(fill)
		}
		.class(`class`.isEmpty ? "github-icon-view" : "github-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 1024, 1024)
		.xmlns("http://www.w3.org/2000/svg")
		.xmlnsXlink("http://www.w3.org/1999/xlink")
		.render(indent: indent)
	}
}

#endif
