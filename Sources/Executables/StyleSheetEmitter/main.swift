import CSSBuilder
import DesignTokens
import Foundation
import HTMLBuilder
import WebComponents
import SVGBuilder

@main
struct StyleSheetEmitter {
  static func main() throws {
    let args = CommandLine.arguments
    let publicDir: String
    if let i = args.firstIndex(of: "--public-dir"), i + 1 < args.count {
      publicDir = args[i + 1]
    } else {
      publicDir = "Public"
    }

    StaticStyleSheetEmitter.begin(publicDirectory: publicDir)
    // Catalog—one instance emits full superset via data-attributes
    _ = ButtonView(label: "Solid", weight: .solid).build()
    _ = ButtonView(label: "Subtle", weight: .subtle).build()
    _ = ButtonView(icon: IconView(icon: { s in SearchIconView(size: s) }, size: sizeIconSmall), size: .medium, ariaLabel: "search").build()
    _ = ButtonView(icon: IconView(icon: { s in SearchIconView(size: s) }, size: sizeIconSmall), size: .medium, ariaLabel: "search", class: "navbar-search-btn").build()
    _ = SearchBarView(openDialog: true, class: "home", placeholder: "Search", ariaLabel: "Search", searchField: "q", searchEndpoint: "/search/suggest", resultUrlBase: "/search").build()
    _ = TeXView("x", displayMode: true).build()
    _ = RotatingSectorView().build()
    _ = RotatingRingSectorView().build()
    _ = RotatingRingSectorWithDiscView().build()

    try StaticStyleSheetEmitter.emitCollected(HTMLGlobalStyle.shared.getAndResetStyleSheets())
    let paths = StaticStyleSheetEmitter.finish()
    guard !paths.isEmpty else { throw E.missing }
    for p in paths { print("Emitted /\(p)") }
  }

  enum E: Error { case missing }
}
