/// A part of a page drawn disabled at once (user, 2026-11-03): a tree node
/// an open object holds, or one another node's change freezes—its Value
/// box, its accordions and the fields, labels and buttons in them. Its page
/// marks the part (`attribute`, "true") and makes what in it takes input
/// inert; every component in it draws its own disabled state, in the
/// disabled tokens, never an opacity over it: a field its disabled ground
/// and border, a label, its "(optional)" and its info the disabled color,
/// an accordion its header and chevron, a button as a disabled button, a
/// tree's marker its disabled ring. Unmarked, each is drawn as it was.
///
/// It is the part's state, not its controls': nothing in it is `disabled`,
/// so a form still posts what it holds as it stands. A component's rule for
/// it is its own disabled rule's selector within a marked part,
/// `:where([data-disabled-region='true']) &…`, as weightless as the mark,
/// or weighed (`[data-disabled-region='true'] &…`) where its enabled rules
/// weigh more (a button's color by its weight and color).
public enum DisabledRegion {
  /// The attribute that marks a part.
  public static let attribute = "data-disabled-region"
}
