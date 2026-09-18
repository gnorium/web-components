#if SERVER
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// The components the client can build for itself, registered so that every
  /// page carries their styles.
  ///
  /// A page links the stylesheets its *server* render asked for. That is the
  /// right rule for everything the server draws, and the wrong one for anything
  /// the client draws later: an alert raised by `AlertAPI` after the page has
  /// loaded, a card built by `AccordionFactory`, a tooltip. Nothing in the
  /// server render mentions them, so the page links no styles for them, and
  /// they arrive unstyled — which is how the sign-in form came to show a bare
  /// ✓ and an undecorated dismiss box.
  ///
  /// Pages used to fix this one at a time, by building a throwaway instance in
  /// `build()`. That put the burden on whoever wrote the page to know what the
  /// client might raise on it, and nothing failed when they did not: the page
  /// simply looked wrong in a state nobody had opened yet.
  ///
  /// So the knowledge lives here instead, once, and ``LayoutView`` registers
  /// the lot on every render. A component the client can construct is added to
  /// this list when it is written, not to each page that might see it.
  public enum ClientBuiltStyleSheets {
    /// Build one of each, purely to register. The markup is discarded; the
    /// registration is the point.
    public static func register() {
      _ = AlertView(color: .gray, inline: true, customIcon: "") { [] }.build()
      _ = AccordionView(id: "client-built-accordion") { [] } content: { [] }.build()
      _ = ButtonView(label: "Client built").build()
      _ = CheckboxView(id: "client-built-checkbox", name: "client-built") { [] }.build()
      _ = DropdownView(
        id: "client-built-dropdown", name: "client-built", label: "Client built", options: []
      ).build()
      _ = LabelView { [] }.build()
      _ = RadioView(id: "client-built-radio", name: "client-built", value: "one") { [] }.build()
      _ = RotatingSectorView(ariaHidden: true).build()
      _ = TextInputView(id: "client-built-text-input", name: "client-built").build()
      _ = TooltipView(tooltip: "Client built") { [] }.build()
      _ = AnimatedUpDownChevronView(id: "client-built-up-down-chevron").build()
      _ = AnimatedRightDownChevronView(id: "client-built-right-down-chevron").build()
    }
  }
#endif
