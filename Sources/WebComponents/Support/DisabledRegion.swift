/// A part of a page drawn disabled at once (user, 2026-11-03): a tree node
/// an open object holds, or one another node's change freezes—its Value
/// box, its accordions and the fields and buttons in them. Its page marks
/// the part (`attribute`, "true", or `set` on the client, which also takes
/// input from it), and it is drawn as a page that reads draws its fields,
/// never greyed out nor faded: every field its disabled field's own look,
/// the disabled ground and border, its value in the base color, an empty
/// one's placeholder its placeholder's; every button and pager a disabled
/// one's; a tree's marker its disabled ring. Its labels, their
/// "(optional)" and info, its accordions' headers and chevrons and its
/// section titles keep their own colors, and its accordions still open and
/// close, so what they hold is read. Unmarked, each is drawn as it was.
///
/// It is the part's state, not its controls': nothing in it is `disabled`,
/// so a form still posts what it holds as it stands. A component's rule for
/// it is its own disabled rule's selector within a marked part,
/// `:where([data-disabled-region='true']) &…`, as weightless as the mark,
/// or weighed (`[data-disabled-region='true'] &…`) where its enabled rules
/// weigh more (a button's color by its weight and color).
public enum DisabledRegion {
  /// The attribute that marks a part.
  public static let attribute = "data-disabled-region"
}

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  extension DisabledRegion {
    /// Marks `part` drawn disabled, or not, and takes input from all in it
    /// but its accordions' headers, which still open and close (user,
    /// 2026-11-03): each of its parts that holds no accordion is inert
    /// whole, so what loads into it later (a reader's pages) is too; in an
    /// accordion's header only its own controls (a tick) are. Unmarked, it
    /// gives back only what it took, never what its page made inert.
    public static func set(_ part: DOM.Element, disabled: Bool) {
      // As it stands already: a page checks its parts on every input.
      if stringEquals(part.getAttribute("data-disabled-region") ?? "false", "true") == disabled { return }
      part.setAttribute("data-disabled-region", disabled ? "true" : "false")
      for taken in part.querySelectorAll("[data-region-inert]") {
        taken.removeAttribute("inert")
        taken.removeAttribute("data-region-inert")
      }
      if disabled { shut(childrenOf: part) }
    }

    private static func shut(_ element: DOM.Element) {
      if element.hasAttribute("inert") { return }
      element.setAttribute("inert", "")
      element.setAttribute("data-region-inert", "")
    }

    /// Every child of `container`, but its accordions' headers.
    private static func shut(childrenOf container: DOM.Element) {
      for child in container.querySelectorAll(":scope > *") {
        if child.classList.contains("accordion-view") {
          shut(accordion: child)
        } else if let _ = child.querySelector(".accordion-view") {
          shut(childrenOf: child)
        } else {
          shut(child)
        }
      }
    }

    /// An accordion's own controls in its header, and all it holds but the
    /// headers of the accordions in it.
    private static func shut(accordion: DOM.Element) {
      for child in accordion.querySelectorAll(":scope > *") where !child.classList.contains("accordion-details") {
        shut(child)
      }
      if let summary = accordion.querySelector(":scope > .accordion-details > .accordion-summary") {
        for control in summary.querySelectorAll("input, button, select, textarea, label") { shut(control) }
      }
      if let content = accordion.querySelector(
        ":scope > .accordion-details > .accordion-content-clip > .accordion-content")
      {
        shut(childrenOf: content)
      }
    }
  }
#endif
