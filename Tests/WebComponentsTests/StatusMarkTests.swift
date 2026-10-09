import CSSBuilder
import DOMBuilder
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

final class StatusMarkTests: XCTestCase {
  private func attribute(_ name: String, in element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func capture(_ build: () -> DOM.Node) throws -> (DOM.Element, String, String) {
    var node: DOM.Node?
    let styles = HTMLGlobalStyle.collecting { node = build() }.currentStyleSheets()
    XCTAssertEqual(styles.count, 1)
    let sheet = try XCTUnwrap(styles.first)
    return (try XCTUnwrap(node as? DOM.Element), sheet.owner, sheet.css)
  }

  func testMarksOwnTheirClassesSizesAndAccessibleLabels() throws {
    let cases: [(String, String, () -> DOM.Node)] = [
      ("rotating-sector-view", "Explication running", {
        RotatingSectorView(size: px(16), class: "roster-mark").build()
      }),
      ("rotating-ring-sector-view", "Translation layer loading", {
        RotatingRingSectorView(size: px(16), class: "roster-mark").build()
      }),
      ("rotating-ring-sector-with-disc-view", "Translation running", {
        RotatingRingSectorWithDiscView(size: px(16), class: "roster-mark").build()
      }),
    ]
    for (owner, label, build) in cases {
      let (root, styleOwner, css) = try capture(build)
      XCTAssertEqual(root.tag, "svg")
      XCTAssertEqual(attribute("class", in: root), "\(owner) roster-mark")
      XCTAssertEqual(attribute("viewBox", in: root), "0 0 1024 1024")
      XCTAssertEqual(attribute("style", in: root), "width: 16px; height: 16px;")
      XCTAssertEqual(attribute("role", in: root), "progressbar")
      XCTAssertEqual(attribute("aria-label", in: root), label)
      XCTAssertEqual(styleOwner, owner)
      XCTAssertFalse(css.contains("roster-mark"))
      XCTAssertFalse(css.contains("16px"))
    }
  }

  func testRingGeometryMatchesRingedDiscMarkAndOnlyTheRingAnimates() throws {
    let (root, _, css) = try capture { RotatingRingSectorWithDiscView().build() }
    let idle = try XCTUnwrap(RingedDiscIconView(size: px(8)).build() as? DOM.Element)
    let disc = try XCTUnwrap(root.children[0] as? DOM.Element)
    let ring = try XCTUnwrap(root.children[1] as? DOM.Element)
    let idleDisc = try XCTUnwrap(idle.children[0] as? DOM.Element)
    let idleRing = try XCTUnwrap(idle.children[1] as? DOM.Element)
    XCTAssertEqual(root.children.count, 2)
    XCTAssertEqual(disc.tag, "circle")
    XCTAssertEqual(ring.tag, "path")
    for key in ["cx", "cy", "r"] {
      XCTAssertEqual(attribute(key, in: disc), attribute(key, in: idleDisc))
    }
    XCTAssertEqual(attribute("stroke-width", in: ring), attribute("stroke-width", in: idleRing))
    XCTAssertEqual(attribute("stroke", in: ring), "currentColor")
    XCTAssertEqual(attribute("fill", in: root), "currentColor")
    let path = try XCTUnwrap(attribute("d", in: ring))
    XCTAssertTrue(path.contains("A 448,448 "), "Expected the ring's 448-radius arc; got: \(path)")
    XCTAssertNil(attribute("style", in: disc))
    XCTAssertFalse(css.contains("rotating-ring-sector-with-disc-core"))
    let animatedBlocks = css.components(separatedBy: "}").filter { $0.contains("animation:") }
    XCTAssertEqual(animatedBlocks.count, 2)
    for block in animatedBlocks {
      XCTAssertTrue(
        block.contains(".rotating-ring-sector-with-disc-view> .rotating-ring-sector-with-disc-ring"),
        "Animation must target only the ring child; got: \(block)")
    }
  }

  func testEveryMarkStopsRotationForReducedMotionWithoutHidingTheShape() throws {
    for build in [
      { RotatingSectorView().build() },
      { RotatingRingSectorView().build() },
      { RotatingRingSectorWithDiscView().build() },
    ] {
      let (root, _, css) = try capture(build)
      XCTAssertTrue(css.contains("prefers-reduced-motion: reduce"))
      XCTAssertTrue(css.contains("animation: none;"))
      XCTAssertTrue(css.contains("var(--animation-duration-fast)"))
      XCTAssertTrue(css.contains("var(--animation-timing-function-base)"))
      XCTAssertTrue(css.contains("transform-origin: 50% 50%;"))
      XCTAssertFalse(css.contains("display: none"))
      XCTAssertTrue(root.children.contains { ($0 as? DOM.Element)?.tag == "path" })
    }
  }

  func testDecorativeMarksDoNotAnnounceLabels() throws {
    let marks = [
      RotatingSectorView(ariaHidden: true).build(),
      RotatingRingSectorView(ariaHidden: true).build(),
      RotatingRingSectorWithDiscView(ariaHidden: true).build(),
    ]
    for mark in marks {
      let root = try XCTUnwrap(mark as? DOM.Element)
      XCTAssertEqual(attribute("aria-hidden", in: root), "true")
      XCTAssertNil(attribute("aria-label", in: root))
    }
  }

  func testLabeledSectorRetainsItsOwnScopeAndDoesNotAnimateTheLabel() throws {
    let (root, owner, css) = try capture {
      RotatingSectorView(showLabel: true, ariaLabel: "Working", class: "custom") {
        "Working"
      }.build()
    }
    XCTAssertEqual(root.tag, "div")
    XCTAssertEqual(attribute("class", in: root), "rotating-sector-view custom")
    XCTAssertEqual(owner, "rotating-sector-view")
    XCTAssertEqual(root.children.count, 2)
    let svg = try XCTUnwrap(root.children[0] as? DOM.Element)
    let label = try XCTUnwrap(root.children[1] as? DOM.Element)
    XCTAssertEqual(svg.tag, "svg")
    XCTAssertEqual(attribute("aria-hidden", in: svg), "true")
    XCTAssertEqual(attribute("class", in: label), "rotating-sector-label")
    XCTAssertTrue(css.contains("gap: var(--spacing-8);"))
    for block in css.components(separatedBy: "}").filter({ $0.contains("animation:") }) {
      XCTAssertTrue(block.contains(".rotating-sector-shape"))
    }
  }
}
