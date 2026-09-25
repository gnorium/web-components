#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A ChipInput allows users to create chips to filter content or make selections.
  /// Chips are editable and can be removed.
  public struct ChipInputView: HTMLContent {
    public struct Chip: Sendable {
      let id: String
      let value: String
      let icon: String?

      public init(id: String, value: String, icon: String? = nil) {
        self.id = id
        self.value = value
        self.icon = icon
      }
    }

    let id: String
    let name: String
    let chips: [Chip]
    let placeholder: String
    let separateInput: Bool
    let disabled: Bool
    let readonly: Bool
    let status: ValidationStatus
    let `class`: String

    public enum ValidationStatus: String, Sendable {
      case `default`
      case error
    }

    public init(
      id: String,
      name: String,
      chips: [Chip] = [],
      placeholder: String = "",
      separateInput: Bool = false,
      disabled: Bool = false,
      readonly: Bool = false,
      status: ValidationStatus = .default,
      class: String = ""
    ) {
      self.id = id
      self.name = name
      self.chips = chips
      self.placeholder = placeholder
      self.separateInput = separateInput
      self.disabled = disabled
      self.readonly = readonly
      self.status = status
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      let chipElements = chips.map { chip in
        div {
          if let icon = chip.icon {
            span { icon }
              .class("chip-icon")
              .ariaHidden(true)
          }

          span { chip.value }
            .class("chip-text")

          button {
            span { "×" }
              .ariaHidden(true)
          }
          .type(.button)
          .class("chip-button")
          .ariaLabel("Remove \(chip.value)")
          .data("chip-id", chip.id)
        }
        .class("chip")
        .data("chip-id", chip.id)
        .tabindex(0)

      }

      let containerElement: HTML.HTMLDivElement

      if separateInput {
        containerElement = div {
          if !chips.isEmpty {
            div { chipElements }
              .class("chip-input-chips")
          }

          div {
            TextInputView(
              id: id,
              name: name,
              placeholder: placeholder,
              type: .text,
              status: status == .error ? .error : .default,
              disabled: disabled,
              readonly: readonly
            )
          }
          .class("chip-input-input-wrapper")
        }
      } else {
        containerElement = div {
          chipElements
          TextInputView(
            id: id,
            name: name,
            placeholder: placeholder,
            type: .text,
            status: status == .error ? .error : .default,
            disabled: disabled,
            readonly: readonly,
            class: "chip-input-input"
          )
        }
        .class("chip-input-items")
      }

      return div {
        containerElement
      }
      .class(`class`.isEmpty ? "chip-input-view" : "chip-input-view \(`class`)")
      .data("disabled", disabled)
      .data("status", status.rawValue)
      .style {
        selector("&[data-disabled='true']") {
          opacity(opacityMedium)
          cursor(cursorNotAllowed)
        }
        descendant(".chip") {
          display(.inlineFlex)
          alignItems(.center)
          maxWidth(perc(100))
          padding(spacing4, spacing8)
          backgroundColor(backgroundColorInteractiveSubtle)
          border(borderWidthBase, .solid, borderColorSubtle)
          borderRadius(borderRadiusBase)
          fontSize(fontSizeSmall14)
          fontWeight(fontWeightNormal)
          color(colorBase)
          cursor(cursorBase)
          transition(.all, s(0.2), .easeInOut)
          userSelect(.none)
          pseudoClass(.hover) {
            backgroundColor(backgroundColorInteractiveSubtleHover).important()
            borderColor(borderColorSubtle).important()
            transform(translateY(px(-1)))
            boxShadow(px(0), px(2), px(4), boxShadowColorBase).important()
          }
          pseudoClass(.focus) {
            borderColor(borderColorBlueFocus).important()
            boxShadow(px(0), px(0), px(0), px(2), boxShadowColorBlueFocus).important()
            outline(px(1), .solid, .transparent).important()
          }
        }
        descendant(".chip-icon") { display(.inlineFlex) }
        descendant(".chip-button") {
          display(.inlineFlex)
          alignItems(.center)
          justifyContent(.center)
          width(minSizeInteractivePointer)
          height(minSizeInteractivePointer)
          padding(0)
          backgroundColor(.transparent)
          border(.none)
          color(colorSubtle)
          cursor(cursorBase)
          borderRadius(borderRadiusCircle)
          pseudoClass(.hover) {
            backgroundColor(backgroundColorInteractiveSubtleHover).important()
            color(colorBase).important()
          }
          pseudoClass(.active) { backgroundColor(backgroundColorInteractiveSubtleActive).important() }
          pseudoClass(.focus) {
            outline(px(2), .solid, borderColorBlueFocus).important()
            outlineOffset(px(-2)).important()
          }
        }
        selector("&[data-disabled='true']") {
          descendant(".chip-button") {
            cursor(cursorNotAllowed)
            opacity(opacityMedium)
          }
          descendant(".chip-input-items") {
            backgroundColor(backgroundColorDisabled)
            borderColor(borderColorDisabled)
            color(colorDisabled)
          }
        }
        selector(".chip-input-chips", ".chip-input-input-wrapper", ".chip-input-items") {
          padding(spacing8)
          backgroundColor(backgroundColorBase)
          border(borderWidthBase, .solid, borderColorInputBinary)
          borderRadius(borderRadiusBase)
        }
        selector("&[data-status='error']") {
          selector(".chip-input-chips", ".chip-input-input-wrapper", ".chip-input-items") {
            borderColor(borderColorRed)
          }
        }
        descendant(".chip-input-chips") {
          display(.flex)
          flexWrap(.wrap)
          gap(spacing8)
        }
        descendant(".chip-input-input-wrapper") {
          display(.flex)
          transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
          pseudoClass(.focusWithin) {
            borderColor(borderColorBlueFocus).important()
            boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
          }
        }
        descendant(".chip-input-items") {
          display(.flex)
          flexWrap(.wrap)
          alignItems(.center)
          gap(spacing8)
          minHeight(minSizeInteractivePointer)
          transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
          pseudoClass(.focusWithin) {
            borderColor(borderColorBlueFocus).important()
            boxShadow(px(0), px(0), px(0), px(1), boxShadowColorBlueFocus).important()
          }
        }
      }
    }
  }
#endif
