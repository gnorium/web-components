#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  // MARK: - Schema
  /// Declares the available filterable fields for a page.
  ///
  /// A `repeatable` select may fill several rows. Each row submits its own
  /// `name=value`, so the query repeats the parameter; a page reads repeated
  /// values of one field as alternatives (OR) and different fields as
  /// conditions that all hold (AND).
  ///
  /// Two fields may submit one parameter — a select of set spans and a date,
  /// both `since` — and a value in force goes to the first that can hold it.
  public enum FilterField: Sendable {
    case text(name: String, label: String, placeholder: String)
    case select(
      name: String, label: String, options: [(value: String, label: String)],
      repeatable: Bool = false)
    /// A day, as `yyyy-mm-dd`, picked with the date picker.
    case date(name: String, label: String)

    /// The parameter the field submits.
    public var name: String {
      switch self {
      case .text(let name, _, _): return name
      case .select(let name, _, _, _): return name
      case .date(let name, _): return name
      }
    }

    /// What the field picker names the field by: its parameter, or for a
    /// date its parameter marked as one, so two fields of one parameter are
    /// two choices.
    public var key: String {
      switch self {
      case .date(let name, _): return "\(name):date"
      default: return name
      }
    }

    public var label: String {
      switch self {
      case .text(_, let label, _): return label
      case .select(_, let label, _, _): return label
      case .date(_, let label): return label
      }
    }

    public var repeatable: Bool {
      switch self {
      case .text, .date: return false
      case .select(_, _, _, let repeatable): return repeatable
      }
    }

    /// Whether its value is typed or picked in an input rather than chosen
    /// from a list.
    public var takesInput: Bool {
      switch self {
      case .text, .date: return true
      case .select: return false
      }
    }

    /// Whether a value in force can show in this field: a select holds its
    /// options, a date a day, a text anything.
    public func holds(_ value: String) -> Bool {
      switch self {
      case .text: return true
      case .select(_, _, let options, _): return options.contains { $0.value == value }
      case .date:
        let parts = value.split(separator: "-")
        return parts.count == 3 && parts.allSatisfy { Int($0) != nil }
      }
    }
  }

  // MARK: - Server view

  /// Smart filter bar: dynamic add/remove filter rows, Apply on row 1.
  ///
  /// Layout (CSS grid, display:contents on rows):
  ///   Col 1: field picker  Col 2: value  Col 3: +/–  Col 4: Apply (row 1) or placeholder
  /// On a phone it stacks into one column, Apply last.
  public struct FilterBarView: HTMLContent {
    let action: String
    let schema: [FilterField]
    /// The filters in force, one per row, in row order. A repeatable field
    /// may appear more than once.
    let activeFilters: [(name: String, value: String)]
    let hiddenFields: [(name: String, value: String)]
    let `class`: String

    public init(
      action: String,
      schema: [FilterField],
      activeFilters: [(name: String, value: String)] = [],
      hiddenFields: [(name: String, value: String)] = [],
      class: String = ""
    ) {
      self.action = action
      self.schema = schema
      self.activeFilters = activeFilters
      self.hiddenFields = hiddenFields
      self.`class` = `class`
    }

    private var activeRows: [(field: FilterField, value: String)] {
      var rows: [(FilterField, String)] = []
      for filter in activeFilters {
        let fields = schema.filter { $0.name == filter.name }
        if let field = fields.first(where: { $0.holds(filter.value) }) ?? fields.first {
          rows.append((field, filter.value))
        }
      }
      if rows.isEmpty, let first = schema.first {
        rows.append((first, ""))
      }
      return rows
    }

    public func build() -> DOM.Node {
      // A text or date field's input is built by the client when the field is
      // picked; the page links only the sheets touched while rendering, so
      // build one here, discarded, or the input arrives unstyled.
      if schema.contains(where: \.takesInput) {
        _ = TextInputView(id: "filter-bar-preload", name: "", value: "", fullWidth: true).build()
      }
      if schema.contains(where: { if case .date = $0 { return true } else { return false } }) {
        _ = DatePickerView(id: "filter-bar-date-preload", name: "", fullWidth: true).build()
      }
      let rows = activeRows
      // Another row can always hold a repeatable field; otherwise one row
      // per field.
      let addExhausted = rows.count >= schema.count && !schema.contains(where: \.repeatable)
      let schemaJSON = buildSchemaJSON()

      return form {
        for hidden in hiddenFields {
          input()
            .type(.hidden)
            .name(hidden.name)
            .value(hidden.value)
        }

        div {
          for (index, row) in rows.enumerated() {
            filterRow(field: row.field, value: row.value, index: index, isFirst: index == 0, addExhausted: addExhausted)
          }
        }
        .class("filter-bar-grid")
        .data("schema", schemaJSON)
        .data("action", action)
        .style {
          selector("&") {
            display(.grid)
            gridTemplateColumns("160px minmax(0, 1fr) 44px auto")
            gap(spacing8)
            alignItems(.center)
            width(perc(100))
          }
          descendant(".filter-bar-row") { display(.contents) }
          descendant(".filter-bar-row[data-first='false'] .filter-bar-remove-btn") { gridColumn("3 / span 2") }
          // On a phone the bar stacks: each part on its own line at full
          // width — field, value, the + or − — and Apply last, under every
          // filter.
          media(maxWidth(maxWidthBreakpointMobile)) {
            selector("&") {
              gridTemplateColumns("minmax(0, 1fr)").important()
            }
            descendant(".filter-bar-row[data-first='false'] .filter-bar-remove-btn") {
              gridColumn("auto").important()
            }
            descendant(".filter-bar-apply") {
              order(1).important()
            }
          }
        }
      }
      .action(action)
      .method(.get)
      .class("filter-bar-view \(`class`)")
      .style {
        selector("&") {
          display(.flex)
          flexDirection(.column)
          gap(spacing12)
          padding(spacing12, spacing16)
          border(borderWidthBase, .solid, borderColorBase)
          borderRadius(borderRadiusBase)
          backgroundColor(backgroundColorNeutralSubtle)
          width(perc(100))
        }
      }
    }

    @HTMLBuilder
    private func filterRow(field: FilterField, value: String, index: Int, isFirst: Bool, addExhausted: Bool)
      -> some HTMLContent
    {
      div {
        // Col 1: field picker
        fieldPicker(activeField: field, rowIndex: index)

        // Col 2: value input
        valueInput(field: field, value: value, rowIndex: index)

        // Col 3: + button (row 0) or − button spanning cols 3+4 (other rows)
        if isFirst {
          ButtonView(
            label: "+",
            buttonColor: .gray,
            weight: .subtle,
            size: .medium,
            disabled: addExhausted,
            type: .button,
            class: "filter-bar-add-btn",
            labelFontWeight: fontWeightSemiBold
          )
        } else {
          ButtonView(
            label: "−",
            buttonColor: .gray,
            weight: .subtle,
            size: .medium,
            type: .button,
            class: "filter-bar-remove-btn",
            labelFontWeight: fontWeightSemiBold
          )
        }

        // Col 4: Apply (row 0 only — other rows have − spanning into this col)
        if isFirst {
          ButtonView(
            label: "Apply",
            buttonColor: .blue,
            weight: .solid,
            size: .medium,
            type: .submit,
            class: "filter-bar-apply",
            labelFontWeight: fontWeightSemiBold
          )
        }
      }
      .class("filter-bar-row")
      .data("row-index", "\(index)")
      .data("first", isFirst)
    }

    @HTMLBuilder
    private func fieldPicker(activeField: FilterField, rowIndex: Int) -> some HTMLContent {
      DropdownView(
        id: "filter-field-picker-\(rowIndex)",
        name: "__field_\(rowIndex)",
        label: "",
        options: schema.map { DropdownView.DropdownOption(value: $0.key, display: $0.label) },
        placeholder: "Field",
        selectedValue: activeField.key,
        class: "filter-bar-field-picker",
        buttonSize: .medium,
        fullWidth: true
      )
    }

    @HTMLBuilder
    private func valueInput(field: FilterField, value: String, rowIndex: Int) -> some HTMLContent {
      switch field {
      case .text(let name, _, let placeholder):
        TextInputView(
          id: "filter-\(name)-\(rowIndex)",
          name: name,
          placeholder: placeholder,
          value: value,
          fullWidth: true,
          class: "filter-bar-value-input"
        )

      case .select(let name, let label, let options, _):
        DropdownView(
          id: "filter-\(name)-\(rowIndex)",
          name: name,
          label: "",
          options: options.map { DropdownView.DropdownOption(value: $0.value, display: $0.label) },
          placeholder: label,
          selectedValue: value.isEmpty ? nil : value,
          class: "filter-bar-value-select",
          buttonSize: .medium,
          fullWidth: true
        )

      case .date(let name, _):
        DatePickerView(
          id: "filter-\(name)-\(rowIndex)",
          name: name,
          value: value,
          fullWidth: true,
          class: "filter-bar-value-input"
        )
      }
    }

    private func buildSchemaJSON() -> String {
      var parts: [String] = []
      for field in schema {
        switch field {
        case .text(let name, let label, let placeholder):
          parts.append(
            "{\"key\":\"\(field.key)\",\"name\":\"\(name)\",\"label\":\"\(label)\",\"type\":\"text\",\"placeholder\":\"\(placeholder)\"}"
          )
        case .select(let name, let label, let options, let repeatable):
          let opts = options.map { "{\"\($0.value)\":\"\($0.label)\"}" }.joined(separator: ",")
          parts.append(
            "{\"key\":\"\(field.key)\",\"name\":\"\(name)\",\"label\":\"\(label)\",\"type\":\"select\",\"repeatable\":\"\(repeatable)\",\"options\":[\(opts)]}"
          )
        case .date(let name, let label):
          parts.append(
            "{\"key\":\"\(field.key)\",\"name\":\"\(name)\",\"label\":\"\(label)\",\"type\":\"date\"}"
          )
        }
      }
      return "[\(parts.joined(separator: ","))]"
    }
  }
#endif

// MARK: - WASM hydration

#if CLIENT
  import DesignTokens
  import DOMBuilder
  import EmbeddedSwiftUtilities
  import HTMLBuilder
  import WebAPIs
  import WebTypes

  public class FilterBarHydration: @unchecked Sendable {
    public static nonisolated(unsafe) var instance: FilterBarHydration?
    private let dropdownHydration = DropdownHydration()
    private let textInputHydration = TextInputHydration()
    private let datePickerHydration = DatePickerHydration()

    public static func hydrateIfPresent() {
      guard document.querySelector(".filter-bar-view") != nil else { return }
      instance = FilterBarHydration()
    }

    public init() {
      let grids = document.querySelectorAll(".filter-bar-grid")
      for grid in grids {
        _ = FilterBarInstance(
          grid: grid,
          dropdownHydration: dropdownHydration,
          textInputHydration: textInputHydration,
          datePickerHydration: datePickerHydration
        )
      }
    }
  }

  // WASM-safe schema entry — struct avoids [String:String] dict subscript (String.hashValue culprit)
  private struct SchemaEntry: @unchecked Sendable {
    /// What the field picker names it by; `name` is the parameter it submits.
    let key: String
    let name: String
    let label: String
    let isText: Bool
    let isDate: Bool
    let placeholder: String
    let repeatable: Bool
  }

  private class FilterBarInstance: @unchecked Sendable {
    private let grid: DOM.Element
    private let dropdownHydration: DropdownHydration
    private let textInputHydration: TextInputHydration
    private let datePickerHydration: DatePickerHydration
    private var schema: [SchemaEntry] = []

    init(
      grid: DOM.Element, dropdownHydration: DropdownHydration, textInputHydration: TextInputHydration,
      datePickerHydration: DatePickerHydration
    ) {
      self.grid = grid
      self.dropdownHydration = dropdownHydration
      self.textInputHydration = textInputHydration
      self.datePickerHydration = datePickerHydration
      parseSchema()
      wireRows()
      wireAddButton()
    }

    // MARK: - Setup

    private func parseSchema() {
      guard let raw = grid.getAttribute(data("schema")), !stringIsEmpty(raw) else { return }
      let objects = splitJSONObjects(raw)
      for obj in objects {
        guard let key = extractJSONString(obj, key: "key"),
          let name = extractJSONString(obj, key: "name"),
          let typeStr = extractJSONString(obj, key: "type")
        else { continue }
        let label = extractJSONString(obj, key: "label") ?? name
        let placeholder = extractJSONString(obj, key: "placeholder") ?? ""
        let isText = stringEquals(typeStr, "text")
        let isDate = stringEquals(typeStr, "date")
        let repeatable = extractJSONString(obj, key: "repeatable").map { stringEquals($0, "true") } ?? false
        schema.append(
          SchemaEntry(
            key: key, name: name, label: label, isText: isText, isDate: isDate,
            placeholder: placeholder, repeatable: repeatable))
      }
    }

    private func wireRows() {
      let rows = grid.querySelectorAll(".filter-bar-row")
      for row in rows {
        wireFieldPicker(in: row)
        wireRemoveButton(in: row)
      }
    }

    private func wireAddButton() {
      guard let btn = grid.querySelector(".filter-bar-add-btn") else { return }
      _ = btn.addEventListener(.click) { [self] _ in self.addRow() }
      updateAddButton()
    }

    private func updateAddButton() {
      guard let btn = grid.querySelector(".filter-bar-add-btn") else { return }
      let exhausted = nextField() == nil
      if exhausted {
        btn.setAttribute("disabled", "true")
      } else {
        btn.removeAttribute("disabled")
      }
    }

    // MARK: - Field picker

    private func wireFieldPicker(in row: DOM.Element) {
      guard let container = row.querySelector(".filter-bar-field-picker"),
        let hiddenInput = container.querySelector(#"input[type="hidden"]"#) as? HTML.HTMLInputElement
      else { return }
      _ = hiddenInput.addEventListener(.change) { [self] _ in
        self.onFieldChange(fieldKey: hiddenInput.value, row: row)
      }
    }

    private func onFieldChange(fieldKey: String, row: DOM.Element) {
      guard let entry = schema.first(where: { stringEquals($0.key, fieldKey) }) else { return }
      replaceValueInput(in: row, with: entry, value: "")
    }

    // MARK: - Value input swap

    private func replaceValueInput(in row: DOM.Element, with entry: SchemaEntry, value: String) {
      let fieldName = entry.name
      let placeholder = entry.placeholder

      // Remove existing value input(s)
      if let existing = row.querySelector(".filter-bar-value-input") {
        existing.remove()
      }
      if let existing = row.querySelector(".filter-bar-value-select") {
        existing.remove()
      }

      // Insert before +/– button (col 3)
      let addOrRemoveBtn =
        row.querySelector(".filter-bar-add-btn") ?? row.querySelector(".filter-bar-remove-btn")

      if entry.isDate {
        let picker = DatePickerFactory.createElement(
          id: "filter-\(fieldName)-swap",
          name: fieldName,
          value: value,
          fullWidth: true,
          class: "filter-bar-value-input",
          hydrator: datePickerHydration
        )
        row.insertBefore(picker, addOrRemoveBtn)
      } else if entry.isText {
        let input = TextInputFactory.createElement(
          id: "filter-\(fieldName)-swap",
          name: fieldName,
          placeholder: placeholder,
          value: value,
          fullWidth: true,
          class: "filter-bar-value-input",
          hydrator: textInputHydration
        )
        row.insertBefore(input, addOrRemoveBtn)
      } else {
        let options = optionsForField(entry.key)
        let dropdown = DropdownFactory.createElement(
          id: "filter-\(fieldName)-swap",
          name: fieldName,
          options: options,
          placeholder: entry.label,
          selectedValue: value.isEmpty ? nil : value,
          class: "filter-bar-value-select",
          buttonSize: .medium,
          fullWidth: true,
          hydrator: dropdownHydration
        )
        row.insertBefore(dropdown, addOrRemoveBtn)
      }
    }

    private func optionsForField(_ fieldKey: String) -> [DropdownView.DropdownOption] {
      guard let rawSchema = grid.getAttribute(data("schema")) else { return [] }
      guard let fromField = findAndSkip("\"key\":\"\(fieldKey)\"", in: rawSchema) else { return [] }
      guard let afterOptions = findAndSkip("\"options\":[", in: fromField) else { return [] }
      guard let optionsStr = findUntil("]", in: afterOptions) else { return [] }
      let objects = splitJSONObjects(optionsStr)
      var result: [DropdownView.DropdownOption] = []
      for obj in objects {
        guard let colonIdx = stringIndexOf(obj, ":") else { continue }
        let beforeColon = stringSubstring(obj, from: 0, to: colonIdx)
        let afterColon = stringSubstring(obj, from: colonIdx + 1)
        guard let optValue = extractFirstQuotedString(beforeColon),
          let optLabel = extractFirstQuotedString(afterColon)
        else { continue }
        result.append(DropdownView.DropdownOption(value: optValue, display: optLabel))
      }
      return result
    }

    // MARK: - Add / Remove

    private func addRow() {
      guard let nextField = nextField() else { return }

      let row = buildNewRow(field: nextField, rowIndex: nextRowIndex())
      grid.appendChild(row)
      wireFieldPicker(in: row)
      wireRemoveButton(in: row)
      updateAddButton()
    }

    private func wireRemoveButton(in row: DOM.Element) {
      guard let btn = row.querySelector(".filter-bar-remove-btn") else { return }
      _ = btn.addEventListener(.click) { [self] _ in self.removeRow(row) }
    }

    private func removeRow(_ row: DOM.Element) {
      row.remove()
      updateAddButton()
    }

    private func buildNewRow(field: SchemaEntry, rowIndex: Int) -> DOM.Element {
      let row = document.createElement("div")
      _ = row.classList.add("filter-bar-row")
      row.setAttribute(data("row-index"), "\(rowIndex)")
      row.setAttribute(data("first"), false)

      // Col 1: field picker via DropdownFactory
      let picker = DropdownFactory.createElement(
        id: "filter-field-picker-\(rowIndex)",
        name: "__field_\(rowIndex)",
        options: schema.map { DropdownView.DropdownOption(value: $0.key, display: $0.label) },
        placeholder: "Field",
        selectedValue: field.key,
        class: "filter-bar-field-picker",
        buttonSize: .medium,
        fullWidth: true,
        hydrator: dropdownHydration
      )
      row.appendChild(picker)

      // Col 2: value input
      if field.isDate {
        let picker = DatePickerFactory.createElement(
          id: "filter-\(field.name)-\(rowIndex)",
          name: field.name,
          fullWidth: true,
          class: "filter-bar-value-input",
          hydrator: datePickerHydration
        )
        row.appendChild(picker)
      } else if field.isText {
        let input = TextInputFactory.createElement(
          id: "filter-\(field.name)-\(rowIndex)",
          name: field.name,
          placeholder: field.placeholder,
          fullWidth: true,
          class: "filter-bar-value-input",
          hydrator: textInputHydration
        )
        row.appendChild(input)
      } else {
        let options = optionsForField(field.key)
        let valueDropdown = DropdownFactory.createElement(
          id: "filter-\(field.name)-\(rowIndex)",
          name: field.name,
          options: options,
          placeholder: field.label,
          class: "filter-bar-value-select",
          buttonSize: .medium,
          fullWidth: true,
          hydrator: dropdownHydration
        )
        row.appendChild(valueDropdown)
      }

      // Col 3–4: remove button spanning both cols
      let btn = ButtonViewFactory.createElement(
        label: "−",
        buttonColor: .gray,
        weight: .subtle,
        size: .medium,
        type: .button,
        class: "filter-bar-remove-btn"
      )
      row.appendChild(btn)

      return row
    }

    // MARK: - Helpers

    /// The field a new row starts on: the first not yet in use, else the first
    /// that may repeat. Nil when neither is left.
    private func nextField() -> SchemaEntry? {
      let usedKeys = usedFieldKeys()
      if let unused = schema.first(where: { entry in
        !usedKeys.contains(where: { stringEquals($0, entry.key) })
      }) {
        return unused
      }
      return schema.first(where: { $0.repeatable })
    }

    private func usedFieldKeys() -> [String] {
      var names: [String] = []
      let pickers = grid.querySelectorAll(".filter-bar-field-picker")
      for picker in pickers {
        if let hidden = picker.querySelector(#"input[type="hidden"]"#) as? HTML.HTMLInputElement {
          names.append(hidden.value)
        }
      }
      return names
    }

    private func nextRowIndex() -> Int {
      grid.querySelectorAll(".filter-bar-row").count
    }

    // Splits "{...},{...}" into individual object strings. UTF-8 byte-safe.
    private func splitJSONObjects(_ str: String) -> [String] {
      let bytes = Array(str.utf8)
      let open = UInt8(ascii: "{")
      let close = UInt8(ascii: "}")
      var results: [String] = []
      var depth = 0
      var start = -1
      for (i, b) in bytes.enumerated() {
        if b == open {
          if depth == 0 { start = i }
          depth += 1
        } else if b == close {
          depth -= 1
          if depth == 0 && start >= 0 {
            results.append(stringSubstring(str, from: start, to: i + 1))
            start = -1
          }
        }
      }
      return results
    }

    // Returns substring after first occurrence of needle. UTF-8 byte-safe via stringIndexOf.
    private func findAndSkip(_ needle: String, in haystack: String) -> String? {
      guard let idx = stringIndexOf(haystack, needle) else { return nil }
      return stringSubstring(haystack, from: idx + needle.utf8.count)
    }

    // Returns substring before first occurrence of needle string. UTF-8 byte-safe.
    private func findUntil(_ needle: String, in str: String) -> String? {
      guard let idx = stringIndexOf(str, needle) else { return nil }
      return stringSubstring(str, from: 0, to: idx)
    }

    private func extractJSONString(_ obj: String, key: String) -> String? {
      let pattern = "\"\(key)\":"
      guard let after = findAndSkip(pattern, in: obj) else { return nil }
      return extractFirstQuotedString(after)
    }

    // Extracts first "..." string. UTF-8 byte-safe — handles ASCII JSON content.
    private func extractFirstQuotedString(_ s: String) -> String? {
      let bytes = Array(s.utf8)
      let quote = UInt8(ascii: "\"")
      let backslash = UInt8(ascii: "\\")
      var inString = false
      var escaped = false
      var start = -1
      for (i, b) in bytes.enumerated() {
        if escaped { escaped = false; continue }
        if b == backslash { escaped = true; continue }
        if b == quote {
          if inString { return stringSubstring(s, from: start, to: i) }
          inString = true
          start = i + 1
        }
      }
      return nil
    }
  }
#endif
