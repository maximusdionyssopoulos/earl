package ApplicationServices

import "core:sys/posix"
foreign import AX "system:ApplicationServices.framework"

import CF "../CoreFoundation"

AXUIElementRef :: CF.TypeRef
AXValue :: CF.TypeRef

AXError :: enum i32 {
	kAXErrorSuccess                           = 0,
	kAXErrorAttributeUnsupported              = -25205,
	kAXErrorIllegalArgument                   = -25201,
	kAXErrorInvalidUIElement                  = -25202,
	kAXErrorCannotComplete                    = -25204,
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

AXValueType :: enum u32 {
	AXError = 5,
	CFRange = 4,
	CGPoint = 1,
	CGRect  = 3,
	CGSize  = 2,
	Illegal = 0,
}

Attribute :: CF.String
PositionAttribute := Attribute(CF.STR("AXPosition"))
SizeAttribute := (CF.STR("AXSize"))
// FocusedAttribute :: CF.StringMakeConstantString("kAXFocused")
WindowsAttribute := CF.STR("AXWindows")


@(default_calling_convention = "c", link_prefix = "AX")
foreign AX {
	IsProcessTrusted :: proc() -> bool ---
	UIElementCreateSystemWide :: proc() -> AXUIElementRef ---
	UIElementCreateApplication :: proc(pid: posix.pid_t) -> AXUIElementRef ---
	UIElementCopyAttributeValue :: proc(element: AXUIElementRef, attribute: CF.String, value: ^CF.TypeRef) -> AXError ---
	UIElementSetAttributeValue :: proc(element: AXUIElementRef, attribute: CF.String, value: CF.TypeRef) -> AXError ---
	ValueCreate :: proc(theType: AXValueType, ptr: rawptr) -> AXValue ---
	ValueGetValue :: proc(value: AXValue, theType: AXValueType, valuePtr: rawptr) -> bool ---
}

getApplicationPids :: proc(pids: ^[posix.pid_t]struct{}) -> bool {
	if !IsProcessTrusted() do return false

	options := WindowListOption(
		kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
	)
	window_list := WindowListCopyWindowInfo(options, kCGNullWindowID)
	defer cf.ReleaseObject(window_list)

	count := ArrayGetCount(window_list)
	defer delete(processed_pids)

	for i in 0 ..< count {
		{
			dict := ArrayGetValueAtIndex(window_list, i)
			pid := dict->Dictionary_getInt(WindowOwnerPID) or_continue

			if (pid in processed_pids) do continue

			pids[pid] = {}
		}
	}

	return true

}

getWindowRefsFromPid :: proc(pid: posix.pid_t, window_refs: ^[dynamic]AXUIElementRef) {
	appAxUIEl := UIElementCreateApplication(pid)

	windowAxUIElements: CF.Array
	ax_error := UIElementCopyAttributeValue(appAxUIEl, WindowsAttribute, &windowAxUIElements)
	if ax_error != AXError.kAXErrorSuccess do return

	windowsCount := CF.ArrayGetCount(windowAxUIElements)
	for i in 0 ..< windowsCount {
		append(window_refs, CF.ArrayGetValueAtIndex(windowAxUIElements, i))
	}
}
