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
            span { CopyIconView(size: ButtonView.ButtonSize.large.iconSize) }
              .class("copy-icon")
            span { CheckIconView(size: ButtonView.ButtonSize.large.iconSize) }
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
          boxSizing(.borderBox)
          margin(0)
          border(borderWidthBase, .solid, borderColorBase)
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
          borderBottom(borderWidthBase, .solid, borderColorBase)
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
          // An icon-only large control, as ButtonView's: a 48 square, a card
          // header's (user, 2026-10-10).
          width(ButtonView.ButtonSize.large.minSize)
          height(ButtonView.ButtonSize.large.minSize)
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
        selector("& .hljs-name", "& .hljs-tag") { color(syntaxKeywords).important() }
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
        copyIcon.appendChild(CopyIconFactory.createElement(size: sizeIconSmall))

        let successIcon = document.createElement(.span)
        successIcon.classList.add("success-icon")
        successIcon.appendChild(CheckIconFactory.createElement(size: sizeIconSmall))

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

    /// Its copy button bound and its code highlighted, once.
    private static func bind(_ button: DOM.Element, pre: DOM.Element) {
      if stringEquals(button.getAttribute(data("copy-bound")) ?? "", "true") { return }
      button.setAttribute(data("copy-bound"), true)
      if let code = pre.querySelector("code") {
        HighlightJS.highlightElement(elementID: code.id)
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
