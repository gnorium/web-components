import EmbeddedSwiftUtilities

/// Associates remote suggestions with the exact query that produced them.
/// A new query invalidates suggestions before its debounce or request runs.
struct ComboboxSearch {
  private(set) var sequence = 0
  private var resultQuery: String?

  mutating func begin() -> Int {
    sequence += 1
    resultQuery = nil
    return sequence
  }

  mutating func receive(query: String, sequence answer: Int, currentQuery: String) -> Bool {
    guard answer == sequence, stringEquals(query, currentQuery) else { return false }
    resultQuery = query
    return true
  }

  func matches(_ query: String) -> Bool {
    if case .some(let resultQuery) = resultQuery { return stringEquals(resultQuery, query) }
    return false
  }
}
