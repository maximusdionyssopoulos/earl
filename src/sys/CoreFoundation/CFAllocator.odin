package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"
Allocator :: TypeRef

foreign CoreFoundation {
	AllocatorGetDefault :: proc() -> Allocator ---
}
