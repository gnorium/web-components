import CSSBuilder
import CSSOMBuilder
import DesignTokens
import DOMBuilder
import EmbeddedSwiftUtilities
import HTMLBuilder
import WebTypes

/// What a list of options the server gives says under the options it shows
/// (a dropdown's `listURL` or `searchURL`, a combobox's `searchURL`): while
/// the answer they wait on is on its way, a plain wait, the rotating ring
/// sector, as a search of the server under way shows it (TestamentFindView's);
/// once that answer failed, the same row says so in the wait's place,
/// vaguely, in the words every field's message is drawn in, never why (the
/// bridge logs the reason). Each a one-line option's row; neither shows
/// otherwise. Its list says which (`show(_:in:)`), and asks again on its
/// next open or keystroke, which takes the failure away while it waits
/// (user, 2026-11-05).
///
/// Built on both sides: a dropdown or combobox the client builds draws it
/// too. `build()` stays embedded-safe.
public struct OptionsStatusView: HTMLContent {
  /// What it says.
  public enum State: Sendable {
    /// Nothing: no answer on its way, none failed.
    case idle
    /// The wait: the answer its options wait on is on its way.
    case busy
    /// The failure: the latest answer failed.
    case failed
  }

  public init() {}

  public func build() -> DOM.Node {
    div {
      div {
        RotatingDottedRingSectorView(size: lineHeightSmall22, ariaLabel: "Loading the options")
      }
      .class("options-status-loading")
      div { FieldValidationMessageView(status: .error, message: "The options could not be loaded.") }
        .class("options-status-failed")
        .role(.alert)
    }
    .class("options-status-view")
    .data("state", Self.name(of: .idle))
    .style {
      // A one-line option's row (48), its line on the options' 8 inset:
      // the wait's ring in its middle, the failure's message at its start.
      // Each only while its list says so (`data-state`).
      selector("& > .options-status-loading", "& > .options-status-failed") {
        display(.none)
        alignItems(.center)
        padding(spacing8)
        minHeight(ButtonView.ButtonSize.large.minSize)
        boxSizing(.borderBox)
      }
      child(".options-status-loading") {
        justifyContent(.center)
      }
      selector("&[data-state='busy'] > .options-status-loading", "&[data-state='failed'] > .options-status-failed") {
        display(.flex)
      }
      ButtonView.phoneStepRowCSS(".options-status-loading", ".options-status-failed")
    }
  }

  /// `state` as `data-state` says it.
  static func name(of state: State) -> String {
    switch state {
    case .idle: return "idle"
    case .busy: return "busy"
    case .failed: return "failed"
    }
  }
}

#if CLIENT
  import WebAPIs

  extension OptionsStatusView {
    /// Says `state` on `view` (an `OptionsStatusView`'s element), when it
    /// says another: saying again what it says touches nothing.
    public static func show(_ state: State, in view: DOM.Element?) {
      guard let view else { return }
      let said = name(of: state)
      if stringEquals(view.getAttribute(data("state")) ?? "", said) { return }
      view.setAttribute(data("state"), said)
    }
  }
#endif
