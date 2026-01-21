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
                url: url,
                ariaLabel: "Admin Console",
                class: "navbar-admin-console-btn"
            ) {
                IconView(icon: { s in ConfigureIconView(width: s, height: s) }, size: .medium)
            }
        }
        .title("Admin Console")
        .style {
            display(.flex)
            alignItems(.center)
            justifyContent(.center)
            width(px(44))
            height(px(44))
            borderRadius(borderRadiusPill)
            color(colorBase)
            textDecoration(.none)
            transition(.all, s(0.15), .ease)
            
            pseudoClass(.hover) {
                backgroundColor(backgroundColorInteractiveSubtle)
                color(colorProgressive).important()
            }
        }
        .render(indent: indent)
    }
}

#endif
