#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct LightModeIconView: HTML {
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
            defs {
                clipPath {
					rect().width(16).height(16).fill(.white)
                }
                .id("clip")
            }

            g {
                path()
				.d(M(8, 1.11133), V(2.00022))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(12.8711, 3.12891), L(12.2427, 3.75735))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(14.8889, 8), H(14))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(12.8711, 12.8711), L(12.2427, 12.2427))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(8, 14.8889), V(14))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(3.12891, 12.8711), L(3.75735, 12.2427))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(1.11133, 8), H(2.00022))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(3.12891, 3.12891), L(3.75735, 3.75735))
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)

                path()
				.d(M(8.00043, 11.7782), C(10.0868, 11.7782, 11.7782, 10.0868, 11.7782, 8.00043), C(11.7782, 5.91402, 10.0868, 4.22266, 8.00043, 4.22266), C(5.91402, 4.22266, 4.22266, 5.91402, 4.22266, 8.00043), C(4.22266, 10.0868, 5.91402, 11.7782, 8.00043, 11.7782), Z())
				.strokeWidth(strokeWidth)
				.strokeLinecap(.round)
				.strokeLinejoin(.round)
            }
            .clipPath(url("#clip"))
        }
		.class(`class`.isEmpty ? "light-mode-icon-view" : "light-mode-icon-view \(`class`)")
        .width(width)
        .height(height)
        .viewBox(0, 0, 16, 16)
        .fill(.none)
        .stroke(stroke)
        .xmlns("http://www.w3.org/2000/svg")
        .render(indent: indent)
    }
}

#endif
