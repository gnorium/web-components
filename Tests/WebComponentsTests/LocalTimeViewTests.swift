import Foundation
import XCTest
@testable import WebComponents

/// The stamp draws its words without a `DateFormatter` (Linux traps on a
/// zone missing from the image's tzdata, "Asia/Calcutta"); these hold the
/// words to what the formatter wrote, where the formatter still works.
final class LocalTimeViewTests: XCTestCase {
  private func formatted(_ date: Date, _ pattern: String, zone: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: zone)
    formatter.dateFormat = pattern
    return formatter.string(from: date)
  }

  func testWordsMatchTheFormatterInEveryZone() {
    let instants: [TimeInterval] = [
      0, 1_781_515_805, 1_792_152_328.75, 1_792_108_799, 1_792_108_800, 1_773_552_600, 1_793_510_999,
      951_782_400, 1_234_567_890, 4_102_444_799,
    ]
    for zone in ["UTC", "Asia/Kolkata", "Asia/Calcutta", "America/New_York", "Australia/Lord_Howe", "Pacific/Chatham"] {
      ViewerZone.$identifier.withValue(zone) {
        for interval in instants {
          let date = Date(timeIntervalSince1970: interval)
          XCTAssertEqual(LocalTimeView.text(date, format: .date, fallbackSuffix: "UTC"), formatted(date, "MMM d, yyyy", zone: zone), "\(interval) \(zone)")
          XCTAssertEqual(LocalTimeView.text(date, format: .time, fallbackSuffix: "UTC"), formatted(date, "h:mm a", zone: zone), "\(interval) \(zone)")
          XCTAssertEqual(
            LocalTimeView.text(date, format: .dateTime, fallbackSuffix: "UTC"),
            formatted(date, "MMM d, yyyy 'at' h:mm a", zone: "UTC") + " UTC", "\(interval)")
          XCTAssertEqual(
            LocalTimeView.text(date, format: .instant, fallbackSuffix: "UTC"),
            formatted(date, "MMM d, yyyy 'at' h:mm:ss a", zone: "UTC") + " UTC", "\(interval)")
          XCTAssertEqual(LocalTimeView.iso(date), ISO8601DateFormatter().string(from: date), "\(interval)")
        }
      }
    }
  }

  func testRendersTheReaderZone() {
    let date = Date(timeIntervalSince1970: 1_792_152_328)  // 2026-10-16T12:05:28Z
    ViewerZone.$identifier.withValue("Asia/Calcutta") {
      let html = LocalTimeView(date: date, format: .time).build().render()
      XCTAssertTrue(html.contains(">5:35 PM<"), html)
      XCTAssertTrue(html.contains("datetime=\"2026-10-16T12:05:28Z\""), html)
    }
  }
}
