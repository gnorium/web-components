#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DOMBuilder
  import DesignTokens
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebTypes

  /// A rail: the thin line down beside something that folds—a thread's
  /// locution, a tree's node and every node under it—that a pointer folds
  /// and opens it by (user, 2026-10-16; a tree's nodes 2026-11-03).
  ///
  /// Its `reach` wide, its 1px line down its middle. Under the
  /// pointer the line goes from the subtle border color to the base one, its
  /// width unchanged. Where the line is its owner's to draw (a thread's, which
  /// runs on between its locutions), the rail draws its own only under the
  /// pointer (`Line.overlay`).
  ///
  /// Pointer-only: hidden from assistive technology and never focused—a
  /// `div`, not a button—so a click on it leaves focus nowhere hidden. Its
  /// owner places it and says what a click does; the keyboard folds the same
  /// thing by the owner's own control (an avatar, a chevron).
  public struct RailView: HTMLContent {
    /// Whose line the reader sees.
    public enum Line: String, Sendable {
      /// The rail's: drawn subtle, base under the pointer.
      case own
      /// Its owner's, drawn beneath it: the rail's line shows only under the
      /// pointer, over the owner's.
      case overlay
    }

    /// The rail's width: the stretch either side of its line the pointer
    /// finds it in.
    static let reach: CSS.Length = spacing16

    let line: Line
    let `class`: String

    public init(line: Line = .own, class: String = "") {
      self.line = line
      self.class = `class`
    }

    public func build() -> DOM.Node {
      div {
        span {}
          .class("rail-line")
      }
      .class(stringIsEmpty(`class`) ? "rail-view" : "rail-view \(`class`)")
      .ariaHidden(true)
      .data("rail-line", line.rawValue)
      .style {
        // Its owner positions it; relative until then, so its line has a
        // box to run down.
        selector("&") {
          position(.relative)
          display(.block)
          width(Self.reach)
          padding(0)
          margin(0)
          border(.none)
          backgroundColor(backgroundColorTransparent)
          cursor(.pointer)
        }
        // A 1px line half a step in, on a whole pixel: centered in an
        // even-width rail it would land on a half pixel and read thicker.
        descendant(".rail-line") {
          position(.absolute)
          insetInlineStart(spacing8)
          insetBlockStart(0)
          insetBlockEnd(0)
          width(borderWidthBase)
        }
        selector("&[data-rail-line='own'] .rail-line") {
          backgroundColor(borderColorSubtle)
        }
        // Under the pointer, subtle to base, its width unchanged (user,
        // 2026-10-16).
        selector("&:hover .rail-line") {
          backgroundColor(borderColorBase)
        }
      }
      .build()
    }
  }
#endif
