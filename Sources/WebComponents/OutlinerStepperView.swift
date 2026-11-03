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
  ///
  /// A node an open object holds (`hold`, user 2026-11-03) is still
  /// stepped to: "− Testament 1.1." is disabled there, and at a node one it
  /// holds stands under (it would go with it), and "+ Testament 1.1.1." at a
  /// place under one it holds; the button's tooltip is then the object's
  /// whole UUID, its one link, as a held node's marker's is
  /// (`OutlinerView.Grip.hold`).
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

    /// What marks a node an open object holds (user, 2026-11-01), among its
    /// outline item's attributes (`OutlinerView.Node.data`): the object's
    /// whole UUID, the words of the link its tooltip holds, and its page.
    public static func hold(id: String, url: String) -> [(String, String)] {
      [("outliner-hold", id), ("outliner-hold-url", url)]
    }

    /// A stepper's button in the tooltip a hold speaks in: off, and its
    /// clicks its button's, until the stepper steps onto a node or a place
    /// a hold keeps (`OutlinerStepper`), which fills its link.
    private func held(_ button: ButtonView) -> TooltipView {
      TooltipView(placement: .bottomStart, font: .mono, pins: false, off: true, class: "button-tooltip outliner-stepper-hold") {
        LinkView(url: "#") { "" }
      } content: {
        button
      }
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
          held(
            ButtonView(
              label: place, icon: IconView.add, buttonColor: .gray, weight: .subtle, size: .large, disabled: true,
              type: .button, ariaLabel: "Add \(lower) 1.", class: "outliner-stepper-button",
              labelFontWeight: fontWeightSemiBold))
        }
        PaginationView(
          size: .large, kind: "outliner-stepper", ariaLabel: "Which \(lower) goes",
          previousAriaLabel: "Previous \(lower)", nextAriaLabel: "Next \(lower)",
          previousDisabled: true, nextDisabled: true, class: "outliner-stepper-remove"
        ) {
          held(
            ButtonView(
              label: place, icon: IconView.subtract, buttonColor: .gray, weight: .subtle, size: .large,
              disabled: true, type: .button, ariaLabel: "Remove \(lower)", class: "outliner-stepper-button",
              labelFontWeight: fontWeightSemiBold))
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
        // One row, the add stepper then the remove stepper, each whole and
        // its content's width, a step apart (user, 2026-11-03), wrapping
        // only where they do not fit.
        selector("&") {
          display(.flex)
          flexWrap(.wrap)
          alignItems(.center)
          gap(spacing16)
          minWidth(0)
        }
        // A phone (`ButtonView.phoneStep`'s width, where the two never fit):
        // each stepper a row of its own, the whole width—‹ at its start, ›
        // at its end, its button stretching between them, its icon and
        // label one group centered in it, the button's own gap apart (user,
        // 2026-11-03): a button the whole width never moves its chevrons,
        // so its label keeps no width for its longest number.
        media(maxWidth(maxWidthBreakpointPhoneNarrow)) {
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
          selector("& .outliner-stepper-button .button-label") {
            minWidth(0).important()
          }
        }
        selector("& .outliner-stepper-restore-icon", "& .outliner-stepper-remove-icon") {
          display(.none)
        }
        // The hold's tooltip round a button sizes as the button alone: it
        // never holds it wider than its stepper (a phone's long number).
        selector("& .outliner-stepper-hold", "& .outliner-stepper-hold > .tooltip-trigger-content") {
          minWidth(0)
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DesignTokens
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
      // Where it rests: the tree's end, as drawn.
      homeParent = view.parentElement
      if let parent = homeParent { homeNext = Self.following(view, in: parent) }
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

    /// An open object holding a node, as its page marks the node's item
    /// (`OutlinerStepperView.hold`): its whole UUID and its page.
    private struct Hold {
      let id: String
      let url: String
    }

    /// The hold on `item` itself; nil for none, or for the tree's top.
    private static func hold(of item: DOM.Element?) -> Hold? {
      guard let item, let id = item.getAttribute(data("outliner-hold")) else { return nil }
      return Hold(id: id, url: item.getAttribute(data("outliner-hold-url")) ?? "")
    }

    /// What keeps a node from going: a hold on it, or on the first node
    /// under it, which would go with it.
    private static func removalHold(of item: DOM.Element) -> Hold? {
      if let own = hold(of: item) { return own }
      for under in item.querySelectorAll(".outliner-item") {
        if let found = hold(of: under) { return found }
      }
      return nil
    }

    /// What keeps a place from taking a new node: a hold on the node it
    /// would go under.
    private static func placeHold(of place: Place) -> Hold? { hold(of: place.parent) }

    private var topList: DOM.Element? { tree.querySelector(":scope > .outliner-list") }

    private static func number(of item: DOM.Element) -> String {
      OutlinerHydration.number(of: item)
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
      // A removal done: on to the node after the one removed, or the one
      // before where there is none.
      if let pending = pendingRemoval {
        var at = -1
        for (index, candidate) in targets.enumerated() where candidate.id == pending.id { at = index }
        if at < 0 {
          target = targets.isEmpty ? -1 : min(max(pendingIndex, 0), targets.count - 1)
          pendingRemoval = nil
        } else if Self.isRemoved(targets[at]) {
          target = at + 1 < targets.count ? at + 1 : max(at - 1, 0)
          pendingRemoval = nil
        }
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
      // Each button its content's width, its icon and label one group, the
      // button's own gap apart (user, 2026-11-03): no width kept for a
      // longer number.
      if let pager = addPager {
        let chosen = place >= 0 ? places[place] : nil
        let hold = chosen.flatMap { Self.placeHold(of: $0) }
        name(pager, number: chosen?.number ?? "", verb: "Add", restoring: false, enabled: chosen != nil, hold: hold)
        pager.querySelector(".pagination-prev")?.setDisabled(place <= 0)
        pager.querySelector(".pagination-next")?.setDisabled(place < 0 || place + 1 >= places.count)
        stepClass(pager)
      }
      if let pager = removePager {
        let chosen = target >= 0 ? targets[target] : nil
        let restoring = chosen.map { Self.isRemoved($0) } ?? false
        // A removed node is never held: what it restores keeps nothing.
        let hold = restoring ? nil : chosen.flatMap { Self.removalHold(of: $0) }
        name(
          pager, number: chosen.map { Self.number(of: $0) } ?? "", verb: restoring ? "Restore" : "Remove",
          restoring: restoring, enabled: chosen != nil, hold: hold)
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
    /// 1.2.", "− Testament 1.1.", a removed one's "+ Testament 1.1."; where
    /// a hold keeps it, disabled and the hold in its tooltip.
    private func name(_ pager: DOM.Element, number: String, verb: String, restoring: Bool, enabled: Bool, hold: Hold?) {
      guard let button = pager.querySelector(".outliner-stepper-button") else { return }
      let text = stringIsEmpty(number) ? noun : stringJoin([noun, " ", number, "."], separator: "")
      button.querySelector(".button-label")?.textContent = text
      let spoken = stringIsEmpty(number) ? lowerNoun : stringJoin([lowerNoun, " ", number, "."], separator: "")
      button.setAttribute("aria-label", stringJoin([verb, " ", spoken], separator: ""))
      var held = false
      if let _ = hold { held = true }
      button.setDisabled(!enabled || held)
      show(hold, on: pager)
      // A removal's icon: − to remove, + to restore.
      if let icon = button.querySelector(".icon-view"),
        let source = pager.querySelector(
          restoring ? ".outliner-stepper-restore-icon .icon-view" : ".outliner-stepper-remove-icon .icon-view"),
        removePager?.id == pager.id
      {
        icon.setInnerHTML(source.innerHTML)
      }
    }

    /// The pager's tooltip, saying the hold that keeps its button (user,
    /// 2026-11-03): the object's whole UUID, its one link; a click or a tap
    /// on the disabled button pins it, and it takes the focus the button no
    /// longer can. Off, and its button's own clicks and taps left alone,
    /// with none.
    private func show(_ hold: Hold?, on pager: DOM.Element) {
      guard let trigger = pager.querySelector(".outliner-stepper-hold") else { return }
      guard let hold else {
        trigger.setAttribute(data("tooltip-off"), "true")
        trigger.setAttribute(data("pins"), "false")
        trigger.removeAttribute("tabindex")
        return
      }
      if let link = TooltipHydration.bubble(of: trigger)?.querySelector("a") {
        link.setAttribute("href", hold.url)
        link.textContent = hold.id
      }
      trigger.setAttribute(data("tooltip-off"), "false")
      trigger.setAttribute(data("pins"), "true")
      trigger.setAttribute("tabindex", "0")
    }

    // MARK: - Marking

    /// Where the row rests, at the tree's end: its parent and what follows
    /// it there.
    private var homeParent: DOM.Element?
    private var homeNext: DOM.Element?

    /// The element after `element` among `parent`'s children; nil for none.
    private static func following(_ element: DOM.Element, in parent: DOM.Element) -> DOM.Element? {
      var found = false
      for child in parent.querySelectorAll(":scope > *") {
        if found { return child }
        if child.id == element.id { found = true }
      }
      return nil
    }

    /// Moves the row into `parent`, before `next` (last where nil): the
    /// element itself, never a copy, so what it holds keeps its state, and
    /// the focus kept where it was in it (a move can drop it).
    private func moveRow(into parent: DOM.Element, before next: DOM.Element?) {
      var target = next
      if let next, next.id == view.id { target = Self.following(view, in: parent) }
      if let current = view.parentElement, current.id == parent.id {
        let after = Self.following(view, in: parent)
        switch (after, target) {
        case (nil, nil): return
        case let (a?, b?) where a.id == b.id: return
        default: break
        }
      }
      var focused: DOM.Element?
      if let active = document.activeElement, view.contains(active) { focused = active }
      if let target { parent.insertBefore(view, target) } else { parent.appendChild(view) }
      if let focused, document.activeElement?.id != focused.id {
        focused.focus(DOM.FocusOptions(preventScroll: true))
      }
    }

    /// The row where it acts (user, 2026-11-03), the choice marked there,
    /// while the person uses a stepper—from a press on its chevrons, or
    /// focus on its controls, until focus or the pointer's press leaves the
    /// row: the add stepper's at the place chosen, right where the new node
    /// would go, its line just above it; the remove stepper's right after
    /// the node chosen, ringed above it. At rest, at the tree's end.
    private func mark() {
      for item in tree.querySelectorAll("[data-outliner-target]") { item.removeAttribute(data("outliner-target")) }
      guard let using else {
        view.setAttribute(data("outliner-stepper-at"), "rest")
        if let homeParent { moveRow(into: homeParent, before: homeNext) }
        return
      }
      if let pager = addPager, pager.id == using.id, place >= 0 {
        let chosen = places[place]
        view.setAttribute(data("outliner-stepper-at"), "add")
        if let after = chosen.after, let list = after.parentElement {
          moveRow(into: list, before: Self.following(after, in: list))
        } else if let list = chosen.parent.flatMap({ $0.querySelector(":scope > .outliner-list") }) ?? topList {
          moveRow(into: list, before: items(in: list).first)
        }
      } else if let pager = removePager, pager.id == using.id, target >= 0, let list = targets[target].parentElement {
        let chosen = targets[target]
        chosen.setAttribute(data("outliner-target"), "true")
        view.setAttribute(data("outliner-stepper-at"), "remove")
        moveRow(into: list, before: Self.following(chosen, in: list))
      }
      // Under a folded node, it opens.
      OutlinerHydration.expand(around: view)
    }

    /// The stepper in use, whose choice is marked; nil at rest.
    private var using: DOM.Element?

    /// Whether a pointer is pressed on the row: its focus then waits for
    /// the press's click to move it, or the click would land where it was.
    private var pressing = false

    /// Whether a press outside the row has ended its use: the row goes
    /// back to the tree's end once the press's click is done.
    private var leaving = false

    private func use(_ pager: DOM.Element?) {
      using = pager
      if pressing, let _ = pager { return }
      if leaving { return }
      mark()
    }

    /// Keeps the row in view where it now stands, scrolling only as far as
    /// it takes (user, 2026-11-03): with the line above it, or the heading
    /// of the node it removes, where both fit.
    private func reveal(adding: Bool) {
      guard let row = view.getBoundingClientRect() else { return }
      var above = spacing24.value
      if !adding, target >= 0,
        let heading = targets[target].querySelector(":scope > .outliner-row")?.getBoundingClientRect(),
        row.bottom - heading.top <= window.innerHeight
      {
        above = stringJoin([intToString(Int(row.top - heading.top) + 16), "px"], separator: "")
      }
      view.setStyleProperty("scroll-margin-block-start", above)
      view.setStyleProperty("scroll-margin-block-end", spacing8.value)
      let still = window.matchMedia("(prefers-reduced-motion: reduce)")
      view.scrollIntoView(CSSOM.ScrollIntoViewOptions(behavior: still ? .auto : .smooth, block: .nearest))
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
      // Focus leaving the row, or a press anywhere outside it, ends the
      // use: the row goes back to the tree's end. Focus dropped by its own
      // move comes back to it at once, so it is read a turn later.
      _ = view.addEventListener(.focusout) { [self] event in
        if let next = event.payload.relatedTarget, self.view.contains(next) { return }
        _ = setTimeout(0) {
          if let active = document.activeElement, self.view.contains(active) { return }
          if self.pressing { return }
          self.use(nil)
        }
      }
      _ = view.addEventListener(.mousedown) { [self] _ in self.pressing = true }
      _ = document.addEventListener(.mouseup) { [self] _ in
        guard self.pressing || self.leaving else { return }
        // After the press's click, which steps or acts where it was, or
        // lands on what was pressed outside: the row moves only then, so
        // nothing shifts under the pointer between its press and its click.
        _ = setTimeout(0) {
          self.pressing = false
          self.leaving = false
          self.mark()
        }
      }
      _ = document.addEventListener(.mousedown) { [self] event in
        guard let target = event.target, !self.view.contains(target) else { return }
        guard let _ = self.using else { return }
        self.using = nil
        self.leaving = true
        for item in self.tree.querySelectorAll("[data-outliner-target]") {
          item.removeAttribute(data("outliner-target"))
        }
      }
      // The tree changed: read again.
      _ = tree.addEventListener("outliner-change") { [self] _ in self.refresh() }
    }

    private func step(adding: Bool, by delta: Int) {
      using = adding ? addPager : removePager
      // A removal asked about and let go is no longer waited on.
      if !adding { pendingRemoval = nil }
      if adding { placeStepped = true } else { targetStepped = true }
      if adding {
        guard !places.isEmpty else { return }
        place = max(0, min(places.count - 1, place + delta))
      } else {
        guard !targets.isEmpty else { return }
        target = max(0, min(targets.count - 1, target + delta))
      }
      draw()
      // A chevron stepped to the end turns disabled under focus, which then
      // leaves the row and ends its use, unmarking the choice: focus goes
      // to the other chevron, the page kept where it is.
      // The row moved as it stepped (`mark`) may have dropped it already.
      if let pager = using, let pressed = pager.querySelector(delta < 0 ? ".pagination-prev" : ".pagination-next"),
        pressed.hasAttribute("disabled"),
        let other = pager.querySelector(delta < 0 ? ".pagination-next" : ".pagination-prev"),
        !other.hasAttribute("disabled")
      {
        var kept = false
        if let focused = document.activeElement, view.contains(focused), focused.id != pressed.id { kept = true }
        if !kept { other.focus(DOM.FocusOptions(preventScroll: true)) }
      }
      reveal(adding: adding)
    }

    /// A removal pressed for, until the tree says it is done (a page may
    /// ask first): the node, and where it stood among the nodes that go.
    private var pendingRemoval: DOM.Element?
    private var pendingIndex = -1

    /// Acts on the choice, and keeps the row with it (user, 2026-11-03): an
    /// added node's row right after it, the add stepper there, at the place
    /// after the new node; a removal's on the node next to the one removed,
    /// or the one before where there is none. The stepper stays in use, the
    /// focus on its button.
    private func press(adding: Bool) {
      if adding {
        guard place >= 0 else { return }
        let chosen = places[place]
        if let _ = Self.placeHold(of: chosen) { return }
        insert(chosen)
        // The new node: where the place said it would go.
        var added: DOM.Element?
        if let after = chosen.after, let list = after.parentElement {
          var found = false
          for item in items(in: list) {
            if found {
              added = item
              break
            }
            if item.id == after.id { found = true }
          }
        } else {
          added = items(in: chosen.parent.flatMap { $0.querySelector(":scope > .outliner-list") } ?? topList).first
        }
        using = addPager
        refresh()
        if let added {
          let next = Place(parent: chosen.parent, after: added, number: "")
          var found = false
          for (index, candidate) in places.enumerated() where Self.same(candidate, next) {
            place = index
            found = true
          }
          placeStepped = found
          // No place after it (a page that takes one new node): the remove
          // stepper on the new node, the row after it all the same.
          if !found {
            for (index, candidate) in targets.enumerated() where candidate.id == added.id {
              target = index
              targetStepped = true
              using = removePager
            }
          }
        }
        draw()
      } else {
        guard target >= 0 else { return }
        if !Self.isRemoved(targets[target]), let _ = Self.removalHold(of: targets[target]) { return }
        // A restore keeps the stepper on the node it brings back.
        pendingRemoval = Self.isRemoved(targets[target]) ? nil : targets[target]
        pendingIndex = target
        using = removePager
        targetStepped = true
        remove(targets[target])
        refresh()
      }
      if let pager = using, let button = pager.querySelector(".outliner-stepper-button"),
        let focused = document.activeElement, !view.contains(focused) || focused.id != button.id
      {
        if !button.hasAttribute("disabled") { button.focus(DOM.FocusOptions(preventScroll: true)) }
      }
      reveal(adding: adding)
    }
  }
#endif
