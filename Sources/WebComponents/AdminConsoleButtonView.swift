#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Specialized button for the Admin Console link
public struct AdminConsoleButtonView: HTMLProtocol {
    let url: String
    let size: ButtonView.ButtonSize

    public init(url: String = "/admin-console", size: ButtonView.ButtonSize = .large) {
        self.url = url
        self.size = size
    }

    public func render(indent: Int = 0) -> String {
        div {
            ButtonView(
                label: "",
                icon: IconView(icon: { s in ConfigureIconView(width: s, height: s) }, size: size == .small ? .xSmall : size == .medium ? .small : .medium),
                weight: .plain,
                size: size,
                url: url,
                ariaLabel: "Admin Console",
                class: "navbar-admin-console-btn"
            )
        }
        .class("admin-console-button-view")
        .title("Admin Console")
        .style {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
        }
        .render(indent: indent)
    }
}

#endif
