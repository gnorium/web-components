#if !os(WASI)

import CSSBuilder
import DesignTokens
import HTMLBuilder
import WebTypes

/// Generic form view component for creating and editing records.
/// Auto-generates form fields based on configuration.
public struct FormView: HTML {
	/// Form field configuration
	public struct Field: Sendable {
		public let name: String
		public let label: String
		public let type: FieldType
		public let value: String
		public let required: Bool
		public let placeholder: String?
		public let helpText: String?
		public let options: [(value: String, label: String)]?
		public let readOnly: Bool
		public let rows: Int
		
		public enum FieldType: String, Sendable {
			case text
			case textarea
			case email
			case url
			case password
			case number
			case date
			case datetime
			case checkbox
			case select
			case hidden
		}
		
		public init(
			name: String,
			label: String,
			type: FieldType = .text,
			value: String = "",
			required: Bool = false,
			placeholder: String? = nil,
			helpText: String? = nil,
			options: [(value: String, label: String)]? = nil,
			readOnly: Bool = false,
			rows: Int = 5
		) {
			self.name = name
			self.label = label
			self.type = type
			self.value = value
			self.required = required
			self.placeholder = placeholder
			self.helpText = helpText
			self.options = options
			self.readOnly = readOnly
			self.rows = rows
		}
	}
	
	let title: String
	let formAction: String
	let fields: [Field]
	let submitLabel: String
	let cancelUrl: String?
	let cancelLabel: String
	
	public init(
		title: String,
		action: String,
		fields: [Field],
		submitLabel: String = "Save",
		cancelUrl: String? = nil,
		cancelLabel: String = "Cancel"
	) {
		self.title = title
		self.formAction = action
		self.fields = fields
		self.submitLabel = submitLabel
		self.cancelUrl = cancelUrl
		self.cancelLabel = cancelLabel
	}
	
	public func render(indent: Int = 0) -> String {
		div {
			// Header
			h1 { title }
				.style {
					fontFamily(typographyFontSerif)
					fontSize(px(32))
					fontWeight(.normal)
					color(colorBase)
					margin(0)
					marginBottom(spacing32)
				}
			
			// Form
			form {
				for field in fields {
					renderField(field)
				}
				
				// Actions
				div {
					button { submitLabel }
						.type(.submit)
						.style {
							padding(spacing12, spacing24)
							fontFamily(typographyFontSans)
							fontSize(fontSizeMedium16)
							fontWeight(500)
							color(colorInverted)
							backgroundColor(backgroundColorProgressive)
							border(.none)
							borderRadius(borderRadiusBase)
							cursor(.pointer)
							transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
							
							pseudoClass(.hover) {
								backgroundColor(backgroundColorProgressiveHover)
							}
						}
					
					if let url = cancelUrl {
						a { cancelLabel }
							.href(url)
							.style {
								padding(spacing12, spacing24)
								fontFamily(typographyFontSans)
								fontSize(fontSizeMedium16)
								color(colorBase)
								backgroundColor(backgroundColorInteractive)
								border(borderWidthBase, borderStyleBase, borderColorBase)
								borderRadius(borderRadiusBase)
								textDecoration(.none)
								transition(.backgroundColor, transitionDurationBase, transitionTimingFunctionSystem)
								
								pseudoClass(.hover) {
									backgroundColor(backgroundColorInteractiveSubtleHover)
								}
							}
					}
				}
				.class("form-actions")
				.style {
					display(.flex)
					gap(spacing16)
					marginTop(spacing32)
				}
			}
			.action(formAction)
			.method(.post)
		}
		.class("form-view")
		.style {
			maxWidth(px(800))
			margin(0, .auto)
			padding(spacing48, spacing24)
		}
		.render(indent: indent)
	}
	
	@HTMLBuilder
	private func renderField(_ field: Field) -> HTML {
		if field.type == .hidden {
			input()
				.type(.hidden)
				.name(field.name)
				.value(field.value)
		} else if field.type == .checkbox {
			div {
				label {
					input()
						.type(.checkbox)
						.name(field.name)
						.value("true")
						.checked(field.value == "true")
						.style { marginRight(spacing8) }
					
					span { field.label }
				}
				.style {
					display(.flex)
					alignItems(.center)
					fontSize(fontSizeMedium16)
					color(colorBase)
					cursor(.pointer)
				}
				
				if let help = field.helpText {
					p { help }
						.style {
							fontSize(fontSizeSmall14)
							color(colorSubtle)
							marginTop(spacing4)
							marginBottom(0)
						}
				}
			}
			.class("form-field")
			.style { marginBottom(spacing24) }
		} else {
			div {
				label { field.label + (field.required ? "" : " (optional)") }
					.for(field.name)
					.style {
						display(.block)
						fontSize(fontSizeSmall14)
						fontWeight(500)
						color(colorBase)
						marginBottom(spacing8)
					}
				
				fieldInput(field)
				
				if let help = field.helpText {
					p { help }
						.style {
							fontSize(fontSizeSmall14)
							color(colorSubtle)
							marginTop(spacing8)
							marginBottom(0)
						}
				}
			}
			.class("form-field")
			.style { marginBottom(spacing24) }
		}
	}
	
	@HTMLBuilder
	private func fieldInput(_ field: Field) -> HTML {
		switch field.type {
		case .textarea:
			textarea { field.value }
				.name(field.name)
				.id(field.name)
				.required(field.required)
				.disabled(field.readOnly)
				.rows(field.rows)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
				
		case .select:
			select {
				for opt in field.options ?? [] {
					option { opt.label }
						.value(opt.value)
						.selected(opt.value == field.value)
				}
			}
			.name(field.name)
			.id(field.name)
			.required(field.required)
			.disabled(field.readOnly)
			.style { inputStyle() }
			
		case .email:
			input()
				.type(.email)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
				
		case .url:
			input()
				.type(.url)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
				
		case .password:
			input()
				.type(.password)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
				
		case .number:
			input()
				.type(.number)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
				
		case .date:
			input()
				.type(.date)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.style { inputStyle() }
				
		case .datetime:
			input()
				.type(.datetimeLocal)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.style { inputStyle() }
				
		default:
			input()
				.type(.text)
				.name(field.name)
				.id(field.name)
				.value(field.value)
				.required(field.required)
				.disabled(field.readOnly)
				.placeholder(field.placeholder ?? "")
				.style { inputStyle() }
		}
	}
	
	@CSSBuilder
	private func inputStyle() -> [CSS] {
		width(perc(100))
		padding(spacing12, spacing16)
		fontFamily(typographyFontSans)
		fontSize(fontSizeMedium16)
		color(colorBase)
		backgroundColor(backgroundColorBase)
		border(borderWidthBase, borderStyleBase, borderColorBase)
		borderRadius(borderRadiusBase)
		
		pseudoClass(.focus) {
			borderColor(borderColorProgressiveFocus)
			outline(.none)
			boxShadow(.inset, 0, 0, 0, px(1), borderColorProgressiveFocus)
		}
		
		pseudoClass(.disabled) {
			backgroundColor(backgroundColorDisabledSubtle)
			color(colorDisabled)
			cursor(.notAllowed)
		}
	}
}

#endif
