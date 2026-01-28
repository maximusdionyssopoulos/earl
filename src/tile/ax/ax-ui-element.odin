package ax

import cf "core:sys/darwin/CoreFoundation"
foreign import AX "system:ApplicationServices.framework"

import cfe "cf-extensions"

AXUIElementRef :: cf.TypeRef


AXError :: enum i32 {
	kAXErrorSuccess                           = 0,
	kAXErrorAttributeUnsupported              = -25025,
	kAXErrorIllegalArgument                   = -25201,
	kAXErrorInvalidUIElement                  = -25202,
	kAXErrorCannotComplete                    = -250204,
	kAXErrorNotImplemented                    = -25208,
	kAXErrorNoValue                           = -25212,
	kAXErrorAPIDisabled                       = -25211,
	kAXErrorActionUnsupported                 = -25206,
	kAXErrorFailure                           = -25200,
	kAXErrorInvalidUIElementObserver          = -25203,
	kAXErrorNotEnoughPrecision                = -25214,
	kAXErrorNotificationAlreadyRegistered     = -25209,
	kAXErrorNotificationNotRegistered         = -25210,
	kAXErrorNotificationUnsupported           = -25207,
	kAXErrorParameterizedAttributeUnsupported = -25213,
}

@(default_calling_convention = "c", link_prefix = "AX")
foreign AX {
	IsProcessTrusted :: proc() -> bool ---
	UIElementCreateSystemWide :: proc() -> AXUIElementRef ---
	UIElementCreateApplication :: proc(pid: i32) -> AXUIElementRef ---
	UIElementCopyAttributeValue :: proc(element: AXUIElementRef, attribute: cf.String, value: cf.TypeRef) -> AXError ---
	UIElementSetAttributeValue :: proc(element: AXUIElementRef, attribute: cf.String, value: Maybe(cf.TypeRef)) -> AXError ---
}

@(default_calling_convention = "c", link_prefix = "kAX")
foreign AX {
	PositionAttribure: cf.String
	SizeAttribute: cf.String
	FocusedAttribute: cf.String
	WindowsAttibute: cf.String
}

GetCurrentWindowAXUIElements :: proc(
	allocator := context.allocator,
) -> (
	arr: [dynamic]AXUIElementRef,
	ok: bool,
) #optional_ok {
	if !IsProcessTrusted() do return

	options := WindowListOption(
		kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
	)
	window_list := CGWindowListCopyWindowInfo(options, kCGNullWindowID)
	defer cf.ReleaseObject(window_list)

	count := cfe.ArrayGetCount(window_list)
	processed_pids := make(map[i32]bool)
	defer delete(processed_pids)

	ax_ui_elements := make([dynamic]AXUIElementRef, allocator)

	for i in 0 ..< count {
		{
			dict := cfe.ArrayGetValueAtIndex(window_list, i)
			// defer cf.ReleaseObject(dict)

			pid := cfe.get_int_from_dict(dict, kCGWindowOwnerPID) or_continue

			if (pid in processed_pids) do continue

			processed_pids[pid] = true

			appAxUIEl := UIElementCreateApplication(pid)

			windowAxUIElements: cfe.Array
			if UIElementCopyAttributeValue(appAxUIEl, WindowsAttibute, windowAxUIElements) != AXError.kAXErrorSuccess do return

			windowsCount := cfe.ArrayGetCount(windowAxUIElements)
			for j in 0 ..< count {
				append(&ax_ui_elements, cfe.ArrayGetValueAtIndex(windowAxUIElements, j))
			}
		}
	}

	return ax_ui_elements, true
}
