package ax

import cf "core:sys/darwin/CoreFoundation"
foreign import AX "system:ApplicationServices.framework"


AXUIElementRef :: cf.TypeRef


@(default_calling_convention = "c", link_prefix = "AX")
foreign AX {
	IsProcessTrusted :: proc() -> bool ---
	UIElementCreateSystemWide :: proc() -> AXUIElementRef ---
	UIElementCreateApplication :: proc(pid: i32) -> AXUIElementRef ---
}
