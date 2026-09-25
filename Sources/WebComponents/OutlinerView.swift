import EmbeddedSwiftUtilities

/// Which items of an outline moved between two arrangements of it.
///
/// An item moved when its parent changed. Among items that kept their parent,
/// the ones that kept their order relative to each other did not move — the
/// longest run of them whose old positions still increase — and every other
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
  /// Two orders can be equally short of the old one — swap two neighbours
  /// and either of them could be the one that moved. `touched` breaks the
  /// tie: an item the reader actually moved is the one reported, rather
  /// than the neighbour it passed.
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

  /// Which elements belong to one longest strictly increasing subsequence —
  /// of those, the one that keeps the most `untouched` elements, and then
  /// the one that keeps the items that stood earliest. That last is the
  /// usual case settled right: an item moved up past its neighbours is the
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

  /// A nested list its reader can rearrange: by dragging an item's handle,
  /// by picking it up and moving it with a toolbar, or from the keyboard.
  ///
  /// Each item carries content the caller builds, a label to announce it by,
  /// and a rank. Ranks order the levels an outline may nest — the smaller the
  /// number, the higher the level — and one rule holds for every outline,
  /// whatever it outlines:
  ///
  /// - an item may sit under an item of its own rank: an edition grouping
  ///   editions, a sense grouping senses;
  /// - it may sit under an item of any higher rank, at any depth;
  /// - it may never sit under an item of a lower rank: an edition under a
  ///   copy;
  /// - nothing may sit under an item of the leaf rank, the most concrete,
  ///   whose items are attested directly: a manifest by its images, a leaf
  ///   sense by its utterances.
  ///
  /// A refused move is refused where it is attempted, with an alert over the
  /// outline and the same words in the live region: the caller's one
  /// sentence, "A more abstract testament can't go under a more concrete
  /// one." There is no depth limit, and no option to loosen or tighten the
  /// rule: a bibliographic tree and a lexicographic one nest the same way.
  ///
  /// The nesting is the items' own. Each item's content is handed the pieces
  /// the outline puts in it — its handle, the line saying how its number
  /// changed, and the list of the items under it — and places them in its own
  /// layout: the handle in its header, the list inside its body. A child sits
  /// inside its parent, is carried with it, and is hidden when its parent is
  /// closed; the indent is whatever the parent's body gives it.
  ///
  /// The handle is the only control in a row. Pressing it — a click, a tap,
  /// Space or Enter — picks the item up: it is marked as held, and a toolbar
  /// appears at the foot of the screen with the four moves — up, down, out a
  /// level, in a level — each unavailable where it cannot go, and Done. The
  /// item stays held through as many moves as it takes, until Done, another
  /// press on its handle, or Escape. From the keyboard, while it is held, ↑
  /// and ↓ move it among its siblings, Tab and → put it under the item above,
  /// Shift-Tab and ← take it out to its parent's level, and Enter, Space or
  /// Escape put it down. Tab is only taken while an item is held. A handle
  /// can also be dragged: with a mouse at once, on a touch screen after a
  /// long press.
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
  /// their order — so a move marks the item moved, not every neighbour it
  /// renumbered. Every item whose number changed — moved, or only renumbered
  /// by a move near it — says so as a changed field says it: "Diff: 1.3 →
  /// 1.1". The root dispatches `outliner-change` with the JSON after every
  /// move.
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
      /// The item, given the pieces the outline puts in it.
      public let content: @Sendable (Slots) -> [DOM.Node]
      public let children: [Node]

      public init(
        id: String,
        label: String,
        rank: Int,
        origin: Origin? = nil,
        movable: Bool = true,
        children: [Node] = [],
        @HTMLBuilder content: @escaping @Sendable (Slots) -> [DOM.Node]
      ) {
        self.id = id
        self.label = label
        self.rank = rank
        self.origin = origin
        self.movable = movable
        self.children = children
        self.content = content
      }
    }

    /// What the outline puts in an item, for the item to place: every piece
    /// must be placed, the handle and the number's diff before the list.
    public struct Slots: Sendable {
      /// The grip that picks the item up, for the start of its header.
      public let handle: DOM.Node
      /// "Diff: 2.1 → 1.1", shown once the item's number has changed, for
      /// under its title.
      public let diff: DOM.Node
      /// The items under this one, for inside its body.
      public let children: DOM.Node
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
    let name: String
    let form: String?
    let numberSelector: String
    let rankRefusal: String
    let touched: [String]
    let `class`: String

    /// - Parameters:
    ///   - label: What the outline is, for the list's accessible name.
    ///   - rootID: The parent the top level names in the JSON.
    ///   - rootRank: The rank of that root; nothing may rise above it.
    ///   - leafRank: The most concrete rank, which nothing may sit under.
    ///   - name: The hidden input's name, and `form` the form it submits
    ///     with when the outline is not inside it.
    ///   - numberSelector: Where in an item's content its number — 1, 2.1 —
    ///     is written, so a caller that shows numbers keeps them true as the
    ///     outline changes. Empty writes none.
    ///   - rankRefusal: What a move the ranks refuse is told, in the page's
    ///     own words for what it outlines.
    ///   - touched: The items the reader has already moved, when the outline
    ///     is brought back mid-edit: where two readings of what moved are
    ///     equally short, theirs is the one reported.
    public init(
      id: String,
      label: String,
      rootID: String,
      rootRank: Int = 0,
      leafRank: Int? = nil,
      nodes: [Node],
      name: String,
      form: String? = nil,
      numberSelector: String = "",
      rankRefusal: String = "A more abstract item can't go under a more concrete one.",
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
      self.touched = touched
      self.`class` = `class`
    }

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

    public func build() -> DOM.Node {
      let moved = movedIDs
      // A list of items and every list under them: the nesting is data, so
      // the markup recurses.
      func list(_ nodes: [Node], parent: String, prefix: String) -> HTML.HTMLOListElement {
        ol {
          for (position, node) in nodes.enumerated() {
            item(node, parent: parent, position: position, prefix: prefix)
          }
        }
        .class("outliner-list")
      }

      func item(_ node: Node, parent: String, position: Int, prefix: String) -> DOM.Node {
        let number = prefix.isEmpty ? "\(position + 1)" : "\(prefix).\(position + 1)"
        let origin = node.origin ?? Origin(parent: parent, position: position, number: number)
        let isMoved = moved.contains(node.id)
        // The grip: what is pressed to pick the item up, what is dragged, and
        // what the keyboard grabs.
        let handle = button {
          DraggableIconView(width: size16, height: size16)
        }
        .type(.button)
        .class("outliner-handle")
        .draggable(node.movable)
        .disabled(!node.movable)
        .ariaLabel(node.movable ? "Move \(node.label)" : "\(node.label) stays where it is")
        .ariaPressed(false)
        .ariaDescribedby("\(id)-instructions")
        .build()
        // How its number changed, as a changed field says it — shown whenever
        // its number is no longer what it was, and written again by the
        // client as moves change it.
        let diff = div { DiffView(.outline(old: origin.number, new: number)) }
          .class("outliner-diff")
          .data("visible", !stringEquals(origin.number, number))
          .build()
        return li {
          div {
            node.content(
              Slots(
                handle: handle, diff: diff,
                children: list(node.children, parent: node.id, prefix: number).build()))
          }
          .class("outliner-row")
        }
        .class("outliner-item")
        .data("outliner-id", node.id)
        .data("outliner-label", node.label)
        .data("outliner-rank", node.rank)
        .data("outliner-original-parent", origin.parent)
        .data("outliner-original-position", origin.position)
        .data("outliner-original-number", origin.number)
        .data("outliner-moved", isMoved)
        .data("outliner-touched", touched.contains(node.id))
        .data("outline-state", isMoved ? "moved" : "none")
        .build()
      }

      return div {
        p {
          "Press Space or Enter on a handle to pick an item up; a toolbar at the foot of the screen then moves it. While it is held, the up and down arrows move it among its neighbours, Tab or the right arrow puts it under the item above, Shift-Tab or the left arrow takes it out a level, and Enter, Space or Escape put it down."
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

        list(nodes, parent: rootID, prefix: "")
          .ariaLabel(label)

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
              icon: ArrowUpIconView(width: size20, height: size20), weight: .quiet, size: .large,
              ariaLabel: "Move up", data: [("outliner-action", "up")])
            ButtonView(
              icon: ArrowDownIconView(width: size20, height: size20), weight: .quiet, size: .large,
              ariaLabel: "Move down", data: [("outliner-action", "down")])
            ButtonView(
              icon: ArrowPreviousIconView(width: size20, height: size20), weight: .quiet, size: .large,
              ariaLabel: "Outdent", data: [("outliner-action", "outdent")])
            ButtonView(
              icon: ArrowNextIconView(width: size20, height: size20), weight: .quiet, size: .large,
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
      .id(id)
      .class(`class`.isEmpty ? "outliner-view" : "outliner-view \(`class`)")
      .data("outliner-root-id", rootID)
      .data("outliner-root-rank", rootRank)
      .data("outliner-leaf-rank", leafRank.map(String.init) ?? "")
      .data("outliner-number-selector", numberSelector)
      .data("outliner-rank-refusal", rankRefusal)
      .style {
        // A little room at the edges, so a ring drawn outside a row or a
        // control is not cut off by a container that clips.
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
          padding(spacing4)
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
        // An item with nothing under it has an empty list, kept so a move
        // can put something there.
        descendant(".outliner-list:empty") {
          display(.none)
        }
        descendant(".outliner-item") {
          minWidth(0)
        }
        descendant(".outliner-row") {
          position(.relative)
          minWidth(0)
          borderRadius(borderRadiusBase)
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
        // Where a drag would land: a straight bar, square-ended, centred in
        // the gap above the row or below it — or, for into it, along its foot,
        // indented — drawn apart from the row's border, so it never bends
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
          insetInlineStart(spacing32)
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
          padding(spacing8, spacing12)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          boxShadow(boxShadowMedium)
          pointerEvents(.none)
          whiteSpace(.nowrap)
        }
        descendant(".outliner-diff[data-visible='false']") {
          display(.none)
        }
        // At the foot of the screen, clear of a phone's home indicator, and
        // centred between both sides whichever way the line runs.
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
          border(borderWidthBase, .solid, borderColorSubtle)
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
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Every outliner on the page.
  public final class OutlinerHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: OutlinerHydration?
    private var outliners: [OutlinerInstance] = []

    public static func hydrateIfPresent() {
      guard document.querySelector(".outliner-view") != nil else { return }
      instance = OutlinerHydration()
    }

    public init() {
      for root in document.querySelectorAll(".outliner-view") {
        guard !stringEquals(root.dataset["outliner-hydrated"] ?? "false", "true") else { continue }
        root.setAttribute(data("outliner-hydrated"), "true")
        outliners.append(OutlinerInstance(root: root))
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
    /// what moved is settled in favour of.
    private var touched: [String] = []

    init(root: DOM.Element) {
      self.root = root
      rootID = root.dataset["outliner-root-id"] ?? ""
      rootRank = parseInt(root.dataset["outliner-root-rank"] ?? "0") ?? 0
      leafRank = parseInt(root.dataset["outliner-leaf-rank"] ?? "") ?? -1
      numberSelector = root.dataset["outliner-number-selector"] ?? ""
      rankRefusal = root.dataset["outliner-rank-refusal"] ?? ""
      for item in root.querySelectorAll(".outliner-item") {
        bind(item)
        if stringEquals(item.dataset["outliner-touched"] ?? "false", "true") { touched.append(id(of: item)) }
      }
      bindToolbar()
      refresh()
    }

    // MARK: - Reading the outline

    private func items(in list: DOM.Element) -> [DOM.Element] {
      list.querySelectorAll(":scope > .outliner-item")
    }

    /// The list of an item's children, wherever its content put it: the
    /// first list inside the item, since its own comes before any nested one.
    private func childList(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(".outliner-list")
    }

    /// The item a list belongs to — the nearest item it sits inside; nil for
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

    private func rank(of item: DOM.Element?) -> Int {
      guard let item else { return rootRank }
      return parseInt(item.dataset["outliner-rank"] ?? "0") ?? 0
    }

    private func index(of item: DOM.Element, in siblings: [DOM.Element]) -> Int {
      for (index, sibling) in siblings.enumerated() where sibling.id == item.id { return index }
      return -1
    }

    /// An item's own handle: the first inside it, before its children's.
    private func handle(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(".outliner-handle")
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
      // Under a lower rank, or under the leaf rank, which takes nothing.
      let parentRank = rank(of: parent)
      if let _ = parent, parentRank == leafRank { return rankRefusal }
      guard rank(of: item) >= parentRank else { return rankRefusal }
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

    /// An item's one state, by precedence: refused, held, placeholder, moved,
    /// none.
    private func paint(_ item: DOM.Element) {
      let state: String
      if let target = refusedTarget, target.id == item.id {
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
    /// and a preview of its header — the line with its handle — is made to
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

    /// Numbers, moved marks, the toolbar and the submitted JSON — all read
    /// off the outline as it now stands.
    private func refresh() {
      guard let top = root.querySelector(":scope > .outliner-list") else { return }
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
      for (position, item) in items(in: list).enumerated() {
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
      collect(root.querySelector(":scope > .outliner-list"), parent: rootID, into: &entries)
      return stringJoin(["{", stringJoin(entries, separator: ","), "}"], separator: "")
    }

    private func collect(_ list: DOM.Element?, parent: String, into entries: inout [String]) {
      guard let list else { return }
      for (position, item) in items(in: list).enumerated() {
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
