import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// The icon a status is drawn with: an alert, a field's message, a result.
/// Each status is a Lucide icon (info = `info`, warning = `triangle-alert`,
/// error = `octagon-alert`, success = `circle-check`), stroked with
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

    /// The status mark of an alert of this color, as the server's AlertView
    /// picks it: blue and gray `info`, orange `warning` (triangle-alert),
    /// red `error` (octagon-alert), green `success` (circle-check). The
    /// client's hand-built alerts choose their icon here, so none wears
    /// another color's.
    public static func forAlertColor(_ color: String) -> Status {
      if stringEquals(color, "red") { return .error }
      if stringEquals(color, "orange") { return .warning }
      if stringEquals(color, "green") { return .success }
      return .info
    }
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
      return TriangleAlertIconView(size: iconSize, class: classes).build()
    case .error:
      return OctagonAlertIconView(size: iconSize, class: classes).build()
    case .success:
      return CircleCheckIconView(size: iconSize, class: classes).build()
    }
  }
}
