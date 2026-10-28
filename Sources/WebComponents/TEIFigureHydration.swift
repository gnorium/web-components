#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// A figure's drawing inlined in the text pane (user, 2026-10-28): the
  /// figure's inks traced as vectors when its page was calibrated
  /// (gnorium-python `calibration.figure_trace`), served as SVG at the URL
  /// its `<graphic>` names (`TEIView`'s `.tei-figure-drawing`, `data-graphic`).
  ///
  /// The SVG is fetched and put in place of the image that stood for it,
  /// not shown through `<img>` or a CSS mask: an image resolves
  /// `currentColor` to black, and a mask paints one color, while the
  /// drawing's print layer must take the text's ink (`currentColor`, the
  /// page's default ink rendition and the theme) and its other inks their own
  /// fills, each a `<path>`. Inlined, it is vector still, crisp at any zoom.
  ///
  /// Every figure on the page at load, and every one a reader fetches into
  /// its viewer afterwards (`artifact-markup-added`, a windowed reader's
  /// page turned); a figure inlined once is left alone.
  public final class TEIFigureHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: TEIFigureHydration?

    public static func hydrateIfPresent() {
      if instance == nil {
        instance = TEIFigureHydration()
        for viewer in document.querySelectorAll(".artifact-view") {
          _ = viewer.addEventListener("artifact-markup-added") { _ in
            Self.hydrate(in: viewer)
          }
        }
      }
      hydrate(in: document.body)
    }

    private init() {}

    /// Each drawing under `root` not yet inlined: fetched, and its SVG put in
    /// place of its image once it arrives; left as the image where the
    /// fetch fails.
    public static func hydrate(in root: DOM.Element) {
      for drawing in root.querySelectorAll(".tei-figure-drawing[data-graphic]:not([data-graphic-inlined])") {
        let url = drawing.dataset["graphic"] ?? ""
        guard !stringIsEmpty(url) else { continue }
        drawing.setAttribute(data("graphic-inlined"), "fetching")
        window.fetch(url, RequestInit(method: "GET")) { response in
          guard response.ok, !stringIsEmpty(response.text) else {
            drawing.removeAttribute(data("graphic-inlined"))
            return
          }
          drawing.setInnerHTML(response.text)
          drawing.setAttribute(data("graphic-inlined"), "true")
        }
      }
    }
  }
#endif
