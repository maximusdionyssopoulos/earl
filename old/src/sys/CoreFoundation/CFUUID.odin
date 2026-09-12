package CFoundation

import "core:encoding/uuid"
foreign import CoreFoundation "system:CoreFoundation.framework"
UUID :: TypeRef

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	UUIDCreateFromString :: proc(allocator: Allocator, string: String) -> UUID ---
	UUIDCreateWithBytes :: proc(allocator: Allocator, bytes: uuid.Identifier) -> UUID ---
	UUIDGetUUIDBytes :: proc(_uuid: UUID) -> uuid.Identifier ---
}
