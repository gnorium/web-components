import XCTest
@testable import WebComponents

/// A number range as one URL value carries it (`1000..5000`), both ends
/// included, either open, each a decimal as typed.
final class NumberRangeValueTests: XCTestCase {
  func testRangesAndOpenEnds() throws {
    let both = try XCTUnwrap(NumberRangeValue.parse("1000..5000"))
    XCTAssertEqual(both.start, "1000")
    XCTAssertEqual(both.end, "5000")
    XCTAssertEqual(both.param, "1000..5000")
    let until = try XCTUnwrap(NumberRangeValue.parse("..5000"))
    XCTAssertNil(until.start)
    XCTAssertEqual(until.param, "..5000")
    let since = try XCTUnwrap(NumberRangeValue.parse(" 0.05.. "))
    XCTAssertEqual(since.start, "0.05")
    XCTAssertNil(since.end)
    XCTAssertEqual(NumberRangeValue.parse("5..5")?.param, "5..5", "one value is a range of itself")
    XCTAssertEqual(NumberRangeValue.parse("-3.5..-1")?.param, "-3.5..-1")
  }

  func testRejected() {
    for value in ["", "..", "5", "a..b", "1e3..", "1,000..", "1.2.3..", "5..1", "--1..", "1-..", ".."] {
      XCTAssertNil(NumberRangeValue.parse(value), value)
    }
  }

  func testDecimals() {
    XCTAssertEqual(NumberRangeValue.number("0.0123"), 0.0123)
    XCTAssertEqual(NumberRangeValue.number(".5"), 0.5)
    XCTAssertEqual(NumberRangeValue.number("12."), 12)
    XCTAssertEqual(NumberRangeValue.number("-2.25"), -2.25)
    XCTAssertNil(NumberRangeValue.number("."))
    XCTAssertNil(NumberRangeValue.number("-"))
  }

  /// Two typed ends make the value the hidden input submits; none, nothing.
  func testTypedEnds() {
    XCTAssertEqual(NumberRangeInputView.param(start: "100", end: ""), "100..")
    XCTAssertEqual(NumberRangeInputView.param(start: "", end: " 0.5 "), "..0.5")
    XCTAssertEqual(NumberRangeInputView.param(start: "", end: ""), "")
  }

  func testInputDrawsStartAndEnd() {
    let html = NumberRangeInputView(id: "tokens", name: "tokens", value: "1000..", label: "Tokens").render()
    // The ends named for what the range is of, placeholder as label.
    XCTAssertTrue(html.contains("placeholder=\"Tokens start\""))
    XCTAssertTrue(html.contains("placeholder=\"Tokens end\""))
    XCTAssertTrue(html.contains("<span class=\"text-input-label\">Tokens start</span>"))
    XCTAssertTrue(html.contains("<span class=\"text-input-label\">Tokens end</span>"))
    XCTAssertTrue(html.contains("value=\"From 1000\""))
    XCTAssertTrue(html.contains("value=\"1000..\""))
    XCTAssertTrue(html.contains("value=\"1000\""))
    XCTAssertTrue(html.contains("step=\"any\""))
  }
}
