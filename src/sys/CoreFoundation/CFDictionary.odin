package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Dictionary :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	DictionaryGetValueIfPresent :: proc(theDict: Dictionary, key: rawptr, value: rawptr) -> bool ---
}


Dictionary_getInt :: proc(dict: Dictionary, key: String) -> (i32, bool) {
	val_ptr: TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return 0, false
	}

	num_ref := val_ptr
	result: i32

	Number_getOdinValue(num_ref, i32, &result)
	return result, true
}

Dictionary_getString :: proc(dict: Dictionary, key: String) -> (string, bool) {
	val_ptr: TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return "", false
	}

	return StringCopyToOdinString(cast(String)val_ptr)
}
