import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): the sRGB cusp at twelve OKLCH hues
/// 30° apart from pure red's in light, mirrored in dark to the same contrast
/// against black; the increased-contrast schemes moving only lightness to 7:1.
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
      XCTAssertEqual(NamedColors.hex(name, .light), expected[name], name)
      let cusp = NamedColors.color(name, .light)
      XCTAssertEqual(cusp.c, NamedColors.maxChroma(l: cusp.l, h: cusp.h), accuracy: 1e-9)
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l + 0.01, h: cusp.h))
      XCTAssertGreaterThanOrEqual(cusp.c, NamedColors.maxChroma(l: cusp.l - 0.01, h: cusp.h))
    }
  }

  /// Dark mirrors light: the same hue, its contrast with black that of
  /// light's with white, within what 8-bit writing allows.
  func testDarkMirrorsLightsContrast() {
    for name in NamedColors.names {
      let light = NamedColors.color(name, .light), dark = NamedColors.color(name, .dark)
      let lightRatio = NamedColors.contrast(light, NamedColors.Scheme.light.page)
      let darkRatio = NamedColors.contrast(dark, NamedColors.Scheme.dark.page)
      XCTAssertEqual(darkRatio, lightRatio, accuracy: max(0.02, lightRatio * 0.01), name)
      XCTAssertEqual(dark.h, light.h, accuracy: 1e-9, "\(name) keeps its hue")
      if name != "gray" {
        XCTAssertEqual(dark.c, NamedColors.maxChroma(l: dark.l, h: dark.h), accuracy: 1e-9, "\(name) most chroma")
      }
      print(
        "\(name): light \(NamedColors.hex(name, .light)) \(String(format: "%.2f", lightRatio)):1, dark \(NamedColors.hex(name, .dark)) \(String(format: "%.2f", darkRatio)):1, light more \(NamedColors.hex(name, .lightMoreContrast)), dark more \(NamedColors.hex(name, .darkMoreContrast))")
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
