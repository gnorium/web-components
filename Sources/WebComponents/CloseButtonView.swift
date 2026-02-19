#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

public struct CloseButtonView: HTMLProtocol {
	let ariaLabel: String
	let `class`: String

	public init(
		ariaLabel: String = "Close",
		class customClass: String = ""
	) {
		self.ariaLabel = ariaLabel
		self.class = customClass
	}

	public func render(indent: Int = 0) -> String {
		ButtonView(
			icon: IconView {
				CloseIconView()
			},
			weight: .plain,
    		size: .large,
			ariaLabel: ariaLabel,
			class: "close-button-view \(`class`)"
		)
		.render(indent: indent)
	}
}

#endif
