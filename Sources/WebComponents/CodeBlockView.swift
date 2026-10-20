#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  /// A fenced code block as rendered Markdown shows it, wherever Markdown is
  /// read—a session's output, a prompt (user, 2026-10-07): a header with
  /// the fence's language and a copy button over the code, highlighted.
  /// `MarkdownView` writes every fence as one; `CodeBlockHydration` binds
  /// its button and highlights it, and frames a fence the client rendered.
  public struct CodeBlockView: HTMLContent {
    let language: String
    /// The code, escaped already: the Markdown renderer's.
    let codeHTML: String

    public init(language: String, codeHTML: String) {
      self.language = language
      self.codeHTML = codeHTML
    }

    public func build() -> DOM.Node {
      div {
        div {
          span { language }
            .class("code-block-lang")
          button {
            span { CopyIconView(size: ButtonView.ButtonSize.medium.iconSize) }
              .class("copy-icon")
            span { CheckIconView(size: ButtonView.ButtonSize.medium.iconSize) }
              .class("success-icon")
          }
          .type(.button)
          .class("code-block-copy")
          .ariaLabel("Copy code")
        }
        .class("code-block-header")
        pre { code { HTMLText(content: codeHTML, isRaw: true) }.class("language-\(language)") }
      }
      .class("code-block-view")
      .style {
        selector("&") {
          width(perc(100))
          maxWidth(perc(100))
          alignSelf(.stretch)
          // Never squeezed by a capped flex column (a prompt's rendering
          // scrolls at 256): `overflow: hidden` drops a flex item's automatic
          // minimum height, so the frame shrank and clipped its body's
          // bottom padding. The column scrolls instead.
          flexShrink(0)
          boxSizing(.borderBox)
          margin(0)
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
          // Clip children to radius—otherwise a sharp `pre` fill paints over the corners.
          overflow(.hidden)
          backgroundColor(fill)
        }
        descendant(".code-block-header") {
          display(.flex)
          alignItems(.center)
          justifyContent(.spaceBetween)
          gap(spacing8)
          padding(spacing16)
          backgroundColor(backgroundColorNeutralSubtle)
          borderBottom(borderWidthBase, .solid, borderColorSubtle)
        }
        descendant(".code-block-lang") {
          fontFamily(typographyFontMono)
          fontSize(fontSizeMedium16)
          // Its own leading, never the prose's around the fence: a unitless
          // one set it at 19.5px under 16px Markdown.
          lineHeight(lineHeightSmall22)
          fontWeight(fontWeightSemiBold)
          color(colorSubtle)
          textTransform(.lowercase)
          letterSpacing(px(0.5))
          userSelect(.none)
        }
        descendant(".code-block-copy") {
          display(.flex)
          alignItems(.center)
          justifyContent(.center)
          flexShrink(0)
          // An icon-only medium control, as ButtonView's: a 40 square—the
          // header is furniture, as the markup pane's bars (user, 2026-10-10).
          width(ButtonView.ButtonSize.medium.minSize)
          height(ButtonView.ButtonSize.medium.minSize)
          padding(0)
          boxSizing(.borderBox)
          backgroundColor(.transparent)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          cursor(.pointer)
          color(colorSubtle)
          transition(.color, ms(200), .backgroundColor, ms(200))
        }
        selector("& .code-block-copy .copy-icon", "& .code-block-copy .success-icon") {
          display(.flex)
          alignItems(.center)
          pointerEvents(.none)
        }
        descendant(".code-block-copy .success-icon") {
          display(.none)
        }
        descendant(".code-block-copy.is-copied .copy-icon") {
          display(.none).important()
        }
        descendant(".code-block-copy.is-copied .success-icon") {
          display(.flex).important()
        }
        descendant(".code-block-copy:hover") {
          backgroundColor(backgroundColorInteractiveSubtleHover).important()
          color(colorBase).important()
        }
        descendant("pre") {
          margin(0).important()
          border(.none).important()
          borderRadius(0).important()
          padding(spacing16).important()
          backgroundColor(.transparent).important()
          maxWidth(perc(100))
          overflow(.visible)
        }
        descendant("pre code") {
          // A block, so its lines are its own 22: inline in the pre, the
          // pre's taller strut would set every line in standards mode.
          display(.block)
          backgroundColor(.transparent).important()
          padding(0).important()
          borderRadius(0)
          border(.none)
          fontFamily(typographyFontMono)
          // CodeEditorView's size: every code display reads at one size.
          fontSize(fontSizeMedium16)
          lineHeight(lineHeightSmall22)
          color(syntaxPlainText)
          // Wrap long TEI lines: `anywhere` split tag names (`<title` /
          // `Stmt>`), so break only where a token cannot fit the line.
          whiteSpace(.preWrap)
          overflowWrap(.breakWord)
          wordBreak(.normal)
          tabSize(4)
        }
        selector("& .hljs-keyword", "& .hljs-selector-tag") { color(syntaxKeywords).important() }
        selector("& .hljs-string", "& .hljs-doctag", "& .hljs-regexp", "& .hljs-meta .hljs-string") {
          color(syntaxStrings).important()
        }
        selector("& .hljs-subst") { color(syntaxPlainText).important() }
        selector("& .hljs-comment", "& .hljs-quote") {
          color(syntaxComments).important()
          fontStyle(.italic)
        }
        selector("& .hljs-number", "& .hljs-literal") { color(syntaxNumbers).important() }
        selector("& .hljs-type", "& .hljs-built_in") { color(syntaxTypeDeclarations).important() }
        selector("& .hljs-attr", "& .hljs-attribute") { color(syntaxAttributes).important() }
        selector("& .hljs-title.class_") { color(syntaxProjectClassNames).important() }
        selector("& .hljs-title.function_") { color(syntaxProjectFunctionAndMethodNames).important() }
        selector("& .hljs-params") { color(syntaxParamInternalName).important() }
        selector("& .hljs-meta") { color(syntaxProjectPreprocessorMacros).important() }
        // A tag's marks plain, its name a keyword, as `CodeSyntax` colors XML.
        selector("& .hljs-tag") { color(syntaxPlainText).important() }
        selector("& .hljs-name") { color(syntaxKeywords).important() }
        selector("& .hljs-punctuation") { color(syntaxPlainText).important() }
        selector("& .hljs-addition") { color(syntaxAddition).important() }
        selector("& .hljs-deletion") { color(syntaxDeletion).important() }
        selector("& .hljs-section", "& .hljs-bullet") { color(syntaxHeading).important() }
        selector("& .hljs-link", "& .hljs-symbol", "& .hljs-bullet") { color(syntaxUrls).important() }
      }
      .build()
    }
  }
#endif

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  /// Every code block under a node, live: a framed one (`CodeBlockView`)
  /// gets its copy button bound and its code highlighted, once; a bare fence
  /// the client rendered (a session's streamed output) is framed first. A
  /// Mermaid diagram is left as it is.
  public enum CodeBlockHydration {
    /// The page's framed blocks, bound. Only `hydrate(in:)` frames: a bare
    /// `<pre>` elsewhere (a transcript's Raw, a prompt's source) is no fence.
    public static func hydrateIfPresent() {
      for frame in document.querySelectorAll(".code-block-view") {
        if let pre = frame.querySelector("pre"), let button = frame.querySelector(".code-block-copy") {
          bind(button, pre: pre)
        }
      }
    }

    /// A container of rendered Markdown: its bare fences framed, every block bound.
    public static func hydrate(in container: DOM.Element) {
      for pre in container.querySelectorAll("pre") {
        if stringContains(pre.className, "mermaid") { continue }
        if let parent = pre.parentElement, stringContains(parent.className, "code-block-view") {
          if let button = parent.querySelector(".code-block-copy") { bind(button, pre: pre) }
          continue
        }

        let wrapper = document.createElement(.div)
        wrapper.classList.add("code-block-view")

        let header = document.createElement(.div)
        header.classList.add("code-block-header")

        let language = document.createElement(.span)
        language.classList.add("code-block-lang")
        language.textContent = fenceLanguage(of: pre)

        let button = document.createElement(.button)
        button.classList.add("code-block-copy")
        button.setAttribute("type", "button")
        button.setAttribute("aria-label", "Copy code")

        let copyIcon = document.createElement(.span)
        copyIcon.classList.add("copy-icon")
        copyIcon.appendChild(CopyIconFactory.createElement(size: ButtonView.ButtonSize.medium.iconSize))

        let successIcon = document.createElement(.span)
        successIcon.classList.add("success-icon")
        successIcon.appendChild(CheckIconFactory.createElement(size: ButtonView.ButtonSize.medium.iconSize))

        button.appendChild(copyIcon)
        button.appendChild(successIcon)
        header.appendChild(language)
        header.appendChild(button)

        pre.parentElement?.insertBefore(wrapper, pre)
        wrapper.appendChild(header)
        wrapper.appendChild(pre)

        bind(button, pre: pre)
      }
    }

    /// The blocks waiting to be highlighted, and the observer that waits
    /// for each to come near the screen, by its code's id.
    nonisolated(unsafe) static var waiting: [DOM.Element] = []
    nonisolated(unsafe) static var observers: [Int32: Int32] = [:]
    nonisolated(unsafe) static var pumping = false

    /// A block's code highlighted (highlight.js) before it can be seen, and
    /// never taken off again: now where it is on screen or within a screen
    /// of it; else once it comes within a screen (an `IntersectionObserver`
    /// whose margin is the screen's height) or in idle time, whichever is
    /// first. A page of a hundred blocks, or a stream committing one after
    /// another, never highlights them all in one task.
    public static func highlightSoon(_ code: DOM.Element) {
      guard !code.hasAttribute("data-highlighted") else { return }
      if isNear(code) {
        highlight(code)
        return
      }
      waiting.append(code)
      let margin = stringJoin([intToString(Int(window.innerHeight)), "px 0px"], separator: "")
      observers[code.id] = code.observeIntersection(rootMargin: margin) { near in
        if near { highlight(code) }
      }
      pump()
    }

    /// Whether `code` has a box on screen or within a screen of it.
    static func isNear(_ code: DOM.Element) -> Bool {
      guard let rect = code.getBoundingClientRect(), rect.height > 0 else { return false }
      let height = window.innerHeight
      return rect.bottom > -height && rect.top < 2 * height
    }

    /// The waiting blocks near the screen highlighted now: after a switch
    /// that shows them (Raw put away), before the frame draws them.
    public static func highlightNear() {
      for code in waiting where isNear(code) { highlight(code) }
    }

    /// `code` highlighted, once, and no longer waited for.
    static func highlight(_ code: DOM.Element) {
      if let handle = observers[code.id] {
        code.unobserveIntersection(handle)
        observers[code.id] = nil
      }
      waiting.removeAll { $0.id == code.id }
      guard !code.hasAttribute("data-highlighted") else { return }
      HighlightJS.highlightElement(elementID: code.id)
    }

    /// The rest highlighted in idle time, a block at a time while the
    /// period lasts.
    static func pump() {
      guard !pumping, !waiting.isEmpty else { return }
      pumping = true
      _ = window.requestIdleCallback { deadline in
        pumping = false
        // At least one a period, however long it takes: a block is
        // highlighted whole (highlight.js has no step).
        repeat {
          guard let code = waiting.first else { break }
          highlight(code)
        } while deadline.timeRemaining() > 0
        pump()
      }
    }

    /// A fence still being written, `delta` added at its end: each line it
    /// completes added colored (highlight.js, those lines alone), the line
    /// still open as plain text after them until its end comes. Only what
    /// was added is read, never the block again; what it held when it was
    /// drawn is highlighted once, at the first. Closed, the fence is drawn
    /// whole as a block of its own and highlighted whole.
    public static func append(_ delta: String, to code: DOM.Element) {
      let open = code.querySelector(":scope > .code-block-open-line")
      if open == nil, !code.hasAttribute("data-highlighted") {
        HighlightJS.highlightElement(elementID: code.id)
      }
      var pending = ""
      if let open { pending = open.textContent }
      let text = stringJoin([pending, delta], separator: "")
      let bytes = Array(text.utf8)
      var cut = bytes.count
      while cut > 0, bytes[cut - 1] != 0x0A { cut -= 1 }
      let rest = String(decoding: bytes[cut..<bytes.count], as: UTF8.self)
      if cut > 0 {
        let lines = String(decoding: bytes[0..<cut], as: UTF8.self)
        var language = "plaintext"
        if let pre = code.parentElement { language = fenceLanguage(of: pre) }
        let html = HighlightJS.highlight(lines, language: language)
        if let open {
          open.insertAdjacentHTML(.beforebegin, html)
        } else {
          code.insertAdjacentHTML(.beforeend, html)
        }
      }
      if let open {
        open.textContent = rest
      } else if !stringIsEmpty(rest) {
        let line = document.createElement(.span)
        line.className = "code-block-open-line"
        line.textContent = rest
        code.appendChild(line)
      }
    }

    /// The fence's language (`language-…` on its code), "text" for none.
    private static func fenceLanguage(of pre: DOM.Element) -> String {
      guard let code = pre.querySelector("code") else { return "text" }
      let names = code.className
      guard let index = stringIndexOf(names, "language-") else { return "text" }
      var language = stringSubstring(names, from: index + 9)
      if let space = stringIndexOf(language, " ") {
        language = stringSubstring(language, from: 0, to: space)
      }
      return stringIsEmpty(language) ? "text" : language
    }

    /// Its copy button bound and its code highlighted, once (`highlightSoon`).
    private static func bind(_ button: DOM.Element, pre: DOM.Element) {
      if stringEquals(button.getAttribute(data("copy-bound")) ?? "", "true") { return }
      button.setAttribute(data("copy-bound"), true)
      if let code = pre.querySelector("code") {
        highlightSoon(code)
      }

      _ = button.addEventListener(.click) { (event: Event) in
        event.stopPropagation()
        event.preventDefault()
        let code = pre.querySelector("code") ?? pre
        button.classList.add("is-copied")
        button.setAttribute("aria-label", "Copied")
        window.navigator.clipboard.writeText(from: code)
        _ = window.setTimeout(2000) {
          button.classList.remove("is-copied")
          button.setAttribute("aria-label", "Copy code")
        }
      }
    }
  }
#endif
