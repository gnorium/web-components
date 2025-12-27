#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// InfoChip component following Wikimedia Codex design system specification
/// A non-interactive indicator that provides information and/or conveys a status.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/info-chip.html
public struct InfoChipView: HTML {
	let status: Status
	let icon: String?
	let content: [HTML]
	let `class`: String

	public enum Status: String, Sendable {
		case notice
		case warning
		case error
		case success
	}

	public init(
		status: Status = .notice,
		icon: String? = nil,
		class: String = "",
		@HTMLBuilder content: () -> [HTML]
	) {
		self.status = status
		self.icon = icon
		self.content = content()
		self.`class` = `class`
	}

	@CSSBuilder
	private func infoChipViewCSS(_ status: Status) -> [CSS] {
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

		switch status {
		case .notice:
			color(colorNotice)
			backgroundColor(backgroundColorNoticeSubtle)
			border(borderWidthBase, .solid, borderColorNotice)
		case .warning:
			color(colorWarning)
			backgroundColor(backgroundColorWarningSubtle)
			border(borderWidthBase, .solid, borderColorWarning)
		case .error:
			color(colorError)
			backgroundColor(backgroundColorErrorSubtle)
			border(borderWidthBase, .solid, borderColorError)
		case .success:
			color(colorSuccess)
			backgroundColor(backgroundColorSuccessSubtle)
			border(borderWidthBase, .solid, borderColorSuccess)
		}
	}

	@CSSBuilder
	private func infoChipIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(sizeIconSmall)
		height(sizeIconSmall)
		flexShrink(0)
		fontSize(fontSizeSmall14)
	}

	@CSSBuilder
	private func infoChipTextCSS() -> [CSS] {
		flex(1)
		minWidth(0)
		textOverflow(.ellipsis)
		overflow(.hidden)
		whiteSpace(.nowrap)
	}

	public func render(indent: Int = 0) -> String {
		let defaultIcon: String = {
			switch status {
			case .notice: return "ℹ"
			case .warning: return "⚠"
			case .error: return "✖"
			case .success: return "✓"
			}
		}()

		let shouldShowIcon = icon != nil || status != .notice

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
		.class(`class`.isEmpty ? "info-chip-view info-chip-\(status.rawValue)" : "info-chip-view info-chip-\(status.rawValue) \(`class`)")
		.style {
			infoChipViewCSS(status)
		}
		.render(indent: indent)
	}
}

#endif
