import EmbeddedSwiftUtilities
import WebTypes

/// Ids made unique where one form is drawn several times on a page.
///
/// A form's fields are named for what they are — `work-edition`,
/// `as-publication-year` — and a page that draws the same form for several
/// things at once, one per testament, would repeat every one of them. An id
/// names one element on a page, and a label's `for` and an `aria-describedby`
/// pointing at a repeated one find the first, wherever it is.
///
/// So the element that holds one copy of the form scopes it: every id under
/// it is prefixed, and every reference to one of those ids — a label's `for`,
/// the ARIA attributes that name elements — is prefixed with it. References
/// to ids outside it are left alone, and so is its own id, which what stands
/// outside it names. It carries its prefix in `data-id-scope`, where client
/// code working inside it reads it back to name an element by its id.
public enum IDScope {
  /// The attribute a scoping element carries its prefix in.
  public static let attribute = "data-id-scope"
}

#if SERVER
  import DOMBuilder

  extension IDScope {
    /// The attributes whose value names elements by id: one, or several
    /// separated by spaces.
    static let references: Set<String> = [
      "for", "list", "headers", "form", "popovertarget", "commandfor", "anchor",
      "aria-activedescendant", "aria-controls", "aria-describedby", "aria-details",
      "aria-errormessage", "aria-flowto", "aria-labelledby", "aria-owns",
    ]
  }

  extension DOM.Element {
    /// Scopes every id under this element with `prefix`, as `IDScope` says.
    @discardableResult
    public func scopingIDs(_ prefix: String) -> Self {
      guard !prefix.isEmpty else { return self }
      var ids: Set<String> = []
      func collect(_ node: DOM.Node) {
        guard let element = node as? DOM.Element else {
          (node as? DOM.DocumentFragment)?.children.forEach(collect)
          return
        }
        for (name, value) in element.attributes where name == "id" { ids.insert(value) }
        element.children.forEach(collect)
      }
      func rewrite(_ node: DOM.Node) {
        guard let element = node as? DOM.Element else {
          (node as? DOM.DocumentFragment)?.children.forEach(rewrite)
          return
        }
        element.attributes = element.attributes.map { name, value in
          if name == "id" { return (name, prefix + value) }
          guard IDScope.references.contains(name) else { return (name, value) }
          let tokens = value.split(separator: " ").map { ids.contains(String($0)) ? prefix + $0 : String($0) }
          return (name, tokens.joined(separator: " "))
        }
        element.children.forEach(rewrite)
      }
      children.forEach(collect)
      children.forEach(rewrite)
      attributes.removeAll { $0.0 == IDScope.attribute }
      attributes.append((IDScope.attribute, prefix))
      return self
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import WebAPIs

  extension IDScope {
    /// The prefix the ids around `element` carry: its own scope's, or none.
    public static func prefix(of element: DOM.Element) -> String {
      element.closest("[data-id-scope]")?.getAttribute(attribute) ?? ""
    }

    /// An id as it is written where `element` is.
    public static func id(_ id: String, in element: DOM.Element) -> String {
      stringJoin([prefix(of: element), id], separator: "")
    }

    /// The selector for an element by its id, where `element` is.
    public static func selector(_ id: String, in element: DOM.Element) -> String {
      stringJoin(["#", prefix(of: element), id], separator: "")
    }
  }
#endif
