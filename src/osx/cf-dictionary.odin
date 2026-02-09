package osx

foreign import CoreFoundation "system:CoreFoundation.framework"
import cf "core:sys/darwin/CoreFoundation"

Dictionary :: cf.TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	DictionaryGetValueIfPresent :: proc(theDict: Dictionary, key: rawptr, value: rawptr) -> bool ---
}

get_int_from_dict :: proc(dict: Dictionary, key: cf.String) -> (i32, bool) {
	val_ptr: cf.TypeRef

	if !DictionaryGetValueIfPresent(dict, rawptr(key), &val_ptr) {
		return 0, false
	}

	num_ref := val_ptr
	result: i32

	cf_number_get_value(num_ref, i32, &result)
	return result, true
}
