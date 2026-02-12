#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct PaginationView: HTMLProtocol {
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
                        color(colorBase)
                        textDecoration(.none)
                        fontWeight(fontWeightNormal)
                        pseudoClass(.focus) {
                            outline(borderWidthBase, .solid, colorBlueFocus).important()
                            outlineOffset(px(2)).important()
                        }
                    }
                }
            } else {
                div {}
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
                                color(colorBlue)
                                fontWeight(fontWeightNormal)
                                padding(spacing8, spacing12)
                                borderRadius(borderRadiusPill)
                                display(.inlineBlock)

                                pseudoClass(.hover) {
                                    color(colorBlueHover).important()
                                }
                                pseudoClass(.active) {
                                    color(colorBlueActive).important()
                                }
                                pseudoClass(.focus) {
                                    color(colorBlueFocus).important()
                                    outline(borderWidthBase, .solid, colorBlueFocus).important()
                                    outlineOffset(px(2)).important()
                                }
                            }
                        } else {
                            a { page.label }
							.class("page-label")
                            .href(page.href)
                            .style {
                                fontFamily(typographyFontSans)
                                fontSize(fontSizeMedium16)
                                color(colorBase)
                                textDecoration(.none)
                                fontWeight(fontWeightNormal)
                                padding(spacing8, spacing12)
                                display(.inlineBlock)
                                pseudoClass(.focus) {
                                    color(colorBlueFocus).important()
                                    outline(borderWidthBase, .solid, colorBlueFocus).important()
                                    outlineOffset(px(2)).important()
                                    borderRadius(borderRadiusPill).important()
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
                        color(colorBase)
                        textDecoration(.none)
                        fontWeight(fontWeightNormal)
                        pseudoClass(.focus) {
                            outline(borderWidthBase, .solid, colorBlueFocus).important()
                            outlineOffset(px(2)).important()
                        }
                    }
                }
                .style {
                    textAlign(.end)
                }
            } else {
                div {}
            }
        }
        .class(`class`.isEmpty ? "pagination-view" : "pagination-view \(`class`)")
        .style {
            display(.flex)
            flexDirection(.row)
            justifyContent(.spaceBetween)
            alignItems(.center)
            gap(spacing32)
        }
        .render(indent: indent)
    }
}

#endif
