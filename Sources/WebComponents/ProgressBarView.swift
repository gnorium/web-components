#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import Foundation
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  /// A visual element used to indicate the progress of an action or process.
  public struct ProgressBarView: HTMLContent {
    let inline: Bool
    let ariaLabel: String?
    let ariaHidden: Bool
    let disabled: Bool
    let value: Double  // 0.0 - 1.0
    let `class`: String

    public init(
      inline: Bool = false,
      ariaLabel: String? = nil,
      ariaHidden: Bool = false,
      disabled: Bool = false,
      value: Double = 0,
      class: String = ""
    ) {
      self.inline = inline
      self.ariaLabel = ariaLabel
      self.ariaHidden = ariaHidden
      self.disabled = disabled
      self.value = value
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
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

      let percentage = min(max(value, 0), 1) * 100
      var progressBar = div {
        svg {
          rect()
            .x(0)
            .y(0)
            .width(100)
            .height(100)
            .fill(backgroundColorBlueSubtle)
          rect()
            .x(0)
            .y(0)
            .width(percentage)
            .height(100)
            .fill(backgroundColorBlue)
        }
        .class("progress-bar-graphic")
        .viewBox(0, 0, 100, 100)
        .preserveAspectRatio("none")
        .xmlns("http://www.w3.org/2000/svg")
      }
      .class(progressBarClasses)
      .data("inline", inline)
      .data("disabled", disabled)
      .role("progressbar")
      .ariaHidden(ariaHidden)
      .ariaValueMin(0)
      .ariaValueMax(100)
      .ariaValueNow(Int(percentage))

      if let ariaLabel = ariaLabel {
        progressBar = progressBar.ariaLabel(ariaLabel)
      }

      return
        progressBar
        .style {
          selector("&") {
            display(.block)
            position(.relative)
            borderRadius(borderRadiusPill)
            overflow(.hidden)
          }
          child(".progress-bar-graphic") {
            display(.block)
            width(perc(100))
            height(perc(100))
          }
          selector("&[data-inline='true']") { height(px(2)) }
          selector("&[data-inline='false']") { height(px(8)) }
          selector("&[data-disabled='true']") { opacity(0.5) }
        }

    }
  }
#endif
