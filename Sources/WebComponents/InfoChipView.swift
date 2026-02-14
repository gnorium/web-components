#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// InfoChip — a non-interactive indicator that provides information and/or conveys a status.
public struct InfoChipView: HTMLProtocol {
	let chipColor: InfoChipColor
	let weight: Weight
	let icon: String?
	let content: [HTMLProtocol]
	let `class`: String

	/// Apple HIG color for the chip
	public enum InfoChipColor: String, Sendable {
		case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray

		// Legacy aliases
		public static let notice = InfoChipColor.gray
		public static let warning = InfoChipColor.orange
		public static let error = InfoChipColor.red
		public static let success = InfoChipColor.green
	}

	/// Legacy alias
	public typealias Status = InfoChipColor

	/// Visual weight of the chip
	public enum Weight: String, Sendable {
		/// Light background, colored text, border (default)
		case subtle
		/// Filled background, inverted text, no border
		case solid
	}

	public init(
		chipColor: InfoChipColor = .gray,
		weight: Weight = .subtle,
		icon: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.chipColor = chipColor
		self.weight = weight
		self.icon = icon
		self.content = content()
		self.`class` = `class`
	}

	/// Legacy init
	public init(
		color: InfoChipColor,
		weight: Weight = .subtle,
		icon: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.chipColor = color
		self.weight = weight
		self.icon = icon
		self.content = content()
		self.`class` = `class`
	}

	/// Legacy init
	public init(
		status: InfoChipColor,
		weight: Weight = .subtle,
		icon: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTMLProtocol]
	) {
		self.chipColor = status
		self.weight = weight
		self.icon = icon
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func infoChipViewCSS(_ chipColor: InfoChipColor, _ weight: Weight) -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		gap(spacing4)
		maxHeight(maxHeightChip)
		padding(spacing4, spacing8)
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		fontWeight(fontWeightSemiBold)
		lineHeight(lineHeightXSmall20)
		borderRadius(borderRadiusPill)
		whiteSpace(.nowrap)
		textOverflow(.ellipsis)
		overflow(.hidden)

		switch (chipColor, weight) {
		case (.red, .subtle):
			color(colorRed)
			backgroundColor(backgroundColorRedSubtle)
			border(borderWidthBase, .solid, borderColorRed)
		case (.red, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorRed)
		case (.orange, .subtle):
			color(colorOrange)
			backgroundColor(backgroundColorOrangeSubtle)
			border(borderWidthBase, .solid, borderColorOrange)
		case (.orange, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorOrange)
		case (.yellow, .subtle):
			color(colorYellow)
			backgroundColor(backgroundColorYellowSubtle)
			border(borderWidthBase, .solid, borderColorYellow)
		case (.yellow, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorYellow)
		case (.green, .subtle):
			color(colorGreen)
			backgroundColor(backgroundColorGreenSubtle)
			border(borderWidthBase, .solid, borderColorGreen)
		case (.green, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorGreen)
		case (.mint, .subtle):
			color(colorMint)
			backgroundColor(backgroundColorMintSubtle)
			border(borderWidthBase, .solid, borderColorMint)
		case (.mint, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorMint)
		case (.teal, .subtle):
			color(colorTeal)
			backgroundColor(backgroundColorTealSubtle)
			border(borderWidthBase, .solid, borderColorTeal)
		case (.teal, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorTeal)
		case (.cyan, .subtle):
			color(colorCyan)
			backgroundColor(backgroundColorCyanSubtle)
			border(borderWidthBase, .solid, borderColorCyan)
		case (.cyan, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorCyan)
		case (.blue, .subtle):
			color(colorBlue)
			backgroundColor(backgroundColorBlueSubtle)
			border(borderWidthBase, .solid, borderColorBlue)
		case (.blue, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorBlue)
		case (.indigo, .subtle):
			color(colorIndigo)
			backgroundColor(backgroundColorIndigoSubtle)
			border(borderWidthBase, .solid, borderColorIndigo)
		case (.indigo, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorIndigo)
		case (.purple, .subtle):
			color(colorPurple)
			backgroundColor(backgroundColorPurpleSubtle)
			border(borderWidthBase, .solid, borderColorPurple)
		case (.purple, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorPurple)
		case (.pink, .subtle):
			color(colorPink)
			backgroundColor(backgroundColorPinkSubtle)
			border(borderWidthBase, .solid, borderColorPink)
		case (.pink, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorPink)
		case (.brown, .subtle):
			color(colorBrown)
			backgroundColor(backgroundColorBrownSubtle)
			border(borderWidthBase, .solid, borderColorBrown)
		case (.brown, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorBrown)
		case (.gray, .subtle):
			color(colorGray)
			backgroundColor(backgroundColorGraySubtle)
			border(borderWidthBase, .solid, borderColorGray)
		case (.gray, .solid):
			color(colorInvertedFixed)
			backgroundColor(colorGray)
		}
	}

	@CSSBuilder
	private func infoChipIconCSS() -> [CSSProtocol] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconSmall)
		height(sizeIconSmall)
		flexShrink(0)
		fontSize(fontSizeSmall14)
	}

	@CSSBuilder
	private func infoChipTextCSS() -> [CSSProtocol] {
		flex(1)
		minWidth(0)
		textOverflow(.ellipsis)
		overflow(.hidden)
		whiteSpace(.nowrap)
	}

	public func render(indent: Int = 0) -> String {
		let defaultIcon: String = {
			switch chipColor {
			case .gray: return "ℹ"
			case .orange: return "⚠"
			case .red: return "✗"
			case .mint: return "✓"
			case .yellow, .green, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown: return "●"
			}
		}()

		let shouldShowIcon = icon != nil || chipColor != .gray

		return span {
			if shouldShowIcon {
				span {
					icon ?? defaultIcon
				}
				.class("info-chip-icon")
				.ariaHidden(true)
				.style {
					infoChipIconCSS()
				}
			}

			span {
				content
			}
			.class("info-chip-text")
			.style {
				infoChipTextCSS()
			}
		}
		.class(`class`.isEmpty ? "info-chip-view info-chip-\(chipColor.rawValue) info-chip-\(weight.rawValue)" : "info-chip-view info-chip-\(chipColor.rawValue) info-chip-\(weight.rawValue) \(`class`)")
		.style {
			infoChipViewCSS(chipColor, weight)
		}
		.render(indent: indent)
	}
}

#endif
