#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct DropdownView: HTML {
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
    let required: Bool
    let tooltip: String?
    let `class`: String
    let buttonWeight: ButtonView.ButtonWeight
    let buttonSize: ButtonView.ButtonSize
    let fullWidth: Bool
    let dropdownWidth: Length?
    let menuWidth: Length?

    public init(
        id: String,
        name: String,
        label: String,
        options: [DropdownOption],
        placeholder: String = "Select an option",
        required: Bool = false,
        tooltip: String? = nil,
        class: String = "",
        buttonWeight: ButtonView.ButtonWeight = .normal,
        buttonSize: ButtonView.ButtonSize = .medium,
        fullWidth: Bool = true,
        width: Length? = nil,
        menuWidth: Length? = nil
    ) {
        self.id = id
        self.name = name
        self.labelText = label
        self.options = options
        self.placeholder = placeholder
        self.required = required
        self.tooltip = tooltip
        self.`class` = `class`
        self.buttonWeight = buttonWeight
        self.buttonSize = buttonSize
        self.fullWidth = fullWidth
        self.dropdownWidth = width
        self.menuWidth = menuWidth
    }

    public func render(indent: Int = 0) -> String {
        div {
            // Label (hidden if quiet/transparent mode)
            if buttonWeight == .normal || buttonWeight == .primary {
                label {
                    labelText

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
                    display(.block)
                    fontSize(fontSizeMedium16)
                    fontWeight(600)
                    color(colorBase)
                    marginBottom(rem(0.5))
                    fontFamily(typographyFontSans)
                }
            }

            // Hidden input to store the selected value
            input()
            .type(.hidden)
            .id("\(id)-value")
            .name(name)
            .required(required)

            // Dropdown container
            div {
                // Trigger button
                div {
                    ButtonView(
                        label: "",
                        weight: buttonWeight,
                        size: buttonSize,
                        fullWidth: fullWidth,
                        class: "dropdown-trigger",
                        buttonFontWeight: fontWeightNormal
                    ) {
                        span { placeholder }
                        .class("dropdown-selected-text")
                        .data("dropdown-selected-text", true)
                        .style {
                            flex(1)
                            textAlign(.left)
                            color(buttonWeight == .quiet || buttonWeight == .transparent ? colorBase : colorSubtle)
                            whiteSpace(.nowrap)
                        }
                        .title(options.first { $0.display == placeholder }?.altDisplay ?? placeholder)

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
                    
                    if buttonWeight == .normal || buttonWeight == .primary {
                        backgroundColor(backgroundColorBase)
                        border(borderWidthBase, .solid, borderColorBase)
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
                                fontSize(fontSizeMedium16)
                                lineHeight(1.5)
                                color(colorBase)
                                backgroundColor(backgroundColorBase)
                                border(borderWidthBase, .solid, borderColorBase)
                                borderRadius(borderRadiusBase)
                                boxSizing(.borderBox)
                                pseudoClass(.focus) {
                                    outline(borderWidthThick, .solid, colorProgressive).important()
                                    borderColor(borderColorProgressive).important()
                                }
                            }
                    }
                    .style {
                        padding(spacing8)
                        borderBottom(borderWidthBase, .solid, borderColorSubtle)
                    }

                    // Options list
                    div {
                        options.map { option in
                            div {
                                option.altDisplay ?? option.display
                            }
                            .class(option.display == placeholder ? "dropdown-option is-selected" : "dropdown-option")
                            .data("dropdown-option", true)
                            .data("value", option.value)
                            .data("display", option.display)
                            .data("alt-display", option.altDisplay ?? "")
                            .style {
                                padding(spacing8, spacing12)
                                fontSize(fontSizeMedium16)
                                color(option.display == placeholder ? colorInvertedFixed : colorBase)
                                backgroundColor(option.display == placeholder ? backgroundColorProgressive : backgroundColorTransparent)
                                cursor(cursorBaseHover)
                                transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                                pseudoClass(.hover) {
                                    backgroundColor(backgroundColorProgressive).important()
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
                    left(0)
                    if let mw = menuWidth {
                        width(mw)
                    } else if dropdownWidth != nil {
                        minWidth(px(200))
                    } else {
                        right(0)
                    }
                    marginTop(spacing4)
                    backgroundColor(backgroundColorBase)
                    border(borderWidthBase, .solid, borderColorBase)
                    borderRadius(borderRadiusBase)
                    boxShadow(boxShadowMedium)
                    zIndex(1000)
                    display(.none)
                }
            }
            .class("dropdown-container")
            .data("dropdown-container", true)
            .style {
                position(.relative)
            }
        }
        .class(`class`.isEmpty ? "dropdown-view form-group" : "dropdown-view form-group \(`class`)")
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

		// Find hidden input by id
		let expectedId = "\(dropdownId)-value"
		let allInputs = document.querySelectorAll("input")
		for input in allInputs {
			if let inputId = input.getAttribute("id"),
			   stringEquals(inputId, expectedId) {
				hiddenInput = input
				break
			}
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
			option.style.display(matches ? .block : .none)
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
		option.style.backgroundColor(backgroundColorProgressive)
		option.style.color(colorInvertedFixed)

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
            guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
                  let dropdownId = trigger.getAttribute("data-dropdown-id") else { continue }

            let instance = DropdownInstance(container: container, dropdownId: dropdownId)
            instances.append(instance)
        }
    }

    public func hydrateDropdown(dropdownId: String) {
        let allContainers = document.querySelectorAll("[data-dropdown-container=\"true\"]")

        for container in allContainers {
            guard let trigger = container.querySelector("[data-dropdown-trigger=\"true\"]"),
                  let id = trigger.getAttribute("data-dropdown-id"),
                  stringEquals(id, dropdownId) else { continue }

            let instance = DropdownInstance(container: container, dropdownId: dropdownId)
            instances.append(instance)
            break
        }
    }
}

#endif
