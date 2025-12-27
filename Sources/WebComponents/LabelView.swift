#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Label component following Wikimedia Codex design system specification
/// A Label provides a descriptive title for an input or form field.
/// Every input or form field must have an associated label for accessibility.
///
/// Codex Reference: https://doc.wikimedia.org/codex/main/components/demos/label.html
public struct LabelView: HTML {
	let icon: String?
	let optional: Bool
	let optionalFlag: String
	let visuallyHidden: Bool
	let isLegend: Bool
	let inputId: String?
	let descriptionId: String?
	let disabled: Bool
	let labelContent: [HTML]
	let descriptionContent: [HTML]
	let `class`: String

	public init(
		icon: String? = nil,
		optional: Bool = false,
		optionalFlag: String = "(optional)",
		visuallyHidden: Bool = false,
		isLegend: Bool = false,
		inputId: String? = nil,
		descriptionId: String? = nil,
		disabled: Bool = false,
		class: String = "",
		@HTMLBuilder label: () -> [HTML],
		@HTMLBuilder description: () -> [HTML] = { [] }
	) {
		self.icon = icon
		self.optional = optional
		self.optionalFlag = optionalFlag
		self.visuallyHidden = visuallyHidden
		self.isLegend = isLegend
		self.inputId = inputId
		self.descriptionId = descriptionId
		self.disabled = disabled
		self.`class` = `class`
		self.labelContent = label()
		self.descriptionContent = description()
	}

	@CSSBuilder
	private func labelViewCSS() -> [CSS] {
		if disabled {
			opacity(opacityMedium)
		}
	}

	@CSSBuilder
	private func visuallyHiddenCSS() -> [CSS] {
		position(.absolute)
		width(px(1))
		height(px(1))
		margin(px(-1))
		padding(0)
		overflow(.hidden)
		clip(rect(px(0), px(0), px(0), px(0)))
		whiteSpace(.nowrap)
		borderWidth(0)
	}

	@CSSBuilder
	private func labelTextCSS() -> [CSS] {
		display(.flex)
		alignItems(.center)
		gap(spacing4)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		fontWeight(fontWeightBold)
		lineHeight(lineHeightMedium26)
		color(disabled ? colorDisabled : colorBase)
	}

	@CSSBuilder
	private func labelIconCSS() -> [CSS] {
		display(.inlineFlex)
		alignItems(.center)
		justifyContent(.center)
		width(minSizeIconMedium)
		height(minSizeIconMedium)
		color(disabled ? colorDisabled : colorSubtle)
		flexShrink(0)
	}

	@CSSBuilder
	private func labelOptionalFlagCSS() -> [CSS] {
		color(disabled ? colorDisabled : colorSubtle)
		fontWeight(fontWeightNormal)
	}

	@CSSBuilder
	private func labelDescriptionCSS() -> [CSS] {
		display(.block)
		marginTop(spacing4)
		fontSize(fontSizeSmall14)
		lineHeight(lineHeightSmall22)
		color(disabled ? colorDisabled : colorSubtle)
		fontWeight(fontWeightNormal)
	}

	public func render(indent: Int = 0) -> String {
		let hasDescription = !descriptionContent.isEmpty

		if isLegend {
			return legend {
				span {
					if let iconValue = icon {
						span { iconValue }
							.class("label-icon")
							.ariaHidden(true)
							.style {
								labelIconCSS()
							}
					}

					labelContent

					if optional {
						span { " \(optionalFlag)" }
							.class("label-optional-flag")
							.style {
								labelOptionalFlagCSS()
							}
					}
				}
				.class("label-text")
				.style {
					labelTextCSS()
				}

				if hasDescription {
					span { descriptionContent }
						.class("label-description")
						.id(descriptionId ?? "")
						.style {
							labelDescriptionCSS()
						}
				}
			}
			.class(`class`.isEmpty ? (visuallyHidden ? "label-view visually-hidden" : "label-view") : (visuallyHidden ? "label-view visually-hidden \(`class`)" : "label-view \(`class`)"))
			.style {
				labelViewCSS()

				if visuallyHidden {
					visuallyHiddenCSS()
				}
			}
			.render(indent: indent)
		} else {
			return div {
				if let forId = inputId {
					label {
						if let iconValue = icon {
							span { iconValue }
								.class("label-icon")
								.ariaHidden(true)
								.style {
									labelIconCSS()
								}
						}

						labelContent

						if optional {
							span { " \(optionalFlag)" }
								.class("label-optional-flag")
								.style {
									labelOptionalFlagCSS()
								}
						}
					}
					.for(forId)
					.class("label-text")
					.style {
						marginBottom(hasDescription ? spacing4 : spacing0)
						labelTextCSS()
					}
				} else {
					span {
						if let iconValue = icon {
							span { iconValue }
								.class("label-icon")
								.ariaHidden(true)
								.style {
									labelIconCSS()
								}
						}

						labelContent

						if optional {
							span { " \(optionalFlag)" }
								.class("label-optional-flag")
								.style {
									labelOptionalFlagCSS()
								}
						}
					}
					.class("label-text")
					.style {
						marginBottom(hasDescription ? spacing4 : spacing0)
						labelTextCSS()
					}
				}

				if hasDescription {
					span { descriptionContent }
						.class("label-description")
						.id(descriptionId ?? "")
						.style {
							labelDescriptionCSS()
						}
				}
			}
			.class(`class`.isEmpty ? (visuallyHidden ? "label-view visually-hidden" : "label-view") : (visuallyHidden ? "label-view visually-hidden \(`class`)" : "label-view \(`class`)"))
			.style {
				labelViewCSS()

				if visuallyHidden {
					visuallyHiddenCSS()
				}
			}
			.render(indent: indent)
		}
	}
}

#endif
