import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11; design-notes/iscc-nbs-vivid-cusps.html):
/// each hue derived from its vivid ISCC–NBS centroid through the Munsell
/// renotation, each color the sRGB cusp at that hue, and the
/// increased-contrast schemes moving only lightness to 7:1.
final class NamedColorsTests: XCTestCase {
  /// The renotation entries (Newhall, Nickerson & Judd 1943, real.dat; xyY
  /// under Illuminant C) that bracket each vivid centroid's notation.
  static let renotation: [(String, Double, Double, Double, Double, Double)] = [
    ("10PB", 2, 20, 0.1998, 0.0718, 3.126), ("10PB", 2, 22, 0.1978, 0.0643, 3.126),
    ("2.5P", 2, 20, 0.2320, 0.0779, 3.126), ("2.5P", 2, 22, 0.2298, 0.0696, 3.126),
    ("10PB", 3, 20, 0.2030, 0.0930, 6.555), ("10PB", 3, 22, 0.2004, 0.0847, 6.555),
    ("2.5P", 3, 20, 0.2354, 0.1003, 6.555), ("2.5P", 3, 22, 0.2329, 0.0911, 6.555),
    ("5P", 3, 20, 0.2639, 0.1074, 6.555), ("7.5P", 3, 20, 0.2961, 0.1151, 6.555),
    ("5R", 4, 14, 0.5734, 0.3057, 12.000), ("5R", 4, 16, 0.6039, 0.2978, 12.000),
    ("7.5R", 4, 14, 0.5959, 0.3269, 12.000), ("7.5R", 4, 16, 0.6260, 0.3192, 12.000),
    ("2.5PB", 4, 14, 0.1473, 0.1513, 12.000), ("2.5PB", 4, 16, 0.1336, 0.1349, 12.000),
    ("5PB", 4, 14, 0.1627, 0.1479, 12.000), ("5PB", 4, 16, 0.1504, 0.1317, 12.000),
    ("5P", 4, 20, 0.2670, 0.1300, 12.000), ("7.5P", 4, 20, 0.3010, 0.1396, 12.000),
    ("5G", 5, 18, 0.1489, 0.5171, 19.770), ("7.5G", 5, 18, 0.1372, 0.4705, 19.770),
    ("2.5PB", 5, 14, 0.1642, 0.1728, 19.770), ("2.5PB", 5, 16, 0.1495, 0.1559, 19.770),
    ("5PB", 5, 14, 0.1773, 0.1689, 19.770), ("5PB", 5, 16, 0.1638, 0.1521, 19.770),
    ("2.5YR", 6, 16, 0.5698, 0.3990, 30.050), ("5YR", 6, 16, 0.5597, 0.4239, 30.050),
    ("5G", 6, 18, 0.1785, 0.4924, 30.050), ("7.5G", 6, 18, 0.1654, 0.4551, 30.050),
    ("10RP", 7, 12, 0.4260, 0.2980, 43.060), ("10RP", 7, 14, 0.4456, 0.2931, 43.060),
    ("2.5R", 7, 12, 0.4435, 0.3119, 43.060), ("2.5R", 7, 14, 0.4660, 0.3082, 43.060),
    ("2.5YR", 7, 16, 0.5522, 0.3989, 43.060), ("5YR", 7, 16, 0.5437, 0.4228, 43.060),
    ("2.5Y", 7, 14, 0.4950, 0.4773, 43.060), ("2.5Y", 7, 16, 0.5049, 0.4843, 43.060),
    ("5Y", 7, 14, 0.4791, 0.4965, 43.060), ("5Y", 7, 16, 0.4875, 0.5047, 43.060),
    ("2.5Y", 8, 14, 0.4842, 0.4712, 59.100), ("2.5Y", 8, 16, 0.4957, 0.4800, 59.100),
    ("5Y", 8, 14, 0.4699, 0.4920, 59.100), ("5Y", 8, 16, 0.4791, 0.5012, 59.100),
  ]

  static let families = ["R", "YR", "Y", "GY", "G", "BG", "B", "PB", "P", "RP"]

  /// ASTM D1535 hue number (10RP = 0) of a hue like "2.5PB".
  static func hueNumber(_ text: Substring) -> Double {
    let digits = text.prefix { $0.isNumber || $0 == "." }
    let family = families.firstIndex(of: String(text.dropFirst(digits.count)))!
    return (Double(family) * 10 + Double(digits)!).truncatingRemainder(dividingBy: 100)
  }

  /// xy on a hue page at an integer value, linear in chroma.
  static func page(_ hue: Double, _ value: Double, _ chroma: Double) -> (Double, Double) {
    let rows = renotation.filter { abs(hueNumber(Substring($0.0)) - hue) < 1e-9 && $0.1 == value }
    let low = rows.filter { $0.2 <= chroma }.max { $0.2 < $1.2 }!
    let high = rows.filter { $0.2 >= chroma }.min { $0.2 < $1.2 }!
    let t = high.2 == low.2 ? 0 : (chroma - low.2) / (high.2 - low.2)
    return (low.3 + (high.3 - low.3) * t, low.4 + (high.4 - low.4) * t)
  }

  /// A Munsell notation's OKLCH hue: xy linear in chroma, hue and value,
  /// Y by ASTM D1535, Illuminant C adapted to D65 by Bradford, OKLab.
  static func oklchHue(_ notation: String) -> Double {
    let parts = notation.split(separator: " ")
    let vc = parts[1].split(separator: "/")
    let h = hueNumber(parts[0]), v = Double(vc[0])!, c = Double(vc[1])!
    let low = (h / 2.5).rounded(.down) * 2.5, th = (h - low) / 2.5
    var xys: [(Double, (Double, Double))] = []
    for value in Set([v.rounded(.down), v.rounded(.up)]).sorted() {
      let a = page(low.truncatingRemainder(dividingBy: 100), value, c)
      let b = page((low + 2.5).truncatingRemainder(dividingBy: 100), value, c)
      xys.append((value, (a.0 + (b.0 - a.0) * th, a.1 + (b.1 - a.1) * th)))
    }
    var (x, y) = xys[0].1
    if xys.count == 2 {
      let t = (v - xys[0].0) / (xys[1].0 - xys[0].0)
      x += (xys[1].1.0 - x) * t
      y += (xys[1].1.1 - y) * t
    }
    let Y = (1.1914 * v - 0.22533 * v * v + 0.23352 * pow(v, 3) - 0.020484 * pow(v, 4) + 0.00081939 * pow(v, 5)) / 100
    let xyz = [x * Y / y, Y, (1 - x - y) * Y / y]
    // Bradford, C to D65.
    let m = [[0.8951, 0.2664, -0.1614], [-0.7502, 1.7135, 0.0367], [0.0389, -0.0685, 1.0296]]
    let mi = [[0.9869929, -0.1470543, 0.1599627], [0.4323053, 0.5183603, 0.0492912], [-0.0085287, 0.0400428, 0.9684867]]
    func mul(_ a: [[Double]], _ v: [Double]) -> [Double] { a.map { r in zip(r, v).map(*).reduce(0, +) } }
    func white(_ x: Double, _ y: Double) -> [Double] { [x / y, 1, (1 - x - y) / y] }
    let cC = mul(m, white(0.31006, 0.31616)), c65 = mul(m, white(0.31271, 0.32902))
    let cone = mul(m, xyz)
    let d65 = mul(mi, (0..<3).map { cone[$0] * c65[$0] / cC[$0] })
    let lms = mul(
      [[0.8189330101, 0.3618667424, -0.1288597137], [0.0329845436, 0.9293118715, 0.0361456387],
       [0.0482003018, 0.2643662691, 0.6338517070]], d65
    ).map { cbrt($0) }
    let a = 1.9779984951 * lms[0] - 2.4285922050 * lms[1] + 0.4505937099 * lms[2]
    let b = 0.0259040371 * lms[0] + 0.7827717662 * lms[1] - 0.8086757660 * lms[2]
    let hue = atan2(b, a) * 180 / .pi
    return hue < 0 ? hue + 360 : hue
  }

  func testEachHueIsItsVividCentroidsHueViaTheRenotation() {
    for hue in NamedColors.hues {
      XCTAssertEqual(Self.oklchHue(hue.notation), hue.h, accuracy: 0.001, "\(hue.name) (\(hue.notation))")
    }
  }

  func testEachColorIsTheCuspAtItsHue() {
    let expected = [
      "pink": "#FF0059", "red": "#FF0042", "orange": "#FF8D00", "yellow": "#FFD200",
      "green": "#00FFCA", "blue": "#00B7FF", "violet": "#9C00FF", "purple": "#DF00FF",
    ]
    for (name, hex) in expected {
      for scheme in [NamedColors.Scheme.light, .dark] {
        XCTAssertEqual(NamedColors.hex(NamedColors.color(name, scheme)), hex, "\(name) \(scheme)")
      }
      let cusp = NamedColors.color(name, .light)
      // On the gamut boundary at the most chromatic lightness.
      XCTAssertEqual(cusp.c, NamedColors.maxChroma(l: cusp.l, h: cusp.h), accuracy: 1e-9)
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l + 0.01, h: cusp.h))
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l - 0.01, h: cusp.h))
    }
    XCTAssertEqual(NamedColors.names, ["pink", "red", "orange", "yellow", "green", "blue", "violet", "purple", "gray"])
  }

  func testIncreasedContrastMovesOnlyLightnessToSevenToOne() {
    for scheme in [NamedColors.Scheme.lightMoreContrast, .darkMoreContrast] {
      for name in NamedColors.names {
        let color = NamedColors.color(name, scheme)
        let base = NamedColors.color(name, scheme.isDark ? .dark : .light)
        XCTAssertGreaterThanOrEqual(NamedColors.contrast(color, scheme.page), 7, "\(name) \(scheme)")
        XCTAssertEqual(color.h, base.h, "\(name) keeps its hue")
        if name != "gray" {
          XCTAssertEqual(color.c, NamedColors.maxChroma(l: color.l, h: color.h), accuracy: 1e-9, "\(name) most chroma")
        }
        let subtle = NamedColors.moreContrastSubtle(name, scheme)
        XCTAssertGreaterThanOrEqual(NamedColors.contrast(subtle, scheme.baseText), 7, "\(name) \(scheme) subtle")
        print("\(scheme) \(name): \(NamedColors.hex(color)) subtle \(NamedColors.hex(subtle))")
      }
    }
  }
}
