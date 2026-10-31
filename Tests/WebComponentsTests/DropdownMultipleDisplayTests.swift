import DOMBuilder
import HTMLBuilder
import XCTest
@testable import WebComponents

/// A multi-select dropdown's closed value reads as an English list with the
/// Oxford comma, never "A, B".
final class DropdownMultipleDisplayTests: XCTestCase {
  private func shown(_ values: [String]) -> String {
    let options = ["A", "B", "C"].map { DropdownView.DropdownOption(value: $0, display: $0) }
    return DropdownView(
      id: "d", name: "d", label: "Letters", options: options, multiple: true, selectedValues: values
    ).build().render()
  }

  func testChosenNamesReadAsAnEnglishList() {
    XCTAssertTrue(shown(["A"]).contains(">A<"))
    XCTAssertTrue(shown(["A", "B"]).contains("A and B"))
    XCTAssertTrue(shown(["A", "B", "C"]).contains("A, B, and C"))
    XCTAssertFalse(shown(["A", "B"]).contains("A, B<"))
  }
}
