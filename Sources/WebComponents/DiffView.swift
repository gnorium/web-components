#if !os(WASI)

import CSSBuilder
import DesignTokens
import DiffEngine
import HTMLBuilder
import WebTypes

/// Inline diff view with two levels of highlighting:
/// - Line-level: subtle red/green background on entire changed lines
/// - Word-level: strong red/green highlight on specific changed words
public struct DiffView: HTMLProtocol {
	let segments: [DiffSegment]
	let stats: DiffStats
	let `class`: String

	public struct DiffStats: Sendable {
		public let inserted: Int
		public let deleted: Int
		public let unchanged: Int

		public var hasChanges: Bool { inserted > 0 || deleted > 0 }
	}

	public init(old: String, new: String, class: String = "") {
		self.segments = DiffEngine.diff(old: old, new: new)
		self.`class` = `class`

		var inserted = 0
		var deleted = 0
		var unchanged = 0
		for segment in segments {
			switch segment {
			case .inserted(let t): inserted += t.count
			case .deleted(let t): deleted += t.count
			case .unchanged(let t), .deletedContext(let t), .insertedContext(let t):
				unchanged += t.count
			}
		}
		self.stats = DiffStats(inserted: inserted, deleted: deleted, unchanged: unchanged)
	}

	public func render(indent: Int = 0) -> String {
		let rootClass = `class`.isEmpty
			? "diff-view"
			: "diff-view \(`class`)"

		return div {
			// Stats bar
			if stats.hasChanges {
				div {
					if stats.deleted > 0 {
						span { "\u{2212}\(stats.deleted)" }
						.class("diff-stat-deleted")
						.style { diffStatDeletedCSS() }
					}

					if stats.inserted > 0 {
						span { "+\(stats.inserted)" }
						.class("diff-stat-inserted")
						.style { diffStatInsertedCSS() }
					}

					span { "\(stats.deleted + stats.inserted) chars changed" }
					.style { diffStatSummaryCSS() }
				}
				.class("diff-stats")
				.style { diffStatsCSS() }
			}

			// Legend
			div {
				div {
					span {}
					.class("diff-legend-swatch-deleted")
					.style { diffLegendSwatchDeletedCSS() }

					span { "Removed" }
					.style { diffLegendLabelCSS() }
				}
				.style { diffLegendItemCSS() }

				div {
					span {}
					.class("diff-legend-swatch-inserted")
					.style { diffLegendSwatchInsertedCSS() }

					span { "Added" }
					.style { diffLegendLabelCSS() }
				}
				.style { diffLegendItemCSS() }
			}
			.class("diff-legend")
			.style { diffLegendCSS() }

			// Diff content
			if stats.hasChanges {
				code {
					for segment in segments {
						switch segment {
						case .unchanged(let text):
							text
						case .deleted(let text):
							del(text)
							.class("diff-deleted")
							.style { diffDeletedCSS() }
						case .inserted(let text):
							ins(text)
							.class("diff-inserted")
							.style { diffInsertedCSS() }
						case .deletedContext(let text):
							span { text }
							.class("diff-deleted-context")
							.style { diffDeletedContextCSS() }
						case .insertedContext(let text):
							span { text }
							.class("diff-inserted-context")
							.style { diffInsertedContextCSS() }
						}
					}
				}
				.class("diff-content")
				.style { diffContentCSS() }
			} else {
				div {
					p { "No changes between these versions." }
					.style { diffEmptyCSS() }
				}
				.class("diff-empty-box")
				.style { diffEmptyBoxCSS() }
			}
		}
		.class(rootClass)
		.style { diffViewCSS() }
		.render(indent: indent)
	}

	// MARK: - Styles

	@CSSBuilder
	private func diffViewCSS() -> [CSSProtocol] {
		display(.flex)
		flexDirection(.column)
		gap(spacing16)
	}

	@CSSBuilder
	private func diffStatsCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing12)
		fontFamily(typographyFontMono)
		fontSize(fontSizeSmall14)
	}

	@CSSBuilder
	private func diffStatDeletedCSS() -> [CSSProtocol] {
		color(colorRed)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func diffStatInsertedCSS() -> [CSSProtocol] {
		color(colorGreen)
		fontWeight(fontWeightBold)
	}

	@CSSBuilder
	private func diffStatSummaryCSS() -> [CSSProtocol] {
		color(colorSubtle)
		fontWeight(fontWeightNormal)
	}

	@CSSBuilder
	private func diffLegendCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing16)
	}

	@CSSBuilder
	private func diffLegendItemCSS() -> [CSSProtocol] {
		display(.flex)
		alignItems(.center)
		gap(spacing4)
	}

	@CSSBuilder
	private func diffLegendSwatchDeletedCSS() -> [CSSProtocol] {
		display(.inlineBlock)
		width(px(14))
		height(px(14))
		borderRadius(borderRadiusMinimal)
		backgroundColor(colorRed)
	}

	@CSSBuilder
	private func diffLegendSwatchInsertedCSS() -> [CSSProtocol] {
		display(.inlineBlock)
		width(px(14))
		height(px(14))
		borderRadius(borderRadiusMinimal)
		backgroundColor(colorGreen)
	}

	@CSSBuilder
	private func diffLegendLabelCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeXSmall12)
		color(colorSubtle)
	}

	@CSSBuilder
	private func diffContentCSS() -> [CSSProtocol] {
		display(.block)
		fontFamily(typographyFontMono)
		fontSize(fontSizeSmall14)
		lineHeight(1.6)
		color(colorBase)
		backgroundColor(backgroundColorNeutralSubtle)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
		padding(spacing16)
		margin(0)
		whiteSpace(.preWrap)
		wordBreak(.breakWord)
		overflow(.auto)
	}

	// Word-level: strong highlight on specific changed words
	@CSSBuilder
	private func diffDeletedCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorRed)
		color(colorInvertedFixed)
		textDecoration(.none)
		borderRadius(borderRadiusMinimal)
		padding(0, spacing4)
	}

	@CSSBuilder
	private func diffInsertedCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorGreen)
		color(colorInvertedFixed)
		textDecoration(.none)
		borderRadius(borderRadiusMinimal)
		padding(0, spacing4)
	}

	// Line-level: subtle background on entire changed lines
	@CSSBuilder
	private func diffDeletedContextCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorRedSubtle)
	}

	@CSSBuilder
	private func diffInsertedContextCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorGreenSubtle)
	}

	@CSSBuilder
	private func diffEmptyBoxCSS() -> [CSSProtocol] {
		backgroundColor(backgroundColorNeutralSubtle)
		border(borderWidthBase, .solid, borderColorSubtle)
		borderRadius(borderRadiusBase)
	}

	@CSSBuilder
	private func diffEmptyCSS() -> [CSSProtocol] {
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		color(colorSubtle)
		textAlign(.center)
		padding(spacing32)
		margin(0)
	}
}

#endif
