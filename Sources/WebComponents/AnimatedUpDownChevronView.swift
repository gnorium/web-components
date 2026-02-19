#if !os(WASI)

import HTMLBuilder
import SVGBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// An animated filled chevron SVG that morphs between collapsed (v down) and
/// expanded (^ up) states via SMIL `<animate>` on the polygon `points` attribute.
/// Used for table sort indicators and group expand/collapse toggles.
///
/// To trigger the animation from JS/WASI:
/// ```js
/// let el = document.querySelector('#my-id-up-down-chevron animate');
/// el.beginElement();
/// setTimeout(() => {
///   let from = el.getAttribute('from'), to = el.getAttribute('to');
///   el.parentElement.setAttribute('points', to);
///   el.setAttribute('from', to);
///   el.setAttribute('to', from);
/// }, 210);
/// ```
public struct AnimatedUpDownChevronView: HTMLProtocol {
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
	// Collapsed chevron (v down-pointing):
	//   outer-left:  (2.5, 4.75)
	//   outer-tip:   (10, 12.25)
	//   outer-right: (17.5, 4.75)
	//   inner-right: (19, 6.25)
	//   inner-tip:   (10, 15.25)
	//   inner-left:  (1, 6.25)
	//
	// Expanded chevron (^ up-pointing):
	//   outer-left:  (2.5, 15.25)
	//   outer-tip:   (10, 7.75)
	//   outer-right: (17.5, 15.25)
	//   inner-right: (19, 13.75)
	//   inner-tip:   (10, 4.75)
	//   inner-left:  (1, 13.75)
	//
	// Each vertex moves only vertically for a smooth SMIL morph.

	static let collapsedPoints = "2.5,4.75 10,12.25 17.5,4.75 19,6.25 10,15.25 1,6.25"
	static let expandedPoints = "2.5,15.25 10,7.75 17.5,15.25 19,13.75 10,4.75 1,13.75"

	public func render(indent: Int = 0) -> String {
		let currentPoints = expanded ? Self.expandedPoints : Self.collapsedPoints
		let targetPoints = expanded ? Self.collapsedPoints : Self.expandedPoints

		return svg {
			polygon {
				animate()
					.attributeName(.points)
					.from(currentPoints)
					.to(targetPoints)
					.dur(ms(200))
					.fill(.freeze)
					.begin(.indefinite)
			}
			.points(currentPoints)
			.fill(.currentColor)
		}
		.class(`class`.isEmpty ? "animated-up-down-chevron" : "animated-up-down-chevron \(`class`)")
		.id("\(id)-up-down-chevron")
		.width(width)
		.height(height)
		.viewBox(0, 0, 20, 20)
		.xmlns("http://www.w3.org/2000/svg")
		.render(indent: indent)
	}
}

#endif
