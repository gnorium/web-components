import CSSBuilder
import DesignTokens
import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// A component's rules are shared by every instance of its class: two
/// variants must render the same stylesheet, each variant's rule present and
/// keyed by a data attribute, and what differs per instance lives in the
/// element's own attributes and inline style.
final class StyleVariantTests: XCTestCase {
  private func attribute(_ name: String, in element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func render(_ build: () -> DOM.Node) throws -> (root: DOM.Element, css: String) {
    var node: DOM.Node?
    let sheets = HTMLGlobalStyle.collecting { node = build() }.currentStyleSheets()
    return (try XCTUnwrap(node as? DOM.Element), sheets.map { $0.css }.joined(separator: "\n"))
  }

  /// Both variants' stylesheets are identical, and hold every rule in `rules`.
  private func assertSharedRules(_ a: String, _ b: String, contains rules: [String], file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(a, b, "The stylesheet depends on the instance", file: file, line: line)
    for rule in rules {
      XCTAssertTrue(a.contains(rule), "Missing rule \(rule)", file: file, line: line)
    }
  }

  func testMenuItemVariantsShareOneStylesheetKeyedByData() throws {
    let plain = try render { MenuItemView(id: "a", value: "a", label: "A").build() }
    let variant = try render {
      MenuItemView(
        id: "b", value: "b", disabled: true, selected: true, active: true, highlighted: true, label: "B",
        searchQuery: "b", hideDescriptionOverflow: true, action: .red, multiselect: true
      ).build()
    }
    let linked = try render { MenuItemView(id: "c", value: "c", label: "C", url: "/c").build() }

    assertSharedRules(
      plain.css, variant.css,
      contains: [
        "[data-disabled='true']", "[data-color='red']", "[data-selected='true'] .menu-item-checkbox",
        "[data-highlighted='true']", "[data-active='true']", "[data-label-weight='semibold'] .menu-item-label",
        "[data-hide-description-overflow='true'] .menu-item-description",
      ])
    XCTAssertEqual(plain.css, linked.css, "The link and the list item share the rules")

    XCTAssertEqual(attribute("data-disabled", in: plain.root), "false")
    XCTAssertEqual(attribute("data-disabled", in: variant.root), "true")
    XCTAssertEqual(attribute("data-selected", in: variant.root), "true")
    XCTAssertEqual(attribute("data-color", in: plain.root), "default")
    XCTAssertEqual(attribute("data-color", in: variant.root), "red")
    XCTAssertEqual(attribute("data-label-weight", in: plain.root), "normal")
    XCTAssertEqual(attribute("data-label-weight", in: variant.root), "semibold")
    XCTAssertEqual(attribute("data-highlighted", in: variant.root), "true")
    XCTAssertNil(attribute("data-highlighted", in: plain.root))
    XCTAssertEqual(linked.root.tag, "a")
  }

  func testDropdownVariantsShareOneStylesheetKeyedByDataAndCustomProperties() throws {
    let options = [DropdownView.DropdownOption(value: "x", display: "X")]
    let fluid = try render {
      DropdownView(id: "d1", name: "d1", label: "One", options: options).build()
    }
    let sized = try render {
      DropdownView(
        id: "d2", name: "d2", label: "Two", options: options, fullWidth: false, width: px(200),
        menuWidth: px(320), fontSize: fontSizeSmall14
      ).build()
    }
    let beside = try render {
      DropdownView(id: "d3", name: "d3", label: "Three", options: options, fullWidth: false, width: px(200)).build()
    }

    assertSharedRules(
      fluid.css, sized.css,
      contains: [
        "[data-full-width='true']", "[data-full-width='false']", "[data-fixed-width='true'] .dropdown-trigger-wrapper",
        "[data-menu-width='custom'] .dropdown-menu", "[data-menu-width='beside-fixed-trigger'] .dropdown-menu",
        "var(--dropdown-font-size)", "var(--dropdown-width)", "var(--dropdown-menu-width)",
      ])
    XCTAssertEqual(fluid.css, beside.css)

    XCTAssertEqual(attribute("data-full-width", in: fluid.root), "true")
    XCTAssertEqual(attribute("data-full-width", in: sized.root), "false")
    XCTAssertEqual(attribute("data-fixed-width", in: fluid.root), "false")
    XCTAssertEqual(attribute("data-fixed-width", in: sized.root), "true")
    XCTAssertEqual(attribute("data-menu-width", in: fluid.root), "auto")
    XCTAssertEqual(attribute("data-menu-width", in: sized.root), "custom")
    XCTAssertEqual(attribute("data-menu-width", in: beside.root), "beside-fixed-trigger")

    let fluidStyle = attribute("style", in: fluid.root) ?? ""
    let sizedStyle = attribute("style", in: sized.root) ?? ""
    XCTAssertTrue(fluidStyle.contains("--dropdown-font-size: \(fontSizeMedium16.value)"))
    XCTAssertFalse(fluidStyle.contains("--dropdown-width"))
    XCTAssertTrue(sizedStyle.contains("--dropdown-font-size: \(fontSizeSmall14.value)"))
    XCTAssertTrue(sizedStyle.contains("--dropdown-width: \(px(200).value)"))
    XCTAssertTrue(sizedStyle.contains("--dropdown-menu-width: \(px(320).value)"))
  }

  func testTextInputVariantsShareOneStylesheetWithInlineFontSize() throws {
    let medium = try render { TextInputView(id: "t1", name: "t1").build() }
    let small = try render { TextInputView(id: "t2", name: "t2", inputFontSize: fontSizeSmall14).build() }

    assertSharedRules(medium.css, small.css, contains: ["var(--text-input-font-size)"])
    XCTAssertTrue((attribute("style", in: medium.root) ?? "").contains("--text-input-font-size: \(fontSizeMedium16.value)"))
    XCTAssertTrue((attribute("style", in: small.root) ?? "").contains("--text-input-font-size: \(fontSizeSmall14.value)"))
  }

  func testComboboxVariantsShareOneStylesheetKeyedByLimit() throws {
    let unlimited = try render { ComboboxView(id: "c1", name: "c1").build() }
    let limited = try render { ComboboxView(id: "c2", name: "c2", visibleItemLimit: 5).build() }

    assertSharedRules(
      unlimited.css, limited.css,
      contains: ["[data-has-visible-limit='true'] .combobox-listbox", "var(--combobox-visible-limit-height)"])
    XCTAssertEqual(attribute("data-has-visible-limit", in: unlimited.root), "false")
    XCTAssertEqual(attribute("data-has-visible-limit", in: limited.root), "true")
    XCTAssertFalse((attribute("style", in: unlimited.root) ?? "").contains("--combobox-visible-limit-height"))
    XCTAssertTrue((attribute("style", in: limited.root) ?? "").contains("--combobox-visible-limit-height"))
  }

  func testTypeaheadSearchVariantsShareOneStylesheet() throws {
    let plain = try render { TypeaheadSearchView(id: "s1", formAction: "/s").build() }
    let expanding = try render {
      TypeaheadSearchView(id: "s2", formAction: "/s", showThumbnail: true, autoExpandWidth: true).build()
    }

    assertSharedRules(
      plain.css, expanding.css,
      contains: [
        "typeahead-search-show-thumbnail.typeahead-search-auto-expand-width .typeahead-search-input-wrapper"
      ])
    XCTAssertFalse((attribute("class", in: plain.root) ?? "").contains("typeahead-search-auto-expand-width"))
    XCTAssertTrue((attribute("class", in: expanding.root) ?? "").contains("typeahead-search-auto-expand-width"))
  }
}
