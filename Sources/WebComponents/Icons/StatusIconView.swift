import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// The icon a status is drawn with: an alert, a field's message, a result.
/// Each status is a Lucide icon (info = `info`, warning = `octagon-alert`,
/// error = `circle-x`, success = `circle-check`), stroked with
/// `currentColor`, so it takes the color around it.
/// Available on SERVER + CLIENT: client code renders it into a DOM element
/// (`element.innerHTML = StatusIconView(.success).render()`).
public struct StatusIconView: HTMLContent {
  let status: Status
  let iconSize: CSS.Length
  let `class`: String

  public enum Status: Sendable {
    case info
    case warning
    case error
    case success
  }

  public init(
    _ status: Status,
    size: CSS.Length,
    class: String = ""
  ) {
    self.status = status
    self.iconSize = size
    self.class = `class`
  }

  public func build() -> DOM.Node {
    let classes = stringIsEmpty(`class`) ? "status-icon-view" : "status-icon-view \(`class`)"
    switch status {
    case .info:
      return InfoIconView(size: iconSize, class: classes).build()
    case .warning:
      return OctagonAlertIconView(size: iconSize, class: classes).build()
    case .error:
      return CircleXIconView(size: iconSize, class: classes).build()
    case .success:
      return CircleCheckIconView(size: iconSize, class: classes).build()
    }
  }
}
