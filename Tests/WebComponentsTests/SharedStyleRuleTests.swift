import CSSBuilder
import DOMBuilder
import DesignTokens
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// Selector rules are shared by every instance of a view (prefixed by its
/// first class, appended to one stylesheet), so a value that differs per
/// instance must be inline or a data attribute, never inside such a rule.
final class SharedStyleRuleTests: XCTestCase {
  private func capture(_ build: () -> DOM.Node) throws -> (DOM.Element, String) {
    var node: DOM.Node?
    let sheets = HTMLGlobalStyle.collecting { node = build() }.currentStyleSheets()
    return (try XCTUnwrap(node as? DOM.Element), sheets.map(\.css).joined(separator: "\n"))
  }

  private func attribute(_ name: String, in element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func descendants(of element: DOM.Element) -> [DOM.Element] {
    var found: [DOM.Element] = []
    for child in element.children {
      if let childElement = child as? DOM.Element {
        found.append(childElement)
        found.append(contentsOf: descendants(of: childElement))
      }
    }
    return found
  }

  func testStatusCellColorIsInlineNotInTheSharedRules() throws {
    let (first, firstCSS) = try capture {
      TableCellView(.status(icon: "A", bgColor: colorBase)).build()
    }
    let (second, secondCSS) = try capture {
      TableCellView(.status(icon: "B", bgColor: colorDisabled)).build()
    }
    XCTAssertEqual(firstCSS, secondCSS)
    // The icon's shared rule holds no background: the color is inline. (The
    // sheet's other rules use these tokens legitimately.)
    let iconRule = try XCTUnwrap(firstCSS.components(separatedBy: "}").first { $0.contains(".table-cell-status-icon") })
    XCTAssertFalse(iconRule.contains("background"))
    for (root, token) in [(first, "--color-base"), (second, "--color-disabled")] {
      let icon = try XCTUnwrap(descendants(of: root).first {
        attribute("class", in: $0)?.contains("table-cell-status-icon") == true
      })
      XCTAssertTrue(try XCTUnwrap(attribute("style", in: icon)).contains(token))
    }
  }

  func testButtonRulesDoNotDependOnTheInstance() throws {
    let (_, firstCSS) = try capture {
      ButtonView(label: "One", buttonColor: .gray, weight: .subtle, size: .medium).build()
    }
    let (_, secondCSS) = try capture {
      ButtonView(label: "Two", buttonColor: .blue, weight: .solid, size: .large, disabled: true).build()
    }
    XCTAssertEqual(firstCSS, secondCSS)
  }

  func testChevronRulesAreOneTextForEveryInstance() throws {
    let (_, rightDownOpen) = try capture {
      AnimatedRightDownChevronView(id: "a", expanded: true, size: px(16)).build()
    }
    let (_, rightDownClosed) = try capture {
      AnimatedRightDownChevronView(id: "b", expanded: false, size: px(32)).build()
    }
    XCTAssertEqual(rightDownOpen, rightDownClosed)
    let (_, upDownSmall) = try capture {
      AnimatedUpDownChevronView(id: "a", expanded: true, size: px(16)).build()
    }
    let (_, upDownLarge) = try capture {
      AnimatedUpDownChevronView(id: "b", expanded: false, size: px(32)).build()
    }
    XCTAssertEqual(upDownSmall, upDownLarge)
    XCTAssertFalse(upDownSmall.contains("32px"))
  }
}
