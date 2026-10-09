import EmbeddedSwiftUtilities

/// The editable states in HTML include an empty attribute and
/// `plaintext-only`. Invalid or missing states inherit from the parent;
/// `false` explicitly ends that inheritance.
enum KeyboardShortcuts {
  static func isEditable(tag: String, contentEditableAncestors: [String]) -> Bool {
    if stringEquals(tag, "INPUT") || stringEquals(tag, "TEXTAREA") || stringEquals(tag, "SELECT") {
      return true
    }
    for attribute in contentEditableAncestors {
      let value = stringLowercased(attribute)
      if stringIsEmpty(value) || stringEquals(value, "true") || stringEquals(value, "plaintext-only") {
        return true
      }
      if stringEquals(value, "false") { return false }
    }
    return false
  }

  /// These keys edit code or move its caret. Keep the browser's default
  /// action, but do not let ancestor search/viewer shortcuts consume them.
  static func editorOwns(_ key: String) -> Bool {
    stringEquals(key, "/") || stringEquals(key, "ArrowLeft") || stringEquals(key, "ArrowRight")
      || stringEquals(key, "ArrowUp") || stringEquals(key, "ArrowDown")
      || stringEquals(key, "Home") || stringEquals(key, "End")
      || stringEquals(key, "PageUp") || stringEquals(key, "PageDown")
  }
}

#if CLIENT
  import DOMBuilder
  import WebAPIs
  import WebTypes

  extension KeyboardShortcuts {
    static func isEditable(_ target: DOM.Element?) -> Bool {
      guard let target else { return false }
      var attributes: [String] = []
      var element: DOM.Element? = target
      while let current = element {
        if case .some(let value) = current.getAttribute("contenteditable") {
          attributes.append(value)
        }
        element = current.parentElement
      }
      return isEditable(tag: target.tagName, contentEditableAncestors: attributes)
    }
  }
#endif
