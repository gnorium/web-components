import EmbeddedSwiftUtilities

/// How far a run of text goes in the sans (Noto Sans, at its regular
/// weight), in thousandths of its em, as its font sets each character: what
/// a field keeps clear for text that stands inside it and is none of its
/// value (`TextAreaView.suffix`, `TextInputView.suffix`: a tree row's date,
/// "AD 1603"). Both sides: the field as it is drawn, and a client writing
/// it again. A character outside ASCII counts a whole em, never less than
/// it runs.
public enum SansAdvance {
  /// U+0020 SPACE through U+007E TILDE, in order.
  static let ascii: [Int] = [
    260, 269, 408, 646, 572, 831, 732, 225, 300, 300, 551, 572, 268, 322, 268, 372,
    572, 572, 572, 572, 572, 572, 572, 572, 572, 572, 268, 268, 572, 572, 572, 434,
    899, 639, 650, 632, 730, 556, 519, 728, 741, 339, 273, 619, 524, 907, 760, 781,
    605, 781, 622, 549, 556, 731, 600, 930, 586, 566, 572, 329, 372, 329, 572, 444,
    281, 561, 615, 480, 615, 564, 344, 615, 618, 258, 258, 534, 258, 935, 618, 605,
    615, 615, 413, 479, 361, 618, 508, 786, 529, 510, 470, 380, 551, 380, 572,
  ]

  /// An em, for a character the table does not hold.
  static let em = 1000

  /// "AD 1603": its characters' advances, summed.
  public static func of(_ text: String) -> Int {
    var advance = 0
    for byte in text.utf8 {
      if byte >= 0x20 && byte <= 0x7E {
        advance += ascii[Int(byte) - 0x20]
      } else if byte & 0xC0 != 0x80 {
        // A character's first byte; the bytes that continue it add nothing.
        advance += em
      }
    }
    return advance
  }

  /// Its advance as a CSS length: "calc(3912 * 0.001em)".
  public static func length(_ text: String) -> String {
    stringJoin(["calc(", intToString(of(text)), " * 0.001em)"], separator: "")
  }
}
