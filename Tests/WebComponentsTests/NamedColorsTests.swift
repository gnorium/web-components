import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): the sRGB cusp at twelve OKLCH hues
/// 30° apart from pure red's, the same in light and dark; the
/// increased-contrast schemes moving only lightness to 7:1.
final class NamedColorsTests: XCTestCase {
  func testEachColorIsTheCuspEveryThirtyDegreesFromRed() {
    let expected = [
      "red": "#FF0000", "orange": "#FF8E00", "yellow": "#FFCA00", "lime": "#DCFF00", "green": "#00FF73",
      "mint": "#00FFDF", "cyan": "#00E5FF", "blue": "#00B0FF", "indigo": "#2C00FF", "violet": "#9000FF",
      "magenta": "#FF00FB", "pink": "#FF008A",
    ]
    XCTAssertEqual(
      NamedColors.names,
      ["red", "orange", "yellow", "lime", "green", "mint", "cyan", "blue", "indigo", "violet", "magenta", "pink",
       "gray"])
    XCTAssertEqual(NamedColors.redHue, 29.23, accuracy: 0.005)
    for (index, name) in NamedColors.hueNames.enumerated() {
      XCTAssertEqual(NamedColors.hue(name), (NamedColors.redHue + 30 * Double(index)).truncatingRemainder(dividingBy: 360))
      for scheme in [NamedColors.Scheme.light, .dark] {
        XCTAssertEqual(NamedColors.hex(name, scheme), expected[name], "\(name) \(scheme)")
      }
      let cusp = NamedColors.color(name, .light)
      XCTAssertEqual(cusp.c, NamedColors.maxChroma(l: cusp.l, h: cusp.h), accuracy: 1e-9)
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l + 0.01, h: cusp.h))
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l - 0.01, h: cusp.h))
    }
  }

  func testIncreasedContrastMovesOnlyLightnessToSevenToOne() {
    for scheme in [NamedColors.Scheme.lightMoreContrast, .darkMoreContrast] {
      for name in NamedColors.names {
        let color = NamedColors.color(name, scheme)
        let base = NamedColors.color(name, scheme.isDark ? .dark : .light)
        XCTAssertGreaterThanOrEqual(NamedColors.contrast(color, scheme.page), 7, "\(name) \(scheme)")
        XCTAssertEqual(color.h, base.h, accuracy: 1e-9, "\(name) keeps its hue")
        if name != "gray", color != base {
          XCTAssertEqual(color.c, NamedColors.maxChroma(l: color.l, h: color.h), accuracy: 1e-9, "\(name) most chroma")
        }
        let subtle = NamedColors.moreContrastSubtle(name, scheme)
        XCTAssertGreaterThanOrEqual(NamedColors.contrast(subtle, scheme.baseText), 7, "\(name) \(scheme) subtle")
        print("\(scheme) \(name): \(NamedColors.hex(name, scheme)) subtle \(NamedColors.hex(subtle))")
      }
    }
  }
}
