import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): twelve OKLCH hues 30° apart from
/// pure red's, and gray, each at exactly its scheme's contrast with the
/// page—3:1 by default, 7:1 for increased contrast—with the most chroma sRGB
/// allows at that lightness. 3:1 against white is 7:1 against black, so two
/// sets serve four schemes.
final class NamedColorsTests: XCTestCase {
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

  /// By APCA (user, 2026-10-12): each color at APCA's own level against
  /// the page—Lc 60 by default, Lc 75 in increased contrast—its hue kept,
  /// the most chroma.
  func testEachStandsAtItsAPCALevel() {
    for scheme in NamedColors.Scheme.allCases {
      let page = scheme.isDark ? 0 : 255
      let level = scheme.isMoreContrast ? NamedColors.namedLcMoreContrast : NamedColors.namedLc
      for name in NamedColors.names {
        let color = NamedColors.color(name, scheme)
        let lc = abs(NamedColors.APCA.lc(text: NamedColors.rgb(color), background: (page, page, page)))
        // Within what 8-bit writing allows.
        XCTAssertEqual(lc, level, accuracy: 1, "\(name) \(scheme)")
        if name != "gray" {
          XCTAssertEqual(color.h, NamedColors.hue(name), accuracy: 1e-9, "\(name) keeps its hue")
          XCTAssertEqual(color.c, NamedColors.maxChroma(l: color.l, h: color.h), accuracy: 1e-9, "\(name) most chroma")
        } else {
          XCTAssertEqual(color.c, 0)
        }
        let label = scheme.isDark ? (0, 0, 0) : (255, 255, 255)
        print("HEX \(scheme) \(name) \(NamedColors.hex(color)) label Lc \(String(format: "%.1f", NamedColors.APCA.lc(text: label, background: NamedColors.rgb(color))))")
      }
    }
  }

  /// The final ramp (user, 2026-10-12).
  func testTheNeutralRampsValues() {
    let order: [NamedColors.Neutral] = [
      .fillSecondary, .fillTertiary, .fillGrayQuaternary, .fillQuaternary, .fillGrayTertiary,
      .border, .glyphGrayQuaternary, .glyphGrayTertiary, .glyphGraySecondary, .glyphGray,
    ]
    let light = NamedColors.neutralRamp(.light), dark = NamedColors.neutralRamp(.dark)
    XCTAssertEqual(order.map { light[$0]! }, [248, 241, 234, 227, 220, 148, 127, 105, 74, 21])
    XCTAssertEqual(order.map { dark[$0]! }, [39, 56, 68, 80, 91, 172, 190, 207, 228, 251])
    for scheme in NamedColors.Scheme.allCases {
      let ramp = NamedColors.neutralRamp(scheme)
      print("RAMP \(scheme)", order.map { ramp[$0]! }, "subtle border", ramp[.borderSecondary]!)
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

  /// APCA 0.0.98G-4g: the reference contrasts.
  func testAPCAMatchesItsReference() {
    let white = (255, 255, 255), black = (0, 0, 0)
    XCTAssertEqual(NamedColors.APCA.lc(text: black, background: white), 106.04, accuracy: 0.01)
    XCTAssertEqual(NamedColors.APCA.lc(text: white, background: black), -107.88, accuracy: 0.01)
    XCTAssertEqual(NamedColors.APCA.lc(text: (248, 248, 248), background: white), 0)
    XCTAssertGreaterThan(NamedColors.APCA.sapc(text: (248, 248, 248), background: white), 0)
  }

  /// The neutral ramp (user, 2026-10-12): achromatic grays, set in light and
  /// mirrored to dark by equal APCA; five fills evenly spaced; WCAG 2 floors.
  func testTheNeutralRampMirrorsByAPCA() {
    let light = NamedColors.neutralRamp(.light), dark = NamedColors.neutralRamp(.dark)
    let fills: [NamedColors.Neutral] = [.fillSecondary, .fillTertiary, .fillGrayQuaternary, .fillQuaternary, .fillGrayTertiary]
    XCTAssertEqual(fills.map { light[$0]! }, [248, 241, 234, 227, 220])
    XCTAssertEqual(fills.map { dark[$0]! }, [39, 56, 68, 80, 91])
    for scheme in NamedColors.Scheme.allCases {
      let ramp = NamedColors.neutralRamp(scheme)
      // The fills stay in increased contrast.
      for fill in fills { XCTAssertEqual(ramp[fill], (scheme.isDark ? dark : light)[fill], "\(fill) \(scheme)") }
      let page = scheme.isDark ? 0 : 255
      func wcag(_ a: Int, _ b: Int) -> Double { NamedColors.wcag(a, b) }
      XCTAssertGreaterThanOrEqual(wcag(ramp[.border]!, page), scheme.isMoreContrast ? 6.9 : 3, "\(scheme) border")
      XCTAssertGreaterThanOrEqual(wcag(ramp[.glyphGrayTertiary]!, page), 4.5, "\(scheme) placeholder")
      XCTAssertGreaterThanOrEqual(wcag(ramp[.glyphGrayTertiary]!, ramp[.fillGrayQuaternary]!), 4.5, "\(scheme) placeholder on subtle")
    }
  }

  /// Fills and foreground strictly ordered by APCA in every scheme: fills,
  /// then border < disabled < placeholder < subtle < base.
  func testTheNeutralRampKeepsItsOrder() {
    let order: [NamedColors.Neutral] = [
      .fillSecondary, .fillTertiary, .fillGrayQuaternary, .fillQuaternary, .fillGrayTertiary,
      .borderSecondary, .border, .glyphGrayQuaternary, .glyphGrayTertiary, .glyphGraySecondary, .glyphGray,
    ]
    for scheme in NamedColors.Scheme.allCases {
      let ramp = NamedColors.neutralRamp(scheme), page = scheme.isDark ? 0 : 255
      let values = order.map { NamedColors.apca(ramp[$0]!, on: page) }
      for (a, b) in zip(values, values.dropFirst()) { XCTAssertLessThan(a, b, "\(scheme) \(order.map { ramp[$0]! })") }
    }
  }
}
