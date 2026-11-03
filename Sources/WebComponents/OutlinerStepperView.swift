import EmbeddedSwiftUtilities

#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A tree's one row of controls (user, 2026-11-03), after the tree: two
  /// steppers drawn as an artifact's page stepper is (`PaginationView`), the
  /// plain chevrons round a control, both a large control's size (medium on
  /// a phone). "‹ [+ Testament 1.2.] ›": its chevrons
  /// step through every place a new node may go, in the tree's order—under
  /// each node, as its first, and right after it—where the tree's rules
  /// allow one; its button, named by the number the new node will get,
  /// puts one there, open. "‹ [− Testament 1.1.] ›": its chevrons step
  /// through the nodes that may be removed; its button removes the one
  /// chosen, with every node under it (a removed one it restores, "+
  /// Testament 1.1."). While a stepper is in use—from a press on its
  /// chevrons, or focus on its controls, until focus leaves the row—the
  /// place chosen (a line where the node will stand) or the node chosen (a
  /// ring round its heading) is marked in the tree, a chevron's press
  /// scrolling to it; nothing is marked at rest. The tree's page says where
  /// a new node may go and what a press does (`OutlinerStepper`).
  public struct OutlinerStepperView: HTMLContent {
    let tree: String
    let noun: String

    /// - Parameters:
    ///   - tree: The id of the tree it steps through (`OutlinerView`).
    ///   - noun: What the tree's nodes are: "Testament".
    public init(tree: String, noun: String) {
      self.tree = tree
      self.noun = noun
    }

    public func build() -> DOM.Node {
      let place = "\(noun) 1."
      let lower = noun.lowercased()
      return div {
        PaginationView(
          size: .large, kind: "outliner-stepper", ariaLabel: "Where a new \(lower) goes",
          previousAriaLabel: "Previous place", nextAriaLabel: "Next place", previousDisabled: true, nextDisabled: true,
          class: "outliner-stepper-add"
        ) {
          ButtonView(
            label: place, icon: IconView.add, buttonColor: .gray, weight: .subtle, size: .large, disabled: true,
            type: .button, ariaLabel: "Add \(lower) 1.", class: "outliner-stepper-button",
            labelFontWeight: fontWeightSemiBold)
        }
        PaginationView(
          size: .large, kind: "outliner-stepper", ariaLabel: "Which \(lower) goes",
          previousAriaLabel: "Previous \(lower)", nextAriaLabel: "Next \(lower)",
          previousDisabled: true, nextDisabled: true, class: "outliner-stepper-remove"
        ) {
          ButtonView(
            label: place, icon: IconView.subtract, buttonColor: .gray, weight: .subtle, size: .large,
            disabled: true, type: .button, ariaLabel: "Remove \(lower)", class: "outliner-stepper-button",
            labelFontWeight: fontWeightSemiBold)
          // A removed node's: the same button, restoring it.
          span {
            IconView.add
          }
          .class("outliner-stepper-restore-icon")
          .hidden()
          span {
            IconView.subtract
          }
          .class("outliner-stepper-remove-icon")
          .hidden()
        }
      }
      .class("outliner-stepper-view")
      .data("outliner-stepper-for", tree)
      .data("noun", noun)
      .data("noun-lower", lower)
      .style {
        // One row, each stepper whole and its content's width, wrapping
        // where they do not fit.
        selector("&") {
          display(.flex)
          flexWrap(.wrap)
          alignItems(.center)
          gap(spacing16)
          minWidth(0)
        }
        // A phone (the forms' breakpoint, `FormActionsView`): each stepper
        // a row of its own, the whole width—‹ at its start, › at its end,
        // its button stretching between them, its label centered (user,
        // 2026-11-03).
        media(maxWidth(maxWidthBreakpointMobile)) {
          selector("&") {
            flexDirection(.column).important()
            alignItems(.stretch).important()
          }
          selector("& > .pagination-view") {
            width(perc(100)).important()
          }
          selector("& .outliner-stepper-button") {
            flex(1).important()
            justifyContent(.center).important()
          }
        }
        selector("& .outliner-stepper-restore-icon", "& .outliner-stepper-remove-icon") {
          display(.none)
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// A tree's steppers on the client (`OutlinerStepperView`): the places a
  /// new node may go and the nodes that may go, read off the tree as it
  /// stands, and what a press does, the page's own.
  public final class OutlinerStepper: @unchecked Sendable {
    /// Where a new node goes: under `parent` (nil, the tree's top), right
    /// after `after`, one of its nodes, or first where `after` is nil.
    public struct Place {
      public let parent: DOM.Element?
      public let after: DOM.Element?
      public let number: String
    }

    private let view: DOM.Element
    private let tree: DOM.Element
    private let noun: String
    /// The noun as it is said mid-sentence: "testament".
    private let lowerNoun: String
    /// Whether a new node may go under `parent` (nil, the top).
    private let allows: (DOM.Element?) -> Bool
    /// Puts a new node at a place.
    private let insert: (Place) -> Void
    /// Whether a node may be removed, or restored where it is removed.
    private let removable: (DOM.Element) -> Bool
    /// Removes a node, or restores a removed one.
    private let remove: (DOM.Element) -> Void

    private var places: [Place] = []
    private var place = -1
    private var targets: [DOM.Element] = []
    private var target = -1

    public init?(
      view: DOM.Element, allows: @escaping (DOM.Element?) -> Bool, insert: @escaping (Place) -> Void,
      removable: @escaping (DOM.Element) -> Bool, remove: @escaping (DOM.Element) -> Void
    ) {
      guard let tree = document.getElementById(view.dataset["outliner-stepper-for"] ?? "") else { return nil }
      self.view = view
      self.tree = tree
      noun = view.dataset["noun"] ?? ""
      lowerNoun = view.dataset["noun-lower"] ?? ""
      self.allows = allows
      self.insert = insert
      self.removable = removable
      self.remove = remove
      bind()
      refresh()
      // Read off the tree and bound: what a page (or a test) waits on.
      view.setAttribute(data("outliner-stepper-ready"), "true")
    }

    // MARK: - Reading the tree

    private func items(in list: DOM.Element?) -> [DOM.Element] {
      (list?.querySelectorAll(":scope > .outliner-item") ?? []).filter { !Self.isRemoved($0) }
    }

    private static func isRemoved(_ item: DOM.Element) -> Bool {
      stringEquals(item.getAttribute(data("outliner-removed")) ?? "false", "true")
    }

    private var topList: DOM.Element? { tree.querySelector(":scope > .outliner-list") }

    private static func number(of item: DOM.Element) -> String {
      guard let fold = item.querySelector(":scope > .outliner-row .outliner-fold") else { return "" }
      return stringTrim(fold.textContent)
    }

    /// Every place a new node may go, in the tree's order: under each
    /// node, as its first, and right after it; an empty tree's first.
    private func readPlaces() -> [Place] {
      var out: [Place] = []
      func walk(_ list: DOM.Element?, parent: DOM.Element?) {
        for item in items(in: list) {
          let number = Self.number(of: item)
          if allows(item) {
            out.append(Place(parent: item, after: nil, number: stringJoin([number, "1"], separator: ".")))
          }
          walk(item.querySelector(":scope > .outliner-list"), parent: item)
          if allows(parent) {
            out.append(Place(parent: parent, after: item, number: OutlinerHydration.nextSibling(of: number)))
          }
        }
      }
      walk(topList, parent: nil)
      if items(in: topList).isEmpty, allows(nil) { out.append(Place(parent: nil, after: nil, number: "1")) }
      return out
    }

    /// The nodes that may go, or come back, in the tree's order.
    private func readTargets() -> [DOM.Element] {
      var out: [DOM.Element] = []
      for item in tree.querySelectorAll(".outliner-item") {
        // Under a removed node: it went with it, and comes back with it.
        var above = item.parentElement?.closest(".outliner-item")
        var under = false
        while let current = above {
          if Self.isRemoved(current) { under = true }
          above = current.parentElement?.closest(".outliner-item")
        }
        if under { continue }
        if removable(item) { out.append(item) }
      }
      return out
    }

    // MARK: - Drawing

    /// Whether the person stepped to the place, or the node, chosen: kept
    /// then as the tree changes, until a press acts on it.
    private var placeStepped = false
    private var targetStepped = false

    /// Reads the tree again, keeping a choice the person stepped to where it
    /// still stands; else each stepper's default: a new node's after the
    /// last node at the top (else the first place it may go), a removal's
    /// the last node.
    public func refresh() {
      let previousPlace = placeStepped && place >= 0 && place < places.count ? places[place] : nil
      let previousTarget = targetStepped && target >= 0 && target < targets.count ? targets[target] : nil
      places = readPlaces()
      targets = readTargets()
      place = -1
      if let previousPlace {
        for (index, candidate) in places.enumerated() where Self.same(candidate, previousPlace) { place = index }
      }
      if place < 0 {
        let tops = items(in: topList)
        if let last = tops.last {
          for (index, candidate) in places.enumerated() where candidate.parent == nil {
            if let after = candidate.after, after.id == last.id { place = index }
          }
        }
        if place < 0 { place = places.isEmpty ? -1 : 0 }
      }
      target = -1
      if let previousTarget {
        for (index, candidate) in targets.enumerated() where candidate.id == previousTarget.id { target = index }
      }
      if target < 0 { target = targets.count - 1 }
      draw()
    }

    private static func same(_ a: Place, _ b: Place) -> Bool {
      let parents: Bool
      if let p = a.parent, let q = b.parent { parents = p.id == q.id } else { parents = a.parent == nil && b.parent == nil }
      let afters: Bool
      if let p = a.after, let q = b.after { afters = p.id == q.id } else { afters = a.after == nil && b.after == nil }
      return parents && afters
    }

    private var addPager: DOM.Element? { view.querySelector(".outliner-stepper-add") }
    private var removePager: DOM.Element? { view.querySelector(".outliner-stepper-remove") }

    private func draw() {
      // Each button as wide as its longest label, so its chevrons stay put
      // as it steps.
      var longestPlace = 0
      for candidate in places { longestPlace = max(longestPlace, candidate.number.utf8.count) }
      var longestTarget = 0
      for candidate in targets { longestTarget = max(longestTarget, Self.number(of: candidate).utf8.count) }
      for (pager, longest) in [(addPager, longestPlace), (removePager, longestTarget)] {
        guard let label = pager?.querySelector(".outliner-stepper-button .button-label") else { continue }
        let chars = noun.utf8.count + 2 + longest
        label.setStyleProperty("min-width", stringJoin([intToString(chars), "ch"], separator: ""))
      }
      if let pager = addPager {
        let chosen = place >= 0 ? places[place] : nil
        name(pager, number: chosen?.number ?? "", verb: "Add", restoring: false, enabled: chosen != nil)
        pager.querySelector(".pagination-prev")?.setDisabled(place <= 0)
        pager.querySelector(".pagination-next")?.setDisabled(place < 0 || place + 1 >= places.count)
        stepClass(pager)
      }
      if let pager = removePager {
        let chosen = target >= 0 ? targets[target] : nil
        let restoring = chosen.map { Self.isRemoved($0) } ?? false
        name(
          pager, number: chosen.map { Self.number(of: $0) } ?? "", verb: restoring ? "Restore" : "Remove",
          restoring: restoring, enabled: chosen != nil)
        pager.querySelector(".pagination-prev")?.setDisabled(target <= 0)
        pager.querySelector(".pagination-next")?.setDisabled(target < 0 || target + 1 >= targets.count)
        stepClass(pager)
      }
      mark()
    }

    /// A pager's chevrons drawn disabled as the page's are.
    private func stepClass(_ pager: DOM.Element) {
      for selector in [".pagination-prev", ".pagination-next"] {
        guard let chevron = pager.querySelector(selector) else { continue }
        if chevron.hasAttribute("disabled") {
          chevron.classList.add("pagination-disabled")
        } else {
          chevron.classList.remove("pagination-disabled")
        }
      }
    }

    /// The pager's button named for the number it acts on: "+ Testament
    /// 1.2.", "− Testament 1.1.", a removed one's "+ Testament 1.1.".
    private func name(_ pager: DOM.Element, number: String, verb: String, restoring: Bool, enabled: Bool) {
      guard let button = pager.querySelector(".outliner-stepper-button") else { return }
      let text = stringIsEmpty(number) ? noun : stringJoin([noun, " ", number, "."], separator: "")
      button.querySelector(".button-label")?.textContent = text
      let spoken = stringIsEmpty(number) ? lowerNoun : stringJoin([lowerNoun, " ", number, "."], separator: "")
      button.setAttribute("aria-label", stringJoin([verb, " ", spoken], separator: ""))
      button.setDisabled(!enabled)
      // A removal's icon: − to remove, + to restore.
      if let icon = button.querySelector(".icon-view"),
        let source = pager.querySelector(
          restoring ? ".outliner-stepper-restore-icon .icon-view" : ".outliner-stepper-remove-icon .icon-view"),
        removePager?.id == pager.id
      {
        icon.setInnerHTML(source.innerHTML)
      }
    }

    // MARK: - Marking

    /// The place or the node chosen, marked in the tree while the person
    /// uses that stepper—from a press on its chevrons, or focus on its
    /// controls, until focus or the pointer's press leaves the row—and
    /// never at rest.
    private func mark() {
      for item in tree.querySelectorAll("[data-outliner-spot]") { item.removeAttribute(data("outliner-spot")) }
      for item in tree.querySelectorAll("[data-outliner-target]") { item.removeAttribute(data("outliner-target")) }
      guard let using else { return }
      if let pager = addPager, pager.id == using.id, place >= 0 {
        let chosen = places[place]
        if let after = chosen.after {
          after.setAttribute(data("outliner-spot"), "after")
        } else if let parent = chosen.parent {
          if let first = items(in: parent.querySelector(":scope > .outliner-list")).first {
            first.setAttribute(data("outliner-spot"), "before")
          } else {
            parent.setAttribute(data("outliner-spot"), "under")
          }
        }
      }
      if let pager = removePager, pager.id == using.id, target >= 0 {
        targets[target].setAttribute(data("outliner-target"), "true")
      }
    }

    /// The stepper in use, whose choice is marked; nil at rest.
    private var using: DOM.Element?

    private func use(_ pager: DOM.Element?) {
      using = pager
      mark()
    }

    /// Scrolls the place or the node chosen into view.
    private func reveal(adding: Bool) {
      let element: DOM.Element?
      if adding {
        let chosen = place >= 0 ? places[place] : nil
        element = chosen.flatMap { $0.after ?? $0.parent }
      } else {
        element = target >= 0 ? targets[target] : nil
      }
      guard let element else { return }
      OutlinerHydration.expand(around: element)
      let heading = element.querySelector(":scope > .outliner-row") ?? element
      heading.scrollIntoView(CSSOM.ScrollIntoViewOptions(block: .nearest))
    }

    // MARK: - Binding

    private func bind() {
      for (pager, adding) in [(addPager, true), (removePager, false)] {
        guard let pager else { continue }
        _ = pager.querySelector(".pagination-prev")?.addEventListener(.click) { [self] event in
          event.preventDefault()
          self.step(adding: adding, by: -1)
        }
        _ = pager.querySelector(".pagination-next")?.addEventListener(.click) { [self] event in
          event.preventDefault()
          self.step(adding: adding, by: 1)
        }
        _ = pager.querySelector(".outliner-stepper-button")?.addEventListener(.click) { [self] event in
          event.preventDefault()
          self.press(adding: adding)
        }
        _ = pager.addEventListener(.focusin) { [self] _ in self.use(pager) }
      }
      // Focus leaving the row, or a press anywhere outside it, ends the use.
      _ = view.addEventListener(.focusout) { [self] event in
        if let next = event.payload.relatedTarget, self.view.contains(next) { return }
        self.use(nil)
      }
      _ = document.addEventListener(.mousedown) { [self] event in
        guard let target = event.target, !self.view.contains(target) else { return }
        self.use(nil)
      }
      // The tree changed: read again.
      _ = tree.addEventListener("outliner-change") { [self] _ in self.refresh() }
    }

    private func step(adding: Bool, by delta: Int) {
      using = adding ? addPager : removePager
      if adding { placeStepped = true } else { targetStepped = true }
      if adding {
        guard !places.isEmpty else { return }
        place = max(0, min(places.count - 1, place + delta))
      } else {
        guard !targets.isEmpty else { return }
        target = max(0, min(targets.count - 1, target + delta))
      }
      draw()
      reveal(adding: adding)
    }

    private func press(adding: Bool) {
      if adding {
        guard place >= 0 else { return }
        insert(places[place])
      } else {
        guard target >= 0 else { return }
        remove(targets[target])
      }
      using = nil
      if adding { placeStepped = false } else { targetStepped = false }
      refresh()
    }
  }
#endif
