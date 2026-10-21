import CSSBuilder
import DOMBuilder
import Foundation
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// The status-mark Lucide ports are tight: each viewBox is its stroked
/// glyph's own bounding box, measured here from the drawn geometry (paths
/// and circles, arcs sampled), not from the bounds the view declares.
final class LucideIconTightnessTests: XCTestCase {
  private struct Bounds {
    var minX = Double.infinity, minY = Double.infinity
    var maxX = -Double.infinity, maxY = -Double.infinity
    mutating func add(_ x: Double, _ y: Double) {
      minX = min(minX, x); minY = min(minY, y)
      maxX = max(maxX, x); maxY = max(maxY, y)
    }
  }

  private func attribute(_ name: String, in element: DOM.Element) -> String? {
    element.attributes.first { $0.0 == name }?.1
  }

  private func numbers(_ text: String) -> [Double] {
    let regex = try! NSRegularExpression(pattern: #"-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?"#)
    let range = NSRange(text.startIndex..., in: text)
    return regex.matches(in: text, range: range).map { Double(text[Range($0.range, in: text)!])! }
  }

  /// Adds every point of an SVG path's centerline, arcs sampled.
  private func addPath(_ d: String, to bounds: inout Bounds) {
    let regex = try! NSRegularExpression(pattern: #"[MmLlHhVvAaCcZz][^MmLlHhVvAaCcZz]*"#)
    var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0
    for match in regex.matches(in: d, range: NSRange(d.startIndex..., in: d)) {
      let segment = String(d[Range(match.range, in: d)!])
      let command = segment.first!
      let args = numbers(String(segment.dropFirst()))
      let relative = command.isLowercase
      switch command.uppercased() {
      case "M", "L":
        var i = 0
        while i + 1 < args.count {
          x = (relative ? x : 0) + args[i]; y = (relative ? y : 0) + args[i + 1]
          if i == 0 && command.uppercased() == "M" { startX = x; startY = y }
          bounds.add(x, y); i += 2
        }
      case "H":
        for value in args { x = (relative ? x : 0) + value; bounds.add(x, y) }
      case "V":
        for value in args { y = (relative ? y : 0) + value; bounds.add(x, y) }
      case "A":
        var i = 0
        while i + 6 < args.count {
          let r = args[i], large = args[i + 3] != 0, sweep = args[i + 4] != 0
          let endX = (relative ? x : 0) + args[i + 5], endY = (relative ? y : 0) + args[i + 6]
          addArc(from: (x, y), to: (endX, endY), radius: r, large: large, sweep: sweep, to: &bounds)
          x = endX; y = endY; i += 7
        }
      case "C":
        // A cubic Bézier: its end point; its control points lie inside the
        // glyph's bounds for every ported icon (the stamp's), so the curve
        // reaches no farther than its other parts.
        var i = 0
        while i + 5 < args.count {
          x = (relative ? x : 0) + args[i + 4]; y = (relative ? y : 0) + args[i + 5]
          bounds.add(x, y); i += 6
        }
      case "Z":
        x = startX; y = startY
      default:
        XCTFail("Unexpected path command \(command) in \(d)")
      }
    }
  }

  /// A circular arc (rx = ry, no rotation), sampled along its sweep.
  private func addArc(
    from start: (Double, Double), to end: (Double, Double), radius: Double, large: Bool, sweep: Bool,
    to bounds: inout Bounds
  ) {
    let dx = end.0 - start.0, dy = end.1 - start.1
    let chord = (dx * dx + dy * dy).squareRoot()
    let h = max(0, radius * radius - chord * chord / 4).squareRoot()
    let midX = (start.0 + end.0) / 2, midY = (start.1 + end.1) / 2
    for sign in [1.0, -1.0] {
      let cx = midX - sign * dy / chord * h, cy = midY + sign * dx / chord * h
      let a1 = atan2(start.1 - cy, start.0 - cx)
      var delta = atan2(end.1 - cy, end.0 - cx) - a1
      if sweep { while delta < 0 { delta += 2 * .pi } } else { while delta > 0 { delta -= 2 * .pi } }
      if (abs(delta) > .pi) == large {
        for step in 0...2000 {
          let angle = a1 + delta * Double(step) / 2000
          bounds.add(cx + radius * cos(angle), cy + radius * sin(angle))
        }
        return
      }
    }
    XCTFail("No arc center found")
  }

  func testStatusMarkPortsAreTightToTheirStrokedGlyph() throws {
    let icons: [(String, DOM.Node)] = [
      ("check", CheckIconView(size: px(22)).build()),
      ("x", XIconView(size: px(22)).build()),
      ("octagon-alert", OctagonAlertIconView(size: px(22)).build()),
      ("triangle-alert", TriangleAlertIconView(size: px(22)).build()),
      ("circle-check", CircleCheckIconView(size: px(22)).build()),
      ("info", InfoIconView(size: px(22)).build()),
      ("arrow-right", ArrowRightIconView(size: px(22)).build()),
      ("stamp", StampIconView(size: px(22)).build()),
    ]
    for (name, node) in icons {
      let svg = try XCTUnwrap(node as? DOM.Element, name)
      let box = numbers(try XCTUnwrap(attribute("viewBox", in: svg), name))
      XCTAssertEqual(box.count, 4, name)
      XCTAssertEqual(box[0], 0, name)
      XCTAssertEqual(box[1], 0, name)
      XCTAssertEqual(max(box[2], box[3]), 1024, accuracy: 0.01, "\(name): the long edge is 1024")
      // The size token sits on the long edge (height when square), in CSS;
      // none in attributes.
      let style = try XCTUnwrap(attribute("style", in: svg), name)
      XCTAssertEqual(style, box[2] > box[3] ? "width: 22px;" : "height: 22px;", name)
      XCTAssertNil(attribute("width", in: svg), name)
      XCTAssertNil(attribute("height", in: svg), name)
      XCTAssertEqual(attribute("stroke-linecap", in: svg), "round", name)
      XCTAssertEqual(attribute("stroke-linejoin", in: svg), "round", name)

      let group = try XCTUnwrap(svg.children.first as? DOM.Element, name)
      let transform = numbers(try XCTUnwrap(attribute("transform", in: group), name))
      XCTAssertEqual(transform.count, 3, name)
      let (tx, ty, scale) = (transform[0], transform[1], transform[2])
      let stroke = try XCTUnwrap(Double(try XCTUnwrap(attribute("stroke-width", in: group), name)), name)
      XCTAssertEqual(stroke * scale, iconStrokeWidth, accuracy: 0.01, "\(name): the shared stroke")

      var glyph = Bounds()
      for case let part as DOM.Element in group.children {
        switch part.tag {
        case "path":
          addPath(try XCTUnwrap(attribute("d", in: part), name), to: &glyph)
        case "circle":
          let cx = Double(attribute("cx", in: part)!)!, cy = Double(attribute("cy", in: part)!)!
          let r = Double(attribute("r", in: part)!)!
          glyph.add(cx - r, cy - r); glyph.add(cx + r, cy + r)
        default:
          XCTFail("\(name): unexpected \(part.tag)")
        }
      }
      // Round caps and joins reach half the stroke past the centerline in
      // every direction: the stroked glyph touches all four sides.
      let half = iconStrokeWidth / 2
      let tolerance = 0.5
      XCTAssertEqual(glyph.minX * scale + tx - half, 0, accuracy: tolerance, "\(name): left margin")
      XCTAssertEqual(glyph.minY * scale + ty - half, 0, accuracy: tolerance, "\(name): top margin")
      XCTAssertEqual(glyph.maxX * scale + tx + half, box[2], accuracy: tolerance, "\(name): right margin")
      XCTAssertEqual(glyph.maxY * scale + ty + half, box[3], accuracy: tolerance, "\(name): bottom margin")
    }
  }
}
