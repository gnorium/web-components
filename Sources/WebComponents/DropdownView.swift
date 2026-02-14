#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct DropdownView: HTMLProtocol {
    public struct DropdownOption: Sendable {
        public let value: String
        public let display: String
        public let altDisplay: String?

        public init(value: String, display: String, altDisplay: String? = nil) {
            self.value = value
            self.display = display
            self.altDisplay = altDisplay
        }
    }

    let id: String
    let name: String
    let labelText: String
    let options: [DropdownOption]
    let placeholder: String
    let selectedValue: String?
    let required: Bool
    let disabled: Bool
    let tooltip: String?
    let `class`: String
    let buttonWeight: ButtonView.ButtonWeight
    let buttonSize: ButtonView.ButtonSize
    let fullWidth: Bool
    let dropdownWidth: Length?
    let menuWidth: Length?
    let textFontSize: Length
    let contentJustifyContent: CSSJustifyContent

    public init(
        id: String,
        name: String,
        label: String,
        options: [DropdownOption],
        placeholder: String = "Select an option",
        selectedValue: String? = nil,
        required: Bool = false,
        disabled: Bool = false,
        tooltip: String? = nil,
        class: String = "",
        buttonWeight: ButtonView.ButtonWeight = .subtle,
        buttonSize: ButtonView.ButtonSize = .medium,
        fullWidth: Bool = true,
        width: Length? = nil,
        menuWidth: Length? = nil,
        fontSize: Length = fontSizeSmall14,
        contentJustifyContent: CSSJustifyContent = .spaceBetween
    ) {
        self.id = id
        self.name = name
        self.labelText = label
        self.options = options
        self.placeholder = placeholder
        self.selectedValue = selectedValue
        self.required = required
        self.disabled = disabled
        self.tooltip = tooltip
        self.`class` = `class`
        self.buttonWeight = buttonWeight
        self.buttonSize = buttonSize
        self.fullWidth = fullWidth
        self.dropdownWidth = width
        self.menuWidth = menuWidth
        self.textFontSize = fontSize
        self.contentJustifyContent = contentJustifyContent
    }

    public func render(indent: Int = 0) -> String {
        div {
            // Label
            if !labelText.isEmpty {
                label {
                    span { labelText }
                    .class("dropdown-label-text")

                    if let tooltipText = tooltip {
						TooltipView(tooltip: tooltipText, placement: .bottom) {
							IconView {
								InfoIconView()
							}
						}
                    }
                }
                .for(id)
                .style {
                    display(.flex)
                    alignItems(.center)
                    gap(spacing4)
                    fontSize(textFontSize)
                    fontWeight(600)
                    color(colorBase)
                    fontFamily(typographyFontSans)
                }
            }

            // Dropdown container
            div {
                // Hidden input to store the selected value
                input()
                .type(.hidden)
                .id("\(id)-value")
                .name(name)
                .value(selectedValue ?? "")
                .required(required)
                .disabled(disabled)

                // Determine display text - use selected option's display or placeholder
                let displayText: String = {
                    if let value = selectedValue,
                       let option = options.first(where: { $0.value == value }) {
                        return option.display
                    }
                    return placeholder
                }()
                // Trigger button
                div {
                    ButtonView(
                        label: "",
                        weight: buttonWeight,
                        size: buttonSize,
                        disabled: disabled,
                        fullWidth: fullWidth,
                        class: "dropdown-trigger",
                        labelFontWeight: fontWeightNormal,
                        contentJustifyContent: contentJustifyContent
                    ) {
                        span { displayText }
                        .class("dropdown-selected-text")
                        .data("dropdown-selected-text", true)
                        .style {
                            textAlign(.start)
                            color(colorBase)
                            whiteSpace(.nowrap)
                        }
                        .title(options.first { $0.value == selectedValue }?.altDisplay ?? displayText)

                        // Icons
                        span {
                            IconView(
                                icon: { s in
                                    ExpandIconView(width: s, height: s)
                                },
                                size: buttonSize == .small ? .xSmall : buttonSize == .medium ? .small : .medium,
                                class: "dropdown-expand-icon"
                            )
                        }
                        .data("dropdown-expand-icon", true)
                        .style {
                            display(.flex)
                            transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                        }

                        span {
                            IconView(
                                icon: { s in
                                    CollapseIconView(width: s, height: s)
                                },
                                size: buttonSize == .small ? .xSmall : buttonSize == .medium ? .small : .medium,
                                class: "dropdown-collapse-icon"
                            )
                        }
                        .data("dropdown-collapse-icon", true)
                        .style {
                            display(.none)
                            transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                        }
                    }
                }
				.class("dropdown-trigger-wrapper")
                .data("dropdown-trigger", true)
                .data("dropdown-id", id)
                .style {
                    if let w = dropdownWidth {
                        width(w)
                    } else if fullWidth {
                        width(perc(100))
                    } else {
                        width(.fitContent)
                    }
                    display(.flex)
                    flex(1)
                    justifyContent(.spaceBetween)
                    media(maxWidth(maxWidthBreakpointMobile)) {
                        width(perc(100)).important()
                    }
                }

                // Dropdown menu
                div {
                    // Search input
                    div {
                        input()
						.type(.text)
						.placeholder("Search...")
						.class("dropdown-search-input")
						.data("dropdown-search", true)
						.style {
							width(perc(100))
							padding(spacing8, spacing12)
							fontSize(textFontSize)
							lineHeight(1.5)
							color(colorBase)
							backgroundColor(backgroundColorBase)
							border(borderWidthBase, .solid, borderColorBase)
							borderRadius(borderRadiusBase)
							boxSizing(.borderBox)
							pseudoClass(.focus) {
								outline(borderWidthThick, .solid, colorBlue).important()
								borderColor(borderColorBlue).important()
							}
						}
                    }
                    .style {
                        padding(spacing8)
                        borderBlockEnd(borderWidthBase, .solid, borderColorSubtle)
                    }

                    // Options list
                    div {
                        options.map { option in
                            let isSelected = option.value == selectedValue
                            return div {
                                span { option.display }
                                if let alt = option.altDisplay, !alt.isEmpty {
                                    span { alt }
                                    .style {
                                        marginInlineStart(.auto)
                                    }
                                }
                            }
                            .class(isSelected ? "dropdown-option is-selected" : "dropdown-option")
                            .data("dropdown-option", true)
                            .data("value", option.value)
                            .data("display", option.display)
                            .data("alt-display", option.altDisplay ?? "")
                            .style {
                                display(.flex)
                                alignItems(.center)
                                gap(spacing8)
                                padding(spacing8, spacing12)
                                fontSize(textFontSize)
                                color(isSelected ? colorInvertedFixed : colorBase)
                                backgroundColor(isSelected ? backgroundColorBlue : backgroundColorTransparent)
                                cursor(cursorBaseHover)
                                transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                                pseudoClass(.hover) {
                                    backgroundColor(backgroundColorBlue).important()
                                    color(colorInvertedFixed).important()
                                }
                            }
                        }
                    }
                    .class("dropdown-options-list")
                    .data("dropdown-options-list", true)
                    .style {
                        maxHeight(px(300))
                        overflowY(.auto)
                    }
                }
                .class("dropdown-menu")
                .data("dropdown-menu", true)
                .style {
                    position(.absolute)
                    top(perc(100))
                    insetInlineStart(0)
                    if let mw = menuWidth {
                        width(mw)
                    } else if dropdownWidth != nil {
                        minWidth(px(250))
                    } else {
                        insetInlineEnd(0)
                    }
                    marginBlockStart(spacing4)
                    backgroundColor(backgroundColorBase)
                    border(borderWidthBase, .solid, borderColorBase)
                    borderRadius(borderRadiusBase)
                    boxShadow(boxShadowMedium)
                    zIndex(zIndexDropdown)
                    display(.none)
                    overflow(.hidden)
                    media(maxWidth(maxWidthBreakpointMobile)) {
                        width(perc(100)).important()
                        insetInlineStart(0).important()
                        insetInlineEnd(0).important()
                    }
                }
            }
            .class("dropdown-container")
            .data("dropdown-container", true)
            .data("dropdown-disabled", disabled)
            .style {
                position(.relative)
                if disabled {
                    pointerEvents(.none)
                }
                media(maxWidth(maxWidthBreakpointMobile)) {
                    width(perc(100)).important()
                }
            }
        }
        .class(`class`.isEmpty ? "dropdown-view" : "dropdown-view \(`class`)")
		.style {
			display(.flex)
			flexDirection(.column)
			gap(spacing8)
			if fullWidth {
				width(perc(100))
			} else {
				media(maxWidth(maxWidthBreakpointMobile)) {
					width(perc(100)).important()
				}
			}
		}
        .render(indent: indent)
    }
}

#endif

#if os(WASI)

import WebAPIs
import DesignTokens
import WebTypes
import EmbeddedSwiftUtilities

private class DropdownInstance: @unchecked Sendable {
	private var container: Element?
	private var trigger: Element?
	private var menu: Element?
	private var searchInput: Element?
	private var optionsList: Element?
	private var selectedText: Element?
	private var hiddenInput: Element?
	private var expandIcon: Element?
	private var collapseIcon: Element?
	private var isOpen: Bool = false
	private var allOptions: [Element] = []

	init(container: Element, dropdownId: String) {
		self.container = container
		trigger = container.querySelector("[data-dropdown-trigger=\"true\"]")
		menu = container.querySelector("[data-dropdown-menu=\"true\"]")
		searchInput = container.querySelector("[data-dropdown-search=\"true\"]")
		optionsList = container.querySelector("[data-dropdown-options-list=\"true\"]")
		selectedText = container.querySelector("[data-dropdown-selected-text=\"true\"]")
		expandIcon = container.querySelector("[data-dropdown-expand-icon=\"true\"]")
		collapseIcon = container.querySelector("[data-dropdown-collapse-icon=\"true\"]")

		// Find hidden input relative to container
		hiddenInput = container.querySelector("input[type=\"hidden\"]")
		if hiddenInput == nil {
			hiddenInput = container.parentElement?.querySelector("input[type=\"hidden\"]")
		}

		// Get all options
		if let optionsList {
			allOptions = Array(optionsList.querySelectorAll("[data-dropdown-option=\"true\"]"))
		}

		bindEvents()
	}

	private func bindEvents() {
		guard let trigger, let searchInput else { return }

		// Toggle dropdown on trigger click
		_ = trigger.addEventListener(.click) { [self] _ in
			self.toggleDropdown()
		}

		// Search functionality
		_ = searchInput.addEventListener(.input) { [self] _ in
			self.filterOptions()
		}

		// Option click handlers
		for option in allOptions {
			_ = option.addEventListener(.click) { [self] _ in
				self.selectOption(option)
			}
		}

		// Click outside handler
		_ = document.addEventListener(.click) { [self] event in
			guard self.isOpen,
				  let target = event.target,
				  let container = self.container else { return }

			// Close if click is outside the dropdown container
			if !container.contains(target) {
				self.closeDropdown()
			}
		}

		// Keydown handler for auto-focusing search
		_ = document.addEventListener(.keydown) { [self] event in
			guard self.isOpen, let searchInput = self.searchInput else { return }
            
            // Get key from event
            let key = event.key

            // Check if it's a single printable character (and not a modifier combo if possible to check)
            // Note: Simplistic check for length 1 and alphanumeric ranges could work
            // Check if it's a single printable character (and not a modifier combo if possible to check)
            // Note: Simplistic check for length 1 and alphanumeric ranges could work
            if key.utf8.count == 1, let charByte = key.utf8.first {
                // Check if it's a letter or number (ASCII only to avoid Unicode normalization code bloat)
                // a-z: 97-122
                // A-Z: 65-90
                // 0-9: 48-57
                let isLetterOrNumber = (charByte >= 97 && charByte <= 122) || 
                                       (charByte >= 65 && charByte <= 90) || 
                                       (charByte >= 48 && charByte <= 57)
                
                if isLetterOrNumber {
                    searchInput.focus()
                }
            }
		}
	}

	private func toggleDropdown() {
		if isOpen {
			closeDropdown()
		} else {
			openDropdown()
		}
	}

	private func openDropdown() {
		menu?.style.display(.block)
		expandIcon?.style.display(.none)
		collapseIcon?.style.display(.flex)
		isOpen = true
	}

	private func closeDropdown() {
		menu?.style.display(.none)
		expandIcon?.style.display(.flex)
		collapseIcon?.style.display(.none)
		isOpen = false
		searchInput?.value = ""
		filterOptions() // Reset filter
	}

	private func filterOptions() {
		guard let searchInput else { return }

		let searchValue = searchInput.value

		for option in allOptions {
			guard let displayValue = option.getAttribute("data-display") else {
				option.style.display(.none)
				continue
			}

			// Use utility function for case-insensitive substring match
			let matches = stringContainsCaseInsensitive(displayValue, searchValue) ||
                          stringContainsCaseInsensitive(option.getAttribute("data-alt-display") ?? "", searchValue)
			if matches {
				option.style.display(.flex)
			} else {
				option.style.display(.none)
			}
		}
	}
    
	private func selectOption(_ option: Element) {
		guard let value = option.getAttribute("data-value"),
			  let display = option.getAttribute("data-display") else { return }

		// Update hidden input
		hiddenInput?.value = value

		// Get altDisplay for tooltip
		let altDisplay = option.getAttribute("data-alt-display") ?? display

		// Update selected text and title (tooltip)
		selectedText?.innerHTML = display
		selectedText?.setAttribute("title", altDisplay)

		// Update selected state in menu
		for opt in allOptions {
			_ = opt.classList.remove("is-selected")
			opt.style.backgroundColor(backgroundColorTransparent)
			opt.style.color(colorBase)
		}
		_ = option.classList.add("is-selected")
		option.style.backgroundColor(backgroundColorBlue)
		option.style.color(colorInvertedFixed)

		// Dispatch change event on hidden input
		if let hiddenInput {
			hiddenInput.dispatchEvent(.change)
		}

		closeDropdown()
	}
}

public class DropdownHydration: @unchecked Sendable {
    private var instances: [DropdownInstance] = []

    public init() {
        hydrateAllDropdowns()
    }

    private func hydrateAllDropdowns() {
        let allContainers = document.querySelectorAll("[data-dropdown-container=\"true\"]")
        for container in allContainers {
            if container.hasAttribute("data-dropdown-hydrated") { continue }

            guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
                  let dropdownId = trigger.getAttribute("data-dropdown-id") else { continue }

            let instance = DropdownInstance(container: container, dropdownId: dropdownId)
            instances.append(instance)
            container.setAttribute("data-dropdown-hydrated", "true")
        }
    }

    public func hydrate(element: Element) {
        if element.hasAttribute("data-dropdown-hydrated") { return }
        
        guard let trigger = element.querySelector("[data-dropdown-trigger=\"true\"]"),
              let dropdownId = trigger.getAttribute("data-dropdown-id") else { return }

        let instance = DropdownInstance(container: element, dropdownId: dropdownId)
        instances.append(instance)
        element.setAttribute("data-dropdown-hydrated", "true")
    }

    public func hydrateDropdown(dropdownId: String) {
        let allContainers = document.querySelectorAll("[data-dropdown-container=\"true\"]")

        for container in allContainers {
            if container.hasAttribute("data-dropdown-hydrated") { continue }

            guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
                  let id = trigger.getAttribute("data-dropdown-id"),
                  stringEquals(id, dropdownId) else { continue }

            let instance = DropdownInstance(container: container, dropdownId: dropdownId)
            instances.append(instance)
            container.setAttribute("data-dropdown-hydrated", "true")
            break
        }
    }
}

#endif
