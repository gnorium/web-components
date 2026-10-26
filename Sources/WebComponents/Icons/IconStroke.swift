/// The stroke of every stroked icon in its 1024 box, the same for all of
/// them: Lucide's 2 against the 20 + 2 a full-height glyph spans (user,
/// 2026-10-26). Each icon is cut tight to its glyph and stroked with this, so
/// icons drawn at one size stroke alike; the Lucide ports bake it into their
/// files (design-notes/lucide-port), the rings draw with it.
public let iconStrokeWidth: Double = 1024 * 2 / 22
