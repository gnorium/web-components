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

#if os(WASI)

import WebAPIs
import EmbeddedSwiftUtilities

/// WASI factory for creating AnimatedRightDownChevronView DOM elements dynamically.
public enum AnimatedRightDownChevronFactory {
	/// The SVG innerHTML for the down-pointing chevron polygon (20×20 viewBox).
	/// CSS-rotated -90deg for collapsed (right-pointing), 0deg for expanded (down-pointing).
	private static let chevronSVGContent = "<polygon points=\"2.5,4.75 10,12.25 17.5,4.75 19,6.25 10,15.25 1,6.25\" fill=\"currentColor\"/>"

	/// Creates an animated chevron SVG element matching the server-rendered AnimatedRightDownChevronView.
	/// - Parameters:
	///   - id: Base ID (element gets id="\(id)-chevron")
	///   - expanded: Initial state (false = right-pointing >, true = down-pointing v)
	/// - Returns: A wrapper element containing the SVG (use innerHTML injection since createElementNS is complex in WASI)
	public static func createElement(id: String, expanded: Bool = false) -> Element {
		let wrapper = document.createElement("span")
		let rotation = expanded ? "rotate(0deg)" : "rotate(-90deg)"
		let expandedStr = expanded ? "true" : "false"
		wrapper.innerHTML = stringConcat(
			"<svg class=\"animated-chevron\" id=\"", id, "-chevron\"",
			" width=\"20\" height=\"20\" viewBox=\"0 0 20 20\"",
			" xmlns=\"http://www.w3.org/2000/svg\"",
			" data-expanded=\"", expandedStr, "\"",
			" fill=\"currentColor\"",
			" style=\"transition:transform 200ms ease;transform:", rotation, ";transform-origin:50% 50%\">",
			chevronSVGContent,
			"</svg>"
		)
		// Return the SVG element itself (unwrap from span)
		if let svg = wrapper.firstElementChild {
			return svg
		}
		return wrapper
	}
}

#endif
