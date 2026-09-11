#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import Foundation
  import HTMLBuilder
  import WebTypes

  /// A visual element used to display content in various formats and states.
  public struct ImageView: HTMLContent {
    let src: String
    let alt: String
    let aspectRatio: AspectRatio?
    let objectPositionVal: CSS.ObjectPosition
    let objectFitVal: CSS.ObjectFit
    let imagePosition: Position?
    let imageWidth: CSS.Length?
    let imageHeight: CSS.Length?
    let loadingPriority: HTML.Loading
    let placeholderIcon: String?
    let `class`: String

    public enum AspectRatio: String, Sendable {
      case sixteenByNine = "16:9"
      case threeByTwo = "3:2"
      case fourByThree = "4:3"
      case oneByOne = "1:1"
      case threeByFour = "3:4"
      case twoByThree = "2:3"
    }

    public enum Position: String, Sendable {
      case left = "left"
      case center = "center"
      case right = "right"
    }

    public init(
      src: String = "",
      alt: String,
      aspectRatio: AspectRatio? = nil,
      objectPositionVal: CSS.ObjectPosition = .center,
      objectFitVal: CSS.ObjectFit = .cover,
      imagePosition: Position? = nil,
      imageWidth: CSS.Length? = nil,
      imageHeight: CSS.Length? = nil,
      loadingPriority: HTML.Loading = .lazy,
      placeholderIcon: String? = nil,
      class: String = ""
    ) {
      self.src = src
      self.alt = alt
      self.aspectRatio = aspectRatio
      self.objectPositionVal = objectPositionVal
      self.objectFitVal = objectFitVal
      self.imagePosition = imagePosition
      self.imageWidth = imageWidth
      self.imageHeight = imageHeight
      self.loadingPriority = loadingPriority
      self.placeholderIcon = placeholderIcon
      self.`class` = `class`
    }

    public func build() -> DOM.Node {
      let hasImage = !src.isEmpty
      let hasAspectRatio = aspectRatio != nil

      let imageClasses = {
        var classes = "image-view"
        if let aspectRatio = aspectRatio {
          classes +=
            " image-aspect-\(aspectRatio.rawValue.replacingOccurrences(of: ":", with: "-"))"
        }
        if let imagePosition = imagePosition {
          classes += " image-position-\(imagePosition.rawValue)"
        }
        if !`class`.isEmpty {
          classes += " \(`class`)"
        }
        return classes
      }()

      return div {
        if hasImage {
          let imgElement = img()
            .src(src)
            .alt(alt)
            .loading(loadingPriority)
            .class("image-image")
            .data("object-fit", objectFitVal.rawValue)
            .data("object-position", objectPositionVal.rawValue)
            .data("has-aspect-ratio", hasAspectRatio)

          if let imageWidth = imageWidth, let imageHeight = imageHeight {
            imgElement.width(imageWidth).height(imageHeight)
          } else if let imageWidth = imageWidth {
            imgElement.width(imageWidth)
          } else if let imageHeight = imageHeight {
            imgElement.height(imageHeight)
          } else {
            imgElement
          }
        } else {
          span {
            placeholderIcon ?? "🖼"
          }
          .class("image-placeholder")
          .ariaHidden(true)
        }
      }
      .class(imageClasses)
      .data("aspect-ratio", aspectRatio?.rawValue ?? "none")
      .data("position", imagePosition?.rawValue ?? "none")
      .style {
        selector("&") {
          display(.block)
          position(.relative)
          overflow(.hidden)
          backgroundColor(backgroundColorBase)
        }
        selector("&[data-position='left']") { marginInlineEnd(.auto) }
        selector("&[data-position='center']") { marginInline(.auto) }
        selector("&[data-position='right']") { marginInlineStart(.auto) }
        selector("&[data-aspect-ratio='16:9']") { paddingBottom(perc((9.0 / 16.0) * 100)) }
        selector("&[data-aspect-ratio='3:2']") { paddingBottom(perc((2.0 / 3.0) * 100)) }
        selector("&[data-aspect-ratio='4:3']") { paddingBottom(perc((3.0 / 4.0) * 100)) }
        selector("&[data-aspect-ratio='1:1']") { paddingBottom(perc(100)) }
        selector("&[data-aspect-ratio='3:4']") { paddingBottom(perc((4.0 / 3.0) * 100)) }
        selector("&[data-aspect-ratio='2:3']") { paddingBottom(perc((3.0 / 2.0) * 100)) }
        descendant(".image-image") {
          display(.block)
          width(perc(100))
          height(perc(100))
        }
        descendant(".image-image[data-has-aspect-ratio='true']") {
          position(.absolute)
          insetBlockStart(0)
          insetInlineStart(0)
        }
        descendant(".image-image[data-object-fit='\(objectFitVal.rawValue)']") { objectFit(objectFitVal) }
        descendant(".image-image[data-object-position='\(objectPositionVal.rawValue)']") { objectPosition(objectPositionVal) }
        descendant(".image-placeholder") {
          position(.absolute)
          insetBlockStart(0)
          insetInlineStart(0)
          width(perc(100))
          height(perc(100))
          display(.flex)
          alignItems(.center)
          justifyContent(.center)
          backgroundColor(backgroundColorBase)
          color(colorPlaceholder)
          fontSize(sizeIconMedium)
        }
      }
    }
  }
#endif
