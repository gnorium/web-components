#if CLIENT
  import DOMBuilder
  import WebAPIs
  import WebTypes

  /// One scroller moved to show what is in it, and no box around it (user,
  /// 2026-11-05): `scrollIntoView` and a focus that scrolls move every box
  /// around their element that can be scrolled, and a box that only clips
  /// (`overflow: hidden`) is one, so a page's column was left scrolled
  /// sideways, cut off at its start with nothing to scroll it back. Focus
  /// with `preventScroll`, then reveal it in its own scroller here.
  public enum ScrollPort {
    /// `port` scrolled the least it takes to show `element` whole, or its
    /// start where it is larger than `port`; nothing where `element` is not
    /// in it or is in view already.
    public static func reveal(_ element: DOM.Element, in port: DOM.Element) {
      guard port.contains(element), let portBox = port.getBoundingClientRect(),
        let box = element.getBoundingClientRect()
      else { return }
      let top = box.top - portBox.top - port.clientTop
      let left = box.left - portBox.left - port.clientLeft
      let height = port.clientHeight
      let width = port.clientWidth
      if top < 0 || top + box.height > height {
        port.scrollTop += top < 0 || box.height > height ? top : top + box.height - height
      }
      if left < 0 || left + box.width > width {
        port.scrollLeft += left < 0 || box.width > width ? left : left + box.width - width
      }
    }
  }
#endif
