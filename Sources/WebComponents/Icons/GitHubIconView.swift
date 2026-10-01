#if SERVER
  import CSSBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import SVGBuilder
  import WebTypes

  public struct GitHubIconView: HTMLContent {
    let `class`: String
    let width: CSS.Length
    let height: CSS.Length
    let fill: CSS.Color
    let monochrome: Bool

    public init(
      class: String = "",
      width: CSS.Length = px(20),
      height: CSS.Length = px(20),
      fill: CSS.Color = colorBase,
      monochrome: Bool = false
    ) {
      self.class = `class`
      self.width = width
      self.height = height
      self.fill = fill
      self.monochrome = monochrome
    }

    public func build() -> DOM.Node {
      svg {
        path()
          .fillRule(.evenodd)
          .clipRule(.evenodd)
          .d(
            M(512, 12.42), C(229.12, 12.42, 0, 241.54, 0, 524.42),
            C(0, 750.98, 146.56, 942.98, 350.08, 1010.82),
            C(375.68, 1014.66, 385.28, 999.3, 385.28, 985.86),
            C(385.28, 973.7, 384.64, 934.02, 384.64, 890.5),
            C(256, 914.82, 222.72, 859.14, 212.48, 830.34),
            C(206.72, 815.62, 181.76, 770.18, 160, 758.98),
            C(142.08, 748.42, 116.48, 724.74, 159.36, 724.1),
            C(199.68, 723.46, 228.48, 761.22, 238.08, 776.58),
            C(284.16, 854.02, 357.76, 832.58, 387.2, 818.82),
            C(391.68, 785.54, 405.12, 763.14, 419.84, 750.34),
            C(306.24, 737.54, 186.88, 693.38, 186.88, 497.54),
            C(186.88, 441.86, 206.72, 395.78, 239.36, 359.94),
            C(234.24, 347.14, 216.32, 294.66, 244.48, 224.26),
            C(244.48, 224.26, 287.36, 210.82, 385.28, 276.74),
            C(426.24, 265.22, 469.76, 259.46, 513.28, 259.46),
            C(556.8, 259.46, 600.32, 265.22, 641.28, 276.74),
            C(739.2, 210.18, 782.08, 224.26, 782.08, 224.26),
            C(810.24, 294.66, 792.32, 347.14, 787.2, 359.94),
            C(819.84, 395.78, 839.68, 441.22, 839.68, 497.54),
            C(839.68, 694.02, 720, 737.54, 606.08, 750.34),
            C(624.64, 766.34, 640.64, 797.06, 640.64, 845.06),
            C(640.64, 913.54, 640, 968.58, 640, 985.86),
            C(640, 999.3, 649.6, 1015.3, 675.2, 1010.82),
            C(877.44, 942.98, 1024, 750.98, 1024, 524.42),
            C(1024, 241.54, 794.88, 12.42, 512, 12.42), Z())
          .fill(fill)
      }
      .class(`class`.isEmpty ? "github-icon-view" : "github-icon-view \(`class`)")
      .width(width)
      .height(height)
      .viewBox(0, 0, 1024, 1024)
      .xmlns("http://www.w3.org/2000/svg")
      .xmlnsXlink("http://www.w3.org/1999/xlink")

    }
  }
#endif
