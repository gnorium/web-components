import CSSBuilder
import CSSOMBuilder
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import SVGBuilder
import WebTypes

/// Lucide's `signature` (ISC; THIRD_PARTY_NOTICES.md): Commit: an admin's name
/// put to what is sent on to its process; an action button's verb mark (user,
/// 2026-11-13: the gavel read as a verdict, which a Commit is not). Lucide's
/// own geometry (lucide-static 1.60.0), carried flat into the house box: the
/// long edge 1024, the house stroke (`iconStrokeWidth`), round caps and joins,
/// tight to the box (user, 2026-10-26). SERVER + CLIENT: client code renders it
/// too.
public struct SignatureIconView: HTMLContent {
  let iconSize: CSS.Length
  let `class`: String

  public init(
    size: CSS.Length,
    class: String = ""
  ) {
    self.iconSize = size
    self.class = `class`
  }

  public func build() -> DOM.Node {
    svg {
      path().d("M928.52 781.46L822.87 689.93A24.5 24.5 0 0 0 781.52 707.96L781.52 732.46A49 49 0 0 1 732.52 781.46L634.53 781.46A49 49 0 0 1 585.53 732.46C585.53 607.76 389.97 537.94 169.04 536.47A48.99 48.99 0 0 0 169.04 781.46C372.53 781.46 401.54 228.03 448.72 119.98A122.5 122.5 0 1 1 610.91 280.89")
      path().d("M46.55 977.45L928.52 977.45")
    }
    .class(stringIsEmpty(`class`) ? "signature-icon-view" : "signature-icon-view \(`class`)")
    .style { height(iconSize) }
    .viewBox(0, 0, 975.06, 1024)
    .xmlns("http://www.w3.org/2000/svg")
    .fill(.none)
    .stroke(.currentColor)
    .strokeWidth(93.09)
    .strokeLinecap(.round)
    .strokeLinejoin(.round)
    .ariaHidden(true)
    .build()
  }
}

#if CLIENT
  import WebAPIs

  public enum SignatureIconFactory {
    public static func createElement(
      size: CSS.Length,
      class: String = ""
    ) -> DOM.Element {
      let wrapper = document.createElement(.span)
      let view = SignatureIconView(size: size, class: `class`)
      wrapper.innerHTML = view.render()
      if let svg = wrapper.firstElementChild {
        return svg
      }
      return wrapper
    }
  }
#endif
