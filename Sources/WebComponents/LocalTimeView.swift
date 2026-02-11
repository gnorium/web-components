#if !os(WASI)

import Foundation
import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Renders a `<time>` element with an ISO 8601 `datetime` attribute and a UTC fallback display.
/// WASM hydration converts the display to the user's local timezone.
public struct LocalTimeView: HTMLProtocol {
	let date: Date
	let size: Length
	let textColor: CSSColor
	let fallbackSuffix: String

	public init(
		date: Date,
		size: Length = fontSizeSmall14,
		textColor: CSSColor = colorBase,
		fallbackSuffix: String = "UTC"
	) {
		self.date = date
		self.size = size
		self.textColor = textColor
		self.fallbackSuffix = fallbackSuffix
	}

	public func render(indent: Int = 0) -> String {
		let isoFormatter = ISO8601DateFormatter()
		let displayFormatter = DateFormatter()
		displayFormatter.dateStyle = .medium
		displayFormatter.timeStyle = .short
		displayFormatter.timeZone = TimeZone(identifier: "UTC")

		return time { displayFormatter.string(from: date) + " " + fallbackSuffix }
		.datetime(isoFormatter.string(from: date))
		.class("local-time")
		.style {
			fontSize(size)
			color(textColor)
		}
		.render(indent: indent)
	}
}

#endif

#if os(WASI)

import WebAPIs

/// Hydrates all `<time class="local-time">` elements on the page,
/// converting their UTC fallback text to the user's local timezone.
public class LocalTimeHydration: @unchecked Sendable {
	public init() {
		hydrate()
	}

	public func hydrate() {
		let elements = document.querySelectorAll("time.local-time")
		for element in elements {
			guard let iso = element.getAttribute("datetime") else { continue }
			guard let localString = formatLocalDate(iso) else { continue }
			element.textContent = localString
		}
	}
}

#endif
