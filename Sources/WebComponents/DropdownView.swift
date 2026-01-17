#if !os(WASI)

import HTMLBuilder
import CSSBuilder
import SVGBuilder
import DesignTokens
import WebTypes

public struct DropdownView: HTML {
    let id: String
    let name: String
    let labelText: String
    let options: [(value: String, display: String)]
    let placeholder: String
    let required: Bool
    let tooltip: String?
    let `class`: String
    let quiet: Bool
    let dropdownWidth: Length?
    let menuWidth: Length?

    public init(
        id: String,
        name: String,
        label: String,
        options: [(value: String, display: String)],
        placeholder: String = "Select an option",
        required: Bool = false,
        tooltip: String? = nil,
        class: String = "",
        quiet: Bool = false,
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
        self.quiet = quiet
        self.dropdownWidth = width
        self.menuWidth = menuWidth
    }

    public func render(indent: Int = 0) -> String {
        div {
            // Label (hidden if quiet mode)
            if !quiet {
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
                button {
                    span { placeholder }
                        .class("dropdown-selected-text")
                        .data("dropdown-selected-text", true)
                        .style {
                            flex(1)
                            textAlign(.left)
                            color(quiet ? colorBase : colorSubtle)
                            whiteSpace(.nowrap)
                        }

                    // Chevron icon
                    span {
                        svg {
                            path()
							.d(M(4, 6), l(6, 6), l(6, -6))
							.fill(.none)
							.stroke(.currentColor)
							.strokeWidth(2)
							.strokeLinecap(.round)
							.strokeLinejoin(.round)
                        }
                        .width(px(16))
                        .height(px(16))
                        .viewBox(0, 0, 20, 20)
                        .xmlns("http://www.w3.org/2000/svg")
                    }
                    .class("dropdown-chevron")
                    .data("dropdown-chevron", true)
                    .style {
                        display(.flex)
                        alignItems(.center)
                        transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                    }
                }
                .type(.button)
                .class("dropdown-trigger")
                .data("dropdown-trigger", true)
                .data("dropdown-id", id)
                .style {
                    if let w = dropdownWidth {
                        width(w)
                    } else {
                        width(perc(100))
                    }
                    display(.flex)
                    alignItems(.center)
                    justifyContent(.spaceBetween)
                    padding(spacing8, spacing12)
                    fontSize(fontSizeMedium16)
                    lineHeight(1.5)
                    color(colorBase)
                    backgroundColor(quiet ? backgroundColorTransparent : backgroundColorBase)
                    border(borderWidthBase, .solid, quiet ? backgroundColorTransparent : borderColorBase)
                    borderRadius(borderRadiusBase)
                    cursor(cursorBaseHover)
                    boxSizing(.borderBox)
                    transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                    pseudoClass(.hover) {
                        borderColor(borderColorProgressive)
                    }
                    pseudoClass(.focus) {
                        outline(borderWidthThick, .solid, colorProgressive).important()
                        borderColor(borderColorProgressive).important()
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
                                option.display
                            }
                            .class("dropdown-option")
                            .data("dropdown-option", true)
                            .data("value", option.value)
                            .data("display", option.display)
                            .style {
                                padding(spacing8, spacing12)
                                fontSize(fontSizeMedium16)
                                color(colorBase)
                                cursor(cursorBaseHover)
                                transition(transitionPropertyBase, transitionDurationBase, transitionTimingFunctionSystem)
                                pseudoClass(.hover) {
                                    backgroundColor(backgroundColorInteractiveSubtle)
                                    color(colorProgressive)
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
	private var chevron: Element?
	private var isOpen: Bool = false
	private var allOptions: [Element] = []

	init(container: Element, dropdownId: String) {
		self.container = container
		trigger = container.querySelector("[data-dropdown-trigger=\"true\"]")
		menu = container.querySelector("[data-dropdown-menu=\"true\"]")
		searchInput = container.querySelector("[data-dropdown-search=\"true\"]")
		optionsList = container.querySelector("[data-dropdown-options-list=\"true\"]")
		selectedText = container.querySelector("[data-dropdown-selected-text=\"true\"]")
		chevron = container.querySelector("[data-dropdown-chevron=\"true\"]")

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
		chevron?.style.transform(rotate(deg(180)))
		isOpen = true
	}

	private func closeDropdown() {
		menu?.style.display(.none)
		chevron?.style.transform(rotate(deg(0)))
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
			let matches = stringContainsCaseInsensitive(displayValue, searchValue)
			option.style.display(matches ? .block : .none)
		}
	}

	private func selectOption(_ option: Element) {
		guard let value = option.getAttribute("data-value"),
			  let display = option.getAttribute("data-display") else { return }

		// Update hidden input
		hiddenInput?.value = value

		// Update selected text
		selectedText?.innerHTML = display
		selectedText?.style.color(.inherit)

		// Close dropdown
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
