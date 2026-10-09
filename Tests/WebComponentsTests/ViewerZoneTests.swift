import XCTest
@testable import WebComponents

final class ViewerZoneTests: XCTestCase {
  func testEarlyHistoricalYearsRoundTripWithoutThe1900Adjustment() throws {
    for year in [0, 1, 99, 100] {
      let day = CalendarDate(year: year, month: 10, day: 8)
      for zone in ["UTC", "Asia/Kolkata", "America/New_York"] {
        try ViewerZone.$identifier.withValue(zone) {
          let fixed = DateRangeValue.fixed(day, day)
          let parsed = try XCTUnwrap(DateRangeValue.parse(fixed.param))
          XCTAssertEqual(parsed.days().start?.iso, day.iso, "\(year) in \(zone)")
          XCTAssertEqual(parsed.days().end?.iso, day.iso, "\(year) in \(zone)")
          XCTAssertEqual(ViewerZone.localDay(epochMinutes: ViewerZone.epochMinutes(startOf: day)).iso, day.iso)
        }
      }
      ViewerZone.$identifier.withValue("UTC") {
        XCTAssertEqual(DateRangeValue.fixed(day, day).param, "\(day.iso)T00:00Z..\(day.adding(days: 1).iso)T00:00Z")
      }
    }
  }

  func testDSTGapsMoveForwardAndRepeatedHoursChooseTheEarlierOccurrence() throws {
    let cases: [(day: String, minutes: Int, zone: String, expected: String, wall: Int)] = [
      ("2026-03-08", 150, "America/New_York", "2026-03-08T07:30Z", 210),
      ("2026-11-01", 90, "America/New_York", "2026-11-01T05:30Z", 90),
      ("2026-10-04", 135, "Australia/Lord_Howe", "2026-10-03T15:45Z", 165),
      ("2026-04-05", 105, "Australia/Lord_Howe", "2026-04-04T14:45Z", 105),
      ("2011-12-30", 0, "Pacific/Apia", "2011-12-30T10:00Z", 0),
    ]
    for example in cases {
      let day = try XCTUnwrap(CalendarDate.parse(example.day))
      let instant = ViewerZone.epochMinutes(day: day, minutes: example.minutes, zone: example.zone)
      XCTAssertEqual(DateRangeValue.instantText(instant), example.expected, example.zone)
      XCTAssertEqual(ViewerZone.wallMinutes(epochMinutes: instant, zone: example.zone), example.wall, example.zone)
    }
  }

  func testWallTimeSolverRetainsLiteralHistoricalYearWithAnOffset() {
    for year in [1, 99, 100] {
      let day = CalendarDate(year: year, month: 10, day: 8)
      let wall = Int64(day.dayNumber) * 1_440
      let result = ViewerZone.resolveWallMinutes(wall) { _ in 330 }
      XCTAssertEqual(result, wall - 330)
      XCTAssertEqual(DateRangeValue.instantText(result), "\(day.adding(days: -1).iso)T18:30Z")
    }
  }
}
