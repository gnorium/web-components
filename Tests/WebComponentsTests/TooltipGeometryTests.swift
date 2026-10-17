import XCTest
@testable import WebComponents

/// Every placement points its arrow at the trigger's center and keeps the
/// bubble inside the bounds, wrapped (a UUID at 256px) or on one line.
final class TooltipGeometryTests: XCTestCase {
  private typealias Geometry = TooltipView.Geometry

  /// The trigger's center as the bubble's arrow points: the start plus the
  /// arrow's offset.
  private func pointed(
    _ placement: TooltipView.Placement, size: Double, trigger: (Double, Double), extent: Double, gutter: Double
  ) -> (placement: TooltipView.Placement, start: Double, arrowAt: Double) {
    let (chosen, start) = Geometry.choose(
      placement, size: size, triggerStart: trigger.0, triggerEnd: trigger.1, extent: extent, bounds: [gutter, 0])
    let inset = min(Geometry.arrowInset, size / 2)
    let arrow = Geometry.arrow(start: start, size: size, triggerStart: trigger.0, triggerEnd: trigger.1, inset: inset)
    return (chosen, start, start + arrow)
  }

  /// The prompt legend's ⓘ on a 1265px viewport: a wrapped UUID starts the
  /// arrow's inset before the trigger's center, its arrow over that center.
  func testTopStartWrappedUUIDPointsAtTrigger() {
    let result = pointed(.topStart, size: 256, trigger: (420.25, 436.25), extent: 1265, gutter: 63.25)
    XCTAssertEqual(result.placement, .topStart)
    XCTAssertEqual(result.start, 428.25 - 22, accuracy: 0.001)
    XCTAssertEqual(result.arrowAt, 428.25, accuracy: 0.001)
  }

  func testEveryAlignmentPointsAtTriggerAndStaysInside() {
    let sizes = [60.0, 180.0, 256.0]
    let extent = 1265.0
    let gutter = 63.25
    for placement in TooltipView.Placement.allCases {
      for size in sizes {
        for left in stride(from: 0.0, through: extent - 20, by: 7.3) {
          let trigger = (left, left + 20)
          let result = pointed(placement, size: size, trigger: trigger, extent: extent, gutter: gutter)
          XCTAssertGreaterThanOrEqual(result.start, -0.001, "\(placement) \(size) \(left)")
          XCTAssertLessThanOrEqual(result.start + size, extent + 0.001, "\(placement) \(size) \(left)")
          let center = left + 10
          // Clear of the gutter, the arrow reaches the center; at the very
          // edge, as near as the corners allow.
          if center - Geometry.arrowInset >= 0 && center + Geometry.arrowInset <= extent {
            XCTAssertEqual(result.arrowAt, center, accuracy: 0.01, "\(placement) \(size) \(left)")
          }
        }
      }
    }
  }

  /// Near the far edge a start bubble shifts back as far as its arrow
  /// allows, inside the gutter when the end alignment fits there.
  func testStartShiftsBackAtTheFarEdge() {
    let inGutter = pointed(.topStart, size: 256, trigger: (1100, 1120), extent: 1265, gutter: 63.25)
    XCTAssertEqual(inGutter.arrowAt, 1110, accuracy: 0.001)
    XCTAssertLessThanOrEqual(inGutter.start + 256, 1265 - 63.25 + 0.001)
    // The trigger itself in the gutter: the bubble follows it there.
    let atEdge = pointed(.topStart, size: 256, trigger: (1180, 1200), extent: 1265, gutter: 63.25)
    XCTAssertEqual(atEdge.arrowAt, 1190, accuracy: 0.001)
    XCTAssertLessThanOrEqual(atEdge.start + 256, 1265 + 0.001)
  }

  /// A center that is no exact binary fraction: the start computed from it
  /// and the arrow computed back may miss the inset by a rounding error,
  /// which must not reject the placement.
  func testRoundingDoesNotRejectThePlacement() {
    let result = pointed(.topStart, size: 256, trigger: (420.3, 436.3), extent: 1265, gutter: 63.25)
    XCTAssertEqual(result.placement, .topStart)
    XCTAssertEqual(result.arrowAt, 428.3, accuracy: 0.001)
  }

  /// Beside the trigger, along the vertical axis: the same arithmetic.
  func testRightStartPointsAtTriggerMiddle() {
    let result = pointed(.rightStart, size: 60, trigger: (400, 416), extent: 900, gutter: 8)
    XCTAssertEqual(result.placement, .rightStart)
    XCTAssertEqual(result.arrowAt, 408, accuracy: 0.001)
  }

  /// The safe triangle, measured on a vignette page: the pointer leaves the
  /// ⓘ sideways, just right of it, on a diagonal to the bubble's link; every
  /// step of that path heads for the bubble, a turn away from it does not.
  func testDiagonalLeaveHeadsForTheBubble() {
    let trigger = Geometry.Box(left: 821.5, top: 219, right: 837.5, bottom: 235)
    let bubble = Geometry.Box(left: 807.5, top: 151, right: 1063.5, bottom: 211)
    let center = (x: 829.5, y: 227.0)
    let link = (x: 930.7, y: 181.0)
    let left = (x: 837.9, y: 223.2)
    XCTAssertTrue(Geometry.aims(x: left.x, y: left.y, from: center, trigger: trigger, bubble: bubble, gap: 8))
    for step in 1...12 {
      let t = Double(step) / 12
      let x = center.x + (link.x - center.x) * t
      let y = center.y + (link.y - center.y) * t
      XCTAssertTrue(Geometry.aims(x: x, y: y, from: left, trigger: trigger, bubble: bubble, gap: 8), "step \(step)")
    }
    // Along the trigger's row, below the bubble, and away to the corner.
    XCTAssertFalse(Geometry.aims(x: 900, y: 227, from: left, trigger: trigger, bubble: bubble, gap: 8))
    XCTAssertFalse(Geometry.aims(x: 0, y: 0, from: center, trigger: trigger, bubble: bubble, gap: 8))
  }
}
