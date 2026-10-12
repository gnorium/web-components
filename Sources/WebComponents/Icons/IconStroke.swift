import EmbeddedSwiftUtilities

/// The stroke of every stroked icon, in units of the icon's 1024 long
/// edge: Lucide's designed weight, its `stroke-width="2"` on its 24 grid
/// (user, 2026-10-12). Change it here and every stroked icon is redrawn at
/// the new weight, still tight to its box (IconStrokeFit).
public let iconStrokeWidth: Double = 1024 * 2 / 24

/// Fits a stroked glyph drawn in its own units (Lucide's 24 grid, or the
/// icon's own) to the house box: its long edge 1024, its short edge what
/// the glyph needs, the outer edges of its round-capped, round-joined
/// strokes touching the box on every side. Round caps and joins reach
/// exactly half the stroke past the glyph's bounds in every direction, so
/// the bounds plus that half stroke are the box.
public struct IconStrokeFit {
  /// The view box's width and height.
  public let width: Double
  public let height: Double
  /// The glyph's group transform, from its own units to the box's.
  public let transform: String
  /// The stroke in the glyph's own units: `iconStrokeWidth` once scaled.
  public let strokeWidth: Double

  /// `minX`…`maxY` are the glyph's bounds (its strokes' centerlines,
  /// curves' extremes included) in its own units.
  public init(minX: Double, minY: Double, maxX: Double, maxY: Double, stroke: Double = iconStrokeWidth) {
    let glyphWidth = maxX - minX
    let glyphHeight = maxY - minY
    let scale = (1024 - stroke) / (glyphWidth > glyphHeight ? glyphWidth : glyphHeight)
    let half = stroke / 2
    self.width = glyphWidth * scale + stroke
    self.height = glyphHeight * scale + stroke
    self.transform =
      "translate(" + doubleToString(half - minX * scale) + " " + doubleToString(half - minY * scale)
      + ") scale(" + doubleToString(scale) + ")"
    self.strokeWidth = stroke / scale
  }
}
