#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import WebAPIs
  import WebTypes

  /// An element that holds a list the server renders on its own (a
  /// dialog's table, with its filter bar and pager): what the list asks
  /// again—its filter bar's GET form, its pager, its sort headers, a link to
  /// another page of it—loads into the element, never navigating the page.
  ///
  /// `data-fragment-host` marks the element; it holds the list it last
  /// loaded as `data-fragment-url`. The list's root names its own address as
  /// `data-fragment-base`, which every link of its own starts with, and its
  /// stylesheets come with it (the response's `Link` header).
  public enum FragmentHost {
    /// The list a host holds, or "" before its first load.
    public static func url(of host: DOM.Element) -> String {
      host.dataset["fragmentUrl"] ?? ""
    }

    /// Loads `url` into `host` and binds what it brought. The first load
    /// leaves the focus where it is; a later one, asked from inside the
    /// list, puts it on the host so the keyboard stays in the list.
    public static func load(_ host: DOM.Element, url: String) {
      bind(host)
      let first = stringIsEmpty(Self.url(of: host))
      host.setAttribute("aria-busy", "true")
      host.loadFragment(url) { ok in
        host.setAttribute("aria-busy", "false")
        guard ok else {
          host.dataset["fragmentFailed"] = "true"
          return
        }
        host.dataset["fragmentFailed"] = "false"
        host.dataset["fragmentUrl"] = url
        Self.hydrate(host)
        if !first { host.focus() }
      }
    }

    /// The components a list is built of, bound once each.
    private static func hydrate(_ host: DOM.Element) {
      DropdownHydration.hydrate(in: host)
      SelectHydration.hydrate(in: host)
      TextInputHydration.hydrate(in: host)
      DatePickerHydration.hydrateIfPresent()
      TimeInputHydration.hydrateIfPresent()
      FilterBarHydration.hydrate(in: host)
      TableHydration.hydrate(in: host)
      PaginationHydration.hydrate(in: host)
      // Its stamps in the reader's clock before its tooltips move their
      // bubbles away; the page's own, already written, are left as they are
      // (the pass is idempotent).
      LocalTimeHydration.hydrateIfPresent()
      TooltipHydration.hydrate(in: host)
    }

    /// Its filter bar's GET form and its own links, into the host.
    private static func bind(_ host: DOM.Element) {
      guard !stringEquals(host.dataset["fragmentBound"] ?? "", "true") else { return }
      host.dataset["fragmentBound"] = "true"
      _ = host.addEventListener(.submit) { (event: Event) in
        guard let form = event.target?.closest("form") else { return }
        let method = form.getAttribute("method") ?? "get"
        if stringEquals(method, "post") || stringEquals(method, "POST") { return }
        event.preventDefault()
        let action = form.getAttribute("action") ?? Self.base(of: host)
        let query = FormData(form).toString()
        Self.load(host, url: stringIsEmpty(query) ? action : stringJoin([action, "?", query], separator: ""))
      }
      _ = host.addEventListener(.click) { (event: Event) in
        guard let link = event.target?.closest("a"), let href = link.getAttribute("href") else { return }
        let base = Self.base(of: host)
        guard !stringIsEmpty(base), stringStartsWith(href, base) else { return }
        event.preventDefault()
        Self.load(host, url: href)
      }
    }

    /// The address the list it holds names as its own.
    private static func base(of host: DOM.Element) -> String {
      host.querySelector("[data-fragment-base]")?.getAttribute(data("fragment-base")) ?? ""
    }
  }
#endif
