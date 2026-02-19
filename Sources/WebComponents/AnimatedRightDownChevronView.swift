#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// An animated chevron SVG that rotates between collapsed (> right) and
/// expanded (v down) states via CSS `transform: rotate()` transition.
///
/// Renders a down-pointing chevron polygon, then CSS-rotates it -90deg
/// for the collapsed (right-pointing) state. Expanding transitions to
/// 0deg (down-pointing). The transition is purely CSS — no SMIL needed.
///
/// To trigger the animation from JS/WASI:
/// ```js
/// let svg = document.querySelector('#my-id-chevron');
/// svg.style.transform = svg.dataset.expanded === 'true'
///     ? 'rotate(-90deg)' : 'rotate(0deg)';
/// svg.dataset.expanded = svg.dataset.expanded === 'true' ? 'false' : 'true';
/// ```
public struct AnimatedRightDownChevronView: HTMLProtocol {
	let id: String
	let expanded: Bool
	let width: Length
	let height: Length
	let `class`: String

	public init(
		id: String,
		expanded: Bool = false,
		width: Length = px(20),
		height: Length = px(20),
		class: String = ""
	) {
		self.id = id
		self.expanded = expanded
		self.width = width
		self.height = height
		self.class = `class`
	}

	// MARK: - Chevron Geometry (20x20 viewBox)
	//
	// Down-pointing filled chevron (v shape):
	//   1: outer-left  (2.5, 4.75)
	//   2: outer-tip   (10, 12.25)
	//   3: outer-right (17.5, 4.75)
	//   4: inner-right (19, 6.25)
	//   5: inner-tip   (10, 15.25)
	//   6: inner-left  (1, 6.25)
	//
	// This shape is CSS-rotated -90deg to appear as a right-pointing chevron (>),
	// then transitions to 0deg (down-pointing v) when expanded.

	static let chevronPoints = "2.5,4.75 10,12.25 17.5,4.75 19,6.25 10,15.25 1,6.25"

	public func render(indent: Int = 0) -> String {
		return svg {
			polygon()
			.points(Self.chevronPoints)
			.fill(.currentColor)
		}
		.class(`class`.isEmpty ? "animated-chevron" : "animated-chevron \(`class`)")
		.id("\(id)-chevron")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.data("expanded", expanded ? "true" : "false")
		.style {
			transition(.transform, ms(200), .ease)
			transform(rotate(expanded ? deg(0) : deg(-90)))
			transformOrigin(perc(50))
		}
		.render(indent: indent)
	}
}

#endif
