import DesignTokens
import Foundation
import XCTest

/// The named colors (user, 2026-10-11): twelve OKLCH hues 30° apart from
/// pure red's, and gray, each at its scheme's APCA level against the
/// page—Lc 60 by default, Lc 75 for increased contrast—with the most chroma
/// Display P3 allows at that lightness; the sRGB value is its clip (2026-10-14).
final class NamedColorsTests: XCTestCase {
  func testEditorLineMirrorsItsSurfaceContrast() {
    let light = NamedColors.currentLineGray(.light)
    let dark = NamedColors.currentLineGray(.dark)
    XCTAssertEqual(light, 248)
    XCTAssertEqual(dark, 10)
    XCTAssertEqual(NamedColors.wcag(light, 255), NamedColors.wcag(dark, 0), accuracy: 0.005)
    XCTAssertEqual(NamedColors.currentLineGray(.lightMoreContrast), light)
    XCTAssertEqual(NamedColors.currentLineGray(.darkMoreContrast), dark)
  }
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

  /// By APCA in Display P3 (user, 2026-10-12; P3 only 2026-10-14): each hue
  /// at APCA's own level against the page by APCA's P3 luminance—Lc 60 by
  /// default, Lc 75 in increased contrast—its hue kept, the most P3 chroma,
  /// written inside P3; gray achromatic at its level in 8-bit sRGB.
  func testEachStandsAtItsAPCALevelInP3() {
    for scheme in NamedColors.Scheme.allCases {
      let page = scheme.isDark ? 0 : 255
      let level = scheme.isMoreContrast ? NamedColors.namedLcMoreContrast : NamedColors.namedLc
      for name in NamedColors.names {
        let color = NamedColors.color(name, scheme)
        let css = NamedColors.css(name, scheme)
        let parts = css.dropFirst(6).dropLast().split(separator: " ").compactMap { Double($0) }
        XCTAssertEqual(parts.count, 3, css)
        if name == "gray" {
          XCTAssertEqual(color.c, 0)
          let lc = abs(NamedColors.APCA.lc(text: NamedColors.rgb(color), background: (page, page, page)))
          XCTAssertEqual(lc, level, accuracy: 1, "gray \(scheme)")
          XCTAssertNil(NamedColors.cssP3(name, scheme))
          continue
        }
        let p3 = NamedColors.cssP3(name, scheme)!
        XCTAssertEqual(p3, NamedColors.cssP3(color))
        let p3Parts = p3.dropFirst(6).dropLast().split(separator: " ").compactMap { Double($0) }
        XCTAssertEqual(p3Parts[0], color.l, accuracy: 1e-12)
        XCTAssertEqual(p3Parts[1], color.c, accuracy: 1e-12)
        // The sRGB value is the clip, exactly.
        XCTAssertEqual(NamedColors.hex(NamedColors.OKLCH(parts[0], parts[1], parts[2])), NamedColors.clipHex(name, scheme))
        XCTAssertTrue(NamedColors.inDisplayP3(color, tolerance: 1e-12), "\(name) \(scheme) \(css)")
        XCTAssertEqual(color.h, NamedColors.hue(name), accuracy: 1e-4, "\(name) keeps its hue")
        XCTAssertEqual(color.c, NamedColors.maxChromaP3(l: color.l, h: color.h), accuracy: 2e-4, "\(name) most P3 chroma")
        XCTAssertEqual(abs(NamedColors.lcP3(color, on: page)), level, accuracy: 0.1, "\(name) \(scheme) \(css)")
        let clip = NamedColors.rgb(color)
        print(
          "COLOR \(scheme) \(name) \(p3) clip \(NamedColors.clipHex(name, scheme))",
          String(format: "clip Lc %.1f", NamedColors.APCA.lc(text: clip, background: (page, page, page))))
      }
    }
  }

  /// The brand blue (user, 2026-10-14): its P3 value, and its sRGB clip,
  /// the sRGB value everywhere.
  func testTheBrandBlue() {
    XCTAssertEqual(NamedColors.namedLc, 60)
    XCTAssertEqual(NamedColors.namedLcMoreContrast, 75)
    XCTAssertEqual(NamedColors.cssP3("blue", .light), "oklch(0.6374 0.1884 239.2339)")
    XCTAssertEqual(NamedColors.cssP3("blue", .dark), "oklch(0.7528 0.1547 239.2339)")
    XCTAssertEqual(NamedColors.clipHex("blue", .light), "#0095EF")
    XCTAssertEqual(NamedColors.clipHex("blue", .dark), "#34BAFF")
    XCTAssertEqual(NamedColors.clipHex("blue", .lightMoreContrast), "#0074BB")
    XCTAssertEqual(NamedColors.clipHex("blue", .darkMoreContrast), "#8BD3FF")
  }

  /// The sRGB clip is the P3 color in linear sRGB, each channel clipped to
  /// [0, 1], then encoded (as Chrome and Safari draw it on sRGB screens).
  func testTheClipClipsEachChannel() {
    for scheme in NamedColors.Scheme.allCases {
      for name in NamedColors.hueNames {
        let linear = NamedColors.linearSRGB(NamedColors.color(name, scheme))
        func encode(_ v: Double) -> Int {
          let x = min(1, max(0, v))
          return Int(((x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1 / 2.4) - 0.055) * 255).rounded())
        }
        XCTAssertEqual(
          NamedColors.clipHex(name, scheme),
          String(format: "#%02X%02X%02X", encode(linear.r), encode(linear.g), encode(linear.b)), "\(name) \(scheme)")
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
    XCTAssertEqual(order.map { light[$0]! }, [248, 241, 234, 227, 220, 148, 127, 105, 104, 21])
    XCTAssertEqual(order.map { dark[$0]! }, [39, 56, 68, 80, 91, 172, 190, 207, 208, 251])
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

  /// The default subtle fills (user, 2026-10-14): the color at 20% over the
  /// page in gamma-encoded P3, precomputed—no color-mix—written inside P3;
  /// gray's achromatic. Prints each with its clip.
  func testDefaultSubtleFillsAreTheColorAtTwentyPercent() {
    XCTAssertEqual(NamedColors.subtleShare, 0.2)
    for scheme in [NamedColors.Scheme.light, .dark] {
      let page = scheme.isDark ? 0.0 : 1.0
      for name in NamedColors.names {
        let subtle = NamedColors.subtle(name, scheme)
        let c = NamedColors.displayP3(NamedColors.color(name, scheme)), back = NamedColors.displayP3(subtle)
        for (v, w) in [(c.r, back.r), (c.g, back.g), (c.b, back.b)] {
          XCTAssertEqual(w, 0.2 * v + 0.8 * page, accuracy: 0.001, "\(name) \(scheme)")
        }
        if name == "gray" { XCTAssertEqual(subtle.c, 0); continue }
        XCTAssertTrue(NamedColors.inDisplayP3(subtle, tolerance: 1e-12), "\(name) \(scheme)")
        print("SUBTLE \(scheme) \(name) \(NamedColors.cssP3(subtle)) clip \(NamedColors.hex(subtle))")
      }
    }
  }

  /// The sRGB values (each name's clip) and the increased-contrast subtle fills, written for CSS as
  /// oklch(), stay inside sRGB and render the same 8-bit color as the
  /// computed one (user, 2026-10-11).
  func testTheSRGBValuesRoundTripToTheSameBytes() {
    for scheme in NamedColors.Scheme.allCases {
      // Every name's sRGB value: the clip's 8 bits.
      var colors = NamedColors.names.map { ($0, NamedColors.oklch(NamedColors.rgb(NamedColors.color($0, scheme)))) }
      colors += NamedColors.names.map {
        ("\($0) subtle", scheme.isMoreContrast
          ? NamedColors.moreContrastSubtle($0, scheme) : NamedColors.oklch(NamedColors.rgb(NamedColors.subtle($0, scheme))))
      }
      for (name, color) in colors {
        let css = NamedColors.css(color)
        XCTAssertTrue(css.hasPrefix("oklch(") && css.hasSuffix(")"), css)
        let parts = css.dropFirst(6).dropLast().split(separator: " ").compactMap { Double($0) }
        XCTAssertEqual(parts.count, 3, css)
        let value = NamedColors.OKLCH(parts[0], parts[1], parts[2])
        XCTAssertTrue(NamedColors.inGamut(value, tolerance: 1e-12), "\(name) \(scheme) \(css)")
        XCTAssertEqual(NamedColors.hex(value), NamedColors.hex(color), "\(name) \(scheme) \(css)")
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
