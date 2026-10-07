import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DiffEngine
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

#if SERVER
  import Foundation
  import XMLUtilities
#endif

/// What changed, under the thing that changed: a field's old value against
/// its new one, a text's or a page's old lines against its new ones.
///
/// The thing edited shows its new value, clean, framed in orange. This says
/// how it changed, under the label "Diff:", in the subtle text color with
/// the characters that changed colored—red where they were, green where
/// they are—and nothing given a background. No mark is drawn on the text:
/// real text is itself underlined and struck through, so a mark of that kind
/// could not be told from the text.
///
/// Two shapes, by how much there is to show:
///
/// - **A line**—`text`, `outline`, `choice`, `check`—sits where a field's diff
///   line has always sat, under the field: "Diff: old → new". Each kind of
///   value is compared by its own unit, which the caller names: a text word
///   by word, then letter by letter inside a changed word; an outline number
///   level by level, by position; a choice—a dropdown's, a date part's—whole; a checkbox's as one tick, green ticked, red unticked. A value
///   put where there was none is the new one alone, green; one cleared is
///   the old one alone, red.
/// - **A box**—`passage`, `code`, `rendered`—holds the changed lines with a
///   little context, marked by their gutter as a unified diff marks them—"−"
///   for a line taken out, "+" for one put in—in a field's own frame,
///   scrolled once it is taller than a reader's pane. A long line wraps under
///   its own text, the gutter beside it. The gutter and the pairing of the
///   lines carry the meaning, and the color only says exactly where.
///
/// `text`, `outline`, `choice` and `passage` are built in the browser too, as
/// a field is edited; `code` and `rendered` are drawn by the server.
public struct DiffView: HTMLContent {
  public enum Mode: Sendable {
    /// A one-line text's old value against its new one: word by word, then
    /// letter by letter inside a word that changed.
    case text(old: String, new: String)
    /// An outline number's old value against its new one—1.2 → 2.3—level
    /// by level, by position: a level is kept or changed whole.
    case outline(old: String, new: String)
    /// A choice's old value against its new one, whole: a dropdown's, a
    /// date's—a character diff of two option names says nothing their
    /// names do not.
    case choice(old: String, new: String)
    /// A checkbox's change: one ticked box, ☑︎, green where the box was
    /// ticked, red where it was unticked. "Checked → Not checked" says in four words
    /// what the color of one mark says.
    case check(ticked: Bool)
    /// A multi-line text's old value against its new one, line by line.
    case passage(old: String, new: String)
    #if SERVER
      /// Source text, monospaced and uncolored: it is the past, and syntax
      /// color would compete with the live source above it.
      case code(old: String, new: String)
      /// Rendered text as it reads, each line drawn with its formatting, so a
      /// line that changed only how it is set shows the difference itself.
      /// `new` is nil when the new text cannot be rendered—its markup broken
      /// mid-edit.
      case rendered(old: [DiffEngine.RenderedLine], new: [DiffEngine.RenderedLine]?)
    #endif
  }

  let mode: Mode
  let showAllLines: Bool
  /// What stands before it: "Diff:" unless a page says otherwise. Empty
  /// draws none.
  let label: String
  let `class`: String

  /// The one label every diff is given, a line's and a box's alike.
  public static let defaultLabel = "Diff:"

  public init(_ mode: Mode, label: String = DiffView.defaultLabel, class: String = "", showAllLines: Bool = false) {
    self.mode = mode
    self.showAllLines = showAllLines
    self.label = label
    self.`class` = `class`
  }

  /// A page that builds one in the browser links its sheet here, while the
  /// server renders it.
  public static func preloadStyleSheet() {
    _ = DiffView(.text(old: "", new: "")).build()
  }

  public func build() -> DOM.Node {
    // A line's text as the pair it belongs to split it: the changed stretches
    // colored by the row they sit in, white space among them made visible.
    func segmentNodes(_ segments: [DiffSegment]) -> [DOM.Node] {
      segments.map { segment -> DOM.Node in
        switch segment {
        case .unchanged(let text):
          return DOM.Text(text)
        case .changed(let text):
          return span { Self.visible(text) }
            .class("diff-changed")
            .build()
        }
      }
    }

    // A diff's lines, context and changes, in runs with a gap between.
    func rows<C: Sendable>(
      _ hunks: [[DiffEngine.Line<C>]],
      @HTMLBuilder content: (DiffEngine.Line<C>) -> [DOM.Node]
    ) -> DOM.Node {
      div {
        if hunks.isEmpty {
          p { "No diff." }
            .class("diff-note")
        }
        for (index, hunk) in hunks.enumerated() {
          if index > 0 {
            div { "⋯" }
              .class("diff-gap")
              .ariaHidden(true)
          }
          for line in hunk {
            div {
              span {
                switch line.kind {
                case .unchanged: " "
                case .removed: "−"
                case .inserted: "+"
                }
              }
              .class("diff-sign")
              .ariaHidden(true)
              span { content(line) }
                .class("diff-content")
                .dir("auto")
            }
            .class("diff-row")
            .data(
              "diff-line",
              {
                switch line.kind {
                case .unchanged: return "unchanged"
                case .removed: return "removed"
                case .inserted: return "inserted"
                }
              }())
          }
        }
      }
      .class("diff-lines")
      .build()
    }

    let isLine: Bool
    let modeName: String
    let body: DOM.Node
    switch mode {
    case .text(let old, let new), .outline(let old, let new):
      isLine = true
      let pair: (old: [DiffSegment], new: [DiffSegment])
      if case .outline = mode {
        modeName = "outline"
        pair = DiffEngine.outline(old: old, new: new)
      } else {
        modeName = "text"
        pair = DiffEngine.refine(old: old, new: new)
      }
      body = span {
        if !stringIsEmpty(old) {
          span { segmentNodes(stringIsEmpty(new) ? [.changed(old)] : pair.old) }
            .class("diff-old")
            .dir("auto")
        }
        if !stringIsEmpty(old) && !stringIsEmpty(new) {
          span { "→" }
            .class("diff-arrow")
            .ariaHidden(true)
        }
        if !stringIsEmpty(new) {
          span { segmentNodes(stringIsEmpty(old) ? [.changed(new)] : pair.new) }
            .class("diff-new")
            .dir("auto")
        }
      }
      .class("diff-content")
      .build()
    case .choice(let old, let new):
      isLine = true
      modeName = "choice"
      body = span {
        if !stringIsEmpty(old) {
          span { span { old }.class("diff-changed") }
            .class("diff-old")
            .dir("auto")
        }
        if !stringIsEmpty(old) && !stringIsEmpty(new) {
          span { "→" }
            .class("diff-arrow")
            .ariaHidden(true)
        }
        if !stringIsEmpty(new) {
          span { span { new }.class("diff-changed") }
            .class("diff-new")
            .dir("auto")
        }
      }
      .class("diff-content")
      .build()
    case .check(let ticked):
      isLine = true
      modeName = "check"
      body = span {
        span {
          // The ballot box with check, held to its text form by U+FE0E: a
          // color emoji would ignore the green and the red.
          span { "\u{2611}\u{FE0E}" }
            .class("diff-changed")
            .ariaHidden(true)
          span { ticked ? "Ticked" : "Unticked" }
            .class("diff-visually-hidden")
        }
        .class(ticked ? "diff-new" : "diff-old")
        .title(ticked ? "Ticked" : "Unticked")
      }
      .class("diff-content")
      .build()
    case .passage(let old, let new):
      isLine = false
      modeName = "passage"
      body = rows(DiffEngine.hunks(DiffEngine.lines(old: old, new: new), context: 2)) { line in
        segmentNodes(line.segments)
      }
    #if SERVER
      case .code(let old, let new):
        isLine = false
        modeName = "code"
        let lines = DiffEngine.lines(old: old, new: new)
        body = rows(showAllLines ? [lines] : DiffEngine.hunks(lines, context: 3)) { line in
          segmentNodes(line.segments)
        }
      case .rendered(let old, let new):
        isLine = false
        modeName = "rendered"
        if let new {
          body = rows(DiffEngine.hunks(DiffEngine.lines(old: old, new: new), context: 2)) { line in
            // Which characters of the line changed, one flag a character, so
            // each run can be split where the change starts and ends and keep
            // its own setting either side.
            let flags: [Bool] = line.segments.flatMap { segment -> [Bool] in
              switch segment {
              case .unchanged(let text): return [Bool](repeating: false, count: text.unicodeScalars.count)
              case .changed(let text): return [Bool](repeating: true, count: text.unicodeScalars.count)
              }
            }
            let starts = line.content.tokens.reduce(into: [0]) { $0.append($0.last! + $1.text.unicodeScalars.count) }
            let regionChanged: Bool = {
              if case .region? = line.note { return true }
              return false
            }()
            // One parted from its pair by the kind of break before it shows
            // the break; a look-alike says which characters on hover.
            if case .breakKind? = line.note {
              span { line.content.opensBlock ? "¶ " : "↵ " }
                .class("diff-break")
                .title(line.content.opensBlock ? "Paragraph break" : "Line break")
            }
            span {
              for (index, token) in line.content.tokens.enumerated() {
                let own = Array(flags[min(starts[index], flags.count)..<min(starts[index + 1], flags.count)])
                switch token.kind {
                case .text:
                  for run in Self.runs(token.text, own) {
                    if run.changed {
                      span { Self.visible(run.text) }
                        .class("diff-changed")
                        .data("style", token.style.joined(separator: " "))
                        .title(Self.title(of: line, run.text))
                    } else {
                      span { run.text }
                        .data("style", token.style.joined(separator: " "))
                    }
                  }
                case .formula:
                  // A formula is compared whole (its MathML, `TEIMath.markup`),
                  // drawn as the page draws it, and colored whole.
                  if let formula = TEIRenderer.math(markup: token.text) {
                    if own.contains(true) {
                      span { TEIMathView(formula) }
                        .class("diff-changed")
                    } else {
                      TEIMathView(formula)
                    }
                  }
                case .figure:
                  span {
                    if regionChanged {
                      "[Figure: \(token.text)—region changed]"
                    } else {
                      token.text.isEmpty ? "[Figure]" : "[Figure: \(token.text)]"
                    }
                  }
                  .class(own.contains(true) || regionChanged ? "diff-figure diff-changed" : "diff-figure")
                }
              }
            }
            .data("role", line.content.role)
          }
        } else {
          body = p { "Fix the markup to see the rendered diff." }
            .class("diff-note")
            .build()
        }
    #endif
    }

    let rootClass = stringIsEmpty(`class`) ? "diff-view" : stringJoin(["diff-view", `class`], separator: " ")
    return div {
      if !stringIsEmpty(label) {
        span { label }
          .class("diff-label")
      }
      if isLine {
        body
      } else {
        div { body }
          .class("diff-box")
      }
    }
    .class(rootClass)
    .data("shape", isLine ? "line" : "box")
    .data("diff-mode", modeName)
    .style {
      selector("&") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeXSmall12)
        lineHeight(lineHeightXSmall20)
        color(colorSubtle)
        minWidth(0)
      }
      // Where a field's diff line has always been: under the field,
      // indented to its text. Spaced by gaps alone: the label from its
      // values here, the line from what stands above it by the column that
      // holds it.
      selector("&[data-shape='line']") {
        display(.flex)
        flexWrap(.wrap)
        alignItems(.baseline)
        columnGap(spacing4)
        paddingInlineStart(spacing16)
        overflowWrap(.anywhere)
      }
      // The values beside the label, old → new flowing as a line of text
      // does, a long one wrapping under its own start.
      selector("&[data-shape='line'] > .diff-content") {
        flex(1, 1, px(0))
      }
      selector("&[data-shape='box']") {
        display(.flex)
        flexDirection(.column)
        alignItems(.stretch)
        gap(spacing4)
      }
      // A field's own frame, as tall as a reader's pane at most, then
      // scrolled.
      descendant(".diff-box") {
        border(borderWidthBase, .solid, borderColorBase)
        borderRadius(borderRadiusBase)
        padding(spacing8, spacing12)
        maxHeight(size256)
        overflow(.auto)
        minWidth(0)
      }
      descendant(".diff-lines") {
        display(.flex)
        flexDirection(.column)
        minWidth(0)
      }
      descendant(".diff-row") {
        display(.flex)
        alignItems(.baseline)
        gap(spacing8)
        minHeight(lineHeightXSmall20)
      }
      // A box of lines gives its sides' inset to each line, so a changed
      // line's tint runs from edge to edge.
      selector("& .diff-box:has(> .diff-lines)") {
        paddingInline(0)
      }
      selector("& .diff-box > .diff-lines > .diff-row") {
        paddingInline(spacing12)
      }
      descendant(".diff-sign") {
        flexShrink(0)
        width(ch(1))
        whiteSpace(.pre)
        userSelect(.none)
      }
      descendant(".diff-content") {
        minWidth(0)
        whiteSpace(.preWrap)
        overflowWrap(.anywhere)
      }
      descendant(".diff-gap") {
        paddingInlineStart(calc(ch(1) + spacing8))
        userSelect(.none)
      }
      // What the tick says, for a reader who does not see its color.
      descendant(".diff-visually-hidden") {
        position(.absolute)
        width(px(1))
        height(px(1))
        overflow(.hidden)
        clip(rect(px(0), px(0), px(0), px(0)))
        whiteSpace(.nowrap)
      }
      descendant(".diff-note") {
        fontStyle(.italic)
        margin(0)
      }
      // A changed line reads in the base color on its subtle tint, red
      // where it was, green where it is; the characters that changed in it
      // stand out on the solid red or green, inverted (user, 2026-10-08).
      // The same tokens as everywhere: no colors of the diff's own.
      selector("& .diff-row[data-diff-line='removed']") {
        backgroundColor(backgroundColorRedSubtle)
        color(colorBase)
      }
      selector("& .diff-row[data-diff-line='inserted']") {
        backgroundColor(backgroundColorGreenSubtle)
        color(colorBase)
      }
      selector("& .diff-row[data-diff-line='removed'] .diff-changed", "& .diff-old .diff-changed") {
        backgroundColor(backgroundColorRed)
        color(colorInvertedFixed)
        borderRadius(borderRadiusMinimal)
        webkitBoxDecorationBreak(.clone)
        boxDecorationBreak(.clone)
      }
      selector("& .diff-row[data-diff-line='inserted'] .diff-changed", "& .diff-new .diff-changed") {
        backgroundColor(backgroundColorGreen)
        color(colorInvertedFixed)
        borderRadius(borderRadiusMinimal)
        webkitBoxDecorationBreak(.clone)
        boxDecorationBreak(.clone)
      }
      // From the old to the new, in the direction the line reads: the
      // arrow's own box holds the space either side of it, so it wraps
      // with the text it sits in.
      descendant(".diff-arrow") {
        display(.inlineBlock)
        paddingInline(spacing4)
      }
      descendant(".diff-arrow:dir(rtl)") {
        transform(scaleX(-1))
      }

      // Code: as it is written, monospaced, its indentation kept.
      selector("&[data-diff-mode='code'] .diff-box") {
        fontFamily(typographyFontMono)
      }

      // Rendered: the reading's own type, each line set as it reads.
      selector("&[data-diff-mode='rendered'] .diff-box") {
        fontFamily(typographyFontSerif)
        fontSize(fontSizeSmall14)
        lineHeight(lineHeightMedium26)
      }
      selector("&[data-diff-mode='rendered'] .diff-row") {
        minHeight(lineHeightMedium26)
      }
      selector("&[data-diff-mode='rendered'] .diff-content") {
        whiteSpace(.normal)
      }
      selector("& [data-role='heading']", "& [data-role='speaker']") {
        fontWeight(fontWeightSemiBold)
      }
      descendant("[data-role='stage']") {
        fontStyle(.italic)
      }
      selector("& [data-role^='forme']", "& [data-role='page']", "& .diff-figure", "& .diff-break") {
        fontFamily(typographyFontSans)
        fontSize(fontSizeXSmall12)
      }
      descendant(".diff-figure") {
        fontStyle(.italic)
      }
      descendant("[data-style~='italic']") { fontStyle(.italic) }
      // A source's bold run, as transcribed: content, so it stays bold.
      descendant("[data-style~='bold']") { fontWeight(fontWeightBold) }
      descendant("[data-style~='underline']") { textDecoration(.underline) }
      descendant("[data-style~='smallcaps']") { CSS.Property("font-variant-caps", "small-caps") }
      descendant("[data-style~='sub']") {
        verticalAlign(.sub)
        fontSize(em(0.75))
        lineHeight(0)
      }
      descendant("[data-style~='sup']") {
        verticalAlign(.super)
        fontSize(em(0.75))
        lineHeight(0)
      }
    }
    .build()
  }
}

extension DiffView {
  /// White space that changed, made visible: a space is drawn as a middle
  /// dot, since a changed space is otherwise a change nobody can see.
  static func visible(_ text: String) -> String {
    guard DiffEngine.isSpace(text) else { return text }
    var bytes: [UInt8] = []
    for byte in text.utf8 {
      if byte == 0x20 {
        bytes.append(0xC2)
        bytes.append(0xB7)
      } else {
        bytes.append(byte)
      }
    }
    return String(decoding: bytes, as: UTF8.self)
  }
}

#if SERVER
  extension DiffView {
    /// A run of a token's text and whether it changed.
    struct Run {
      let text: String
      let changed: Bool
    }

    /// A token's text split where its characters' flags change.
    static func runs(_ text: String, _ flags: [Bool]) -> [Run] {
      var out: [Run] = []
      var current = ""
      var state = flags.first ?? false
      for (index, scalar) in text.unicodeScalars.enumerated() {
        let flag = index < flags.count ? flags[index] : false
        if flag != state && !current.isEmpty {
          out.append(Run(text: current, changed: state))
          current = ""
        }
        state = flag
        current.unicodeScalars.append(scalar)
      }
      if !current.isEmpty { out.append(Run(text: current, changed: state)) }
      return out
    }

    /// What a changed run says on hover: which characters a look-alike is,
    /// that only the spacing changed.
    static func title(of line: DiffEngine.Line<DiffEngine.RenderedLine>, _ text: String) -> String {
      switch line.note {
      case .lookalike?:
        return "Look-alike characters: "
          + text.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " ")
      case .spacing?: return "Spacing changed"
      default: return ""
      }
    }
  }
#endif

extension DiffView {
  /// The words a text's diff puts in and takes out, as a diffstat counts a
  /// field's size: its words alone—white space and punctuation count for
  /// nothing—compared as `text` compares them, byte for byte.
  public static func wordCount(old: String, new: String) -> (added: Int, removed: Int) {
    func words(_ text: String) -> [[UInt8]] {
      DiffEngine.tokens(text).compactMap { token -> [UInt8]? in
        guard let first = token.utf8.first else { return nil }
        switch first {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x5F, 0x80...0xFF: return Array(token.utf8)
        default: return nil
        }
      }
    }
    return count(DiffEngine.edits(old: words(old), new: words(new)))
  }

  /// The lines a passage's or a source's diff marks "+" and "−", as a
  /// diffstat counts them.
  public static func lineCount(old: String, new: String) -> (added: Int, removed: Int) {
    var added = 0
    var removed = 0
    for line in DiffEngine.lines(old: old, new: new) {
      switch line.kind {
      case .inserted: added += 1
      case .removed: removed += 1
      case .unchanged: break
      }
    }
    return (added, removed)
  }

  static func count(_ script: [DiffEngine.Edit]) -> (added: Int, removed: Int) {
    var added = 0
    var removed = 0
    for edit in script {
      switch edit {
      case .insert: added += 1
      case .delete: removed += 1
      case .keep: break
      }
    }
    return (added, removed)
  }
}
