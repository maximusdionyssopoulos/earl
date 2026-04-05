package CFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"
UUID :: TypeRef

UUIDBytes :: struct {
	byte0:  u8,
	byte1:  u8,
	byte2:  u8,
	byte3:  u8,
	byte4:  u8,
	byte5:  u8,
	byte6:  u8,
	byte7:  u8,
	byte8:  u8,
	byte9:  u8,
	byte10: u8,
	byte11: u8,
	byte12: u8,
	byte13: u8,
	byte14: u8,
	byte15: u8,
}

@(link_prefix = "CF", default_calling_convention = "c")
foreign CoreFoundation {
	UUIDGetUUIDBytes :: proc(uuid: UUID) -> UUIDBytes ---
}
