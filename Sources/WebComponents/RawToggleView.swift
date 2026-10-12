#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The switch between a text and the code it was made from: an icon
  /// alone, named "Raw" (user, 2026-10-12)—a reader's footer, a
  /// locution's. The icon says the code's format: `</>` for TEI/XML, the
  /// Markdown mark for Markdown. A toggle (ToggleButtonView), pressed
  /// while the code shows; its host listens for its `toggle-button-update`.
  public struct RawToggleView: HTMLContent {
    /// The format of the code Raw reveals.
    public enum Source: Sendable {
      /// TEI or other XML: a transcription's markup, a definition's sense.
      case xml
      /// Markdown: a locution's body, a session's prompts and replies.
      case markdown
    }

    let source: Source
    let pressed: Bool
    let disabled: Bool
    let `class`: String

    public init(source: Source, pressed: Bool = false, disabled: Bool = false, class: String = "") {
      self.source = source
      self.pressed = pressed
      self.disabled = disabled
      self.class = `class`
    }

    public func build() -> DOM.Node {
      ToggleButtonView(
        label: "Raw",
        icon: source == .xml
          ? IconView(icon: { s in LucideCodeXmlIconView(size: s) }, size: sizeIconSmall)
          : IconView(icon: { s in MarkdownIconView(size: s) }, size: sizeIconSmall),
        modelValue: pressed,
        // Subtle, its border showing, as the reactions button beside it
        // in a locution's footer (user, 2026-10-12).
        weight: .subtle,
        buttonColor: .gray,
        disabled: disabled,
        iconOnly: true,
        ariaLabel: "Raw",
        size: .medium,
        class: `class`.isEmpty ? "raw-toggle-view" : "raw-toggle-view \(`class`)"
      )
      .build()
    }
  }
#endif
