#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A visual element used to indicate the progress of an action or process.
  public struct ProgressBarView: HTMLContent {
    let inline: Bool
    let ariaLabel: String?
    let ariaHidden: Bool
    let disabled: Bool
    let `class`: String

    public init(
      inline: Bool = false,
      ariaLabel: String? = nil,
      ariaHidden: Bool = false,
      disabled: Bool = false,
      class: String = ""
    ) {
      self.inline = inline
      self.ariaLabel = ariaLabel
      self.ariaHidden = ariaHidden
      self.disabled = disabled
      self.`class` = `class`
    }

    @CSSBuilder
    private func progressBarViewCSS(_ inline: Bool, _ disabled: Bool) -> [CSSRule] {
      display(.block)
      position(.relative)
      backgroundColor(backgroundColorBlueSubtle)
      borderRadius(borderRadiusPill)
      overflow(.hidden)

      if inline {
        height(px(2))
        minWidth(px(64))
      } else {
        height(px(8))
        minWidth(px(256))
      }

      if disabled {
        opacity(0.5)
      }
    }

    @CSSBuilder
    private func progressBarBarCSS() -> [CSSRule] {
      position(.absolute)
      top(0)
      left(0)
      width(perc(0))
      height(perc(100))
      backgroundColor(backgroundColorBlue)
      borderRadius(borderRadiusPill)
      transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
      animation("progress-bar-indeterminate", s(2), .linear, .infinite)
    }

    public func render() -> Node {
      let progressBarClasses = {
        var classes = "progress-bar-view"
        if inline {
          classes += " progress-bar-inline"
        }
        if disabled {
          classes += " progress-bar-disabled"
        }
        if !`class`.isEmpty {
          classes += " \(`class`)"
        }
        return classes
      }()

      var progressBar = div {
        div {}
          .class("progress-bar-bar")
          .style {
            progressBarBarCSS()
          }
      }
      .class(progressBarClasses)
      .role("progressbar")
      .ariaHidden(ariaHidden)
      .ariaValueMin(0)
      .ariaValueMax(100)

      if let ariaLabel = ariaLabel {
        progressBar = progressBar.ariaLabel(ariaLabel)
      }

      return
        progressBar
        .style {
          progressBarViewCSS(inline, disabled)
        }

    }
  }
#endif
