import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// The label before a multiline diff (user, 2026-10-21): Lucide's `diff`
/// mark and "Diff:", the mark as tall as the label's 22px line, in the
/// label's own color. A diff in a line of its own wears only the words.
public struct DiffLabelView: HTMLContent {
  let `class`: String

  public init(class: String = "") {
    self.`class` = `class`
  }

  public func build() -> DOM.Node {
    IconLabelView(
      DiffView.defaultLabel,
      mark: IconView(icon: { s in DiffIconView(size: s) }, size: lineHeightSmall22).build(),
      class: stringIsEmpty(`class`) ? "diff-label" : "diff-label \(`class`)"
    ).build()
  }
}
