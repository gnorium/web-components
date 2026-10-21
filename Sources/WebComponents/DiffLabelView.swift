import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// The label before any diff (user, 2026-10-21): Lucide's `diff` mark and
/// "Diff:"—or the page's own words standing for it—the mark as tall as the
/// label's 22px line, in the label's own color. A line's diff wears it too.
public struct DiffLabelView: HTMLContent {
  let text: String
  let `class`: String

  public init(_ text: String = DiffView.defaultLabel, class: String = "") {
    self.text = text
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    IconLabelView(
      text,
      mark: IconView(icon: { s in DiffIconView(size: s) }, size: lineHeightSmall22).build(),
      class: stringIsEmpty(`class`) ? "diff-label" : "diff-label \(`class`)"
    ).build()
  }
}
