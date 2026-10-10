import EmbeddedSwiftUtilities

/// Which items of an outline moved between two arrangements of it.
///
/// An item moved when its parent changed. Among items that kept their parent,
/// the ones that kept their order relative to each other did not move—the
/// longest run of them whose old positions still increase—and every other
/// one did. So dragging one item to the top of a list reports that one item,
/// not the whole list it renumbered: renumbering alone is never a move.
///
/// Used on both sides: the outliner marks moves as they happen, and a page
/// that shows an outline's history reports them the same way.
public enum OutlineMoves {
  public struct Entry: Sendable {
    public let id: String
    public let oldParent: String
    public let oldPosition: Int
    public let newParent: String
    public let newPosition: Int

    public init(id: String, oldParent: String, oldPosition: Int, newParent: String, newPosition: Int) {
      self.id = id
      self.oldParent = oldParent
      self.oldPosition = oldPosition
      self.newParent = newParent
      self.newPosition = newPosition
    }
  }

  /// Whether each entry moved, in the order given.
  ///
  /// Two orders can be equally short of the old one—swap two neighbors
  /// and either of them could be the one that moved. `touched` breaks the
  /// tie: an item the reader actually moved is the one reported, rather
  /// than the neighbor it passed.
  public static func moved(_ entries: [Entry], touched: [String] = []) -> [Bool] {
    var moved = entries.map { !stringEquals($0.oldParent, $0.newParent) }
    var grouped = [Bool](repeating: false, count: entries.count)
    for start in entries.indices where !moved[start] && !grouped[start] {
      // Everyone who stayed under this parent, in their new order.
      var group: [Int] = []
      for index in entries.indices where !moved[index] && !grouped[index]
        && stringEquals(entries[index].newParent, entries[start].newParent)
      {
        group.append(index)
        grouped[index] = true
      }
      group.sort { entries[$0].newPosition < entries[$1].newPosition }
      let kept = longestIncreasingRun(
        group.map { entries[$0].oldPosition },
        untouched: group.map { index in !touched.contains(where: { stringEquals($0, entries[index].id) }) })
      for (offset, index) in group.enumerated() where !kept[offset] {
        moved[index] = true
      }
    }
    return moved
  }

  /// Which elements belong to one longest strictly increasing subsequence—of
  /// those, the one that keeps the most `untouched` elements, and then
  /// the one that keeps the items that stood earliest. That last is the
  /// usual case settled right: an item moved up past its neighbors is the
  /// one that moved, not all of them moving down.
  static func longestIncreasingRun(_ values: [Int], untouched: [Bool]) -> [Bool] {
    guard !values.isEmpty else { return [] }
    // (length, untouched kept, -sum of kept positions): larger is better.
    func better(_ a: (Int, Int, Int), than b: (Int, Int, Int)) -> Bool {
      if a.0 != b.0 { return a.0 > b.0 }
      if a.1 != b.1 { return a.1 > b.1 }
      return a.2 > b.2
    }
    var score = values.indices.map { (1, untouched[$0] ? 1 : 0, -values[$0]) }
    var previous = [Int](repeating: -1, count: values.count)
    var best = 0
    for i in values.indices {
      let own = (1, untouched[i] ? 1 : 0, -values[i])
      for j in 0..<i where values[j] < values[i] {
        let through = (score[j].0 + own.0, score[j].1 + own.1, score[j].2 + own.2)
        if better(through, than: score[i]) {
          score[i] = through
          previous[i] = j
        }
      }
      if better(score[i], than: score[best]) { best = i }
    }
    var run = [Bool](repeating: false, count: values.count)
    var cursor = best
    while cursor >= 0 {
      run[cursor] = true
      cursor = previous[cursor]
    }
    return run
  }
}

#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The site's one tree: a nested list drawn as a real tree, indented, that
  /// its reader may also rearrange—the record pages' testament and
  /// sentiment trees, an origin's steps, the amendment and submission
  /// outlines, a form's nested steps.
  ///
  /// **Drawn indented.** Each level stands a step (`spacing24`) further in
  /// than its parent, a thin guide line down the step's middle along every
  /// level under it. An item with items under it has a toggle at its start
  /// that collapses and expands them; an item without keeps the toggle's
  /// room, so siblings line up (a tree with no nesting at all draws no
  /// toggle column). An item that is itself an accordion (`accordion`: a
  /// record's row, with its own chevron) has no toggle and no toggle
  /// column: its own chevron collapses it and the items under it, as one
  /// (user, 2026-09-30), and its card holds the items under it, after what
  /// it opens into (2026-10-01). Its children are the outline's to place,
  /// never its content's.
  ///
  /// **Its own controls last.** An item's `footer` (a tree node's + and −)
  /// is its last row, after its content and every item under it: "+" adds
  /// below it (user, 2026-10-01).
  ///
  /// **Deep trees scroll.** The tree sits in a sideways scrollport (as a
  /// table does), and every node is at least `minWidthTreeNode` wide, so a
  /// node at depth 100 is as readable as one at depth 1: past the width the
  /// column gives, the tree scrolls, never the page. A menu opened inside
  /// the scrollport is placed over the page, not cut off at its edge
  /// (`DropdownView`).
  ///
  /// **Arranged** only where it has a `name` (the hidden input the
  /// arrangement posts as): then its reader can rearrange it—by dragging
  /// an item's handle, by picking it up and moving it with a toolbar, or
  /// from the keyboard. With no `name` it is a tree to read: no handles, no
  /// toolbar, nothing posted.
  ///
  /// Each item carries content the caller builds, a label to announce it by,
  /// and a rank. Ranks order the levels an outline may nest—the smaller the
  /// number, the higher the level—and one rule holds for every outline,
  /// whatever it outlines:
  ///
  /// - an item may sit under an item of its own rank: a sense grouping
  ///   senses—unless the outline's ranks are strict (`strictRanks`), where
  ///   each rank stands only under a higher one: a testament tree's
  ///   edition › impression › issue › copy › manifest;
  /// - it may sit under an item of any higher rank, at any depth the
  ///   outline allows;
  /// - it may never sit under an item of a lower rank: an edition under a
  ///   copy;
  /// - nothing may sit under an item of the leaf rank, the most concrete,
  ///   whose items are attested directly: a manifest by its images, a leaf
  ///   sense by its quotations.
  ///
  /// A refused move is refused where it is attempted, with an alert over the
  /// outline and the same words in the live region: the caller's sentence,
  /// "A more abstract testament can't go under a more concrete one.", or,
  /// under the leaf rank, its own where it gives one ("Nothing can go under
  /// a digitization: its canvases attest it."). An outline may also cap its depth (`maxDepth`): a
  /// sentiment tree stops five levels under its title, and a move that would put an item, or one it carries,
  /// deeper is refused in the outline's own words (`depthRefusal`).
  ///
  /// Each item's content is handed the pieces the outline puts in it—its
  /// handle and the line saying how its number changed, both nil in a tree
  /// to read—and places them in its own layout: the handle in its header.
  ///
  /// The handle is the only control in a row that moves it. Pressing it—a
  /// click, a tap, Space or Enter—picks the item up: it is marked as held,
  /// and a toolbar appears at the foot of the screen with the four moves—up,
  /// down, out a level, in a level—each unavailable where it cannot
  /// go, and Done. The item stays held through as many moves as it takes,
  /// until Done, another press on its handle, or Escape. From the keyboard,
  /// while it is held, ↑ and ↓ move it among its siblings, Tab and → put it
  /// under the item above, Shift-Tab and ← take it out to its parent's
  /// level, and Enter, Space or Escape put it down. Tab is only taken while
  /// an item is held. A handle can also be dragged: with a mouse at once, on
  /// a touch screen after a long press. An item moved under a collapsed one
  /// opens it.
  ///
  /// Each item wears one state at a time, in `data-outline-state`, which is
  /// all a caller styles: `refused` while a dragged item hovers it and may
  /// not land there, `held` while it is picked up, `placeholder` for the
  /// place a dragged item left, `moved` once it stands where it did not, and
  /// `none`. They are in that order of precedence, so no two are ever drawn
  /// together. A refusal is said once, in an alert, and leaves no mark.
  ///
  /// The arrangement is submitted as JSON in a hidden input: each item's id
  /// to its parent's and its position among its siblings,
  /// `{"a": {"parent": "root", "position": 0}}`, where the top level's parent
  /// is `rootID`. An item that moved is marked `data-outliner-moved`: one whose
  /// parent changed, or one outside the longest run of its siblings that kept
  /// their order—so a move marks the item moved, not every neighbor it
  /// renumbered. Every item whose number changed—moved, or only renumbered
  /// by a move near it—says so as a changed field says it: "Diff: 1.3 →
  /// 1.1". The root dispatches `outliner-change` with the JSON after every
  /// move.
  ///
  /// An item the page marks `data-outliner-removed="true"` is removed, with
  /// every item under it: left out of the JSON and the numbering, drawn in
  /// the `removed` state, never picked up, and nothing goes under it. The
  /// page dispatches `outliner-removal` on the root after marking or
  /// unmarking one, and the outline reads itself again.
  public struct OutlinerView: HTMLContent {
    public struct Node: Sendable {
      public let id: String
      public let label: String
      public let rank: Int
      /// Where the item stood before this outline was last edited, when
      /// that is not where it is drawn: an outline brought back mid-edit
      /// still reports its moves against the arrangement it started from.
      public let origin: Origin?
      /// Whether the reader may move it. An item that may not keeps its
      /// place: its handle is drawn disabled and nothing picks it up, though
      /// a movable item may still be moved past it, into it or out of it.
      public let movable: Bool
      /// Extra attributes for the item (`li`), for a page that finds its
      /// items by them.
      public let data: [(String, String)]
      /// Whether the item is itself an accordion (`AccordionView`, the
      /// first in its content): its own chevron is its collapse control,
      /// hiding the items under it with its body, and the tree draws no
      /// toggle for it. Open as the accordion is drawn open.
      public let accordion: Bool
      /// The item, given the pieces the outline puts in it.
      public let content: @Sendable (Slots) -> [DOM.Node]
      /// The item's own controls (a tree node's + and −: "+" adds below
      /// it), drawn as its last row: after its content and every item under
      /// it, inside its card where it is one (`accordion`). Shown whether
      /// its items are or not.
      public let footer: @Sendable () -> [DOM.Node]
      public let children: [Node]

      public init(
        id: String,
        label: String,
        rank: Int = 0,
        origin: Origin? = nil,
        movable: Bool = true,
        data: [(String, String)] = [],
        accordion: Bool = false,
        children: [Node] = [],
        @HTMLBuilder content: @escaping @Sendable (Slots) -> [DOM.Node],
        @HTMLBuilder footer: @escaping @Sendable () -> [DOM.Node] = { [] }
      ) {
        self.id = id
        self.label = label
        self.rank = rank
        self.origin = origin
        self.movable = movable
        self.data = data
        self.accordion = accordion
        self.children = children
        self.content = content
        self.footer = footer
      }
    }

    /// What the outline puts in an item, for the item to place. Both are
    /// nil in a tree to read.
    public struct Slots: Sendable {
      /// The grip that picks the item up, for the start of its header.
      public let handle: DOM.Node?
      /// "Diff: 2.1 → 1.1", shown once the item's number has changed, for
      /// under its title.
      public let diff: DOM.Node?
    }

    /// An item's place in the arrangement moves are counted from.
    public struct Origin: Sendable {
      public let parent: String
      public let position: Int
      public let number: String

      public init(parent: String, position: Int, number: String) {
        self.parent = parent
        self.position = position
        self.number = number
      }
    }

    let id: String
    let label: String
    let rootID: String
    let rootRank: Int
    let leafRank: Int?
    let nodes: [Node]
    let name: String?
    let form: String?
    let numberSelector: String
    let rankRefusal: String
    let leafRefusal: String?
    let strictRanks: Bool
    let maxDepth: Int?
    let depthRefusal: String
    let touched: [String]
    let `class`: String

    /// - Parameters:
    ///   - label: What the outline is, for the list's accessible name.
    ///   - rootID: The parent the top level names in the JSON.
    ///   - rootRank: The rank of that root; nothing may rise above it.
    ///   - leafRank: The most concrete rank, which nothing may sit under.
    ///   - name: The hidden input's name, and `form` the form it submits
    ///     with when the outline is not inside it. Nil draws a tree to
    ///     read, which nothing rearranges.
    ///   - numberSelector: Where in an item's content its number—1, 2.1—is
    ///     written, so a caller that shows numbers keeps them true as the
    ///     outline changes. Empty writes none.
    ///   - rankRefusal: What a move the ranks refuse is told, in the page's
    ///     own words for what it outlines.
    ///   - leafRefusal: What a move under the leaf rank is told; nil says
    ///     `rankRefusal`.
    ///   - strictRanks: Whether an item may sit only under a higher rank,
    ///     never under one of its own.
    ///   - maxDepth: The most levels items may stand under the root, the
    ///     top level the first; nil for no limit.
    ///   - depthRefusal: What a move past `maxDepth` is told.
    ///   - touched: The items the reader has already moved, when the outline
    ///     is brought back mid-edit: where two readings of what moved are
    ///     equally short, theirs is the one reported.
    public init(
      id: String,
      label: String,
      rootID: String = "root",
      rootRank: Int = 0,
      leafRank: Int? = nil,
      nodes: [Node],
      name: String? = nil,
      form: String? = nil,
      numberSelector: String = "",
      rankRefusal: String = "A more abstract item can't go under a more concrete one.",
      leafRefusal: String? = nil,
      strictRanks: Bool = false,
      maxDepth: Int? = nil,
      depthRefusal: String = "An item can't go that deep.",
      touched: [String] = [],
      class: String = ""
    ) {
      self.id = id
      self.label = label
      self.rootID = rootID
      self.rootRank = rootRank
      self.leafRank = leafRank
      self.nodes = nodes
      self.name = name
      self.form = form
      self.numberSelector = numberSelector
      self.rankRefusal = rankRefusal
      self.leafRefusal = leafRefusal
      self.strictRanks = strictRanks
      self.maxDepth = maxDepth
      self.depthRefusal = depthRefusal
      self.touched = touched
      self.`class` = `class`
    }

    /// Whether its reader may rearrange it.
    private var arranges: Bool { name != nil }

    private static func json(_ value: String) -> String {
      var out = "\""
      for character in value {
        if character == "\\" {
          out += "\\\\"
        } else if character == "\"" {
          out += "\\\""
        } else {
          out.append(character)
        }
      }
      return out + "\""
    }

    /// The arrangement as rendered, in the form the hidden input submits.
    private var shapeJSON: String {
      var entries: [String] = []
      func walk(_ nodes: [Node], parent: String) {
        for (position, node) in nodes.enumerated() {
          entries.append(
            "\(Self.json(node.id)):{\"parent\":\(Self.json(parent)),\"position\":\(position)}")
          walk(node.children, parent: node.id)
        }
      }
      walk(nodes, parent: rootID)
      return "{" + entries.joined(separator: ",") + "}"
    }

    /// The items that stand somewhere other than where they started.
    private var movedIDs: Set<String> {
      var entries: [OutlineMoves.Entry] = []
      func walk(_ nodes: [Node], parent: String) {
        for (position, node) in nodes.enumerated() {
          entries.append(
            OutlineMoves.Entry(
              id: node.id, oldParent: node.origin?.parent ?? parent,
              oldPosition: node.origin?.position ?? position, newParent: parent, newPosition: position))
          walk(node.children, parent: node.id)
        }
      }
      walk(nodes, parent: rootID)
      return Set(zip(entries, OutlineMoves.moved(entries, touched: touched)).filter(\.1).map(\.0.id))
    }

    /// One item of a tree to read, and every item under it: what a page
    /// adds to a tree already drawn (a form's new step) asks the server for.
    public struct Item: HTMLContent {
      let node: Node

      public init(_ node: Node) {
        self.node = node
      }

      public func build() -> DOM.Node {
        OutlinerView.item(
          node, parent: "", position: 0, prefix: "", treeID: "outliner", arranges: false, moved: [], touched: [])
      }
    }

    /// The toggle that collapses an item's children and expands them again:
    /// its chevron points down while they show. Hidden (its room kept) on
    /// an item with nothing under it.
    private static func toggle(_ node: Node, treeID: String) -> DOM.Node {
      button {
        AnimatedRightDownChevronView(
          id: "\(treeID)-toggle-\(node.id)", expanded: true, size: sizeIconSmall)
      }
      .type(.button)
      .class("outliner-toggle")
      .ariaExpanded(true)
      .ariaLabel(node.label)
      .build()
    }

    /// Whether the first accordion in an item's content (in document order,
    /// the outermost) is drawn open; nil where there is none.
    private static func accordionIsOpen(_ nodes: [DOM.Node]) -> Bool? {
      for node in nodes {
        if let element = node as? DOM.Element {
          if let classes = element.attributes.first(where: { $0.0 == "class" })?.1,
            classes.split(separator: " ").contains("accordion-details")
          {
            return element.attributes.first(where: { $0.0 == "data-expanded" })?.1 == "true"
          }
          if let open = accordionIsOpen(element.children) { return open }
        } else if let fragment = node as? DOM.DocumentFragment {
          if let open = accordionIsOpen(fragment.children) { return open }
        }
      }
      return nil
    }

    /// Marks the first accordion in an item's content (the outermost) as the
    /// item's own: the one its card is drawn by.
    private static func markOwnAccordion(_ nodes: [DOM.Node]) -> Bool {
      for node in nodes {
        if let element = node as? DOM.Element {
          if let classes = element.attributes.first(where: { $0.0 == "class" })?.1,
            classes.split(separator: " ").contains("accordion-view")
          {
            element.attributes.append(("data-outliner-own-accordion", "true"))
            return true
          }
          if markOwnAccordion(element.children) { return true }
        } else if let fragment = node as? DOM.DocumentFragment {
          if markOwnAccordion(fragment.children) { return true }
        }
      }
      return false
    }

    private struct ItemFrame {
      let node: Node
      let number: String
      let origin: Origin
      let isMoved: Bool
      let collapsed: Bool
      let row: DOM.Node
      var nextChild = 0
      var children: [DOM.Node] = []
    }

    /// Build nested markup without keeping a result-builder call on the
    /// stack for every level. Deep origins also render on small worker stacks.
    static func item(
      _ node: Node, parent: String, position: Int, prefix: String, treeID: String, arranges: Bool,
      moved: Set<String>, touched: [String]
    ) -> DOM.Node {
      var frames = [prepareItem(node, parent: parent, position: position, prefix: prefix,
        treeID: treeID, arranges: arranges, moved: moved)]
      while let frame = frames.last {
        if frame.nextChild < frame.node.children.count {
          let index = frame.nextChild
          frames[frames.count - 1].nextChild += 1
          frames.append(prepareItem(frame.node.children[index], parent: frame.node.id, position: index,
            prefix: frame.number, treeID: treeID, arranges: arranges, moved: moved))
        } else {
          frames.removeLast()
          let rendered = finishItem(frame, arranges: arranges, touched: touched)
          if frames.isEmpty { return rendered }
          frames[frames.count - 1].children.append(rendered)
        }
      }
      preconditionFailure("An outliner item always has a root")
    }

    /// Prepare the row before its children, keeping stylesheet registration
    /// in document order; the footer is built after the children finish.
    private static func prepareItem(
      _ node: Node, parent: String, position: Int, prefix: String, treeID: String, arranges: Bool,
      moved: Set<String>
    ) -> ItemFrame {
      let number = prefix.isEmpty ? "\(position + 1)" : "\(prefix).\(position + 1)"
      let origin = node.origin ?? Origin(parent: parent, position: position, number: number)
      let isMoved = moved.contains(node.id)
      var slots = Slots(handle: nil, diff: nil)
      if arranges {
        // The grip: what is pressed to pick the item up, what is dragged,
        // and what the keyboard grabs.
        let handle = button {
          DraggableIconView(size: sizeIconSmall)
        }
        .type(.button)
        .class("outliner-handle")
        .draggable(node.movable)
        .disabled(!node.movable)
        .ariaLabel(node.movable ? "Move \(node.label)" : "\(node.label) stays where it is")
        .ariaPressed(false)
        .ariaDescribedby("\(treeID)-instructions")
        .build()
        // How its number changed, as a changed field says it—shown
        // whenever its number is no longer what it was, and written again
        // by the client as moves change it.
        let diff = div { DiffView(.outline(old: origin.number, new: number)) }
          .class("outliner-diff")
          .data("visible", !stringEquals(origin.number, number))
          .build()
        slots = Slots(handle: handle, diff: diff)
      }
      let content = node.content(slots)
      // An accordion item starts collapsed where its accordion starts closed.
      let collapsed = node.accordion && accordionIsOpen(content) == false
      if node.accordion { _ = markOwnAccordion(content) }
      let row = div {
        if !node.accordion {
          toggle(node, treeID: treeID)
        }
        div { content }
          .class("outliner-node")
      }
      .class("outliner-row")
      .build()
      return ItemFrame(node: node, number: number, origin: origin, isMoved: isMoved, collapsed: collapsed, row: row)
    }

    private static func finishItem(_ frame: ItemFrame, arranges: Bool, touched: [String]) -> DOM.Node {
      let node = frame.node
      var element = li {
        frame.row
        ol { frame.children }.class("outliner-list")
        let footer = node.footer()
        if !footer.isEmpty {
          div { footer }
            .class("outliner-footer")
        }
      }
      .class("outliner-item")
      .data("outliner-id", node.id)
      .data("outliner-label", node.label)
      .data("outliner-collapsed", frame.collapsed)
      .data("outliner-accordion", node.accordion)
      if arranges {
        element =
          element
          .data("outliner-rank", node.rank)
          .data("outliner-original-parent", frame.origin.parent)
          .data("outliner-original-position", frame.origin.position)
          .data("outliner-original-number", frame.origin.number)
          .data("outliner-moved", frame.isMoved)
          .data("outliner-touched", touched.contains(node.id))
          .data("outline-state", frame.isMoved ? "moved" : "none")
      }
      for (key, value) in node.data {
        element = element.data(key, value)
      }
      return element.build()
    }

    public func build() -> DOM.Node {
      let moved = arranges ? movedIDs : []
      let top = ol {
        for (position, node) in nodes.enumerated() {
          Self.item(
            node, parent: rootID, position: position, prefix: "", treeID: id, arranges: arranges, moved: moved,
            touched: touched)
        }
      }
      .class("outliner-list")
      .ariaLabel(label)

      return div {
        if arranges {
          p {
            "Press Space or Enter on a handle to pick an item up; a toolbar at the foot of the screen then moves it. While it is held, the up and down arrows move it among its neighbors, Tab or the right arrow puts it under the item above, Shift-Tab or the left arrow takes it out a level, and Enter, Space or Escape put it down."
          }
          .id("\(id)-instructions")
          .class("outliner-instructions")

          div()
            .class("outliner-live")
            .ariaLive(.assertive)

          div()
            .class("outliner-feedback")
          // The alert a refusal is said in, cloned into the slot above.
          div {
            AlertView(color: .red, inline: true, allowUserDismiss: true) {
              span {}
            }
          }
          .class("outliner-feedback-template")
          .hidden()
        }

        // The scrollport: a deep tree scrolls here, never the page.
        div { top }
          .class("outliner-scroll")
          .data("scrollport", true)

        if let name {
          if let form {
            input()
              .type(.hidden)
              .name(name)
              .form(form)
              .value(shapeJSON)
              .class("outliner-shape")
          } else {
            input()
              .type(.hidden)
              .name(name)
              .value(shapeJSON)
              .class("outliner-shape")
          }

          // The moves for the item held, at the foot of the screen where a
          // thumb reaches them, whatever the row's width.
          div {
            span {}
              .class("outliner-toolbar-label")
            // Large: a thumb's size, as the button sizes give it.
            div {
              ButtonView(
                icon: ArrowUpIconView(size: fontSizeLarge18), weight: .quiet, size: .large,
                ariaLabel: "Move up", data: [("outliner-action", "up")])
              ButtonView(
                icon: ArrowDownIconView(size: fontSizeLarge18), weight: .quiet, size: .large,
                ariaLabel: "Move down", data: [("outliner-action", "down")])
              ButtonView(
                icon: ArrowPreviousIconView(size: fontSizeLarge18), weight: .quiet, size: .large,
                ariaLabel: "Outdent", data: [("outliner-action", "outdent")])
              ButtonView(
                icon: ArrowNextIconView(size: fontSizeLarge18), weight: .quiet, size: .large,
                ariaLabel: "Indent", data: [("outliner-action", "indent")])
            }
            .class("outliner-toolbar-moves")
            ButtonView(
              label: "Done", buttonColor: .blue, weight: .solid, size: .large,
              data: [("outliner-action", "done")])
          }
          .class("outliner-toolbar")
          .role("toolbar")
          .ariaLabel("Move \(label.lowercased())")
          .data("visible", false)
        }
      }
      .id(id)
      .class(`class`.isEmpty ? "outliner-view" : "outliner-view \(`class`)")
      .data("outliner-arranges", arranges)
      .data("outliner-root-id", rootID)
      .data("outliner-root-rank", rootRank)
      .data("outliner-leaf-rank", leafRank.map(String.init) ?? "")
      .data("outliner-number-selector", numberSelector)
      .data("outliner-rank-refusal", rankRefusal)
      .data("outliner-leaf-refusal", leafRefusal ?? rankRefusal)
      .data("outliner-strict-ranks", strictRanks)
      .data("outliner-max-depth", maxDepth.map(String.init) ?? "")
      .data("outliner-depth-refusal", depthRefusal)
      .style { Self.treeCSS() }
      .build()
    }

    /// The tree's own rules: its indent, guide lines, toggles and
    /// scrollport, and an arranged outline's handles, drop marks and
    /// toolbar.
    @CSSBuilder
    public static func treeCSS() -> [CSSOM.CSSRule] {
      selector("&") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        minWidth(0)
      }
      // The scrollport, as a table's: sideways only, its bar over nothing.
      // A little room at its edges, so a ring drawn outside a row or a
      // control is not cut off by the edge that scrolls.
      descendant(".outliner-scroll") {
        overflowX(.auto)
        minWidth(0)
        padding(spacing4)
      }
      selector(
        "& .outliner-scroll::-webkit-scrollbar-track", "& .outliner-scroll::-webkit-scrollbar-track-piece",
        "& .outliner-scroll::-webkit-scrollbar-corner"
      ) {
        backgroundColor(.transparent).important()
      }
      selector("& .outliner-instructions", "& .outliner-live") {
        position(.absolute)
        width(px(1))
        height(px(1))
        margin(px(-1))
        padding(0)
        overflow(.hidden)
        clip(rect(0, 0, 0, 0))
        whiteSpace(.nowrap)
        borderWidth(0)
      }
      descendant(".outliner-feedback:empty") {
        display(.none)
      }
      descendant(".outliner-feedback-template") {
        display(.none)
      }
      descendant(".outliner-list") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        listStyle(.none)
        margin(0)
        padding(0)
        minWidth(0)
      }
      // A level a step in from its parent, the step the toggle's width; a
      // thin line down the step's middle (under the parent's toggle, where
      // it has one), through every level under it.
      descendant(".outliner-list .outliner-list") {
        position(.relative)
        paddingInlineStart(size24)
      }
      descendant(".outliner-list .outliner-list::before") {
        content("\"\"")
        position(.absolute)
        insetBlockStart(0)
        insetBlockEnd(0)
        insetInlineStart((size24 - borderWidthBase) / 2)
        width(borderWidthBase)
        backgroundColor(borderColorBase)
        pointerEvents(.none)
      }
      // An item with nothing under it has an empty list, kept so a move
      // (or a form's new step) can put something there. A page may hide an
      // item's list (a form's step whose children no longer apply).
      selector("& .outliner-list:empty", "& .outliner-list[hidden]") {
        display(.none)
      }
      descendant(".outliner-item") {
        display(.flex)
        flexDirection(.column)
        gap(spacing8)
        minWidth(0)
      }
      // Collapsed, an item folds away everything under its row: its children
      // and its own controls, which belong to its content.
      selector(
        "& .outliner-item[data-outliner-collapsed='true'] > .outliner-list",
        "& .outliner-item[data-outliner-collapsed='true'] > .outliner-footer"
      ) {
        display(.none)
      }
      // An accordion item is one card, as a record page reads: its own
      // accordion's border drawn round the whole item, so the items under it
      // stand inside it, after what its accordion opens into—no step in,
      // no guide line; the card is the nesting.
      descendant(".outliner-item[data-outliner-accordion='true']") {
        gap(0)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
      }
      descendant(".outliner-item[data-outliner-accordion='true'] > .outliner-row [data-outliner-own-accordion='true']") {
        border(.none)
      }
      descendant(".outliner-item[data-outliner-accordion='true'] > .outliner-list") {
        paddingInline(spacing16)
        paddingBlockEnd(spacing16)
      }
      descendant(".outliner-item[data-outliner-accordion='true'] > .outliner-list::before") {
        display(.none)
      }
      // An item's own controls, its last row. In a card, inset as the
      // card's content is, their room taken by what is shown in them: a
      // footer with nothing to show takes none.
      descendant(".outliner-footer") {
        display(.flex)
        flexDirection(.column)
        minWidth(0)
      }
      descendant(".outliner-item[data-outliner-accordion='true'] > .outliner-footer > *") {
        paddingInline(spacing16)
        paddingBlockEnd(spacing16)
      }
      descendant(".outliner-row") {
        position(.relative)
        display(.flex)
        alignItems(.flexStart)
        minWidth(0)
        borderRadius(borderRadiusBase)
      }
      // The node: never narrower than a node is read at, however deep.
      descendant(".outliner-node") {
        flex(1)
        minWidth(minWidthTreeNode)
      }
      // The toggle: the step's width, as tall as a node's one-line header
      // (a line and 16px either side, inside its border), so its chevron
      // stands on the node's first line.
      descendant(".outliner-toggle") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
        width(size24)
        height(spacing16 * 2 + lineHeightSmall22 + borderWidthBase * 2)
        padding(0)
        border(.none)
        borderRadius(borderRadiusBase)
        backgroundColor(.transparent)
        color(colorSubtle)
        cursor(cursorBase)
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      }
      descendant(".outliner-toggle:hover") {
        backgroundColor(backgroundColorInteractiveSubtleHover)
        color(colorBase)
      }
      descendant(".outliner-toggle:focus-visible") {
        outline(borderWidthThick, .solid, borderColorBlueFocus)
        outlineOffset(-borderWidthThick)
      }
      selector(
        "& .outliner-item:has(> .outliner-list:empty) > .outliner-row > .outliner-toggle",
        "& .outliner-item:has(> .outliner-list[hidden]) > .outliner-row > .outliner-toggle"
      ) {
        visibility(.hidden)
      }
      // A tree with no nesting at all has no toggle column.
      selector("&:not(:has(.outliner-item > .outliner-list:not(:empty))) .outliner-toggle") {
        display(.none)
      }
      descendant(".outliner-handle") {
        display(.inlineFlex)
        alignItems(.center)
        justifyContent(.center)
        flexShrink(0)
        width(size24)
        height(size24)
        padding(0)
        border(.none)
        borderRadius(borderRadiusBase)
        backgroundColor(.transparent)
        color(colorSubtle)
        cursor(.grab)
        // A long press drags it; the screen neither scrolls nor offers to
        // copy under the finger.
        touchAction(.none)
        userSelect(.none)
        CSS.Property("-webkit-touch-callout", "none")
        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      }
      // An item that keeps its place: its grip greyed, and nothing to grab.
      descendant(".outliner-handle:disabled") {
        color(colorDisabled)
        cursor(cursorBase)
      }
      descendant(".outliner-handle:not(:disabled):hover") {
        backgroundColor(backgroundColorInteractiveSubtleHover)
        color(colorBase)
      }
      descendant(".outliner-handle:focus-visible") {
        outline(borderWidthThick, .solid, borderColorBlueFocus)
        outlineOffset(-borderWidthThick)
      }
      // Held: the grip filled. How the rest of the item reads as held is
      // its own layout's to say.
      descendant(".outliner-handle[aria-pressed='true']") {
        backgroundColor(backgroundColorBlue)
        color(colorInvertedFixed)
        cursor(.grabbing)
      }
      // Nothing is selected by a drag that strays over text.
      selector("&[data-outliner-dragging='true']") {
        userSelect(.none)
      }
      // Where a drag would land: a straight bar, square-ended, centered in
      // the gap above the row or below it—or, for into it, along its foot,
      // indented—drawn apart from the row's border, so it never bends
      // round a rounded corner.
      selector(
        "& .outliner-row[data-outliner-drop='before']::before",
        "& .outliner-row[data-outliner-drop='after']::after",
        "& .outliner-row[data-outliner-drop='inside']::after"
      ) {
        content("\"\"")
        position(.absolute)
        insetInlineStart(0)
        insetInlineEnd(0)
        height(borderWidthThick)
        backgroundColor(borderColorBlue)
        borderRadius(borderRadiusSharp)
        zIndex(zIndexToolbar)
        pointerEvents(.none)
      }
      descendant(".outliner-row[data-outliner-drop='before']::before") {
        top(-(spacing8 + borderWidthThick) / 2)
      }
      descendant(".outliner-row[data-outliner-drop='after']::after") {
        bottom(-(spacing8 + borderWidthThick) / 2)
      }
      descendant(".outliner-row[data-outliner-drop='inside']::after") {
        bottom(-borderWidthThick / 2)
        insetInlineStart(size24 * 2)
      }
      descendant(".outliner-item[data-outline-state='refused'] > .outliner-row") {
        cursor(.notAllowed)
      }
      // Where the dragged item was: a quiet placeholder, its content faint
      // inside a solid outline. A drag is not a change; the item is marked
      // moved only once it lands somewhere it did not stand.
      descendant(".outliner-item[data-outline-state='placeholder'] > .outliner-row") {
        outline(borderWidthBase, .solid, borderColorBase)
        outlineOffset(-borderWidthBase)
      }
      descendant(".outliner-item[data-outline-state='placeholder'] > .outliner-row > *") {
        opacity(opacityLow)
      }
      // What follows the pointer: the item's header alone, opaque. Parked
      // above the viewport for a mouse, whose drag image is taken from it;
      // under a finger, a little above it and back from it toward its
      // start, where the finger does not hide it. Its start is the line's:
      // the client measures the finger from that side.
      descendant(".outliner-drag-preview") {
        position(.fixed)
        insetBlockStart(0)
        insetInlineStart(0)
        transform(translate(perc(0), perc(-200)))
        zIndex(zIndexToolbar)
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        padding(spacing8)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        // Lifted off the page as it is dragged: the large elevation.
        boxShadow(boxShadowLarge)
        pointerEvents(.none)
        whiteSpace(.nowrap)
      }
      descendant(".outliner-diff[data-visible='false']") {
        display(.none)
      }
      // At the foot of the screen, clear of a phone's home indicator, and
      // centered between both sides whichever way the line runs.
      descendant(".outliner-toolbar") {
        position(.fixed)
        insetInlineStart(0)
        insetInlineEnd(0)
        insetBlockEnd(spacing16 + CSS.Length.environment("safe-area-inset-bottom"))
        width(.fitContent)
        marginInline(.auto)
        zIndex(zIndexToolbar)
        display(.flex)
        alignItems(.center)
        gap(spacing8)
        padding(spacing8)
        maxWidth(vw(100) - spacing16 * 2)
        backgroundColor(backgroundColorBase)
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusPill)
        boxShadow(boxShadowLarge)
      }
      descendant(".outliner-drag-preview[data-following='true']") {
        transform(translate(-spacing16, perc(-100) - spacing32))
      }
      // Back toward the start is rightward where the line runs right to left.
      descendant(".outliner-drag-preview[data-following='true']:dir(rtl)") {
        transform(translate(spacing16, perc(-100) - spacing32))
      }
      descendant(".outliner-toolbar[data-visible='false']") {
        display(.none)
      }
      descendant(".outliner-toolbar-label") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeSmall14)
        color(colorSubtle)
        whiteSpace(.nowrap)
        overflow(.hidden)
        minWidth(0)
        paddingInline(spacing8)
      }
      descendant(".outliner-toolbar-moves") {
        display(.flex)
        gap(spacing4)
        flexShrink(0)
      }
      // On a phone the row is named by the ring round it; the toolbar is
      // its moves alone.
      media(maxWidth(maxWidthBreakpointMobile)) {
        descendant(".outliner-toolbar-label") {
          display(.none).important()
        }
      }
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Every tree on the page: each toggle collapses and expands its item's
  /// children, and an arranged outline is rearranged.
  public final class OutlinerHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: OutlinerHydration?
    private var outliners: [OutlinerInstance] = []
    /// The one listener every toggle answers to, on the document: a tree
    /// the page adds later (a fragment, a form's new step) needs nothing
    /// bound.
    private static nonisolated(unsafe) var togglesBound = false

    public static func hydrateIfPresent() {
      guard document.querySelector(".outliner-view") != nil else { return }
      bindToggles()
      bindAccordions()
      instance = OutlinerHydration()
    }

    /// An item that is itself an accordion collapses with it: its items
    /// show while its accordion is open, whatever opens or closes it.
    public static func bindAccordions() {
      for item in document.querySelectorAll(".outliner-item[data-outliner-accordion='true']") {
        guard !stringEquals(item.dataset["outliner-accordion-bound"] ?? "false", "true"),
          let accordion = ownAccordion(of: item)
        else { continue }
        item.setAttribute(data("outliner-accordion-bound"), "true")
        if let details = accordion.querySelector(":scope > .accordion-details") {
          item.setAttribute(data("outliner-collapsed"), details.hasAttribute(.open) ? "false" : "true")
        }
        _ = accordion.addEventListener("accordion-toggle") { (event: Event) in
          item.setAttribute(data("outliner-collapsed"), stringEquals(event.detail, "true") ? "false" : "true")
        }
      }
    }

    /// An accordion item's own accordion: the first in its node, which is
    /// the outermost.
    private static func ownAccordion(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-row > .outliner-node .accordion-view")
    }

    public init() {
      for root in document.querySelectorAll(".outliner-view[data-outliner-arranges='true']") {
        guard !stringEquals(root.dataset["outliner-hydrated"] ?? "false", "true") else { continue }
        root.setAttribute(data("outliner-hydrated"), "true")
        outliners.append(OutlinerInstance(root: root))
      }
    }

    private static func bindToggles() {
      guard !togglesBound else { return }
      togglesBound = true
      _ = document.addEventListener(.click) { event in
        guard let target = event.target, let toggle = target.closest(".outliner-toggle"),
          let item = toggle.closest(".outliner-item")
        else { return }
        event.preventDefault()
        setCollapsed(item, !stringEquals(item.dataset["outliner-collapsed"] ?? "false", "true"))
      }
    }

    /// Collapses an item's children, or expands them: its toggle and its
    /// chevron say which.
    public static func setCollapsed(_ item: DOM.Element, _ collapsed: Bool) {
      item.setAttribute(data("outliner-collapsed"), collapsed ? "true" : "false")
      guard let toggle = item.querySelector(":scope > .outliner-row > .outliner-toggle") else { return }
      toggle.setAttribute("aria-expanded", collapsed ? "false" : "true")
      toggle.querySelector(".animated-right-down-chevron-view")?.setAttribute(
        data("expanded"), collapsed ? "false" : "true")
    }

    /// Expands every collapsed item above `element`, so it shows: an item
    /// moved under a collapsed one, a step added under one. An accordion
    /// item is opened by its own chevron.
    public static func expand(around element: DOM.Element) {
      var cursor = element.parentElement?.closest(".outliner-item")
      while let item = cursor {
        if stringEquals(item.dataset["outliner-collapsed"] ?? "false", "true") {
          if stringEquals(item.dataset["outliner-accordion"] ?? "false", "true"),
            let summary = ownAccordion(of: item)?.querySelector(".accordion-summary")
          {
            summary.click()
          }
          setCollapsed(item, false)
        }
        cursor = item.parentElement?.closest(".outliner-item")
      }
    }
  }

  private final class OutlinerInstance: @unchecked Sendable {
    private let root: DOM.Element
    private let rootID: String
    private let rootRank: Int
    /// The rank nothing may sit under; -1 when every rank takes children.
    private let leafRank: Int
    private let numberSelector: String
    private let rankRefusal: String
    private let leafRefusal: String
    /// Whether an item stands only under a higher rank.
    private let strictRanks: Bool
    /// The most levels under the root; -1 for no limit.
    private let maxDepth: Int
    private let depthRefusal: String

    /// The item picked up, which the toolbar and the keyboard move.
    private var held: DOM.Element?
    /// The item being dragged, and whether the drag ended on a drop.
    private var dragged: DOM.Element?
    /// The item a dragged one hovers and may not land in.
    private var refusedTarget: DOM.Element?
    private var droppedOnTarget = false
    private var lastRefusal = ""
    /// A touch drag: the press waiting to become one, where it began, the row
    /// under the finger and what a drop there would do.
    private var pressTimer: Int32 = 0
    private var pressX = 0.0
    private var pressY = 0.0
    private var touchRow: DOM.Element?
    private var touchTarget: DOM.Element?
    private var touchPosition = ""
    /// A long press ends in a click the finger did not mean.
    private var swallowClick = false
    /// The items the reader has moved, which a tie between two readings of
    /// what moved is settled in favor of.
    private var touched: [String] = []

    init(root: DOM.Element) {
      self.root = root
      rootID = root.dataset["outliner-root-id"] ?? ""
      rootRank = parseInt(root.dataset["outliner-root-rank"] ?? "0") ?? 0
      leafRank = parseInt(root.dataset["outliner-leaf-rank"] ?? "") ?? -1
      numberSelector = root.dataset["outliner-number-selector"] ?? ""
      rankRefusal = root.dataset["outliner-rank-refusal"] ?? ""
      leafRefusal = root.dataset["outliner-leaf-refusal"] ?? rankRefusal
      strictRanks = stringEquals(root.dataset["outliner-strict-ranks"] ?? "false", "true")
      maxDepth = parseInt(root.dataset["outliner-max-depth"] ?? "") ?? -1
      depthRefusal = root.dataset["outliner-depth-refusal"] ?? ""
      for item in root.querySelectorAll(".outliner-item") {
        bind(item)
        if stringEquals(item.dataset["outliner-touched"] ?? "false", "true") { touched.append(id(of: item)) }
      }
      bindToolbar()
      // A removal, or its undoing, marked by the page.
      _ = root.addEventListener("outliner-removal") { [self] _ in self.changed() }
      refresh()
    }

    // MARK: - Reading the outline

    private func items(in list: DOM.Element) -> [DOM.Element] {
      list.querySelectorAll(":scope > .outliner-item")
    }

    /// The list of an item's children, after its row.
    private func childList(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-list")
    }

    /// The item a list belongs to—the nearest item it sits inside; nil for
    /// the top level.
    private func owner(of list: DOM.Element) -> DOM.Element? {
      list.parentElement?.closest(".outliner-item")
    }

    private func parentItem(of item: DOM.Element) -> DOM.Element? {
      guard let list = item.parentElement else { return nil }
      return owner(of: list)
    }

    private func id(of item: DOM.Element) -> String {
      item.dataset["outliner-id"] ?? ""
    }

    private func label(of item: DOM.Element) -> String {
      item.dataset["outliner-label"] ?? ""
    }

    /// Whether the page removed it, or an item it stands under.
    private func isRemoved(_ item: DOM.Element?) -> Bool {
      var cursor = item
      while let current = cursor {
        if stringEquals(current.dataset["outliner-removed"] ?? "false", "true") { return true }
        cursor = parentItem(of: current)
      }
      return false
    }

    private func rank(of item: DOM.Element?) -> Int {
      guard let item else { return rootRank }
      return parseInt(item.dataset["outliner-rank"] ?? "0") ?? 0
    }

    /// The level an item stands at: 1 at the top level; 0 for the root.
    private func depth(of item: DOM.Element?) -> Int {
      var depth = 0
      var cursor = item
      while let current = cursor {
        depth += 1
        cursor = parentItem(of: current)
      }
      return depth
    }

    /// How many levels an item and the items under it span: 1 for one with
    /// none under it. Removed items are left out, as the arrangement leaves
    /// them out.
    private func height(of item: DOM.Element) -> Int {
      var tallest = 0
      if let list = childList(of: item) {
        for child in items(in: list) where !isRemoved(child) {
          tallest = max(tallest, height(of: child))
        }
      }
      return tallest + 1
    }

    private func index(of item: DOM.Element, in siblings: [DOM.Element]) -> Int {
      for (index, sibling) in siblings.enumerated() where sibling.id == item.id { return index }
      return -1
    }

    /// An item's own handle, in its row.
    private func handle(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-row .outliner-handle")
    }

    private func row(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-row")
    }

    /// Whether `candidate` is `item` or sits anywhere under it.
    private func isWithin(_ candidate: DOM.Element?, _ item: DOM.Element) -> Bool {
      var cursor = candidate
      while let current = cursor {
        if current.id == item.id { return true }
        cursor = parentItem(of: current)
      }
      return false
    }

    /// Whether an event happened on this item and not on one nested in it:
    /// an item's row holds its children's rows, and their events rise
    /// through it.
    private func isOwn(_ event: Event, _ item: DOM.Element) -> Bool {
      guard let target = event.target, let nearest = target.closest(".outliner-item") else { return false }
      return nearest.id == item.id
    }

    // MARK: - Binding

    private func bind(_ item: DOM.Element) {
      // A handle drawn disabled belongs to an item that keeps its place.
      if let handle = handle(of: item), !handle.hasAttribute("disabled") {
        _ = handle.addEventListener(.keydown) { [self] event in self.key(event, on: item) }
        // The handle sits in the item's header, which may open and close its
        // body: a press on it picks the item up and does nothing else.
        _ = handle.addEventListener(.click) { [self] event in
          event.preventDefault()
          event.stopPropagation()
          if self.swallowClick {
            self.swallowClick = false
            return
          }
          if self.isHeld(item) { self.drop() } else { self.grab(item) }
        }
        _ = handle.addEventListener(.dragstart) { [self] event in self.dragStart(event, item) }
        _ = handle.addEventListener(.dragend) { [self] _ in self.dragEnd() }
        _ = handle.addEventListener(.touchstart) { [self] event in self.pressStart(event, item) }
        _ = handle.addEventListener(.touchmove) { [self] event in self.pressMove(event, item) }
        _ = handle.addEventListener(.touchend) { [self] _ in self.pressEnd(item) }
        _ = handle.addEventListener(.touchcancel) { [self] _ in self.pressCancel(item) }
      }
      if let row = row(of: item) {
        _ = row.addEventListener(.dragover) { [self] event in
          guard self.isOwn(event, item) else { return }
          self.dragOver(event, item, row)
        }
        _ = row.addEventListener(.dragleave) { [self] event in
          guard self.isOwn(event, item) else { return }
          row.removeAttribute(data("outliner-drop"))
          if let target = self.refusedTarget, target.id == item.id { self.refuseDrop(on: nil) }
        }
        _ = row.addEventListener(.drop) { [self] event in
          guard self.isOwn(event, item) else { return }
          event.preventDefault()
          row.removeAttribute(data("outliner-drop"))
          self.dropDragged(on: item, at: self.dropPosition(event.clientY, row))
        }
      }
    }

    private var toolbar: DOM.Element? { root.querySelector(":scope > .outliner-toolbar") }

    private func bindToolbar() {
      guard let toolbar else { return }
      for button in toolbar.querySelectorAll("[data-outliner-action]") {
        let action = button.dataset["outliner-action"] ?? ""
        _ = button.addEventListener(.click) { [self] event in
          event.preventDefault()
          guard let item = self.held else { return }
          if stringEquals(action, "done") {
            self.drop()
            self.handle(of: item)?.focus()
            return
          }
          self.act(action, item)
        }
      }
      _ = toolbar.addEventListener(.keydown) { [self] event in
        guard stringEquals(event.key, "Escape"), let item = self.held else { return }
        event.preventDefault()
        self.drop()
        self.handle(of: item)?.focus()
      }
    }

    private func act(_ action: String, _ item: DOM.Element) {
      if stringEquals(action, "up") {
        moveUp(item)
      } else if stringEquals(action, "down") {
        moveDown(item)
      } else if stringEquals(action, "outdent") {
        outdent(item)
      } else if stringEquals(action, "indent") {
        indent(item)
      }
    }

    // MARK: - Holding

    private func isHeld(_ item: DOM.Element) -> Bool {
      guard let held else { return false }
      return held.id == item.id
    }

    private func key(_ event: Event, on item: DOM.Element) {
      let key = event.key
      guard isHeld(item) else {
        if stringEquals(key, " ") || stringEquals(key, "Enter") {
          event.preventDefault()
          event.stopPropagation()
          grab(item)
        }
        return
      }
      if stringEquals(key, "Tab") {
        event.preventDefault()
        if event.shiftKey { outdent(item) } else { indent(item) }
      } else if stringEquals(key, "ArrowUp") {
        event.preventDefault()
        moveUp(item)
      } else if stringEquals(key, "ArrowDown") {
        event.preventDefault()
        moveDown(item)
      } else if stringEquals(key, "ArrowLeft") {
        event.preventDefault()
        outdent(item)
      } else if stringEquals(key, "ArrowRight") {
        event.preventDefault()
        indent(item)
      } else if stringEquals(key, "Escape") || stringEquals(key, " ") || stringEquals(key, "Enter") {
        event.preventDefault()
        event.stopPropagation()
        drop()
      }
      handle(of: item)?.focus()
    }

    private func grab(_ item: DOM.Element) {
      // A removed item stays where it was removed.
      if isRemoved(item) { return }
      if held != nil { drop() }
      held = item
      handle(of: item)?.setAttribute("aria-pressed", "true")
      paint(item)
      toolbar?.setAttribute(data("visible"), "true")
      updateToolbar()
      announce(stringJoin([label(of: item), ", picked up at ", number(of: item), "."], separator: ""))
    }

    /// Puts the held item down where it now stands.
    private func drop() {
      guard let item = held else { return }
      handle(of: item)?.setAttribute("aria-pressed", "false")
      toolbar?.setAttribute(data("visible"), "false")
      held = nil
      paint(item)
      announce(stringJoin([label(of: item), ", dropped at ", number(of: item), "."], separator: ""))
    }

    /// Which moves the held item can make, and whose they are.
    private func updateToolbar() {
      guard let toolbar, let item = held, let list = item.parentElement else { return }
      let siblings = items(in: list)
      let at = index(of: item, in: siblings)
      let parent = parentItem(of: item)
      // Whether it may sit under a parent, asked without a String compare: an
      // optional String's `== nil` pulls Unicode tables into the client.
      func allows(_ parent: DOM.Element?) -> Bool {
        if let _ = refusal(item, under: parent) { return false }
        return true
      }
      let possible: [(String, Bool)] = [
        ("up", at > 0),
        ("down", at >= 0 && at + 1 < siblings.count),
        ("outdent", parent != nil && allows(parent.flatMap { parentItem(of: $0) })),
        ("indent", at > 0 && allows(siblings[at - 1])),
      ]
      for (action, allowed) in possible {
        toolbar.querySelector(stringJoin(["[data-outliner-action='", action, "']"], separator: ""))?
          .setDisabled(!allowed)
      }
      toolbar.querySelector(".outliner-toolbar-label")?.textContent =
        stringJoin([number(of: item), " ", label(of: item)], separator: "")
    }

    // MARK: - Moves

    private func moveUp(_ item: DOM.Element) {
      guard let list = item.parentElement else { return }
      let siblings = items(in: list)
      let at = index(of: item, in: siblings)
      guard at > 0 else {
        return refuse(item, stringJoin([label(of: item), " is already first."], separator: ""))
      }
      list.insertBefore(item, siblings[at - 1])
      moved(item)
    }

    private func moveDown(_ item: DOM.Element) {
      guard let list = item.parentElement else { return }
      let siblings = items(in: list)
      let at = index(of: item, in: siblings)
      guard at >= 0, at + 1 < siblings.count else {
        return refuse(item, stringJoin([label(of: item), " is already last."], separator: ""))
      }
      if at + 2 < siblings.count {
        list.insertBefore(item, siblings[at + 2])
      } else {
        list.appendChild(item)
      }
      moved(item)
    }

    /// Out to the parent's level, just after the parent.
    private func outdent(_ item: DOM.Element) {
      guard let parent = parentItem(of: item), let outer = parent.parentElement else {
        return refuse(item, stringJoin([label(of: item), " is already at the top level."], separator: ""))
      }
      guard place(item, under: owner(of: outer)) else { return }
      let siblings = items(in: outer)
      let at = index(of: parent, in: siblings)
      if at >= 0 && at + 1 < siblings.count {
        outer.insertBefore(item, siblings[at + 1])
      } else {
        outer.appendChild(item)
      }
      moved(item)
    }

    /// Under the item above, as its last child.
    private func indent(_ item: DOM.Element) {
      guard let list = item.parentElement else { return }
      let siblings = items(in: list)
      let at = index(of: item, in: siblings)
      guard at > 0, let target = childList(of: siblings[at - 1]) else {
        return refuse(item, stringJoin([label(of: item), " has nothing above it to go under."], separator: ""))
      }
      guard place(item, under: siblings[at - 1]) else { return }
      target.appendChild(item)
      moved(item)
    }

    /// Whether `item` may sit under `parent` (nil is the top level), refusing
    /// it out loud when it may not.
    private func place(_ item: DOM.Element, under parent: DOM.Element?) -> Bool {
      if let reason = refusal(item, under: parent) {
        refuse(item, reason)
        return false
      }
      return true
    }

    private func refusal(_ item: DOM.Element, under parent: DOM.Element?) -> String? {
      if let parent, isWithin(parent, item) {
        return stringJoin([label(of: item), " cannot go inside itself."], separator: "")
      }
      if let parent, isRemoved(parent) {
        return stringJoin([label(of: parent), " is removed."], separator: "")
      }
      // Under a lower rank, or under the leaf rank, which takes nothing.
      let parentRank = rank(of: parent)
      if let _ = parent, parentRank == leafRank { return leafRefusal }
      guard rank(of: item) > parentRank || (!strictRanks && rank(of: item) == parentRank) else {
        return rankRefusal
      }
      // Past the outline's depth, it or the deepest item it carries.
      if maxDepth >= 0, depth(of: parent) + height(of: item) > maxDepth { return depthRefusal }
      return nil
    }

    /// Says why a move was refused, in the page's alert and the live region.
    /// Nothing on the outline stays marked by it.
    private func refuse(_ item: DOM.Element, _ reason: String) {
      announce(reason)
      guard let slot = root.querySelector(":scope > .outliner-feedback"),
        let template = root.querySelector(":scope > .outliner-feedback-template > .alert-view")
      else { return }
      slot.setInnerHTML("")
      let alert = template.cloneNode(deep: true)
      alert.querySelector(".alert-content")?.textContent = reason
      slot.appendChild(alert)
      AlertHydration.hydrate(alert: alert)
    }

    /// An item's one state, by precedence: removed, refused, held,
    /// placeholder, moved, none.
    private func paint(_ item: DOM.Element) {
      let state: String
      if stringEquals(item.dataset["outliner-removed"] ?? "false", "true") {
        state = "removed"
      } else if let target = refusedTarget, target.id == item.id {
        state = "refused"
      } else if isHeld(item) {
        state = "held"
      } else if let moving = dragged, moving.id == item.id {
        state = "placeholder"
      } else if stringEquals(item.dataset["outliner-moved"] ?? "false", "true") {
        state = "moved"
      } else {
        state = "none"
      }
      item.setAttribute(data("outline-state"), state)
    }

    /// A different item, or none, is now the one refusing the dragged item.
    private func refuseDrop(on target: DOM.Element?) {
      let previous = refusedTarget
      refusedTarget = target
      if let previous { paint(previous) }
      if let target { paint(target) }
    }

    private func moved(_ item: DOM.Element) {
      // A move that went through leaves no refusal standing over it.
      root.querySelector(":scope > .outliner-feedback")?.setInnerHTML("")
      let itemID = id(of: item)
      if !touched.contains(where: { stringEquals($0, itemID) }) { touched.append(itemID) }
      // Moved under a collapsed item, it is shown: it opens.
      OutlinerHydration.expand(around: item)
      changed()
      announce(stringJoin([label(of: item), ", now ", number(of: item), "."], separator: ""))
      root.dispatchEvent(CustomEvent(type: "outliner-move", detail: id(of: item)))
    }

    // MARK: - Drag and drop

    private func dragStart(_ event: Event, _ item: DOM.Element) {
      begin(item)
      let transfer = event.dataTransfer
      transfer.setData("text/plain", id(of: item))
      transfer.effectAllowed = "move"
      // The pointer holds the image by its grip, which is at the image's
      // start: its left, or its right where the line runs right to left.
      if let preview = root.querySelector(":scope > .outliner-drag-preview") {
        let width = preview.getBoundingClientRect()?.width ?? 0
        transfer.setDragImage(preview, x: isRightToLeft ? Int(width) - 16 : 16, y: 16)
      }
    }

    /// A drag begins: the item is the one dragged, its place a placeholder,
    /// and a preview of its header—the line with its handle—is made to
    /// follow the pointer.
    private func begin(_ item: DOM.Element) {
      dragged = item
      droppedOnTarget = false
      lastRefusal = ""
      paint(item)
      root.setAttribute(data("outliner-dragging"), "true")
      root.querySelector(":scope > .outliner-drag-preview").map { root.removeChild($0) }
      guard let header = handle(of: item)?.parentElement else { return }
      let preview = document.createElement(.div)
      preview.setAttribute("class", "outliner-drag-preview")
      preview.setAttribute("aria-hidden", "true")
      preview.appendChild(header.cloneNode(deep: true))
      root.appendChild(preview)
    }

    /// Where on a row the pointer is: its top quarter drops before it, its
    /// bottom quarter after it, anywhere between into it.
    private func dropPosition(_ y: Double, _ row: DOM.Element) -> String {
      guard let rect = row.getBoundingClientRect() else { return "inside" }
      let offset = y - rect.top
      if offset < rect.height / 4 { return "before" }
      if offset > rect.height * 3 / 4 { return "after" }
      return "inside"
    }

    /// Marks the row a dragged item is over with what a drop there would do,
    /// and says whether it may land there.
    private func hover(_ target: DOM.Element, _ row: DOM.Element, at position: String) -> Bool {
      guard let item = dragged else { return false }
      let parent = stringEquals(position, "inside") ? target : parentItem(of: target)
      // Over its own place, or anywhere it carries: nowhere to go, and
      // nothing to say about it.
      if isWithin(target, item) {
        row.removeAttribute(data("outliner-drop"))
        refuseDrop(on: nil)
        lastRefusal = ""
        return false
      }
      if let reason = refusal(item, under: parent) {
        row.removeAttribute(data("outliner-drop"))
        refuseDrop(on: target)
        lastRefusal = reason
        return false
      }
      refuseDrop(on: nil)
      lastRefusal = ""
      row.setAttribute(data("outliner-drop"), position)
      return true
    }

    private func dragOver(_ event: Event, _ target: DOM.Element, _ row: DOM.Element) {
      let transfer = event.dataTransfer
      guard hover(target, row, at: dropPosition(event.clientY, row)) else {
        transfer.dropEffect = "none"
        return
      }
      event.preventDefault()
      transfer.dropEffect = "move"
    }

    /// Puts the dragged item where a drop on `target` at `position` says.
    private func dropDragged(on target: DOM.Element, at position: String) {
      guard let item = dragged, !isWithin(target, item) else { return }
      if stringEquals(position, "inside") {
        guard place(item, under: target), let list = childList(of: target) else { return }
        list.appendChild(item)
      } else {
        guard place(item, under: parentItem(of: target)), let list = target.parentElement else { return }
        if stringEquals(position, "before") {
          list.insertBefore(item, target)
        } else {
          let siblings = items(in: list)
          let at = index(of: target, in: siblings)
          if at >= 0 && at + 1 < siblings.count {
            list.insertBefore(item, siblings[at + 1])
          } else {
            list.appendChild(item)
          }
        }
      }
      droppedOnTarget = true
      moved(item)
    }

    private func dragEnd() {
      for row in root.querySelectorAll("[data-outliner-drop]") {
        row.removeAttribute(data("outliner-drop"))
      }
      refuseDrop(on: nil)
      let item = dragged
      dragged = nil
      root.removeAttribute(data("outliner-dragging"))
      root.querySelector(":scope > .outliner-drag-preview").map { root.removeChild($0) }
      if let item {
        paint(item)
        // Let go over a place it could not go: say why, where it was tried.
        if !droppedOnTarget && !stringIsEmpty(lastRefusal) { refuse(item, lastRefusal) }
      }
      lastRefusal = ""
    }

    // MARK: - Touch: a long press, then a drag

    private func pressStart(_ event: Event, _ item: DOM.Element) {
      pressX = event.clientX
      pressY = event.clientY
      if pressTimer != 0 { clearTimeout(pressTimer) }
      pressTimer = setTimeout(450) { [self] in
        self.pressTimer = 0
        guard self.dragged == nil else { return }
        self.begin(item)
        self.swallowClick = true
        self.follow(self.pressX, self.pressY)
        self.announce(stringJoin([self.label(of: item), ", picked up to drag."], separator: ""))
      }
    }

    private func pressMove(_ event: Event, _ item: DOM.Element) {
      guard let dragging = dragged, dragging.id == item.id else {
        // A finger that moves before the press is long is not a drag.
        let dx = event.clientX - pressX
        let dy = event.clientY - pressY
        if pressTimer != 0 && dx * dx + dy * dy > 64 {
          clearTimeout(pressTimer)
          pressTimer = 0
        }
        return
      }
      follow(event.clientX, event.clientY)
      touchRow?.removeAttribute(data("outliner-drop"))
      refuseDrop(on: nil)
      touchRow = nil
      touchTarget = nil
      guard let under = document.elementFromPoint(event.clientX, event.clientY),
        let row = under.closest(".outliner-row"),
        let target = row.parentElement, target.classList.contains("outliner-item"),
        root.contains(target)
      else { return }
      let position = dropPosition(event.clientY, row)
      touchRow = row
      guard hover(target, row, at: position) else { return }
      touchTarget = target
      touchPosition = position
    }

    /// The preview under the finger: placed at it, and lifted clear of it by
    /// its own stylesheet. The finger is measured from the left; the preview
    /// is placed from its start, which is the right where the line runs right
    /// to left.
    private func follow(_ x: Double, _ y: Double) {
      guard let preview = root.querySelector(":scope > .outliner-drag-preview") else { return }
      preview.setAttribute(data("following"), "true")
      let start = isRightToLeft ? window.innerWidth - x : x
      preview.setStyleProperty("inset-block-start", stringJoin([intToString(Int(y)), "px"], separator: ""))
      preview.setStyleProperty("inset-inline-start", stringJoin([intToString(Int(start)), "px"], separator: ""))
    }

    /// Whether the outline's lines run right to left: the nearest `dir` says.
    private var isRightToLeft: Bool {
      guard let scope = root.closest("[dir]") else { return false }
      return stringEquals(scope.getAttribute("dir") ?? "", "rtl")
    }

    private func pressEnd(_ item: DOM.Element) {
      if pressTimer != 0 {
        clearTimeout(pressTimer)
        pressTimer = 0
      }
      guard let dragging = dragged, dragging.id == item.id else { return }
      touchRow?.removeAttribute(data("outliner-drop"))
      if let target = touchTarget { dropDragged(on: target, at: touchPosition) }
      touchRow = nil
      touchTarget = nil
      dragEnd()
    }

    private func pressCancel(_ item: DOM.Element) {
      if pressTimer != 0 {
        clearTimeout(pressTimer)
        pressTimer = 0
      }
      guard let dragging = dragged, dragging.id == item.id else { return }
      touchRow?.removeAttribute(data("outliner-drop"))
      touchRow = nil
      touchTarget = nil
      droppedOnTarget = true
      dragEnd()
    }

    // MARK: - After a move

    private func number(of item: DOM.Element) -> String {
      var parts: [String] = []
      var cursor: DOM.Element? = item
      while let current = cursor, let list = current.parentElement {
        parts.insert(intToString(index(of: current, in: items(in: list)) + 1), at: 0)
        cursor = owner(of: list)
      }
      return stringJoin(parts, separator: ".")
    }

    private func changed() {
      refresh()
      root.dispatchEvent(CustomEvent(type: "outliner-change", detail: shapeJSON()))
    }

    /// Numbers, moved marks, the toolbar and the submitted JSON—all read
    /// off the outline as it now stands.
    private func refresh() {
      guard let top = root.querySelector(":scope > .outliner-scroll > .outliner-list") else { return }
      var entries: [OutlineMoves.Entry] = []
      var walked: [DOM.Element] = []
      var numbers: [String] = []
      walk(top, parent: rootID, prefix: "", entries: &entries, walked: &walked, numbers: &numbers)
      let moves = OutlineMoves.moved(entries, touched: touched)
      for (offset, item) in walked.enumerated() {
        let moved = moves[offset]
        item.setAttribute(data("outliner-moved"), moved ? "true" : "false")
        paint(item)
        // The item's own number and its diff: the first inside it.
        let original = item.dataset["outliner-original-number"] ?? ""
        let renumbered = !stringEquals(numbers[offset], original)
        if let diff = item.querySelector(".outliner-diff") {
          diff.setAttribute(data("visible"), renumbered ? "true" : "false")
          if renumbered { diff.setInnerHTML(DiffView(.outline(old: original, new: numbers[offset])).render()) }
        }
        if !stringIsEmpty(numberSelector), let slot = item.querySelector(numberSelector) {
          slot.textContent = numbers[offset]
        }
      }
      for item in root.querySelectorAll(".outliner-item[data-outliner-removed='true']") { paint(item) }
      updateToolbar()
      if let input = root.querySelector(":scope > .outliner-shape") {
        input.setAttribute("value", shapeJSON())
        (input as? HTML.HTMLInputElement)?.value = shapeJSON()
      }
    }

    private func walk(
      _ list: DOM.Element, parent: String, prefix: String,
      entries: inout [OutlineMoves.Entry], walked: inout [DOM.Element], numbers: inout [String]
    ) {
      for (position, item) in items(in: list).filter({ !isRemoved($0) }).enumerated() {
        let number = stringIsEmpty(prefix)
          ? intToString(position + 1) : stringJoin([prefix, intToString(position + 1)], separator: ".")
        entries.append(
          OutlineMoves.Entry(
            id: id(of: item),
            oldParent: item.dataset["outliner-original-parent"] ?? "",
            oldPosition: parseInt(item.dataset["outliner-original-position"] ?? "0") ?? 0,
            newParent: parent,
            newPosition: position))
        walked.append(item)
        numbers.append(number)
        if let children = childList(of: item) {
          walk(children, parent: id(of: item), prefix: number, entries: &entries, walked: &walked, numbers: &numbers)
        }
      }
    }

    private static func json(_ value: String) -> String {
      stringJoin(
        ["\"", stringReplace(stringReplace(value, "\\", "\\\\"), "\"", "\\\""), "\""], separator: "")
    }

    private func shapeJSON() -> String {
      var entries: [String] = []
      collect(root.querySelector(":scope > .outliner-scroll > .outliner-list"), parent: rootID, into: &entries)
      return stringJoin(["{", stringJoin(entries, separator: ","), "}"], separator: "")
    }

    private func collect(_ list: DOM.Element?, parent: String, into entries: inout [String]) {
      guard let list else { return }
      for (position, item) in items(in: list).filter({ !stringEquals($0.dataset["outliner-removed"] ?? "false", "true") })
        .enumerated()
      {
        entries.append(
          stringJoin(
            [
              Self.json(id(of: item)), ":{\"parent\":", Self.json(parent), ",\"position\":",
              intToString(position), "}",
            ], separator: ""))
        collect(childList(of: item), parent: id(of: item), into: &entries)
      }
    }

    private func announce(_ message: String) {
      root.querySelector(":scope > .outliner-live")?.textContent = message
    }
  }
#endif
