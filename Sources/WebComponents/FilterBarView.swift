#if SERVER
  import CSSBuilder
  import CSSOMBuilder
  import DesignTokens
  import DOMBuilder
  import HTMLBuilder
  import WebTypes

  // MARK: - Schema
  /// Declares the available filterable fields for a page.
  public enum FilterField: Sendable {
    case text(name: String, label: String, placeholder: String)
    case select(name: String, label: String, options: [(value: String, label: String)])

    public var name: String {
      switch self {
      case .text(let name, _, _): return name
      case .select(let name, _, _): return name
      }
    }

    public var label: String {
      switch self {
      case .text(_, let label, _): return label
      case .select(_, let label, _): return label
      }
    }
  }

  // MARK: - Server view

  /// Smart filter bar: dynamic add/remove filter rows, Apply on row 1.
  ///
  /// Layout (CSS grid, display:contents on rows):
  ///   Col 1: field picker  Col 2: value  Col 3: +/–  Col 4: Apply (row 1) or placeholder
  public struct FilterBarView: HTMLContent {
    let action: String
    let schema: [FilterField]
    let activeFilters: [String: String]
    let hiddenFields: [(name: String, value: String)]
    let `class`: String

    public init(
      action: String,
      schema: [FilterField],
      activeFilters: [String: String] = [:],
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
      for field in schema {
        if let val = activeFilters[field.name] {
          rows.append((field, val))
        }
      }
      if rows.isEmpty, let first = schema.first {
        rows.append((first, ""))
      }
      return rows
    }

    public func build() -> DOM.Node {
      let rows = activeRows
      let addExhausted = rows.count >= schema.count
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
          display(.grid)
          gridTemplateColumns(px(160), fr(1), px(44), .auto)
          gap(spacing8)
          alignItems(.center)
          width(perc(100))
        }
      }
      .action(action)
      .method(.get)
      .class("filter-bar-view \(`class`)")
      .style {
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
            size: .large,
            disabled: addExhausted,
            type: .button,
            class: "filter-bar-add-btn",
            labelFontWeight: fontWeightSemiBold
          )
        } else {
          div {
            ButtonView(
              label: "−",
              buttonColor: .gray,
              weight: .subtle,
              size: .large,
              type: .button,
              class: "filter-bar-remove-btn",
              labelFontWeight: fontWeightSemiBold
            )
          }
          .style {
            gridColumn("3 / span 2")
            display(.flex)
            alignItems(.center)
          }
        }

        // Col 4: Apply (row 0 only — other rows have − spanning into this col)
        if isFirst {
          ButtonView(
            label: "Apply",
            buttonColor: .blue,
            weight: .solid,
            size: .large,
            type: .submit,
            class: "filter-bar-apply",
            labelFontWeight: fontWeightSemiBold
          )
        }
      }
      .class("filter-bar-row")
      .data("row-index", "\(index)")
      .style { display(.contents) }
    }

    @HTMLBuilder
    private func fieldPicker(activeField: FilterField, rowIndex: Int) -> some HTMLContent {
      DropdownView(
        id: "filter-field-picker-\(rowIndex)",
        name: "__field_\(rowIndex)",
        label: "",
        options: schema.map { DropdownView.DropdownOption(value: $0.name, display: $0.label) },
        placeholder: "Field",
        selectedValue: activeField.name,
        class: "filter-bar-field-picker",
        buttonSize: .large,
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

      case .select(let name, let label, let options):
        DropdownView(
          id: "filter-\(name)-\(rowIndex)",
          name: name,
          label: "",
          options: options.map { DropdownView.DropdownOption(value: $0.value, display: $0.label) },
          placeholder: label,
          selectedValue: value.isEmpty ? nil : value,
          class: "filter-bar-value-select",
          buttonSize: .large,
          fullWidth: true
        )
      }
    }

    private func buildSchemaJSON() -> String {
      var parts: [String] = []
      for field in schema {
        switch field {
        case .text(let name, let label, let placeholder):
          parts.append(
            "{\"name\":\"\(name)\",\"label\":\"\(label)\",\"type\":\"text\",\"placeholder\":\"\(placeholder)\"}"
          )
        case .select(let name, let label, let options):
          let opts = options.map { "{\"\($0.value)\":\"\($0.label)\"}" }.joined(separator: ",")
          parts.append(
            "{\"name\":\"\(name)\",\"label\":\"\(label)\",\"type\":\"select\",\"options\":[\(opts)]}"
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
    private let dropdownHydration = DropdownHydration()
    private let textInputHydration = TextInputHydration()

    public init() {
      let grids = document.querySelectorAll(".filter-bar-grid")
      for grid in grids {
        _ = FilterBarInstance(
          grid: grid,
          dropdownHydration: dropdownHydration,
          textInputHydration: textInputHydration
        )
      }
    }
  }

  // WASM-safe schema entry — struct avoids [String:String] dict subscript (String.hashValue culprit)
  private struct SchemaEntry: @unchecked Sendable {
    let name: String
    let label: String
    let isText: Bool
    let placeholder: String
  }

  private class FilterBarInstance: @unchecked Sendable {
    private let grid: DOM.Element
    private let dropdownHydration: DropdownHydration
    private let textInputHydration: TextInputHydration
    private var schema: [SchemaEntry] = []

    init(grid: DOM.Element, dropdownHydration: DropdownHydration, textInputHydration: TextInputHydration) {
      self.grid = grid
      self.dropdownHydration = dropdownHydration
      self.textInputHydration = textInputHydration
      parseSchema()
      wireRows()
      wireAddButton()
    }

    // MARK: - Setup

    private func parseSchema() {
      guard let raw = grid.getAttribute(data("schema")), !stringIsEmpty(raw) else { return }
      let objects = splitJSONObjects(raw)
      for obj in objects {
        guard let name = extractJSONString(obj, key: "name"),
          let typeStr = extractJSONString(obj, key: "type")
        else { continue }
        let label = extractJSONString(obj, key: "label") ?? name
        let placeholder = extractJSONString(obj, key: "placeholder") ?? ""
        let isText = stringEquals(typeStr, "text")
        schema.append(
          SchemaEntry(name: name, label: label, isText: isText, placeholder: placeholder))
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
      let exhausted = usedFieldNames().count >= schema.count
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
        self.onFieldChange(fieldName: hiddenInput.value, row: row)
      }
    }

    private func onFieldChange(fieldName: String, row: DOM.Element) {
      guard let entry = schema.first(where: { stringEquals($0.name, fieldName) }) else { return }
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

      if entry.isText {
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
        let options = optionsForField(fieldName)
        let dropdown = DropdownFactory.createElement(
          id: "filter-\(fieldName)-swap",
          name: fieldName,
          options: options,
          placeholder: entry.label,
          selectedValue: value.isEmpty ? nil : value,
          class: "filter-bar-value-select",
          buttonSize: .large,
          fullWidth: true,
          hydrator: dropdownHydration
        )
        row.insertBefore(dropdown, addOrRemoveBtn)
      }
    }

    private func optionsForField(_ fieldName: String) -> [DropdownView.DropdownOption] {
      guard let rawSchema = grid.getAttribute(data("schema")) else { return [] }
      guard let fromField = findAndSkip("\"name\":\"\(fieldName)\"", in: rawSchema) else { return [] }
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
      let usedNames = usedFieldNames()
      guard
        let nextField = schema.first(where: { entry in
          !usedNames.contains(where: { stringEquals($0, entry.name) })
        })
      else { return }

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
      row.style.display("contents")

      // Col 1: field picker via DropdownFactory
      let picker = DropdownFactory.createElement(
        id: "filter-field-picker-\(rowIndex)",
        name: "__field_\(rowIndex)",
        options: schema.map { DropdownView.DropdownOption(value: $0.name, display: $0.label) },
        placeholder: "Field",
        selectedValue: field.name,
        class: "filter-bar-field-picker",
        buttonSize: .large,
        fullWidth: true,
        hydrator: dropdownHydration
      )
      row.appendChild(picker)

      // Col 2: value input
      if field.isText {
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
        let options = optionsForField(field.name)
        let valueDropdown = DropdownFactory.createElement(
          id: "filter-\(field.name)-\(rowIndex)",
          name: field.name,
          options: options,
          placeholder: field.label,
          class: "filter-bar-value-select",
          buttonSize: .large,
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
        size: .large,
        type: .button,
        class: "filter-bar-remove-btn"
      )
      btn.style.gridColumn("3 / span 2")
      row.appendChild(btn)

      return row
    }

    // MARK: - Helpers

    private func usedFieldNames() -> [String] {
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
