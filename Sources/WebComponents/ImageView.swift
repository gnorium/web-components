#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Image component following Wikimedia Codex design system specification
/// A visual element used to display content in various formats and states.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/image.html
public struct ImageView: HTML {
	let src: String
	let alt: String
	let aspectRatio: AspectRatio?
	let objectPositionVal: CSSObjectPosition
	let objectFitVal: CSSObjectFit
	let imagePosition: Position?
	let imageWidth: Length?
	let imageHeight: Length?
	let loadingPriority: LoadingPriority
	let placeholderIcon: String?
	let `class`: String

	public enum AspectRatio: String, Sendable {
		case sixteenByNine = "16:9"
		case threeByTwo = "3:2"
		case fourByThree = "4:3"
		case oneByOne = "1:1"
		case threeByFour = "3:4"
		case twoByThree = "2:3"
	}

	public enum Position: String, Sendable {
		case left = "left"
		case center = "center"
		case right = "right"
	}

	public enum LoadingPriority: String, Sendable {
		case lazy = "lazy"
		case eager = "eager"
	}

	public init(
		src: String = "",
		alt: String,
		aspectRatio: AspectRatio? = nil,
		objectPositionVal: CSSObjectPosition = .center,
		objectFitVal: CSSObjectFit = .cover,
		imagePosition: Position? = nil,
		imageWidth: Length? = nil,
		imageHeight: Length? = nil,
		loadingPriority: LoadingPriority = .lazy,
		placeholderIcon: String? = nil,
		class: String = ""
	) {
		self.src = src
		self.alt = alt
		self.aspectRatio = aspectRatio
		self.objectPositionVal = objectPositionVal
		self.objectFitVal = objectFitVal
		self.imagePosition = imagePosition
		self.imageWidth = imageWidth
		self.imageHeight = imageHeight
		self.loadingPriority = loadingPriority
		self.placeholderIcon = placeholderIcon
		self.`class` = `class`
	}

	@CSSBuilder
	private func imageViewCSS(_ imagePosition: Position?, _ aspectRatio: AspectRatio?) -> [CSS] {
		display(.block)
		position(.relative)
		overflow(.hidden)
		backgroundColor(backgroundColorBase)

		if let imagePosition = imagePosition {
			switch imagePosition {
			case .left:
				marginRight(.auto)
			case .center:
				marginLeft(.auto)
				marginRight(.auto)
			case .right:
				marginLeft(.auto)
			}
		}

		if let aspectRatio = aspectRatio {
			let paddingValue: Double = {
				switch aspectRatio {
				case .sixteenByNine: return (9.0 / 16.0) * 100
				case .threeByTwo: return (2.0 / 3.0) * 100
				case .fourByThree: return (3.0 / 4.0) * 100
				case .oneByOne: return 100
				case .threeByFour: return (4.0 / 3.0) * 100
				case .twoByThree: return (3.0 / 2.0) * 100
			}
			}()
			paddingBottom(perc(paddingValue))
		}
	}

	@CSSBuilder
	private func imageImageCSS(_ objectFitVal: CSSObjectFit, _ objectPositionVal: CSSObjectPosition, _ hasAspectRatio: Bool) -> [CSS] {
		display(.block)
		width(perc(100))
		height(perc(100))

		if hasAspectRatio {
			position(.absolute)
			top(0)
			left(0)
		}

		objectFit(objectFitVal)
		objectPosition(objectPositionVal)
	}

	@CSSBuilder
	private func imagePlaceholderCSS() -> [CSS] {
		position(.absolute)
		top(0)
		left(0)
		width(perc(100))
		height(perc(100))
		display(.flex)
		alignItems(.center)
		justifyContent(.center)
		backgroundColor(backgroundColorBase)
		color(colorPlaceholder)
		fontSize(sizeIconMedium)
	}

	public func render(indent: Int = 0) -> String {
		let hasImage = !src.isEmpty
		let hasAspectRatio = aspectRatio != nil

		let imageClasses = {
			var classes = "image-view"
			if let aspectRatio = aspectRatio {
				classes += " image-aspect-\(aspectRatio.rawValue.replacingOccurrences(of: ":", with: "-"))"
			}
			if let imagePosition = imagePosition {
				classes += " image-position-\(imagePosition.rawValue)"
			}
			if !`class`.isEmpty {
				classes += " \(`class`)"
			}
			return classes
		}()

		return div {
			if hasImage {
				let imgElement = img()
					.src(src)
					.alt(alt)
					.loading(loadingPriority.rawValue)
					.class("image-image")
					.style {
						imageImageCSS(objectFitVal, objectPositionVal, hasAspectRatio)
					}

				if let imageWidth = imageWidth, let imageHeight = imageHeight {
					imgElement.width(imageWidth).height(imageHeight)
				} else if let imageWidth = imageWidth {
					imgElement.width(imageWidth)
				} else if let imageHeight = imageHeight {
					imgElement.height(imageHeight)
				} else {
					imgElement
				}
			} else {
				span {
					placeholderIcon ?? "🖼"
				}
				.class("image-placeholder")
				.ariaHidden(true)
				.style {
					imagePlaceholderCSS()
				}
			}
		}
		.class(imageClasses)
		.style {
			imageViewCSS(imagePosition, aspectRatio)
		}
		.render(indent: indent)
	}
}

#endif
