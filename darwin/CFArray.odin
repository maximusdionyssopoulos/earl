package darwin

foreign import CoreFoundation "system:CoreFoundation.framework"
Array :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	ArrayGetCount :: proc(theArray: Array) -> Index ---
	ArrayGetValueAtIndex :: proc(theArray: Array, idx: Index) -> TypeRef ---
	ArrayCreate :: proc(allocator: Allocator, values: rawptr, numValues: Index, callbacks: rawptr) -> Array ---
}

