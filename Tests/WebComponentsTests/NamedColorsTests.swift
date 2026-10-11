import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): the RGB wheel's twelve pure hues, HSV at
/// full saturation and value, the same in light and dark; the
/// increased-contrast schemes moving only lightness to 7:1.
final class NamedColorsTests: XCTestCase {
  func testEachColorIsItsWheelHue() {
    let expected = [
      "red": "#FF0000", "orange": "#FF8000", "yellow": "#FFFF00", "chartreuse": "#80FF00", "green": "#00FF00",
      "spring-green": "#00FF80", "cyan": "#00FFFF", "azure": "#0080FF", "blue": "#0000FF", "violet": "#8000FF",
      "magenta": "#FF00FF", "rose": "#FF0080",
    ]
    XCTAssertEqual(
      NamedColors.names,
      ["red", "orange", "yellow", "chartreuse", "green", "spring-green", "cyan", "azure", "blue", "violet", "magenta",
       "rose", "gray"])
    for (name, hex) in expected {
      for scheme in [NamedColors.Scheme.light, .dark] {
        XCTAssertEqual(NamedColors.hex(name, scheme), hex, "\(name) \(scheme)")
      }
      // On the gamut's edge: one channel full, one empty.
      let (r, g, b) = NamedColors.wheel(NamedColors.hues.first { $0.name == name }!.hsv)
      XCTAssertEqual(max(r, g, b), 255, name)
      XCTAssertEqual(min(r, g, b), 0, name)
      // Its OKLCH form writes back to the same bytes.
      XCTAssertEqual(NamedColors.hex(NamedColors.color(name, .light)), hex, "\(name) round trip")
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
