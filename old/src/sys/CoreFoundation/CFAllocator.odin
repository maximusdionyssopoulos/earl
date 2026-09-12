package CFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"
Allocator :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	AllocatorGetDefault :: proc() -> Allocator ---
}
