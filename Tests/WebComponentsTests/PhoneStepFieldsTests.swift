import CSSBuilder
import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// Every control steps down one size on a phone (user, 2026-10-21): a field is
/// the large control's 48 and 40 under the phone step, as the dropdown trigger
/// beside it. And an alert's icon is its color's.
final class PhoneStepFieldsTests: XCTestCase {
  private func css(_ build: () -> DOM.Node) -> (String, String) {
    var node: DOM.Node?
    let sheets = HTMLGlobalStyle.collecting { node = build() }.currentStyleSheets().map(\.css).joined(separator: "\n")
    return (node.map { "\($0)" } ?? "", sheets)
  }

  func testTextInputsAndSelectsStepDownWithTheTrigger() {
    let (_, text) = css { TextInputView(id: "t", name: "t", placeholder: "T").build() }
    XCTAssertTrue(text.contains("data-phone-step='down'] .text-input-view .text-input-input"), text)
    let (_, select) = css { SelectView(id: "s", name: "s", menuItems: []).build() }
    XCTAssertTrue(select.contains("data-phone-step='down'] .select-view .select-handle")
      || select.contains("data-phone-step='down']"), select)
  }

  func testAnAlertCannotWearAnotherColorsIcon() {
    let (red, _) = css { AlertView(color: .red) { "Failed." }.build() }
    XCTAssertTrue(red.contains("alert-red"))
  }
}
