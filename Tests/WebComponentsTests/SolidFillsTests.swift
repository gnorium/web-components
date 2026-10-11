import DesignTokens
import XCTest

/// Every solid fill carries white text at WCAG 2 4.5:1 or more in every
/// scheme, keeps its HIG hue and its HIG relative chroma, stays in sRGB, and
/// stands at the lightness nearest the HIG one that does (user, 2026-10-11).
final class SolidFillsTests: XCTestCase {
  func testEverySolidFillCarriesWhite() {
    for scheme in SolidFills.Scheme.allCases {
      for (name, hig) in scheme.hig {
        let fill = SolidFills.derive(hig)
        let ratio = SolidFills.contrast(fill, SolidFills.white)
        print(
          "\(scheme) \(name): oklch(\(hig.l) \(hig.c) \(hig.h)) \(String(format: "%.2f", SolidFills.contrast(hig, SolidFills.white))):1"
            + " → oklch(\(fill.l) \(fill.c) \(fill.h)) \(String(format: "%.2f", ratio)):1")
        XCTAssertGreaterThanOrEqual(ratio, SolidFills.minimum, "\(scheme) \(name)")
        XCTAssertEqual(fill.h, (hig.h * 100).rounded() / 100, "\(scheme) \(name) keeps its hue")
        XCTAssertTrue(SolidFills.inGamut(fill), "\(scheme) \(name) in sRGB")
        XCTAssertEqual(
          SolidFills.relativeChroma(fill), SolidFills.relativeChroma(hig), accuracy: 0.01,
          "\(scheme) \(name) keeps its relative chroma")
        // Nearest: one step nearer the HIG lightness does not carry white.
        if abs(fill.l - hig.l) >= 0.001 {
          let nearer = fill.l > hig.l ? fill.l - 0.001 : fill.l + 0.001
          let chroma = SolidFills.relativeChroma(hig) * SolidFills.maxChroma(l: nearer, h: hig.h)
          XCTAssertLessThan(
            SolidFills.contrast(.init(nearer, chroma, hig.h), SolidFills.white), SolidFills.minimum,
            "\(scheme) \(name) is the nearest")
        }
      }
    }
  }
}
