import CSSBuilder
import DOMBuilder
import Foundation
import HTMLBuilder
import WebTypes
import XCTest
@testable import WebComponents

/// The Lucide icon ports are tight: each viewBox is its stroked
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
    let regex = try! NSRegularExpression(pattern: #"[MmLlHhVvAaCcQqZz][^MmLlHhVvAaCcQqZz]*"#)
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
      case "C", "Q":
        // A Bézier: its end point and, per axis, where it turns.
        let order = command.uppercased() == "C" ? 6 : 4
        var i = 0
        while i + order - 1 < args.count {
          let base = (relative ? x : 0, relative ? y : 0)
          var points = [(x, y)]
          for k in stride(from: 0, to: order, by: 2) { points.append((base.0 + args[i + k], base.1 + args[i + k + 1])) }
          for t in stride(from: 0.0, through: 1.0, by: 1.0 / 512) {
            var level = points
            while level.count > 1 {
              level = (0..<(level.count - 1)).map { j in
                (level[j].0 + (level[j + 1].0 - level[j].0) * t, level[j].1 + (level[j + 1].1 - level[j].1) * t)
              }
            }
            bounds.add(level[0].0, level[0].1)
          }
          x = points[points.count - 1].0; y = points[points.count - 1].1; i += order
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
    // SVG scales a radius too small for the chord up to half the chord.
    let radius = max(radius, chord / 2)
    let h = max(0, radius * radius - chord * chord / 4).squareRoot()
    let midX = (start.0 + end.0) / 2, midY = (start.1 + end.1) / 2
    for sign in [1.0, -1.0] {
      let cx = midX - sign * dy / chord * h, cy = midY + sign * dx / chord * h
      let a1 = atan2(start.1 - cy, start.0 - cx)
      var delta = atan2(end.1 - cy, end.0 - cx) - a1
      if sweep { while delta < 0 { delta += 2 * .pi } } else { while delta > 0 { delta -= 2 * .pi } }
      if h < 1e-9 || (abs(delta) > .pi) == large {
        for step in 0...2000 {
          let angle = a1 + delta * Double(step) / 2000
          bounds.add(cx + radius * cos(angle), cy + radius * sin(angle))
        }
        return
      }
    }
    XCTFail("No arc center found")
  }

  func testIconPortsAreTightToTheirStrokedGlyph() throws {
    let icons: [(String, DOM.Node)] = [
      ("Plus", PlusIconView(size: px(22)).build()),
      ("ArchiveRestore", ArchiveRestoreIconView(size: px(22)).build()),
      ("ArrowDown", ArrowDownIconView(size: px(22)).build()),
      ("ArrowRight", ArrowRightIconView(size: px(22)).build()),
      ("ArrowLeft", ArrowLeftIconView(size: px(22)).build()),
      ("ArrowUp", ArrowUpIconView(size: px(22)).build()),
      ("FileText", FileTextIconView(size: px(22)).build()),
      ("FilePlus", FilePlusIconView(size: px(22)).build()),
      ("FileStack", FileStackIconView(size: px(22)).build()),
      ("Ban", BanIconView(size: px(22)).build()),
      ("Book", BookIconView(size: px(22)).build()),
      ("Bookmark", BookmarkIconView(size: px(22)).build()),
      ("BookmarkCheck", BookmarkCheckIconView(size: px(22)).build()),
      ("Braces", BracesIconView(size: px(22)).build()),
      ("Calendar", CalendarIconView(size: px(22)).build()),
      ("Check", CheckIconView(size: px(22)).build()),
      ("CheckCheck", CheckCheckIconView(size: px(22)).build()),
      ("CircleCheck", CircleCheckIconView(size: px(22)).build()),
      ("CircleX", CircleXIconView(size: px(22)).build()),
      ("Clock", ClockIconView(size: px(22)).build()),
      ("CodeXML", CodeXMLIconView(size: px(22)).build()),
      ("ChevronUp", ChevronUpIconView(size: px(22)).build()),
      ("SlidersVertical", SlidersVerticalIconView(size: px(22)).build()),
      ("Contrast", ContrastIconView(size: px(22)).build()),
      ("Copy", CopyIconView(size: px(22)).build()),
      ("Delete", DeleteIconView(size: px(22)).build()),
      ("Diff", DiffIconView(size: px(22)).build()),
      ("ChevronDown", ChevronDownIconView(size: px(22)).build()),
      ("Download", DownloadIconView(size: px(22)).build()),
      ("GripVertical", GripVerticalIconView(size: px(22)).build()),
      ("Pencil", PencilIconView(size: px(22)).build()),
      ("Ellipsis", EllipsisIconView(size: px(22)).build()),
      ("FaceSlightlySmilingPlus", FaceSlightlySmilingPlusIconView(size: px(22)).build()),
      ("Feather", FeatherIconView(size: px(22)).build()),
      ("Flag", FlagIconView(size: px(22)).build()),
      ("Gavel", GavelIconView(size: px(22)).build()),
      ("Globe", GlobeIconView(size: px(22)).build()),
      ("Heart", HeartIconView(size: px(22)).build()),
      ("CircleQuestionMark", CircleQuestionMarkIconView(size: px(22)).build()),
      ("MessageCircleQuestionMark", MessageCircleQuestionMarkIconView(size: px(22)).build()),
      ("History", HistoryIconView(size: px(22)).build()),
      ("House", HouseIconView(size: px(22)).build()),
      ("Image", ImageIconView(size: px(22)).build()),
      ("Inbox", InboxIconView(size: px(22)).build()),
      ("Info", InfoIconView(size: px(22)).build()),
      ("Integral", IntegralIconView(size: px(22)).build()),
      ("Key", KeyIconView(size: px(22)).build()),
      ("Languages", LanguagesIconView(size: px(22)).build()),
      ("Layers", LayersIconView(size: px(22)).build()),
      ("Link", LinkIconView(size: px(22)).build()),
      ("ExternalLink", ExternalLinkIconView(size: px(22)).build()),
      ("List", ListIconView(size: px(22)).build()),
      ("Lock", LockIconView(size: px(22)).build()),
      ("LogIn", LogInIconView(size: px(22)).build()),
      ("LogOut", LogOutIconView(size: px(22)).build()),
      ("Markdown", MarkdownIconView(size: px(22)).build()),
      ("Maximize", MaximizeIconView(size: px(22)).build()),
      ("Menu", MenuIconView(size: px(22)).build()),
      ("Merge", MergeIconView(size: px(22)).build()),
      ("MessageSquare", MessageSquareIconView(size: px(22)).build()),
      ("Minimize", MinimizeIconView(size: px(22)).build()),
      ("Moon", MoonIconView(size: px(22)).build()),
      ("ChevronFirst", ChevronFirstIconView(size: px(22)).build()),
      ("ChevronLast", ChevronLastIconView(size: px(22)).build()),
      ("SquareArrowOutUpRight", SquareArrowOutUpRightIconView(size: px(22)).build()),
      ("ChevronRight", ChevronRightIconView(size: px(22)).build()),
      ("OctagonAlert", OctagonAlertIconView(size: px(22)).build()),
      ("PanelTop", PanelTopIconView(size: px(22)).build()),
      ("PanelLeft", PanelLeftIconView(size: px(22)).build()),
      ("Pause", PauseIconView(size: px(22)).build()),
      ("Play", PlayIconView(size: px(22)).build()),
      ("ChevronLeft", ChevronLeftIconView(size: px(22)).build()),
      ("Quote", QuoteIconView(size: px(22)).build()),
      ("RefreshClockwise", RefreshClockwiseIconView(size: px(22)).build()),
      ("RefreshClockwiseOff", RefreshClockwiseOffIconView(size: px(22)).build()),
      ("RotateClockwise", RotateClockwiseIconView(size: px(22)).build()),
      ("RotateCounterclockwise", RotateCounterclockwiseIconView(size: px(22)).build()),
      ("Save", SaveIconView(size: px(22)).build()),
      ("ScrollText", ScrollTextIconView(size: px(22)).build()),
      ("Search", SearchIconView(size: px(22)).build()),
      ("Send", SendIconView(size: px(22)).build()),
      ("Settings", SettingsIconView(size: px(22)).build()),
      ("Forward", ForwardIconView(size: px(22)).build()),
      ("Square", SquareIconView(size: px(22)).build()),
      ("Stamp", StampIconView(size: px(22)).build()),
      ("StepForward", StepForwardIconView(size: px(22)).build()),
      ("Minus", MinusIconView(size: px(22)).build()),
      ("Sun", SunIconView(size: px(22)).build()),
      ("ArrowLeftRight", ArrowLeftRightIconView(size: px(22)).build()),
      ("TextWrap", TextWrapIconView(size: px(22)).build()),
      ("ThumbsDown", ThumbsDownIconView(size: px(22)).build()),
      ("ThumbsUp", ThumbsUpIconView(size: px(22)).build()),
      ("Trash2", Trash2IconView(size: px(22)).build()),
      ("TriangleAlert", TriangleAlertIconView(size: px(22)).build()),
      ("Undo2", Undo2IconView(size: px(22)).build()),
      ("Unlink", UnlinkIconView(size: px(22)).build()),
      ("Upload", UploadIconView(size: px(22)).build()),
      ("UserRound", UserRoundIconView(size: px(22)).build()),
      ("UserPlus", UserPlusIconView(size: px(22)).build()),
      ("LayoutList", LayoutListIconView(size: px(22)).build()),
      ("Volume2", Volume2IconView(size: px(22)).build()),
      ("X", XIconView(size: px(22)).build()),
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

      // The shapes in the box's own units, under no transform, the house
      // stroke on the svg as written (user, 2026-10-26).
      let stroke = try XCTUnwrap(Double(try XCTUnwrap(attribute("stroke-width", in: svg), name)), name)
      XCTAssertEqual(stroke, iconStrokeWidth, accuracy: 0.01, "\(name): the house stroke")

      var glyph = Bounds()
      for case let part as DOM.Element in svg.children {
        XCTAssertNil(attribute("transform", in: part), "\(name): no transform")
        switch part.tag {
        case "path":
          addPath(try XCTUnwrap(attribute("d", in: part), name), to: &glyph)
        case "rect":
          // `x`, `y`, `width`, `height` written with a px unit.
          let value = { (key: String) in self.numbers(self.attribute(key, in: part) ?? "")[0] }
          glyph.add(value("x"), value("y")); glyph.add(value("x") + value("width"), value("y") + value("height"))
        case "ellipse":
          let cx = Double(attribute("cx", in: part)!)!, cy = Double(attribute("cy", in: part)!)!
          let rx = numbers(attribute("rx", in: part)!)[0], ry = numbers(attribute("ry", in: part)!)[0]
          glyph.add(cx - rx, cy - ry); glyph.add(cx + rx, cy + ry)
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
      let half = stroke / 2
      let tolerance = 0.5
      XCTAssertEqual(glyph.minX - half, 0, accuracy: tolerance, "\(name): left margin")
      XCTAssertEqual(glyph.minY - half, 0, accuracy: tolerance, "\(name): top margin")
      XCTAssertEqual(glyph.maxX + half, box[2], accuracy: tolerance, "\(name): right margin")
      XCTAssertEqual(glyph.maxY + half, box[3], accuracy: tolerance, "\(name): bottom margin")
    }
  }
}
