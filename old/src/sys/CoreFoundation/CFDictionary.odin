package CFoundation

import "core:fmt"
foreign import CoreFoundation "system:CoreFoundation.framework"

Dictionary :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	DictionaryGetValueIfPresent :: proc(theDict: Dictionary, key: rawptr, value: rawptr) -> bool ---
	DictionaryContainsKey :: proc(theDict: Dictionary, key: rawptr) -> bool ---
	DictionaryGetValue :: proc(theDict: Dictionary, key: rawptr) -> rawptr ---
}


Dictionary_getNumber :: proc($T: typeid, dict: Dictionary, key: String) -> (T, bool) {
	val_ptr: TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return T{}, false
	}

	num_ref := val_ptr
	result: T

	Number_getOdinValue(num_ref, T, &result)
	return result, true
}

Dictionary_getString :: proc(dict: Dictionary, key: String) -> (string, bool) {
	val_ptr: TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return "", false
	}

	return StringCopyToOdinString(cast(String)val_ptr)
}

Dictionary_getBool :: proc(dict: Dictionary, key: String) -> (bool, bool) {
	val_ptr: TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return false, false
	}


	return BooleanGetValue(val_ptr), true
	// return Number_getOdinValue(cast(TypeRef)val_ptr, bool, nil), true
}
