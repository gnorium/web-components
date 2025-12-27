#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct PaginationView: HTML {
    public let previousLabel: String?
    public let previousHref: String?
    public let nextLabel: String?
    public let nextHref: String?
    public let pageNumbers: [PageNumber]?
    let `class`: String

	public struct PageNumber: Sendable {
        public let label: String
        public let href: String
        public let isActive: Bool

        public init(label: String, href: String, isActive: Bool = false) {
            self.label = label
            self.href = href
            self.isActive = isActive
        }
    }

    public init(
        previousLabel: String? = nil,
        previousHref: String? = nil,
        nextLabel: String? = nil,
        nextHref: String? = nil,
        pageNumbers: [PageNumber]? = nil,
        class: String = ""
    ) {
        self.previousLabel = previousLabel
        self.previousHref = previousHref
        self.nextLabel = nextLabel
        self.nextHref = nextHref
        self.pageNumbers = pageNumbers
        self.`class` = `class`
    }

    public func render(indent: Int = 0) -> String {
        section {
            // Previous link
            if let prevLabel = previousLabel, let prevHref = previousHref {
                div {
                    a { prevLabel }
                    .class("pagination-prev")
                    .href(prevHref)
                    .style {
                        fontFamily(typographyFontSans)
                        fontSize(fontSizeMedium16)
                        color(colorProgressive)
                        textDecoration(.none)
                        fontWeight(fontWeightSemiBold)
                        pseudoClass(.hover) {
                            color(colorProgressiveHover).important()
                            textDecoration(.underline).important()
                        }
                        pseudoClass(.active) {
                            color(colorProgressiveActive).important()
                        }
                        pseudoClass(.focus) {
                            color(colorProgressiveFocus).important()
                            outline(borderWidthBase, .solid, colorProgressiveFocus).important()
                            outlineOffset(px(2)).important()
                        }
                    }
                }
            } else {
                div {}.style { flex(1) }
            }

            // Page numbers (center)
            if let pages = pageNumbers, !pages.isEmpty {
                div {
                    for page in pages {
                        if page.isActive {
                            span { page.label }
							.class("page-label-active")
                            .style {
                                fontFamily(typographyFontSans)
                                fontSize(fontSizeMedium16)
                                color(colorInvertedFixed)
                                fontWeight(fontWeightBold)
                                padding(spacing8, spacing12)
                                backgroundColor(backgroundColorProgressive)
                                borderRadius(borderRadiusBase)
                                display(.inlineBlock)
                            }
                        } else {
                            a { page.label }
							.class("page-label")
                            .href(page.href)
                            .style {
                                fontFamily(typographyFontSans)
                                fontSize(fontSizeMedium16)
                                color(colorProgressive)
                                textDecoration(.none)
                                fontWeight(fontWeightSemiBold)
                                padding(spacing8, spacing12)
                                display(.inlineBlock)
                                pseudoClass(.hover) {
                                    color(colorProgressiveHover).important()
                                    backgroundColor(backgroundColorInteractive).important()
                                    borderRadius(borderRadiusBase).important()
                                }
                                pseudoClass(.active) {
                                    color(colorProgressiveActive).important()
                                }
                                pseudoClass(.focus) {
                                    color(colorProgressiveFocus).important()
                                    outline(borderWidthBase, .solid, colorProgressiveFocus).important()
                                    outlineOffset(px(2)).important()
                                    borderRadius(borderRadiusBase).important()
                                }
                            }
                        }
                    }
                }
                .style {
                    display(.flex)
                    flexDirection(.row)
                    gap(spacing4)
                    alignItems(.center)
                    justifyContent(.center)
                }
            }

            // Next link
            if let nextLabel = nextLabel, let nextHref = nextHref {
                div {
                    a { nextLabel }
                    .class("pagination-next")
                    .href(nextHref)
                    .style {
                        fontFamily(typographyFontSans)
                        fontSize(fontSizeMedium16)
                        color(colorProgressive)
                        textDecoration(.none)
                        fontWeight(fontWeightSemiBold)
                        pseudoClass(.hover) {
                            color(colorProgressiveHover).important()
                            textDecoration(.underline).important()
                        }
                        pseudoClass(.active) {
                            color(colorProgressiveActive).important()
                        }
                        pseudoClass(.focus) {
							color(colorProgressiveFocus).important()
                            outline(borderWidthBase, .solid, colorProgressiveFocus).important()
                            outlineOffset(px(2)).important()
                        }
                    }
                }
                .style {
                    textAlign(.right)
                }
            } else {
                div {}.style { flex(1) }
            }
        }
        .class(`class`.isEmpty ? "pagination-view" : "pagination-view \(`class`)")
        .style {
            display(.flex)
            flexDirection(.row)
            justifyContent(.spaceBetween)
            alignItems(.center)
            maxWidth(px(800))
            margin(spacing48, .auto, 0, .auto)
            padding(spacing32)
            borderTop(borderWidthBase, .solid, borderColorBase)
            gap(spacing32)
        }
        .render(indent: indent)
    }
}

#endif
