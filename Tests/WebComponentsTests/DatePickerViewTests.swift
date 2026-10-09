import DOMBuilder
import WebTypes
import XCTest
@testable import WebComponents

final class DatePickerViewTests: XCTestCase {
  private func elements(in node: DOM.Node) -> [DOM.Element] {
    guard let element = node as? DOM.Element else { return [] }
    return [element] + element.children.flatMap { elements(in: $0) }
  }

  private func presetButtons(in node: DOM.Node) -> [DOM.Element] {
    elements(in: node).filter { element in
      element.tag == "button" && element.attributes.contains {
        $0.0 == "class" && $0.1.split(separator: " ").contains("date-picker-preset")
      }
    }
  }

  func testRenderedPresetsDisableRangesOutsideEitherDateLimit() throws {
    try ViewerZone.$identifier.withValue("UTC") {
      let node = DatePickerView(
        id: "bounded", name: "dates", min: "2026-10-05", max: "2026-10-08", range: true,
        presets: [
          ("2026-10-05T00:00Z..2026-10-09T00:00Z", "Within bounds"),
          ("2026-10-03T00:00Z..2026-10-09T00:00Z", "Starts too early"),
          ("2026-10-05T00:00Z..2026-10-10T00:00Z", "Ends too late"),
        ]).build()
      let buttons = presetButtons(in: node)
      XCTAssertEqual(buttons.count, 3)
      guard buttons.count == 3 else { return }
      XCTAssertFalse(buttons[0].attributes.contains { $0.0 == "disabled" })
      XCTAssertTrue(buttons[1].attributes.contains { $0.0 == "disabled" })
      XCTAssertTrue(buttons[2].attributes.contains { $0.0 == "disabled" })
      let hidden = try XCTUnwrap(elements(in: node).first { element in
        element.tag == "input" && element.attributes.contains { $0.0 == "type" && $0.1 == "hidden" }
      })
      XCTAssertTrue(hidden.attributes.contains { $0.0 == "value" && $0.1 == "" })
    }
  }

  func testDisabledPickerKeepsAllPresetsDisabled() throws {
    let node = DatePickerView(id: "disabled", name: "dates", disabled: true, range: true).build()
    let root = try XCTUnwrap(node as? DOM.Element)
    XCTAssertTrue(root.attributes.contains { $0.0 == "data-disabled" && $0.1 == "true" })
    let buttons = presetButtons(in: node)
    XCTAssertEqual(buttons.count, DateRangeValue.presets.count)
    XCTAssertTrue(buttons.allSatisfy { $0.attributes.contains { $0.0 == "disabled" } })
  }
}
