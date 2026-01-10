#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct SettingsIconView: HTML {
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
			g {
				path()
					.id("a")
					.d(M(1.5, -10), h(-3), l(-1, 6.5), h(5), m(0, 7), h(-5), l(1, 6.5), h(3))

				use()
					.xlinkHref("#a")
					.transform(rotate(45))

				use()
					.xlinkHref("#a")
					.transform(rotate(90))

				use()
					.xlinkHref("#a")
					.transform(rotate(135))
			}
			.xmlnsXlink("http://www.w3.org/1999/xlink")
			.transform(translate(10, 10))

			path()
				.d(M(10, 2.5), a(7.5, 7.5, 0, false, false, 0, 15), a(7.5, 7.5, 0, false, false, 0, -15), v(4), a(3.5, 3.5, 0, false, true, 0, 7), a(3.5, 3.5, 0, false, true, 0, -7))
		}
		.class(`class`.isEmpty ? "settings-icon-view" : "settings-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
