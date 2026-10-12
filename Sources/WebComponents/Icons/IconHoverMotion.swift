#if SERVER
  /// The selectors that move an icon's parts while the control holding it
  /// is hovered or keyboard-focused: the icon never moves on its own, only
  /// with its host button (a ButtonView, a toggle's button). Used inside an
  /// icon's `.style`, where `&` is the icon's root; `part` is the selector
  /// of the part that moves, empty for the whole icon.
  public enum IconHoverMotion {
    public static func hover(_ part: String = "") -> String {
      part.isEmpty ? ".button-view:hover &" : ".button-view:hover & \(part)"
    }

    public static func focus(_ part: String = "") -> String {
      part.isEmpty ? ".button-view:focus-visible &" : ".button-view:focus-visible & \(part)"
    }
  }
#endif
