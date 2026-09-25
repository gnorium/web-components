import CSSBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// The icon a status is drawn with: an alert, a field's message, a result.
/// Each status is a Codex icon (info = infoFilled, warning = alert, error,
/// success), filled with `currentColor`, so it takes the colour around it.
/// Available on SERVER + CLIENT: client code renders it into a DOM element
/// (`element.innerHTML = StatusIconView(.success).render()`).
public struct StatusIconView: HTMLContent {
  let status: Status
  let width: CSS.Length
  let height: CSS.Length
  let `class`: String

  public enum Status: Sendable {
    case info
    case warning
    case error
    case success
  }

  public init(
    _ status: Status,
    width: CSS.Length = px(20),
    height: CSS.Length = px(20),
    class: String = ""
  ) {
    self.status = status
    self.width = width
    self.height = height
    self.class = `class`
  }

  public func build() -> DOM.Node {
    let classes = stringIsEmpty(`class`) ? "status-icon-view" : "status-icon-view \(`class`)"
    switch status {
    case .info:
      return InfoFilledIconView(width: width, height: height, class: classes).build()
    case .warning:
      return AlertIconView(width: width, height: height, class: classes).build()
    case .error:
      return ErrorIconView(width: width, height: height, class: classes).build()
    case .success:
      return SuccessIconView(width: width, height: height, class: classes).build()
    }
  }
}
