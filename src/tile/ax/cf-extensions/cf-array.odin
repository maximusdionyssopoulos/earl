package cf_extensions

foreign import CoreFoundation "system:CoreFoundation.framework"
import cf "core:sys/darwin/CoreFoundation"

Array :: cf.TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	ArrayGetCount :: proc(theArray: Array) -> cf.Index ---
	ArrayGetValueAtIndex :: proc(theArray: Array, idx: cf.Index) -> cf.TypeRef ---
}
