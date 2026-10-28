#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// Raw text, edited where it is read.
  ///
  /// A `CodeView` of the text whose text is itself editable (plain text
  /// only), colored as every code block on the site is. One layer: what is
  /// selected is the colored text, so a selection looks as the browser
  /// draws any, and a drag past the pane's edge scrolls it, as it does over
  /// any text. (A transparent textarea laid over the colors, as this was,
  /// held its own clipped scroller: a drag ran on under the edge with the
  /// pane, the selection drawn in a box left behind, and its selection had
  /// to be recolored by hand.)
  ///
  /// The text is colored by CSS highlights over its text node
  /// (`CodeEditorHydration`), not by markup written into it, so typing never
  /// loses the caret. A hidden textarea carries the value the form posts and
  /// its default; the client keeps it in step both ways.
  public struct CodeEditorView: HTMLContent {
    let id: String
    let name: String
    let value: String
    let language: String
    let ariaLabel: String
    /// Numbered, wide unless an ancestor reflows it (`CodeView.lined`).
    let lined: Bool

    public init(
      id: String, name: String, value: String, language: String = "xml", ariaLabel: String, lined: Bool = false
    ) {
      self.id = id
      self.name = name
      self.value = value
      self.language = language
      self.ariaLabel = ariaLabel
      self.lined = lined
    }

    public func build() -> DOM.Node {
      div {
        CodeView(value, language: language, showLineNumbers: false, editableLabel: ariaLabel, lined: lined)
        textarea(value)
          .id(id)
          .name(name)
          .hidden(true)
          .class("code-editor-input")
      }
      .class("code-editor-view")
      .style {
        // Its own scrollport sideways (2026-10-28): its code view gives up
        // scrolling to it, so a line wider than the field scrolls here, the
        // gutter staying put, and never widens the page. A field in a form
        // had no pane around it, and a long tool file pushed the whole page
        // past the screen.
        selector("&") {
          display(.flex)
          flexDirection(.column)
          minWidth(0)
          maxWidth(perc(100))
          overflowX(.auto)
        }
        // At a field's 16px (user, 2026-10-08): under 16px, iOS Safari zooms
        // the page as the text is focused. Its surface is the pane's.
        descendant(".code-view") {
          backgroundColor(.transparent)
          padding(0)
          borderRadius(0)
          overflow(.visible)
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
        }
        descendant(".code-code") {
          outline(.none)
          caretColor(colorBase)
          // Over the caret's line band, which stands behind it.
          position(.relative)
        }
        // The caret's line (user, 2026-10-12), as Xcode marks it: the neutral
        // subtle fill (the page's gray at `opacity-low`) across the whole width,
        // gutter to edge, every row it wraps to; its number in the text's own
        // color. Only while the editor has the focus and the selection is
        // within one line.
        descendant(".code-current-line") {
          display(.none)
          position(.absolute)
          insetInlineStart(px(0))
          insetInlineEnd(px(0))
          backgroundColor(backgroundColorCurrentLine)
          pointerEvents(.none)
        }
        descendant(".code-view[data-current-line='true'] .code-current-line") {
          display(.block)
        }
        descendant(".code-view[data-current-line='true'] .code-gutter-lines > span[data-current='true']") {
          color(colorBase)
        }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Keeps each editor's text and its form's textarea in step, both ways,
  /// and colors the text by highlights (`CodeSyntax`) once it can be seen,
  /// again a moment after typing stops. Highlights paint over the text node
  /// and write nothing into it, so the caret and the selection stay as the
  /// person left them.
  public enum CodeEditorHydration {
    /// One editor: its text, its form's textarea, its language, and its
    /// colored stretches, by `CodeSyntax.Kind`.
    final class Editor: @unchecked Sendable {
      let code: DOM.Element
      /// The form's textarea; nil for text that is only read.
      let input: HTML.HTMLTextAreaElement?
      let language: CodeSyntax.Language
      /// Its stretches as last colored: the whole text's, read in one pass.
      var tokens: [CodeSyntax.Token] = []
      /// The ranges of the stretches painted now, by index: only those on
      /// and near the lines the pane shows (`paintWindow`). A long page's
      /// ten thousand stretches as live ranges cost every keystroke—the
      /// browser moves each live range with every edit (WebKit took
      /// seconds), and repaints every range of a highlight that changes
      /// (Chrome, a 50 ms frame; user, 2026-10-15).
      var live: [Int: DOM.Range] = [:]
      /// One character's width, measured once (the text is monospaced):
      /// which columns the pane shows.
      var charWidth = 0.0
      /// Its text nodes as last read, where a stretch's range is set.
      var nodes: [(node: DOM.Text, start: Int, end: Int)] = []
      /// Its text as last colored (UTF-8) and how many text nodes held it:
      /// an edit is found against them (`color`).
      var bytes: [UInt8] = []
      var nodeCount = 0
      var colored = false
      /// Whether it is on screen: painted only then.
      var shown = false
      /// Its lines' starts (UTF-16) and tops (from its view's top), as
      /// `number` last measured them; empty for text that is not lined.
      var lineStarts: [Int] = []
      var lineTops: [Double] = []
      var timer: Int32 = 0
      /// Each text node's first byte in `bytes`, in `nodes`' order.
      var byteStarts: [Int] = []
      /// Read-only text's blocks (`updateBlocks`), and how many of its
      /// children have been counted for them.
      var blocks: [Block] = []
      var childrenCounted = 0
      /// Text added at its end since it was last read (`grew`).
      var grown = false
      /// The frame and the idle period asked for its work (`schedule`).
      var frame: Int32 = 0
      var idle: Int32 = 0
      /// Every block read to its end and painted whole.
      var complete = false
      /// Its text nodes as they are read (`readMore`), and whether all are.
      var walker: DOM.TreeWalker? = nil
      var walked = true

      init(code: DOM.Element, input: HTML.HTMLTextAreaElement?) {
        self.code = code
        self.input = input
        self.language = CodeEditorHydration.language(of: code)
      }
    }

    /// The grammar a block is read by: its `data-code-syntax` (`xml`,
    /// `json`, `markdown`, `chat-template`), XML when it names none.
    static func language(of code: DOM.Element) -> CodeSyntax.Language {
      guard let name = code.dataset["codeSyntax"] else { return .xml }
      if stringEquals(name, "json") { return .json }
      if stringEquals(name, "markdown") { return .markdown }
      if stringEquals(name, "chat-template") { return .chatTemplate }
      return .xml
    }

    nonisolated(unsafe) static var editors: [Editor] = []
    /// One highlight a kind, registered under its name, holding every
    /// editor's stretches of that kind.
    nonisolated(unsafe) static var highlights: [Highlight] = []

    /// The editors under `root` that nothing is keeping in step yet.
    public static func hydrate(in root: DOM.Element) {
      for view in root.querySelectorAll(".code-editor-view") {
        if view.hasAttribute("data-code-editor-hydrated") { continue }
        view.setAttribute(data("code-editor-hydrated"), "true")
        guard let input = view.querySelector(".code-editor-input") as? HTML.HTMLTextAreaElement,
          let code = view.querySelector(".code-code")
        else { continue }
        let editor = Editor(code: code, input: input)
        editors.append(editor)
        _ = code.addEventListener(.keydown) { event in
          if KeyboardShortcuts.editorOwns(event.key) { event.stopPropagation() }
        }
        // The caret's line shows while the editor has the focus.
        _ = code.addEventListener("focus") { _ in
          code.setAttribute(data("focused"), "true")
          if code.hasAttribute("data-code-lined") { markCurrentLine(code) }
        }
        _ = code.addEventListener("blur") { _ in
          code.removeAttribute(data("focused"))
          if code.hasAttribute("data-code-lined") { markCurrentLine(code) }
        }
        _ = code.addEventListener(.input) { _ in
          let text = code.textContent
          input.value = text
          // A line added or removed is numbered in the same frame (user,
          // 2026-10-15): the gutter never trails the text. A wrap changed
          // by typing within a line waits for the pause, as coloring does.
          if code.hasAttribute("data-code-lined"), lineCount(text) != numberedLines(code) { number(code) }
          // Colored in the same frame, only what the edit touched (`color`).
          color(editor)
          // Its listeners hear the edit as the textarea's own.
          input.dispatchEvent(.input)
          schedule(editor)
        }
        // A value set from elsewhere—a script, a test—is shown.
        _ = input.addEventListener(.input) { _ in
          let text = input.value
          guard !stringEquals(text, code.textContent) else { return }
          if code.hasAttribute("data-code-lined") {
            // Set from elsewhere, not typed: laid out as served.
            reline(code, text: text)
          } else {
            code.textContent = text
          }
          if code.hasAttribute("data-code-lined") { number(code) }
          color(editor)
        }
        colorIfVisible(code)
      }
      // The caret moved (a click, a key, typing, a script): its line marked
      // in the editor that has it.
      if !listensToSelection {
        listensToSelection = true
        _ = document.addEventListener("selectionchange") { _ in
          for code in document.querySelectorAll(".code-code[data-code-editing='true'][data-code-lined='true'][data-focused='true']") {
            markCurrentLine(code)
          }
        }
      }
      // A pane scrolled: the stretches it now shows painted, once a frame.
      if !listensToScroll {
        listensToScroll = true
        _ = document.addEventListener(
          "scroll",
          { _ in
            guard !scrollPending else { return }
            scrollPending = true
            _ = window.requestAnimationFrame(timed: { time in
              frameTime = time
              scrollPending = false
              for editor in editors where editor.shown { repaint(editor) }
            })
          }, capture: true, passive: true)
      }
      // A pane resized wraps lines anew: every shown editor renumbered.
      if !listensToResize {
        listensToResize = true
        _ = window.addEventListener(.resize) { _ in
          for code in document.querySelectorAll(".code-code[data-code-editing='true'][data-code-lined='true']") {
            number(code)
          }
        }
      }
    }

    /// Colors text that is only read (lined code, an XML block, a
    /// Markdown or JSON Raw) once, when it has a box on screen. Text that
    /// grows (a live session's Raw, `data-live-output`) is colored as it
    /// grows (`grew`), never read whole again here: a click anywhere asks
    /// for this, and a Raw read whole at every click stalled the page.
    public static func colorTextIfVisible(_ code: DOM.Element) {
      guard !code.hasAttribute("data-code-colored"), let rect = code.getBoundingClientRect(), rect.height > 0
      else { return }
      colorText(code)
    }

    /// Colors read-only text now, whether it has a box yet or not: a
    /// card's body drawn as the click that opens it is heard, before the
    /// accordion has laid it out, colored in that same task rather than a
    /// frame later (`colorWhole`).
    public static func colorText(_ code: DOM.Element) {
      guard !code.hasAttribute("data-code-colored") else { return }
      code.setAttribute(data("code-colored"), "true")
      let viewer = Editor(code: code, input: nil)
      editors.append(viewer)
      colorWhole(viewer)
    }

    // MARK: Read-only text

    // Read-only text is colored once and kept colored: its stretches are
    // never taken out as it scrolls away or hides (Raw put away and shown
    // again repaints nothing), each a `StaticRange`, which the browser
    // never moves as the page changes (a live `Range` is moved with every
    // edit of the page, a streamed token's included).
    //
    // Its work is done against a deadline, never in one piece: a frame's
    // share (`frameBudget`) in the frame that shows it, the rest in idle
    // periods (the deadline's own `timeRemaining()`), the clock read after
    // every piece—what is on screen and a screen either side of it first,
    // then the rest in order. A piece is a natural one: a read step reads
    // one line from where its read last stood in the grammar's starting
    // state (`CodeSyntax.tokens(_:language:clean:)`), on to the next such
    // point (`readStep`); painting is one stretch. A block that grows is
    // read again only from its last such point—the work grows with what
    // was added, not with the block.

    /// A frame's share of read-only text's work, in ms: RAIL's figure for
    /// the script a frame may run and still be drawn in time ("aim to
    /// produce a frame in 10 ms", web.dev/articles/rail, Animation).
    public static let frameBudget = 10.0

    /// The timestamp of the frame whose callbacks are running, set by each
    /// of ours as it runs (`requestAnimationFrame(timed:)`): one share of a
    /// frame (`frameBudget`) for all the work its callbacks do—the page's
    /// coloring pass, a Raw's own frame, a scroll's—however many there are.
    /// Work asked for outside a frame (in a click's task) finds that share
    /// spent and is done in the next frame, before it is drawn.
    nonisolated(unsafe) public static var frameTime = -1.0
    nonisolated(unsafe) static var budgetFrame = -2.0
    nonisolated(unsafe) static var budgetEnd = 0.0

    /// When the running frame's share of work ends.
    public static func frameDeadline() -> Double {
      if frameTime != budgetFrame {
        budgetFrame = frameTime
        budgetEnd = window.performance.now() + frameBudget
      }
      return budgetEnd
    }

    /// One block of read-only text (`updateBlocks`): read by its grammar on
    /// its own, from a fresh start.
    final class Block: @unchecked Sendable {
      /// Its first text node, in `nodes`.
      let node: Int
      /// Its stretches in order (units from the text's start), and each
      /// one's paint once painted.
      var tokens: [CodeSyntax.Token] = []
      var ranges: [DOM.StaticRange?] = []
      /// Where its read stands, bytes and units from the text's start: the
      /// grammar's starting state there, and its stretches before it
      /// (`fixed` of them) final.
      var restartByte: Int
      var restartUnit: Int
      var fixed = 0
      /// Read to its end as the text stands.
      var read = false
      /// Its stretches before this are painted, or were looked at (`work`).
      var cursor = 0
      /// The lines the next read step reads: one, doubled after each step
      /// that met no point of the grammar's starting state (a fence, a
      /// comment or a wrapper open across them), so a long one is read in
      /// twice its length in all, never again line by line from its start.
      var reach = 1

      init(node: Int, byte: Int, unit: Int) {
        self.node = node
        restartByte = byte
        restartUnit = unit
      }
    }

    /// What is left of read-only text's work (`work`).
    enum Left {
      case none
      /// Text on screen or near it is not yet colored: the next frame's.
      case near
      /// The rest: idle time's.
      case rest
    }

    /// Read-only text read and colored: what is on screen in this task,
    /// within a frame's share, the rest soon (`schedule`).
    static func colorWhole(_ editor: Editor) {
      startReading(editor)
      editor.colored = true
      editor.shown = true
      paintNear(editor)
    }

    /// Read-only text that has grown at its end (a live session's Raw),
    /// only ever added to there—its last text node grown in place, new
    /// nodes after it: what grew read and colored the next frame, once
    /// however many tokens came (`schedule`). Text not yet colored is
    /// colored when first seen.
    public static func grew(_ code: DOM.Element) {
      guard let editor = editors.first(where: { $0.code.id == code.id }), editor.colored, editor.input == nil
      else { return }
      editor.grown = true
      schedule(editor, near: true)
    }

    /// Text that has stopped growing (a live session's stream ended): its
    /// last block read to its end as it ends, so it reads exactly as a
    /// recorded one.
    public static func completed(_ code: DOM.Element) {
      grew(code)
    }

    /// What grew taken in: what was added to its last text node and the
    /// nodes after it (`readGrowth`), the block that held the end read on
    /// from where it stood, and any block begun since added. Work
    /// proportional to what was added.
    static func takeGrowth(_ editor: Editor) {
      // Still being read: what grew is read in its turn, and a node read
      // before it grew is read again once the whole has been.
      guard editor.walked else { return }
      editor.grown = false
      guard let last = editor.nodes.last, editor.code.contains(last.node) else {
        // Its text set anew: read from the start.
        startReading(editor)
        return
      }
      readGrowth(editor)
      editor.blocks.last?.read = false
      editor.complete = false
      updateBlocks(editor)
    }

    /// Its work asked for: in the next frame where text on screen or near
    /// it waits (`near`), else in idle time.
    static func schedule(_ editor: Editor, near: Bool) {
      if near {
        guard editor.frame == 0 else { return }
        editor.frame = window.requestAnimationFrame(timed: { time in
          frameTime = time
          editor.frame = 0
          paintNear(editor)
        })
        return
      }
      guard editor.idle == 0 else { return }
      editor.idle = window.requestIdleCallback { deadline in
        editor.idle = 0
        if editor.grown { takeGrowth(editor) }
        followUp(editor, work(editor, until: window.performance.now() + deadline.timeRemaining()))
      }
    }

    /// What the screen shows of it colored now, within a frame's share;
    /// the rest asked for (`schedule`).
    static func paintNear(_ editor: Editor) {
      if editor.grown { takeGrowth(editor) }
      guard !editor.complete else { return }
      followUp(editor, work(editor, until: frameDeadline()))
    }

    static func followUp(_ editor: Editor, _ left: Left) {
      switch left {
      case .none: editor.complete = true
      case .near: schedule(editor, near: true)
      case .rest: schedule(editor, near: false)
      }
    }

    /// Its blocks read and painted until `deadline` (`performance.now()`):
    /// those on screen and a screen either side of it first, then the rest
    /// in order. The clock is read after each piece: a read step
    /// (`readStep`), a stretch painted.
    static func work(_ editor: Editor, until deadline: Double) -> Left {
      func late() -> Bool { window.performance.now() >= deadline }
      // Its text read first, a node at a time: nothing is placed on screen
      // before the text before it is known.
      if !editor.walked {
        readMore(editor, until: deadline)
        updateBlocks(editor)
        guard editor.walked else { return .near }
        if editor.grown { takeGrowth(editor) }
      }
      if let near = viewWindow(editor) {
        for index in 0..<editor.blocks.count {
          let block = editor.blocks[index]
          guard blockStartUnit(editor, index) < near.upperBound, blockEndUnit(editor, index) > near.lowerBound else { continue }
          while !block.read {
            if late() { return .near }
            readStep(editor, index)
          }
          // Its stretches in the window, those not yet painted.
          var at = firstToken(block, endingAfter: near.lowerBound)
          while at < block.tokens.count, block.tokens[at].start < near.upperBound {
            if block.ranges[at] == nil, let range = stillRange(editor, block.tokens[at]) {
              block.ranges[at] = range
              paintStill(removing: [], adding: [(block.tokens[at], range)])
              if late() { return .near }
            }
            at += 1
          }
        }
      }
      for index in 0..<editor.blocks.count {
        let block = editor.blocks[index]
        while !block.read {
          if late() { return .rest }
          readStep(editor, index)
        }
        while block.cursor < block.tokens.count {
          let at = block.cursor
          block.cursor += 1
          guard block.ranges[at] == nil, let range = stillRange(editor, block.tokens[at]) else { continue }
          block.ranges[at] = range
          paintStill(removing: [], adding: [(block.tokens[at], range)])
          if late() { return .rest }
        }
      }
      return .none
    }

    /// The first of `block`'s stretches that ends after `unit`.
    static func firstToken(_ block: Block, endingAfter unit: Int) -> Int {
      var low = 0
      var high = block.tokens.count
      while low < high {
        let middle = (low + high) / 2
        if block.tokens[middle].end <= unit { low = middle + 1 } else { high = middle }
      }
      return low
    }

    static func blockStartUnit(_ editor: Editor, _ index: Int) -> Int {
      let node = editor.blocks[index].node
      return node < editor.nodes.count ? editor.nodes[node].start : (editor.nodes.last?.end ?? 0)
    }

    static func blockEndUnit(_ editor: Editor, _ index: Int) -> Int {
      index + 1 < editor.blocks.count ? blockStartUnit(editor, index + 1) : (editor.nodes.last?.end ?? 0)
    }

    static func blockEndByte(_ editor: Editor, _ index: Int) -> Int {
      guard index + 1 < editor.blocks.count else { return editor.bytes.count }
      let node = editor.blocks[index + 1].node
      return node < editor.byteStarts.count ? editor.byteStarts[node] : editor.bytes.count
    }

    /// One step of reading block `index` on from where its read stands:
    /// its next line (its next `reach` lines). Its stretches before the
    /// last point of the grammar's starting state it reached (`clean`) are
    /// final, and its read goes on from there; those after it, where the
    /// step stopped short of the block's end, are read again by the next.
    /// A step that reaches no such point (a fence, a comment or a wrapper
    /// open across its lines) keeps nothing, and the next reads twice the
    /// lines. A line is unbounded: a single-line JSON result of 100 KB is
    /// one step. Stretches read as before keep their paint; only those
    /// that differ are repainted.
    static func readStep(_ editor: Editor, _ index: Int) {
      let block = editor.blocks[index]
      let end = blockEndByte(editor, index)
      var to = block.restartByte
      var lines = 0
      while to < end, lines < block.reach {
        if editor.bytes[to] == 0x0A { lines += 1 }
        to += 1
      }
      let slice = Array(editor.bytes[block.restartByte..<to])
      var clean = 0
      let found = CodeSyntax.tokens(slice, language: editor.language, clean: &clean)
      if to < end, clean == 0 {
        block.reach *= 2
        return
      }
      block.reach = 1
      let partial = to < end
      var cleanUnit = block.restartUnit
      for byte in slice[0..<clean] where byte & 0xC0 != 0x80 { cleanUnit += byte >= 0xF0 ? 2 : 1 }
      var fresh: [CodeSyntax.Token] = []
      var fixed = block.fixed
      for token in found {
        let start = token.start + block.restartUnit
        // Short of the block's end, what follows the clean point is read
        // again by the next step.
        if partial, start >= cleanUnit { break }
        fresh.append(CodeSyntax.Token(kind: token.kind, start: start, end: token.end + block.restartUnit))
        if start < cleanUnit { fixed += 1 }
      }
      merge(block, fresh)
      block.fixed = fixed
      block.restartByte += clean
      block.restartUnit = cleanUnit
      block.read = !partial
    }

    /// `fresh` the block's stretches after its final ones: of those it
    /// had there, one the same keeps its paint, one gone is taken out.
    static func merge(_ block: Block, _ fresh: [CodeSyntax.Token]) {
      var kept = [DOM.StaticRange?](repeating: nil, count: fresh.count)
      var gone: [(CodeSyntax.Token, DOM.StaticRange)] = []
      var next = 0
      var index = block.fixed
      while index < block.tokens.count {
        let token = block.tokens[index]
        while next < fresh.count, fresh[next].start < token.start { next += 1 }
        if next < fresh.count, fresh[next] == token {
          kept[next] = block.ranges[index]
          next += 1
        } else if let range = block.ranges[index] {
          gone.append((token, range))
        }
        index += 1
      }
      block.tokens.removeSubrange(block.fixed..<block.tokens.count)
      block.ranges.removeSubrange(block.fixed..<block.ranges.count)
      block.tokens.append(contentsOf: fresh)
      block.ranges.append(contentsOf: kept)
      block.cursor = min(block.cursor, block.fixed)
      if !gone.isEmpty { paintStill(removing: gone, adding: []) }
    }

    /// The UTF-16 units of `text`.
    static func unitLength(_ text: String) -> Int {
      var length = 0
      for byte in text.utf8 where byte & 0xC0 != 0x80 { length += byte >= 0xF0 ? 2 : 1 }
      return length
    }

    /// What was added at its end since it was read: its last text node's
    /// new text alone (`substringData`; text that grows is only added to at
    /// its end, as `grew` says), and the text nodes after it.
    static func readGrowth(_ editor: Editor) {
      let lastIndex = editor.nodes.count - 1
      let last = editor.nodes[lastIndex]
      let had = last.end - last.start
      let length = last.node.length
      if length > had {
        editor.bytes.append(contentsOf: last.node.substringData(had, length - had).utf8)
        editor.nodes[lastIndex] = (last.node, last.start, last.start + length)
      }
      var units = editor.nodes[lastIndex].end
      let walker = document.createTreeWalker(editor.code, DOM.NodeFilter.SHOW_TEXT)
      walker.currentNode = last.node
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        let text = node.data
        let size = unitLength(text)
        editor.byteStarts.append(editor.bytes.count)
        editor.bytes.append(contentsOf: text.utf8)
        editor.nodes.append((node, units, units + size))
        units += size
      }
      editor.nodeCount = editor.nodes.count
    }

    /// Its text read again from the start, a node at a time (`readMore`):
    /// its nodes, bytes and blocks begun anew, its paint let go.
    static func startReading(_ editor: Editor) {
      editor.bytes = []
      editor.nodes = []
      editor.byteStarts = []
      var gone: [(CodeSyntax.Token, DOM.StaticRange)] = []
      for block in editor.blocks {
        for (at, range) in block.ranges.enumerated() { if let range { gone.append((block.tokens[at], range)) } }
      }
      if !gone.isEmpty { paintStill(removing: gone, adding: []) }
      editor.blocks = []
      editor.childrenCounted = 0
      editor.complete = false
      editor.walker = document.createTreeWalker(editor.code, DOM.NodeFilter.SHOW_TEXT)
      editor.walked = false
    }

    /// Its text nodes read on, the clock read after each, till `deadline`
    /// or its last: a Raw of a thousand runs is read over frames, never in
    /// one task. A node added meanwhile is read in its turn; one grown
    /// after it was read waits for `readGrowth`.
    static func readMore(_ editor: Editor, until deadline: Double) {
      guard let walker = editor.walker else {
        editor.walked = true
        return
      }
      var units = editor.nodes.last?.end ?? 0
      while window.performance.now() < deadline {
        guard let next = walker.nextNode() else {
          editor.walker = nil
          editor.walked = true
          break
        }
        guard let node = next as? DOM.Text else { continue }
        let text = node.data
        let length = unitLength(text)
        editor.byteStarts.append(editor.bytes.count)
        editor.bytes.append(contentsOf: text.utf8)
        editor.nodes.append((node, units, units + length))
        units += length
      }
      editor.nodeCount = editor.nodes.count
    }

    /// A Raw's blocks: each run (a top-level child: a part of the
    /// template's messages, input or output) is read by the grammar on its
    /// own, from a fresh start—the template's special tokens close every
    /// message, so nothing the grammar reads (a fence, a comment, a tool's
    /// result) runs from one run into the next, and one the model left open
    /// (an unclosed fence) stops at its run's end instead of coloring the
    /// rest of the transcript. A recorded Raw is drawn with the same runs,
    /// so it reads the same. Any other text is one block: an XML or JSON
    /// block's children are its lines, which its grammar reads together.
    /// Only children not yet counted are looked at.
    static func updateBlocks(_ editor: Editor) {
      if editor.blocks.isEmpty { editor.blocks = [Block(node: 0, byte: 0, unit: 0)] }
      guard editor.language == .chatTemplate else { return }
      let selector = stringJoin([":scope > :nth-child(n+", intToString(editor.childrenCounted + 1), ")"], separator: "")
      var at = editor.blocks[editor.blocks.count - 1].node
      for child in editor.code.querySelectorAll(selector) {
        // A run with no text yet is counted once it has some.
        guard let first = document.createTreeWalker(child, DOM.NodeFilter.SHOW_TEXT).nextNode() else { break }
        while at < editor.nodes.count, editor.nodes[at].node.id != first.id { at += 1 }
        guard at < editor.nodes.count else { break }
        editor.childrenCounted += 1
        if at > editor.blocks[editor.blocks.count - 1].node {
          editor.blocks.append(Block(node: at, byte: editor.byteStarts[at], unit: editor.nodes[at].start))
          editor.complete = false
        }
      }
    }

    /// Where the screen and a screen either side of it stand in the text
    /// (UTF-16 units): by the caret at the screen's top and bottom where it
    /// falls in the text; where it falls on an element whose contents are
    /// not laid out (`content-visibility` skipping a Raw's run that has not
    /// been drawn yet), by height within that element's text; else by
    /// height within the whole. Nil where none of it is near.
    static func viewWindow(_ editor: Editor) -> Swift.Range<Int>? {
      let total = editor.nodes.last?.end ?? 0
      guard total > 0, let rect = editor.code.getBoundingClientRect(), rect.height > 0 else { return nil }
      let height = window.innerHeight
      guard rect.bottom > -height, rect.top < 2 * height else { return nil }
      func unit(at y: Double) -> Int {
        let clamped = min(max(y, rect.top), rect.bottom)
        if clamped >= 0, clamped < height,
          // Its first column of pixels, inside its box.
          let caret = document.caretPositionFromPoint(max(rect.left, 0) + 1, clamped), let node = caret.offsetNode
        {
          var at = 0
          while at < editor.nodes.count, editor.nodes[at].node.id != node.id { at += 1 }
          if at < editor.nodes.count { return editor.nodes[at].start + caret.offset }
          if let element = node as? DOM.Element, element.id != editor.code.id, editor.code.contains(element),
            let box = element.getBoundingClientRect(), box.height > 0
          {
            // Its text's first and last nodes, and the share of its height
            // above the point.
            let walker = document.createTreeWalker(element, DOM.NodeFilter.SHOW_TEXT)
            var first = -1
            var last = -1
            while let next = walker.nextNode() {
              var index = last < 0 ? 0 : last
              while index < editor.nodes.count, editor.nodes[index].node.id != next.id { index += 1 }
              guard index < editor.nodes.count else { break }
              if first < 0 { first = index }
              last = index
            }
            if first >= 0 {
              let from = editor.nodes[first].start
              let to = editor.nodes[last].end
              let share = min(max((clamped - box.top) / box.height, 0), 1)
              return from + Int(Double(to - from) * share)
            }
          }
        }
        return Int(Double(total) * (clamped - rect.top) / rect.height)
      }
      let top = unit(at: 0)
      let bottom = unit(at: height - 1)
      let span = bottom - top
      return max(0, top - span)..<min(total, bottom + span)
    }

    /// A stretch's range over its text nodes.
    static func stillRange(_ editor: Editor, _ token: CodeSyntax.Token) -> DOM.StaticRange? {
      guard let start = place(token.start, opening: true, in: editor.nodes),
        let end = place(token.end, opening: false, in: editor.nodes)
      else { return nil }
      return DOM.StaticRange(start.0, start.1, end.0, end.1)
    }

    /// Lined text laid out again as `text`'s lines (`CodeView.lines`), the
    /// caret kept where it stood in the text.
    static func reline(_ code: DOM.Element, text: String) {
      var caret = -1
      if let selection = window.getSelection(), selection.rangeCount > 0, let focus = selection.focusNode,
        code.contains(focus)
      {
        let before = document.createRange()
        before.setStart(code, 0)
        before.setEnd(focus, selection.focusOffset)
        caret = before.toString().utf16.count
      }
      let all = CodeLines.lines(of: text)
      var spans: [DOM.Element] = []
      for (index, line) in all.enumerated() {
        let span = document.createElement(.span)
        span.className = "code-line"
        span.setAttribute(.style, "--indent: " + intToString(line.indent))
        span.textContent = line.text + (index < all.count - 1 ? "\n" : "")
        spans.append(span)
      }
      code.replaceChildren(spans)
      code.setAttribute(.style, "--gutter: " + CodeLines.gutter(lines: all.count))
      guard caret >= 0, let selection = window.getSelection() else { return }
      var start = 0
      let walker = document.createTreeWalker(code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        let length = node.data.utf16.count
        if caret <= start + length {
          selection.collapse(node, caret - start)
          return
        }
        start += length
      }
    }

    /// How many lines `text` starts, as `number` counts them: a line
    /// begins at each character that opens the text or follows a line feed.
    static func lineCount(_ text: String) -> Int {
      var count = 0
      var atStart = true
      for byte in text.utf8 where byte & 0xC0 != 0x80 {
        if atStart { count += 1 }
        atStart = byte == 0x0A
      }
      // An empty text shows its first line's number.
      return max(count, 1)
    }

    /// How many numbers the editor's gutter shows now.
    static func numberedLines(_ code: DOM.Element) -> Int {
      code.parentElement?.querySelector(".code-gutter-lines")?.childElementCount ?? 0
    }

    /// A lined editor's numbers, beside its text and never in it: each
    /// logical line's top measured where the text now lays it out (a line
    /// the browser broke within a block is a line of its own), as
    /// CodeMirror and Monaco draw theirs. The editable text is never
    /// touched, so its undo is the browser's, whole.
    static func number(_ code: DOM.Element) {
      guard let gutter = code.parentElement?.querySelector(".code-gutter-lines"),
        let codeRect = code.getBoundingClientRect(), codeRect.height > 0,
        let parentRect = code.parentElement?.getBoundingClientRect()
      else { return }
      var starts: [(DOM.Text, Int)] = []
      var offsets: [Int] = []
      var atStart = true
      var total = 0
      let walker = document.createTreeWalker(code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        var index = 0
        for unit in node.data.utf16 {
          if atStart {
            starts.append((node, index))
            offsets.append(total)
          }
          atStart = unit == 0x0A
          index += 1
          total += 1
        }
      }
      var tops: [Double] = []
      var numbers: [DOM.Element] = []
      // An empty editor still has its first line (user, 2026-10-15).
      if starts.isEmpty {
        let number = document.createElement(.span)
        number.textContent = "1"
        number.setAttribute(.style, "top: " + intToString(Int(codeRect.top - parentRect.top)) + "px")
        number.setAttribute(data("top"), doubleToString(codeRect.top - parentRect.top))
        numbers.append(number)
      }
      for (line, start) in starts.enumerated() {
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(start.0, start.1 + 1)
        guard let rect = range.getBoundingClientRect() else { continue }
        tops.append(rect.top - parentRect.top)
        let number = document.createElement(.span)
        number.textContent = intToString(line + 1)
        number.setAttribute(.style, "top: " + intToString(Int(rect.top - parentRect.top)) + "px")
        number.setAttribute(data("top"), doubleToString(rect.top - parentRect.top))
        numbers.append(number)
      }
      // The column as wide as the widest number, never narrower than one
      // digit; the code is set off by it (its own `--gutter`), so a line
      // the browser wrote outside a line's block—typed into an emptied
      // editor, pasted—is never under the numbers (user, 2026-10-15).
      let width = CodeLines.gutter(lines: max(starts.count, 1))
      code.style.setProperty("--gutter", width)
      gutter.setAttribute(
        .style, "left: " + intToString(Int(codeRect.left - parentRect.left)) + "px; --gutter: " + width)
      gutter.replaceChildren(numbers)
      markCurrentLine(code)
      // Where its lines stand, for the stretches painted (`paintWindow`).
      if let editor = editors.first(where: { $0.code.id == code.id }) {
        editor.lineStarts = tops.count == offsets.count ? offsets : []
        editor.lineTops = tops.count == offsets.count ? tops : []
        repaint(editor)
      }
    }

    nonisolated(unsafe) static var listensToSelection = false

    /// The caret's logical line marked (`.code-current-line`, its gutter
    /// number `data-current`): from the line's first character to the
    /// next line's (or the text's end), every row it wraps to; hidden
    /// unless the editor has the focus and the selection is within one
    /// line. Read from the selection, as the caret moves however it moves.
    static func markCurrentLine(_ code: DOM.Element) {
      guard let view = code.parentElement, let gutter = view.querySelector(".code-gutter-lines") else { return }
      func hide() {
        if view.hasAttribute(data("current-line")) { view.removeAttribute(data("current-line")) }
      }
      guard stringEquals(code.getAttribute(data("focused")) ?? "", "true"), let selection = window.getSelection(),
        selection.rangeCount > 0, let focus = selection.focusNode, let anchor = selection.anchorNode,
        code.contains(focus), code.contains(anchor)
      else { return hide() }
      /// The logical line a point of the text is on: the line breaks before it.
      func line(_ node: DOM.Node, _ offset: Int) -> Int {
        let before = document.createRange()
        before.setStart(code, 0)
        before.setEnd(node, offset)
        var breaks = 0
        for byte in before.toString().utf8 where byte == 0x0A { breaks += 1 }
        return breaks
      }
      let current = line(focus, selection.focusOffset)
      guard selection.isCollapsed || line(anchor, selection.anchorOffset) == current else { return hide() }
      let numbers = gutter.querySelectorAll(":scope > span")
      guard current < numbers.count, let codeRect = code.getBoundingClientRect(),
        let viewRect = view.getBoundingClientRect()
      else { return hide() }
      let top = parseDouble(numbers[current].getAttribute(data("top")) ?? "") ?? 0
      let bottom =
        current + 1 < numbers.count
        ? parseDouble(numbers[current + 1].getAttribute(data("top")) ?? "") ?? top
        : codeRect.bottom - viewRect.top
      var band = view.querySelector(":scope > .code-current-line")
      if band == nil, let first = view.firstChild {
        let made = document.createElement(.div)
        made.className = "code-current-line"
        made.setAttribute("aria-hidden", "true")
        view.insertBefore(made, first)
        band = made
      }
      band?.setAttribute(.style, "top: " + doubleToString(top) + "px; height: " + doubleToString(bottom - top) + "px")
      for (index, number) in numbers.enumerated() {
        if index == current {
          number.setAttribute(data("current"), "true")
        } else if number.hasAttribute(data("current")) {
          number.removeAttribute(data("current"))
        }
      }
      view.setAttribute(data("current-line"), "true")
    }

    /// Colors an editor's text the first time it has a box on screen.
    public static func colorIfVisible(_ code: DOM.Element) {
      guard let rect = code.getBoundingClientRect(), rect.height > 0 else { return }
      // Its numbers as it is laid out now: shown, or the pane resized.
      if code.hasAttribute("data-code-lined") { number(code) }
      guard let editor = editors.first(where: { $0.code.id == code.id }), !editor.colored else { return }
      color(editor)
    }

    nonisolated(unsafe) static var listensToResize = false
    nonisolated(unsafe) static var listensToScroll = false
    nonisolated(unsafe) static var scrollPending = false

    /// Lined text typed into: its numbers measured again beside it once
    /// typing pauses, for a line the typing wrapped anew. A line added or
    /// removed is numbered at once (the input's own listener).
    private static func schedule(_ editor: Editor) {
      guard editor.code.hasAttribute("data-code-lined") else { return }
      if editor.timer != 0 { window.clearTimeout(editor.timer) }
      editor.timer = window.setTimeout(150) {
        editor.timer = 0
        number(editor.code)
      }
    }

    /// The editor's stretches found again over its text nodes as they now
    /// stand. The whole text is read again—a comment or CDATA opened or
    /// closed recolors all it reaches—but only the stretches on and near
    /// the lines on screen have ranges and are painted, and of those only
    /// the ones an edit touched are set anew: those before it keep their
    /// ranges, and those after it too, which the browser moved with the
    /// text as it was typed into. An edit across text nodes (a paste over
    /// lines, a selection deleted), or a range the browser did not carry,
    /// sets the painted ones anew.
    static func color(_ editor: Editor) {
      var nodes: [(node: DOM.Text, start: Int, end: Int)] = []
      var bytes: [UInt8] = []
      var units = 0
      let walker = document.createTreeWalker(editor.code, DOM.NodeFilter.SHOW_TEXT)
      while let next = walker.nextNode() {
        guard let node = next as? DOM.Text else { continue }
        let text = node.data
        var length = 0
        for byte in text.utf8 where byte & 0xC0 != 0x80 { length += byte >= 0xF0 ? 2 : 1 }
        bytes.append(contentsOf: text.utf8)
        nodes.append((node, units, units + length))
        units += length
      }
      let tokens = CodeSyntax.tokens(bytes, language: editor.language)
      editor.nodes = nodes

      var carried = false
      if editor.colored, nodes.count == editor.nodeCount, let edit = edited(old: editor.bytes, new: bytes) {
        let start = unitCount(in: bytes, upTo: edit.prefix)
        let oldEnd = unitCount(in: editor.bytes, upTo: editor.bytes.count - edit.suffix)
        let newEnd = unitCount(in: bytes, upTo: bytes.count - edit.suffix)
        let delta = newEnd - oldEnd
        // Within one text node, before and after.
        if let first = place(start, opening: true, in: nodes), let last = place(newEnd, opening: false, in: nodes),
          first.0.id == last.0.id
        {
          let old = editor.tokens
          var head = 0
          while head < old.count, head < tokens.count, old[head] == tokens[head], old[head].end <= start { head += 1 }
          var oldTail = old.count
          var newTail = tokens.count
          while oldTail > head, newTail > head {
            let a = old[oldTail - 1]
            let b = tokens[newTail - 1]
            guard a.start >= oldEnd, a.kind == b.kind, a.start + delta == b.start, a.end + delta == b.end else { break }
            oldTail -= 1
            newTail -= 1
          }
          let shift = (newTail - head) - (oldTail - head)
          // The painted ranges carried: those before the edit as they are,
          // those after it under their new places, the edit's own out.
          var live: [Int: DOM.Range] = [:]
          var gone: [(CodeSyntax.Token, DOM.Range)] = []
          var check: (index: Int, range: DOM.Range)?
          for (index, range) in editor.live {
            if index < head {
              live[index] = range
            } else if index >= oldTail {
              live[index + shift] = range
              if check == nil || index + shift < check!.index { check = (index + shift, range) }
            } else {
              gone.append((old[index], range))
            }
          }
          // The first range kept after the edit still covers its token.
          var sound = true
          if let check, check.index < tokens.count {
            let token = tokens[check.index]
            sound = Array(check.range.toString().utf16).count == token.end - token.start
          }
          if sound {
            if editor.shown { paint(removing: gone, adding: []) }
            editor.tokens = tokens
            editor.live = live
            carried = true
          }
        }
      }
      if !carried {
        // Every painted range set anew.
        if editor.shown {
          var gone: [(CodeSyntax.Token, DOM.Range)] = []
          for (index, range) in editor.live where index < editor.tokens.count { gone.append((editor.tokens[index], range)) }
          paint(removing: gone, adding: [])
        }
        editor.tokens = tokens
        editor.live = [:]
      }
      editor.bytes = bytes
      editor.nodeCount = nodes.count
      editor.colored = true
      // Colored because it is on screen: painted.
      editor.shown = true
      repaint(editor)
    }

    /// The node a point stands in, and its place there: a point at a
    /// node's end is in it (a stretch's end), unless it opens the next.
    static func place(_ offset: Int, opening: Bool, in nodes: [(node: DOM.Text, start: Int, end: Int)]) -> (DOM.Text, Int)? {
      var low = 0
      var high = nodes.count
      while low < high {
        let middle = (low + high) / 2
        if opening ? offset >= nodes[middle].end : offset > nodes[middle].end { low = middle + 1 } else { high = middle }
      }
      guard low < nodes.count else { return nil }
      return (nodes[low].node, offset - nodes[low].start)
    }

    /// The stretches of an editor on screen painted for the lines the pane
    /// shows and a little either side (`paintWindow`), each given its range
    /// as it comes into view; the rest taken out, their ranges let go.
    static func repaint(_ editor: Editor) {
      // Read-only text keeps what it painted: what the screen shows now
      // painted, if it is not yet.
      if editor.input == nil {
        paintNear(editor)
        return
      }
      // Text whose lines were never measured is painted whole, once: a
      // scroll over it changes nothing, and walking its every stretch each
      // frame (a session's Raw holds tens of thousands) stalled the scroll.
      if editor.shown, editor.lineTops.isEmpty, editor.live.count == editor.tokens.count { return }
      let want = editor.shown ? paintWindow(editor) : []
      var wanted = Set<Int>()
      for index in want { wanted.insert(index) }
      var removing: [(CodeSyntax.Token, DOM.Range)] = []
      var adding: [(CodeSyntax.Token, DOM.Range)] = []
      for (index, range) in editor.live where !wanted.contains(index) {
        if index < editor.tokens.count { removing.append((editor.tokens[index], range)) }
        editor.live[index] = nil
      }
      for index in want where editor.live[index] == nil {
        let token = editor.tokens[index]
        guard let start = place(token.start, opening: true, in: editor.nodes),
          let end = place(token.end, opening: false, in: editor.nodes)
        else { continue }
        let range = document.createRange()
        range.setStart(start.0, start.1)
        range.setEnd(end.0, end.1)
        editor.live[index] = range
        adding.append((token, range))
      }
      paint(removing: removing, adding: adding)
    }

    /// The stretches the pane shows, and a little round them: on the lines
    /// it shows, and of those lines the columns it shows (user,
    /// 2026-10-15)—a page's lines run far past the pane's edge. All of them
    /// for text whose lines were never measured; every column where lines
    /// wrap (Reflow).
    static func paintWindow(_ editor: Editor) -> [Int] {
      let all = Array(0..<editor.tokens.count)
      guard !editor.lineTops.isEmpty, editor.lineTops.count == editor.lineStarts.count,
        let view = editor.code.parentElement, let viewRect = view.getBoundingClientRect()
      else { return all }
      let scroller = editor.code.closest(".artifact-markup")
      let pane = scroller?.getBoundingClientRect()
      let height = window.innerHeight
      let top = max(pane?.top ?? 0, 0) - viewRect.top
      let bottom = min(pane?.bottom ?? height, height) - viewRect.top
      // A little either side, so a scroll shows color before it is
      // repainted the next frame.
      let reach = 120.0
      var first = 0
      while first + 1 < editor.lineTops.count, editor.lineTops[first + 1] < top - reach { first += 1 }
      var last = first
      while last + 1 < editor.lineTops.count, editor.lineTops[last + 1] <= bottom + reach { last += 1 }
      let from = editor.lineStarts[first]
      let to = last + 1 < editor.lineStarts.count ? editor.lineStarts[last + 1] : Int.max
      // The first stretch ending after `from`, and the first starting at or after `to`.
      var low = 0
      var high = editor.tokens.count
      while low < high {
        let middle = (low + high) / 2
        if editor.tokens[middle].end <= from { low = middle + 1 } else { high = middle }
      }
      let start = low
      high = editor.tokens.count
      while low < high {
        let middle = (low + high) / 2
        if editor.tokens[middle].start < to { low = middle + 1 } else { high = middle }
      }
      let lines = start..<max(start, low)
      // The columns the pane shows, where lines do not wrap.
      let wraps = editor.code.closest("[data-reflow='true']") != nil
      guard !wraps, let codeRect = editor.code.getBoundingClientRect(), let width = charWidth(editor), width > 0
      else { return Array(lines) }
      let gutter = parseDouble(stringRemoveSuffix(window.getComputedStyle(editor.code).getPropertyValue("padding-inline-start"), "px")) ?? 0
      let textLeft = codeRect.left + gutter
      let left = max(pane?.left ?? 0, 0)
      let right = min(pane?.right ?? window.innerWidth, window.innerWidth)
      let margin = 20
      let firstColumn = Int((left - textLeft) / width) - margin
      let lastColumn = Int((right - textLeft) / width) + 1 + margin
      var shown: [Int] = []
      var line = first
      for index in lines {
        let token = editor.tokens[index]
        while line + 1 < editor.lineStarts.count, editor.lineStarts[line + 1] <= token.start { line += 1 }
        let column = token.start - editor.lineStarts[line]
        let length = token.end - token.start
        if column + length >= firstColumn && column <= lastColumn { shown.append(index) }
      }
      return shown
    }

    /// One character's width in the editor's text, measured once.
    static func charWidth(_ editor: Editor) -> Double? {
      if editor.charWidth > 0 { return editor.charWidth }
      for (node, _, _) in editor.nodes {
        var offset = 0
        for unit in node.data.utf16 {
          if unit != 0x0A && unit != 0x09 && unit != 0x20 {
            let range = document.createRange()
            range.setStart(node, offset)
            range.setEnd(node, offset + 1)
            guard let rect = range.getBoundingClientRect(), rect.width > 0 else { return nil }
            editor.charWidth = rect.width
            return rect.width
          }
          offset += 1
          if offset > 64 { break }
        }
      }
      return nil
    }

    /// Each colored editor painted while it has a box on screen, for the
    /// lines its pane shows, and taken out of the highlights while it has
    /// none (a page turned away); read-only text keeps its paint, and has
    /// what the screen shows painted, if it is not yet (`paintNear`).
    public static func paintVisible() {
      for editor in editors where editor.colored {
        if editor.input == nil {
          paintNear(editor)
          continue
        }
        editor.shown = (editor.code.getBoundingClientRect()?.height ?? 0) > 0
        repaint(editor)
      }
    }

    /// Where two texts differ: how many bytes they share at the start and,
    /// apart from those, at the end. Nil when they are the same.
    static func edited(old: [UInt8], new: [UInt8]) -> (prefix: Int, suffix: Int)? {
      guard old != new else { return nil }
      let shortest = min(old.count, new.count)
      var prefix = 0
      while prefix < shortest, old[prefix] == new[prefix] { prefix += 1 }
      // Never inside a character: back to its first byte.
      while prefix > 0, prefix < new.count, new[prefix] & 0xC0 == 0x80 { prefix -= 1 }
      var suffix = 0
      while suffix < shortest - prefix, old[old.count - 1 - suffix] == new[new.count - 1 - suffix] { suffix += 1 }
      while suffix > 0, new.count - suffix < new.count, new[new.count - suffix] & 0xC0 == 0x80 { suffix -= 1 }
      return (prefix, suffix)
    }

    /// The UTF-16 units of `bytes`' first `count` bytes.
    static func unitCount(in bytes: [UInt8], upTo count: Int) -> Int {
      var units = 0
      for byte in bytes[0..<count] where byte & 0xC0 != 0x80 { units += byte >= 0xF0 ? 2 : 1 }
      return units
    }

    /// Stretches out of their kinds' highlights and stretches into them;
    /// every other block's stay as they are.
    private static func paint(
      removing old: [(CodeSyntax.Token, DOM.Range)], adding new: [(CodeSyntax.Token, DOM.Range)]
    ) {
      registerHighlights()
      for (token, range) in old { highlights[token.kind.rawValue].delete(range) }
      for (token, range) in new { highlights[token.kind.rawValue].add(range) }
    }

    /// The same, for read-only text's `StaticRange`s.
    private static func paintStill(
      removing old: [(CodeSyntax.Token, DOM.StaticRange)], adding new: [(CodeSyntax.Token, DOM.StaticRange)]
    ) {
      registerHighlights()
      for (token, range) in old { highlights[token.kind.rawValue].delete(range) }
      for (token, range) in new { highlights[token.kind.rawValue].add(range) }
    }

    /// One highlight a kind, registered the first time anything is painted.
    private static func registerHighlights() {
      guard highlights.isEmpty else { return }
      for kind in CodeSyntax.Kind.allCases {
        let highlight = Highlight()
        CSS.highlights.set(kind.highlightName, highlight)
        highlights.append(highlight)
      }
    }
  }
#endif
