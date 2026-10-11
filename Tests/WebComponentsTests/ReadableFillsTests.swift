import DesignTokens
import XCTest

/// Every derived fill reads under its scheme's colorBase at WCAG 2 4.5:1 or
/// more, keeps its HIG hue, stays in sRGB, and stands at the lightness
/// nearest the HIG one that does (user, 2026-10-11).
final class ReadableFillsTests: XCTestCase {
  func testEveryDerivedFillReadsUnderColorBase() {
    for scheme in ReadableFills.Scheme.allCases {
      for (name, hig) in scheme.hig {
        let fill = ReadableFills.derive(hig, base: scheme.base, achromatic: name == "gray")
        let ratio = ReadableFills.contrast(fill, scheme.base)
        print(
          "\(scheme) \(name): HIG \(hig.l) \(hig.c) → \(fill.l) \(fill.c) \(fill.h), "
            + "\(String(format: "%.2f", ReadableFills.contrast(hig, scheme.base))) → \(String(format: "%.2f", ratio))")
        XCTAssertGreaterThanOrEqual(ratio, ReadableFills.minimum, "\(scheme) \(name)")
        XCTAssertEqual(fill.h, (hig.h * 100).rounded() / 100, "\(scheme) \(name) keeps its hue")
        XCTAssertTrue(ReadableFills.inGamut(fill), "\(scheme) \(name) in sRGB")
        // Nearest: one step nearer the HIG lightness, with as much chroma,
        // does not read.
        if abs(fill.l - hig.l) >= 0.001 {
          let nearer = fill.l > hig.l ? fill.l - 0.001 : fill.l + 0.001
          let chroma = name == "gray" ? min(hig.c, ReadableFills.maxChroma(l: nearer, h: hig.h)) : ReadableFills.maxChroma(l: nearer, h: hig.h)
          XCTAssertLessThan(
            ReadableFills.contrast(.init(nearer, chroma, hig.h), scheme.base), ReadableFills.minimum,
            "\(scheme) \(name) is the nearest")
        }
      }
    }
  }
}
