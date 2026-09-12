package darwin

foreign import CoreFoundation "system:CoreFoundation.framework"
Boolean :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	BooleanGetValue :: proc(boolean: Boolean) -> bool ---
}

