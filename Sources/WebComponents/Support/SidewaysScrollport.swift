import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import WebTypes

/// A sideways scrollport (user, 2026-11-02), the one a tree uses
/// (`OutlinerView`) and every list or container of artifacts: what it holds
/// is never narrower than the narrowest it can be (an artifact's one-row
/// footer, `ArtifactView`), and past the width its column gives, the
/// scrollport scrolls sideways from its start edge, never the page, nothing
/// clipped at either side. A little room at its edges, so a ring drawn
/// outside a row or a control is not cut off by the edge that scrolls; its
/// bar over nothing; no edge fade (scrollports never fade).
///
/// `scrollport` is its selector, `content` its contents'.
@CSSBuilder
public func sidewaysScrollport(_ scrollport: String, content: String) -> [CSSOM.CSSRule] {
  selector(scrollport) {
    overflowX(.auto)
    minWidth(0)
    padding(spacing4)
  }
  selector(content) {
    CSS.Property("min-width", "min-content").important()
  }
  selector(
    "\(scrollport)::-webkit-scrollbar-track", "\(scrollport)::-webkit-scrollbar-track-piece",
    "\(scrollport)::-webkit-scrollbar-corner"
  ) {
    backgroundColor(.transparent).important()
  }
}
