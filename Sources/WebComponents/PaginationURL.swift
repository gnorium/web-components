import EmbeddedSwiftUtilities

/// Updates only the page query parameter, retaining the spelling and order
/// of every other parameter and the fragment. Shared by server tests and WASM.
enum PaginationURL {
  static func settingPage(_ page: String, in url: String) -> String {
    let fragmentStart = stringIndexOf(url, "#") ?? url.utf8.count
    let fragment = stringSubstring(url, from: fragmentStart)
    let address = stringSubstring(url, from: 0, to: fragmentStart)
    guard let queryStart = stringIndexOf(address, "?") else {
      return "\(address)?page=\(page)\(fragment)"
    }
    let path = stringSubstring(address, from: 0, to: queryStart)
    let query = stringSubstring(address, from: queryStart + 1)
    var found = false
    var parameters = stringIsEmpty(query) ? [] : stringSplit(query, separator: "&")
    for index in parameters.indices {
      let parameter = parameters[index]
      let keyEnd = stringIndexOf(parameter, "=") ?? parameter.utf8.count
      let key = stringSubstring(parameter, from: 0, to: keyEnd)
      if stringEquals(key, "page") {
        parameters[index] = "page=\(page)"
        found = true
      }
    }
    if !found { parameters.append("page=\(page)") }
    return "\(path)?\(stringJoin(parameters, separator: "&"))\(fragment)"
  }
}
