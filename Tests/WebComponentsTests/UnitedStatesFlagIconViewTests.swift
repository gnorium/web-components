import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

final class UnitedStatesFlagIconViewTests: XCTestCase {
  func testFlagRendersOneTracedPathInTheHouseBox() throws {
    let html = UnitedStatesFlagIconView(size: px(23)).build().render()
    XCTAssertTrue(html.contains("viewBox=\"0 0 1024 1024\""))
    XCTAssertEqual(html.components(separatedBy: "<path").count - 1, 1)
    XCTAssertTrue(html.contains("d=\"M 1024,512 A 512,512 0 0 0 1016.84,426.67"))
    XCTAssertTrue(html.contains("fill-rule=\"evenodd\""))
  }
}
