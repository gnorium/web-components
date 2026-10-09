import XCTest
@testable import WebComponents

final class DateRangeValueTests: XCTestCase {
  func testAcceptedBoundaryInstantsUse64BitMinutes() throws {
    let latest = try XCTUnwrap(DateRangeValue.parse("9999-01-01T00:00Z.."))
    guard case .instant(let minutes)? = latest.start else { return XCTFail("Missing instant") }
    XCTAssertEqual(minutes, 4_222_846_080)
    XCTAssertGreaterThan(minutes, Int64(Int32.max))
    XCTAssertEqual(latest.param, "9999-01-01T00:00Z..")
    for instant in ["0000-01-01T00:00Z", "0001-01-01T00:00Z", "1969-12-31T23:59Z", "9999-12-31T23:59Z"] {
      let value = try XCTUnwrap(DateRangeValue.parse("\(instant).."))
      XCTAssertEqual(value.param, "\(instant)..")
    }
  }

  func testEveryPresetRespectsBothInclusiveDateLimits() throws {
    let now = try XCTUnwrap(DateRangeValue.parseInstant("2026-10-09T12:00Z"))
    try ViewerZone.$identifier.withValue("UTC") {
      for preset in DateRangeValue.presets {
        let value = try XCTUnwrap(DateRangeValue.parse(preset.value))
        let days = value.days(now: now)
        let first = try XCTUnwrap(days.start)
        let last = try XCTUnwrap(days.end)
        XCTAssertTrue(value.isWithin(min: first, max: last, now: now), preset.label)
        XCTAssertFalse(value.isWithin(min: first.adding(days: 1), max: nil, now: now), preset.label)
        XCTAssertFalse(value.isWithin(min: nil, max: last.adding(days: -1), now: now), preset.label)
        XCTAssertEqual(last.iso, "2026-10-09")
      }
      let week = try XCTUnwrap(DateRangeValue.parse("-7d.."))
      XCTAssertFalse(week.isWithin(min: CalendarDate.parse("2026-10-05"), max: nil, now: now))
      let today = try XCTUnwrap(DateRangeValue.parse("-1d.."))
      XCTAssertFalse(today.isWithin(min: nil, max: CalendarDate.parse("2026-10-08"), now: now))
    }
  }

  func testHourlyBoundsResolveFromOneInstantAcrossMidnight() throws {
    let now = try XCTUnwrap(DateRangeValue.parseInstant("2026-10-09T00:30Z"))
    try ViewerZone.$identifier.withValue("UTC") {
      let hour = try XCTUnwrap(DateRangeValue.parse("-1h.."))
      XCTAssertEqual(hour.days(now: now).start?.iso, "2026-10-08")
      XCTAssertEqual(hour.days(now: now).end?.iso, "2026-10-09")
      let interval = try XCTUnwrap(DateRangeValue.parse("-48h..-24h"))
      XCTAssertEqual(interval.days(now: now).start?.iso, "2026-10-07")
      XCTAssertEqual(interval.days(now: now).end?.iso, "2026-10-08")
      // The upper endpoint excludes the minute at exactly midnight.
      let midnight = try XCTUnwrap(DateRangeValue.parseInstant("2026-10-09T00:00Z"))
      XCTAssertEqual(interval.days(now: midnight).end?.iso, "2026-10-07")
    }
  }

  func testHourlyBoundsUseTheViewersCalendarDay() throws {
    let now = try XCTUnwrap(DateRangeValue.parseInstant("2026-10-08T19:00Z"))
    try ViewerZone.$identifier.withValue("Asia/Kolkata") {
      let hour = try XCTUnwrap(DateRangeValue.parse("-1h.."))
      XCTAssertEqual(hour.days(now: now).start?.iso, "2026-10-08")
      XCTAssertEqual(hour.days(now: now).end?.iso, "2026-10-09")
      let interval = try XCTUnwrap(DateRangeValue.parse("-48h..-24h"))
      XCTAssertEqual(interval.days(now: now).start?.iso, "2026-10-07")
      XCTAssertEqual(interval.days(now: now).end?.iso, "2026-10-08")
    }
    try ViewerZone.$identifier.withValue("America/New_York") {
      let interval = try XCTUnwrap(DateRangeValue.parse("-48h..-24h"))
      XCTAssertEqual(interval.days(now: now).start?.iso, "2026-10-06")
      XCTAssertEqual(interval.days(now: now).end?.iso, "2026-10-07")
    }
  }
}
