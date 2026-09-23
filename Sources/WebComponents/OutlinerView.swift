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

  /// A nested list its reader can rearrange: by dragging an item's handle, by
  /// the move buttons beside it, or from the keyboard.
  ///
  /// Each item carries content the caller builds, a label to announce it by,
  /// and a rank. Ranks order the levels an outline may nest — the smaller the
  /// number, the higher the level — and an item may never sit under one of a
  /// larger rank: that move is refused where it is attempted, with a message
  /// on the page and in the live region. Items of equal rank may nest; there
  /// is no depth limit.
  ///
  /// Keyboard: Space or Enter on an item's handle grabs it. While it is held,
  /// ↑ and ↓ (or Cmd/Ctrl-Shift-↑/↓) move it among its siblings, Tab and → put
  /// it under the item above, Shift-Tab and ← take it out to its parent's
  /// level, Enter or Space drops it and Escape puts it back where it was. Tab
  /// is only taken while an item is held; otherwise focus moves as it always
  /// does. The move buttons are drawn when the item is hovered or has focus,
  /// and always while it is held.
  ///
  /// The arrangement is submitted as JSON in a hidden input: each item's id
  /// to its parent's and its position among its siblings,
  /// `{"a": {"parent": "root", "position": 0}}`, where the top level's parent
  /// is `rootID`. An item whose place differs from the one it was rendered in
  /// is marked `data-outliner-moved`, with its original number beside it; the
  /// root dispatches `outliner-change` with the JSON after every move.
  public struct OutlinerView: HTMLContent {
    public struct Node: Sendable {
      public let id: String
      public let label: String
      public let rank: Int
      /// Where the item stood before this outline was last edited, when
      /// that is not where it is drawn: an outline brought back mid-edit
      /// still reports its moves against the arrangement it started from.
      public let origin: Origin?
      public let content: [DOM.Node]
      public let children: [Node]

      public init(
        id: String,
        label: String,
        rank: Int,
        origin: Origin? = nil,
        children: [Node] = [],
        @HTMLBuilder content: () -> [DOM.Node]
      ) {
        self.id = id
        self.label = label
        self.rank = rank
        self.origin = origin
        self.children = children
        self.content = content()
      }
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
    ///   - name: The hidden input's name, and `form` the form it submits
    ///     with when the outline is not inside it.
    ///   - numberSelector: Where in an item's content its number — 1, 2.1 —
    ///     is written, so a caller that shows numbers keeps them true as the
    ///     outline changes. Empty writes none.
    ///   - rankRefusal: Why a rank-breaking move is refused, in the page's own
    ///     words.
    ///   - touched: The items the reader has already moved, when the outline
    ///     is brought back mid-edit: where two readings of what moved are
    ///     equally short, theirs is the one reported.
    public init(
      id: String,
      label: String,
      rootID: String,
      rootRank: Int = 0,
      nodes: [Node],
      name: String,
      form: String? = nil,
      numberSelector: String = "",
      rankRefusal: String = "An item cannot sit under one of a lower rank.",
      touched: [String] = [],
      class: String = ""
    ) {
      self.id = id
      self.label = label
      self.rootID = rootID
      self.rootRank = rootRank
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
        return li {
          div {
            div {
              // The grip: what is dragged, and what the keyboard grabs.
              button {
                DraggableIconView(width: px(16), height: px(16))
              }
              .type(.button)
              .class("outliner-handle")
              .draggable(true)
              .ariaLabel("Move \(node.label)")
              .ariaPressed(false)
              .ariaDescribedby("\(id)-instructions")

              div {
                ButtonView(
                  icon: ArrowUpIconView(width: px(16), height: px(16)), weight: .quiet, size: .mini,
                  ariaLabel: "Move \(node.label) up", borderRadius: borderRadiusBase,
                  data: [("outliner-action", "up")])
                ButtonView(
                  icon: ArrowDownIconView(width: px(16), height: px(16)), weight: .quiet, size: .mini,
                  ariaLabel: "Move \(node.label) down", borderRadius: borderRadiusBase,
                  data: [("outliner-action", "down")])
                ButtonView(
                  icon: ArrowPreviousIconView(width: px(16), height: px(16)), weight: .quiet, size: .mini,
                  ariaLabel: "Move \(node.label) out a level", borderRadius: borderRadiusBase,
                  data: [("outliner-action", "outdent")])
                ButtonView(
                  icon: ArrowNextIconView(width: px(16), height: px(16)), weight: .quiet, size: .mini,
                  ariaLabel: "Move \(node.label) in a level", borderRadius: borderRadiusBase,
                  data: [("outliner-action", "indent")])
              }
              .class("outliner-actions")
            }
            .class("outliner-controls")

            div { node.content }
              .class("outliner-content")
          }
          .class("outliner-row")

          // The moved item's diff line, as a changed field has its
          // "Previously:" — written by the client when it applies.
          p { "Moved from \(origin.number)" }
            .class("outliner-moved-note")
            .data("visible", isMoved)

          list(node.children, parent: node.id, prefix: number)
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
        .data("outliner-grabbed", false)
        .build()
      }

      return div {
        p {
          "Press Space or Enter on a handle to pick an item up. While it is held, the up and down arrows move it among its neighbours, Tab or the right arrow puts it under the item above, Shift-Tab or the left arrow takes it out a level, Enter or Space drops it and Escape puts it back."
        }
        .id("\(id)-instructions")
        .class("outliner-instructions")

        div()
          .class("outliner-live")
          .ariaLive(.assertive)

        div()
          .class("outliner-feedback")

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
      }
      .id(id)
      .class(`class`.isEmpty ? "outliner-view" : "outliner-view \(`class`)")
      .data("outliner-root-id", rootID)
      .data("outliner-root-rank", rootRank)
      .data("outliner-number-selector", numberSelector)
      .data("outliner-rank-refusal", rankRefusal)
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
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
        descendant(".outliner-list") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          listStyle(.none)
          margin(0)
          padding(0)
          minWidth(0)
        }
        // A level in: the children list under its item, indented by the
        // width of the controls so a child's content starts under its
        // parent's.
        descendant(".outliner-item > .outliner-list") {
          paddingInlineStart(spacing24)
        }
        descendant(".outliner-item > .outliner-list:empty") {
          display(.none)
        }
        descendant(".outliner-item") {
          display(.flex)
          flexDirection(.column)
          gap(spacing8)
          minWidth(0)
        }
        descendant(".outliner-row") {
          position(.relative)
          display(.flex)
          alignItems(.flexStart)
          gap(spacing4)
          minWidth(0)
          borderRadius(borderRadiusBase)
        }
        // The grip holds the row's place in the column; the four moves float
        // over the row's top edge when they are wanted, so they never take
        // width from the content — on a phone that width is the row.
        descendant(".outliner-controls") {
          display(.flex)
          alignItems(.center)
          flexShrink(0)
          paddingBlockStart(spacing12)
        }
        descendant(".outliner-content") {
          flex(1)
          minWidth(0)
        }
        descendant(".outliner-handle") {
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
          width(px(24))
          height(px(24))
          padding(0)
          border(.none)
          borderRadius(borderRadiusBase)
          backgroundColor(.transparent)
          color(colorSubtle)
          cursor(.grab)
          transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
        }
        descendant(".outliner-handle:hover") {
          backgroundColor(backgroundColorInteractiveSubtleHover)
          color(colorBase)
        }
        descendant(".outliner-handle:focus-visible") {
          outline(px(2), .solid, borderColorBlueFocus)
          outlineOffset(px(-2))
        }
        descendant(".outliner-item[data-outliner-grabbed='true'] > .outliner-row .outliner-handle") {
          backgroundColor(backgroundColorBlue)
          color(colorInvertedFixed)
          cursor(.grabbing)
        }
        // The move buttons: out of the way until the item is hovered or has
        // focus, and always while it is held.
        // Transparent rather than hidden, so a button pressed from the
        // keyboard can take focus back after its item has moved — moving a
        // node drops focus, and a hidden button cannot be focused again.
        descendant(".outliner-actions") {
          position(.absolute)
          insetInlineStart(0)
          insetBlockEnd(calc("100% - \(spacing4.value)"))
          zIndex(zIndexToolbar)
          display(.flex)
          gap(spacing2)
          padding(spacing2)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          boxShadow(boxShadowSmall)
          opacity(0)
          pointerEvents(.none)
        }
        selector(
          "& .outliner-row:hover > .outliner-controls > .outliner-actions",
          "& .outliner-row:focus-within > .outliner-controls > .outliner-actions",
          "& .outliner-item[data-outliner-grabbed='true'] > .outliner-row > .outliner-controls > .outliner-actions"
        ) {
          opacity(1)
          pointerEvents(.auto)
        }
        descendant(".outliner-actions [aria-disabled='true']") {
          opacity(opacityLow)
          cursor(.notAllowed)
        }
        // Where a drag would land.
        descendant(".outliner-row[data-outliner-drop='before']") {
          boxShadow(px(0), px(-2), px(0), px(0), borderColorBlue)
        }
        descendant(".outliner-row[data-outliner-drop='after']") {
          boxShadow(px(0), px(2), px(0), px(0), borderColorBlue)
        }
        descendant(".outliner-row[data-outliner-drop='inside']") {
          outline(px(2), .solid, borderColorBlue)
          outlineOffset(px(2))
        }
        descendant(".outliner-row[data-outliner-drop='refused']") {
          outline(px(2), .solid, borderColorRed)
          outlineOffset(px(2))
          cursor(.notAllowed)
        }
        descendant(".outliner-item[data-outliner-dragging='true'] > .outliner-row") {
          opacity(opacityLow)
        }
        descendant(".outliner-item[data-outliner-refused='true'] > .outliner-row") {
          outline(px(2), .solid, borderColorRed)
          outlineOffset(px(2))
        }
        descendant(".outliner-moved-note") {
          fontFamily(typographyFontSans)
          fontSize(fontSizeXSmall12)
          color(colorSubtle)
          margin(0)
          paddingInlineStart(spacing16)
        }
        descendant(".outliner-moved-note[data-visible='false']") {
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
    private let numberSelector: String
    private let rankRefusal: String

    /// The item held from the keyboard, and where it was picked up from.
    private var held: DOM.Element?
    private var heldList: DOM.Element?
    private var heldBefore: DOM.Element?
    /// The item being dragged, and whether the drag ended on a drop.
    private var dragged: DOM.Element?
    private var droppedOnTarget = false
    private var lastRefusal = ""
    /// The items the reader has moved, which a tie between two readings of
    /// what moved is settled in favour of.
    private var touched: [String] = []

    init(root: DOM.Element) {
      self.root = root
      rootID = root.dataset["outliner-root-id"] ?? ""
      rootRank = parseInt(root.dataset["outliner-root-rank"] ?? "0") ?? 0
      numberSelector = root.dataset["outliner-number-selector"] ?? ""
      rankRefusal = root.dataset["outliner-rank-refusal"] ?? ""
      for item in root.querySelectorAll(".outliner-item") {
        bind(item)
        if stringEquals(item.dataset["outliner-touched"] ?? "false", "true") { touched.append(id(of: item)) }
      }
      refresh()
    }

    // MARK: - Reading the outline

    private func items(in list: DOM.Element) -> [DOM.Element] {
      list.querySelectorAll(":scope > .outliner-item")
    }

    private func childList(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-list")
    }

    /// The item a list belongs to; nil for the top level.
    private func owner(of list: DOM.Element) -> DOM.Element? {
      guard let parent = list.parentElement, parent.classList.contains("outliner-item") else { return nil }
      return parent
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

    private func handle(of item: DOM.Element) -> DOM.Element? {
      item.querySelector(":scope > .outliner-row > .outliner-controls > .outliner-handle")
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

    // MARK: - Binding

    private func bind(_ item: DOM.Element) {
      if let handle = handle(of: item) {
        _ = handle.addEventListener(.keydown) { [self] event in self.key(event, on: item) }
        _ = handle.addEventListener(.click) { [self] _ in
          if self.isHeld(item) { self.drop() } else { self.grab(item) }
        }
        _ = handle.addEventListener(.dragstart) { [self] event in self.dragStart(event, item) }
        _ = handle.addEventListener(.dragend) { [self] _ in self.dragEnd() }
      }
      for button in item.querySelectorAll(":scope > .outliner-row > .outliner-controls [data-outliner-action]") {
        let action = button.dataset["outliner-action"] ?? ""
        _ = button.addEventListener(.click) { [self] event in
          event.preventDefault()
          self.act(action, item)
          // The item moved in the document, which drops focus; the button
          // pressed is still the one in hand.
          button.focus()
        }
      }
      if let row = item.querySelector(":scope > .outliner-row") {
        _ = row.addEventListener(.dragover) { [self] event in self.dragOver(event, item, row) }
        _ = row.addEventListener(.dragleave) { _ in row.removeAttribute(data("outliner-drop")) }
        _ = row.addEventListener(.drop) { [self] event in self.dropOn(event, item, row) }
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

    // MARK: - Keyboard

    private func isHeld(_ item: DOM.Element) -> Bool {
      guard let held else { return false }
      return held.id == item.id
    }

    private func key(_ event: Event, on item: DOM.Element) {
      let key = event.key
      guard isHeld(item) else {
        if stringEquals(key, " ") || stringEquals(key, "Enter") {
          event.preventDefault()
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
      } else if stringEquals(key, "Escape") {
        event.preventDefault()
        cancel()
      } else if stringEquals(key, " ") || stringEquals(key, "Enter") {
        event.preventDefault()
        drop()
      }
      handle(of: item)?.focus()
    }

    private func grab(_ item: DOM.Element) {
      if held != nil { drop() }
      held = item
      heldList = item.parentElement
      heldBefore = nil
      if let list = heldList {
        let siblings = items(in: list)
        let at = index(of: item, in: siblings)
        if at >= 0 && at + 1 < siblings.count { heldBefore = siblings[at + 1] }
      }
      item.setAttribute(data("outliner-grabbed"), "true")
      handle(of: item)?.setAttribute("aria-pressed", "true")
      announce(stringJoin([label(of: item), ", picked up at ", number(of: item), "."], separator: ""))
    }

    private func drop() {
      guard let item = held else { return }
      release(item)
      announce(stringJoin([label(of: item), ", dropped at ", number(of: item), "."], separator: ""))
    }

    /// Puts the held item back where it was picked up.
    private func cancel() {
      guard let item = held, let list = heldList else { return }
      if let before = heldBefore {
        list.insertBefore(item, before)
      } else {
        list.appendChild(item)
      }
      release(item)
      changed()
      announce(stringJoin([label(of: item), ", back at ", number(of: item), "."], separator: ""))
    }

    private func release(_ item: DOM.Element) {
      item.setAttribute(data("outliner-grabbed"), "false")
      handle(of: item)?.setAttribute("aria-pressed", "false")
      held = nil
      heldList = nil
      heldBefore = nil
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
      guard rank(of: item) >= rank(of: parent) else {
        let where_ = parent.map { label(of: $0) } ?? "the top"
        return stringJoin([label(of: item), " cannot go under ", where_, ". ", rankRefusal], separator: "")
      }
      return nil
    }

    private func refuse(_ item: DOM.Element, _ reason: String) {
      announce(reason)
      if let slot = root.querySelector(":scope > .outliner-feedback") {
        slot.setInnerHTML("")
        AlertAPI.show(reason, type: .red, inline: true, autoDismiss: true, autoDismissTime: 6000, container: slot)
      }
      item.setAttribute(data("outliner-refused"), "true")
      _ = setTimeout(1200) {
        item.removeAttribute(data("outliner-refused"))
      }
    }

    private func moved(_ item: DOM.Element) {
      let itemID = id(of: item)
      if !touched.contains(where: { stringEquals($0, itemID) }) { touched.append(itemID) }
      changed()
      announce(stringJoin([label(of: item), ", now ", number(of: item), "."], separator: ""))
      root.dispatchEvent(CustomEvent(type: "outliner-move", detail: id(of: item)))
    }

    // MARK: - Drag and drop

    private func dragStart(_ event: Event, _ item: DOM.Element) {
      dragged = item
      droppedOnTarget = false
      lastRefusal = ""
      let transfer = event.dataTransfer
      transfer.setData("text/plain", id(of: item))
      transfer.effectAllowed = "move"
      if let row = item.querySelector(":scope > .outliner-row") {
        transfer.setDragImage(row, x: 16, y: 16)
      }
      item.setAttribute(data("outliner-dragging"), "true")
    }

    /// Where on a row the pointer is: its top quarter drops before it, its
    /// bottom quarter after it, anywhere between into it.
    private func dropPosition(_ event: Event, _ row: DOM.Element) -> String {
      guard let rect = row.getBoundingClientRect() else { return "inside" }
      let y = event.clientY - rect.top
      if y < rect.height / 4 { return "before" }
      if y > rect.height * 3 / 4 { return "after" }
      return "inside"
    }

    private func dragOver(_ event: Event, _ target: DOM.Element, _ row: DOM.Element) {
      guard let item = dragged else { return }
      let position = dropPosition(event, row)
      let parent = stringEquals(position, "inside") ? target : parentItem(of: target)
      if isWithin(target, item) {
        row.setAttribute(data("outliner-drop"), "refused")
        lastRefusal = stringJoin([label(of: item), " cannot go inside itself."], separator: "")
        return
      }
      if let reason = refusal(item, under: parent) {
        row.setAttribute(data("outliner-drop"), "refused")
        lastRefusal = reason
        let transfer = event.dataTransfer
        transfer.dropEffect = "none"
        return
      }
      lastRefusal = ""
      event.preventDefault()
      let transfer = event.dataTransfer
      transfer.dropEffect = "move"
      row.setAttribute(data("outliner-drop"), position)
    }

    private func dropOn(_ event: Event, _ target: DOM.Element, _ row: DOM.Element) {
      event.preventDefault()
      row.removeAttribute(data("outliner-drop"))
      guard let item = dragged, !isWithin(target, item) else { return }
      let position = dropPosition(event, row)
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
      if let item = dragged {
        item.removeAttribute(data("outliner-dragging"))
        // Let go over a place it could not go: say why, where it was tried.
        if !droppedOnTarget && !stringIsEmpty(lastRefusal) { refuse(item, lastRefusal) }
      }
      dragged = nil
      lastRefusal = ""
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

    /// Numbers, moved marks, which buttons can act, and the submitted JSON —
    /// all read off the outline as it now stands.
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
        if let note = item.querySelector(":scope > .outliner-moved-note") {
          note.setAttribute(data("visible"), moved ? "true" : "false")
        }
        if !stringIsEmpty(numberSelector),
          let slot = item.querySelector(":scope > .outliner-row > .outliner-content")?.querySelector(numberSelector)
        {
          slot.textContent = numbers[offset]
        }
      }
      if let input = root.querySelector(":scope > .outliner-shape") {
        input.setAttribute("value", shapeJSON())
        (input as? HTML.HTMLInputElement)?.value = shapeJSON()
      }
    }

    private func walk(
      _ list: DOM.Element, parent: String, prefix: String,
      entries: inout [OutlineMoves.Entry], walked: inout [DOM.Element], numbers: inout [String]
    ) {
      let siblings = items(in: list)
      for (position, item) in siblings.enumerated() {
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
        for button in item.querySelectorAll(":scope > .outliner-row > .outliner-controls [data-outliner-action]") {
          let action = button.dataset["outliner-action"] ?? ""
          let disabled: Bool = {
            if stringEquals(action, "up") || stringEquals(action, "indent") { return position == 0 }
            if stringEquals(action, "down") { return position + 1 == siblings.count }
            return stringIsEmpty(prefix)
          }()
          button.setAttribute("aria-disabled", disabled ? "true" : "false")
        }
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
