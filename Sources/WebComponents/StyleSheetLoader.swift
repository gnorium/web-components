#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// A component the client builds fetches its own styles.
  ///
  /// A page links the stylesheets its server render asked for, which is what
  /// keeps a page's CSS to what is on it. A component built after load is not
  /// on it at render time, and cannot be: an alert is raised because something
  /// happened. Linking every such component's styles on every page in case one
  /// is raised is the same mistake in the other direction — any component can be
  /// built anywhere, so that argument ends with every page carrying everything.
  ///
  /// So the component asks, at the moment it is built, for the one file it
  /// needs. The file is the same URL the server would have linked, so a reader
  /// who has met that component anywhere already has it cached; a reader who
  /// never meets it never fetches it.
  public enum StyleSheetLoader {
    /// owner → the versioned URL that serves it, read once from the manifest.
    ///
    /// Two arrays, not a dictionary: hashing a String in Embedded Swift pulls
    /// in Unicode normalisation, and the linker has no _swift_stdlib_getNormData
    /// to give it. A handful of stylesheets is a scan, not a lookup, anyway.
    private nonisolated(unsafe) static var owners: [String] = []
    private nonisolated(unsafe) static var urls: [String] = []
    private nonisolated(unsafe) static var waiting: [String] = []
    private nonisolated(unsafe) static var isFetching = false

    private static func url(ofOwner owner: String) -> String? {
      for (index, known) in owners.enumerated() where stringEquals(known, owner) {
        return urls[index]
      }
      return nil
    }

    /// Link `style-sheets/<owner>.css` unless it is already linked.
    ///
    /// The URL comes from the build's manifest, so it is the same versioned
    /// file the server links on pages that render the component: a reader who
    /// has met it anywhere already has it cached, and nobody fetches a second
    /// copy under an unversioned name.
    public static func ensure(_ owner: String) {
      let marker = "gnorium-style-sheet-\(owner)"
      guard document.querySelector("#\(marker)") == nil else { return }
      // Already linked by the server render of this page: nothing to do.
      guard document.querySelector("link[href*='/\(owner).css']") == nil else { return }
      if let url = url(ofOwner: owner) {
        link(owner: owner, url: url, marker: marker)
        return
      }
      waiting.append(owner)
      fetchManifest()
    }

    private static func fetchManifest() {
      guard !isFetching, let head = document.querySelector("head") else { return }
      isFetching = true
      head.fetch("/style-sheets/manifest.json") { json in
        isFetching = false
        guard let json else { return }
        let pending = waiting
        waiting = []
        for owner in pending {
          guard let url = extractJSONString(json, key: owner) else { continue }
          owners.append(owner)
          urls.append(url)
          link(owner: owner, url: url, marker: "gnorium-style-sheet-\(owner)")
        }
      }
    }

    private static func link(owner: String, url: String, marker: String) {
      guard document.querySelector("#\(marker)") == nil else { return }
      let element = document.createElement("link")
      element.setAttribute("id", marker)
      element.setAttribute("rel", "stylesheet")
      element.setAttribute("href", url)
      document.querySelector("head")?.appendChild(element)
    }
  }
#endif
