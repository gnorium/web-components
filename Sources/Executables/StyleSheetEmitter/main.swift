import CSSBuilder
import Foundation
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
    // Catalogue — one instance emits full superset via data-attributes
    _ = ButtonView(label: "Solid", weight: .solid).build()
    _ = ButtonView(label: "Subtle", weight: .subtle).build()
    _ = ButtonView(icon: IconView { SearchIconView() }, size: .medium, ariaLabel: "search").build()
    _ = ButtonView(icon: IconView { SearchIconView() }, size: .large, ariaLabel: "search", class: "navbar-search-btn").build()
    _ = SearchBarView(openDialog: true, class: "home", placeholder: "Search", ariaLabel: "Search", searchField: "q", searchEndpoint: "/search/suggest", resultUrlBase: "/search").build()
    _ = UnicodeGridView().build()

    let paths = StaticStyleSheetEmitter.finish()
    guard !paths.isEmpty else { throw E.missing }
    for p in paths { print("Emitted /\(p)") }
  }

  enum E: Error { case missing }
}
