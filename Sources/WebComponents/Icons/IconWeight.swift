/// The weight of a house icon drawn beside type (user, 2026-10-30): regular, the house stroke (1024×2/22
/// of the tight glyph's long edge, Lucide's 2 of 24), or semibold, beside semibold type: 1.3 times it,
/// as Noto Sans SemiBold's stems are about 1.3 times Regular's.
/// Available on SERVER + CLIENT.
public enum IconWeight: Sendable {
  case regular
  case semibold

  /// The stroke, or a dot's radius, as a share of the glyph's long edge.
  public var share: Double {
    switch self {
    case .regular: return 2.0 / 22
    case .semibold: return 2.6 / 22
    }
  }
}
