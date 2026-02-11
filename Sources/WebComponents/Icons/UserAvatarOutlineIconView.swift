#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct UserAvatarOutlineIconView: HTMLProtocol {
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
			path()
				.d(M(10, 8), c(1.7, 0, 3.06, -1.35, 3.06, -3), S(11.7, 2, 10, 2), S(6.94, 3.35, 6.94, 5), S(8.3, 8, 10, 8), m(0, 2), c(-2.8, 0, -5.06, -2.24, -5.06, -5), S(7.2, 0, 10, 0), s(5.06, 2.24, 5.06, 5), s(-2.26, 5, -5.06, 5), m(-7, 8), h(14), v(-1.33), c(0, -1.75, -2.31, -3.56, -7, -3.56), s(-7, 1.81, -7, 3.56), Z(), m(7, -6.89), c(6.66, 0, 9, 3.33, 9, 5.56), V(20), H(1), v(-3.33), c(0, -2.23, 2.34, -5.56, 9, -5.56))
		}
		.class(`class`.isEmpty ? "user-avatar-outline-icon-view" : "user-avatar-outline-icon-view \(`class`)")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.fill(.currentColor)
		.render(indent: indent)
	}
}

#endif
