import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): twelve OKLCH hues 30° apart from
/// pure red's, and gray, each at exactly its scheme's contrast with the
/// page—3:1 by default, 7:1 for increased contrast—with the most chroma sRGB
/// allows at that lightness. 3:1 against white is 7:1 against black, so two
/// sets serve four schemes.
final class NamedColorsTests: XCTestCase {
  static let setA = [
    "red": "#FF5F4E", "orange": "#DF7C00", "yellow": "#B79000", "lime": "#889F00", "green": "#00AC4B",
    "mint": "#00A892", "cyan": "#00A4B7", "blue": "#009EE5", "indigo": "#6E8EFF", "violet": "#AD7AFF",
    "magenta": "#FF2CFA", "pink": "#FF549A",
  ]
  static let setB = [
    "red": "#B60000", "orange": "#884900", "yellow": "#6F5600", "lime": "#515F00", "green": "#00682A",
    "mint": "#006557", "cyan": "#00636F", "blue": "#005F8C", "indigo": "#2F31FF", "violet": "#7F00E2",
    "magenta": "#A1009E", "pink": "#B0005D",
  ]

  func testTheHuesStepThirtyDegreesFromRed() {
    XCTAssertEqual(
      NamedColors.names,
      ["red", "orange", "yellow", "lime", "green", "mint", "cyan", "blue", "indigo", "violet", "magenta", "pink",
       "gray"])
    XCTAssertEqual(NamedColors.redHue, 29.2339, accuracy: 0.0001)
    for (index, name) in NamedColors.hueNames.enumerated() {
      XCTAssertEqual(NamedColors.hue(name), (NamedColors.redHue + 30 * Double(index)).truncatingRemainder(dividingBy: 360))
    }
  }

  func testTwoSetsServeFourSchemes() {
    for name in NamedColors.names {
      // Set A: light's default and dark's increased contrast; set B: dark's
      // default and light's increased contrast.
      XCTAssertEqual(NamedColors.hex(name, .light), NamedColors.hex(name, .darkMoreContrast), name)
      XCTAssertEqual(NamedColors.hex(name, .dark), NamedColors.hex(name, .lightMoreContrast), name)
      if let a = Self.setA[name], let b = Self.setB[name] {
        XCTAssertEqual(NamedColors.hex(name, .light), a, "\(name) A")
        XCTAssertEqual(NamedColors.hex(name, .dark), b, "\(name) B")
      }
      print("\(name): A \(NamedColors.hex(name, .light)) B \(NamedColors.hex(name, .dark))")
    }
  }

  func testEachStandsAtExactlyItsContrast() {
    let white = NamedColors.OKLCH(1, 0, 0), black = NamedColors.OKLCH(0, 0, 0)
    for name in NamedColors.names {
      let a = NamedColors.color(name, .light), b = NamedColors.color(name, .dark)
      // Within what 8-bit writing allows.
      XCTAssertEqual(NamedColors.contrast(a, white), 3, accuracy: 0.03, "\(name) A on white")
      XCTAssertEqual(NamedColors.contrast(a, black), 7, accuracy: 0.07, "\(name) A on black")
      XCTAssertEqual(NamedColors.contrast(b, white), 7, accuracy: 0.07, "\(name) B on white")
      XCTAssertEqual(NamedColors.contrast(b, black), 3, accuracy: 0.03, "\(name) B on black")
      if name != "gray" {
        for color in [a, b] {
          XCTAssertEqual(color.h, NamedColors.hue(name), accuracy: 1e-9, "\(name) keeps its hue")
          XCTAssertEqual(color.c, NamedColors.maxChroma(l: color.l, h: color.h), accuracy: 1e-9, "\(name) most chroma")
        }
      } else {
        XCTAssertEqual(a.c, 0)
        XCTAssertEqual(b.c, 0)
      }
    }
  }

  func testIncreasedContrastSubtleFillsCarryBaseTextAtSevenToOne() {
    for scheme in [NamedColors.Scheme.lightMoreContrast, .darkMoreContrast] {
      for name in NamedColors.names {
        let subtle = NamedColors.moreContrastSubtle(name, scheme)
        XCTAssertGreaterThanOrEqual(NamedColors.contrast(subtle, scheme.baseText), 7, "\(name) \(scheme) subtle")
      }
    }
  }

  /// Written for CSS as oklch(), each value stays inside sRGB and renders
  /// the same 8-bit color as the computed one (user, 2026-10-11).
  func testTheOKLCHValuesRoundTripToTheSameBytes() {
    for scheme in NamedColors.Scheme.allCases {
      for name in NamedColors.names {
        let css = NamedColors.css(name, scheme)
        XCTAssertTrue(css.hasPrefix("oklch(") && css.hasSuffix(")"), css)
        let parts = css.dropFirst(6).dropLast().split(separator: " ").compactMap { Double($0) }
        XCTAssertEqual(parts.count, 3, css)
        let value = NamedColors.OKLCH(parts[0], parts[1], parts[2])
        let channels = NamedColors.linearSRGB(value)
        for channel in [channels.r, channels.g, channels.b] {
          XCTAssertTrue(channel >= -1e-12 && channel <= 1 + 1e-12, "\(name) \(scheme) \(css): \(channel)")
        }
        XCTAssertEqual(NamedColors.hex(value), NamedColors.hex(name, scheme), "\(name) \(scheme) \(css)")
      }
    }
  }

  /// The neutral ramp (user, 2026-10-12): achromatic grays, each at its
  /// ratio against the page, mirrored between light and dark; increased
  /// contrast by the log-ratio map (3:1 to 7:1, pinned at 1:1 and 21:1).
  func testTheNeutralRampMirrorsItsRatios() {
    XCTAssertEqual(NamedColors.subtleRatio, 1.20, accuracy: 0.01)
    XCTAssertEqual(NamedColors.moreContrastRatio(1), 1, accuracy: 1e-9)
    XCTAssertEqual(NamedColors.moreContrastRatio(3), 7, accuracy: 1e-9)
    XCTAssertEqual(NamedColors.moreContrastRatio(21), 21, accuracy: 1e-9)
    for scheme in NamedColors.Scheme.allCases {
      for step in NamedColors.Neutral.allCases {
        let gray = NamedColors.neutral(step, scheme)
        let target = scheme.isMoreContrast ? NamedColors.moreContrastRatio(step.ratio) : step.ratio
        let ratio = NamedColors.contrast(gray, scheme.page)
        let (r, g, b) = NamedColors.rgb(gray)
        XCTAssertTrue(r == g && g == b, "\(step) \(scheme) achromatic")
        XCTAssertGreaterThanOrEqual(ratio, target, "\(step) \(scheme)")
        XCTAssertLessThan(ratio, target * 1.06, "\(step) \(scheme)")
      }
    }
    // The defined steps: the base border at 3:1, placeholder at 4.5:1, the
    // subtle fill dark's 26.
    XCTAssertEqual(NamedColors.rgb(NamedColors.neutral(.fillGrayQuaternary, .light)).0, 234)
    XCTAssertEqual(NamedColors.rgb(NamedColors.neutral(.fillGrayQuaternary, .dark)).0, 26)
    XCTAssertEqual(NamedColors.Neutral.border.ratio, 3)
    XCTAssertEqual(NamedColors.Neutral.glyphGrayTertiary.ratio, 4.5)
  }

  /// Fills below their hover below their active; text base > subtle >
  /// placeholder > disabled; in every scheme.
  func testTheNeutralRampKeepsItsOrder() {
    let order: [NamedColors.Neutral] = [
      .fillSecondary, .fillTertiary, .fillGrayQuaternary, .borderSecondary, .fillGrayTertiary, .border,
      .glyphGrayQuaternary, .glyphGrayTertiary, .glyphGraySecondary, .glyphGray,
    ]
    for scheme in NamedColors.Scheme.allCases {
      let ratios = order.map { NamedColors.contrast(NamedColors.neutral($0, scheme), scheme.page) }
      for (a, b) in zip(ratios, ratios.dropFirst()) { XCTAssertLessThan(a, b, "\(scheme) \(ratios)") }
      // Placeholder reads at 4.5:1 on the page.
      XCTAssertGreaterThanOrEqual(ratios[7], 4.5, "\(scheme)")
    }
  }
}
