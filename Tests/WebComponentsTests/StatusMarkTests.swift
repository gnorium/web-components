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
      ("rotating-dotted-ring-sector-view", "Loading", {
        RotatingDottedRingSectorView(size: px(16), class: "roster-mark").build()
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
    // The sector rides on the idle mark's ring: its radius, whatever the
    // shared stroke (`iconStrokeWidth`) makes it.
    let radius = try XCTUnwrap(attribute("r", in: idleRing))
    XCTAssertTrue(path.contains("A \(radius),\(radius) "), "Expected the ring's \(radius)-radius arc; got: \(path)")
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

  func testDottedRingsDrawTwelveAndFiveRoundDotsOnTheSameCircle() throws {
    let still = try XCTUnwrap(DottedRingView(size: px(16)).build() as? DOM.Element)
    XCTAssertEqual(attribute("class", in: still), "dotted-ring-view")
    XCTAssertEqual(attribute("viewBox", in: still), "0 0 1024 1024")
    let ring = try XCTUnwrap(still.children[0] as? DOM.Element)
    let turning = try XCTUnwrap(RotatingDottedRingSectorView().build() as? DOM.Element)
    let sector = try XCTUnwrap(turning.children[0] as? DOM.Element)
    for part in [ring, sector] {
      XCTAssertEqual(part.tag, "path")
      XCTAssertEqual(attribute("stroke-linecap", in: part), "round")
      XCTAssertEqual(attribute("stroke-width", in: part), attribute("stroke-width", in: ring))
      XCTAssertEqual(attribute("stroke", in: part), "currentColor")
      XCTAssertEqual(attribute("fill", in: part), "none")
    }
    // Tight (user, 2026-10-21): the dots' outer edge on the box, as the
    // ring's, the stroke 2 of Lucide's 24.
    XCTAssertEqual(DottedRingView.radius, 512 - iconStrokeWidth / 2, accuracy: 0.001)
    XCTAssertEqual(DottedRingView.radius + iconStrokeWidth / 2, 512, accuracy: 0.001)
    XCTAssertEqual(DottedRingView.radius * 2 * Double.pi / DottedRingView.step, 12, accuracy: 0.001)
    // The pattern repeats each step: a point of a dash, the rest a gap.
    let pattern = try XCTUnwrap(attribute("stroke-dasharray", in: ring)).split(separator: " ").compactMap { Double($0) }
    XCTAssertEqual(pattern.count, 2)
    XCTAssertEqual(pattern[0] + pattern[1], DottedRingView.step, accuracy: 0.001)
    XCTAssertEqual(attribute("stroke-dasharray", in: sector), attribute("stroke-dasharray", in: ring))
    // The sector's 120° is four steps: five dots, both ends included.
    XCTAssertEqual(DottedRingView.radius * 2 * Double.pi / 3 / DottedRingView.step, 4, accuracy: 0.001)
    let d = try XCTUnwrap(attribute("d", in: sector))
    // It starts at the top of the same circle: M 512,(512 − r) A r,r …
    let numbers = d.split(whereSeparator: { !"0123456789.".contains($0) }).compactMap { Double($0) }
    XCTAssertTrue(d.hasPrefix("M"), d)
    XCTAssertGreaterThanOrEqual(numbers.count, 4, d)
    XCTAssertEqual(numbers[0], 512, accuracy: 0.01, d)
    XCTAssertEqual(numbers[1], 512 - DottedRingView.radius, accuracy: 0.01, d)
    XCTAssertEqual(numbers[2], DottedRingView.radius, accuracy: 0.01, d)
    XCTAssertEqual(numbers[3], DottedRingView.radius, accuracy: 0.01, d)
  }

  func testEveryMarkStopsRotationForReducedMotionWithoutHidingTheShape() throws {
    for build in [
      { RotatingSectorView().build() },
      { RotatingDottedRingSectorView().build() },
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
      RotatingDottedRingSectorView(ariaHidden: true).build(),
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

  /// A hand-built (client) alert wears its own color's mark: blue the info
  /// icon, orange the triangle, red the octagon, green the check.
  func testAnAlertColorChoosesItsStatusMark() {
    XCTAssertEqual(StatusIconView.Status.forAlertColor("blue"), .info)
    XCTAssertEqual(StatusIconView.Status.forAlertColor("gray"), .info)
    XCTAssertEqual(StatusIconView.Status.forAlertColor("orange"), .warning)
    XCTAssertEqual(StatusIconView.Status.forAlertColor("red"), .error)
    XCTAssertEqual(StatusIconView.Status.forAlertColor("green"), .success)
  }
}
