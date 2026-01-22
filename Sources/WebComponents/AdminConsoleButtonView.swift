#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import DesignTokens
import WebTypes

/// Specialized button for the Admin Console link
public struct AdminConsoleButtonView: HTML {
    let url: String
    
    public init(url: String = "/admin-console") {
        self.url = url
    }
    
    public func render(indent: Int = 0) -> String {
        div {
            ButtonView(
                label: "",
                icon: IconView(icon: { s in ConfigureIconView(width: s, height: s) }, size: .medium),
                weight: .transparent,
                size: .large,
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
