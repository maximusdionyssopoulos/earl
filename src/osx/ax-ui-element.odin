package osx

import cf "core:sys/darwin/CoreFoundation"
import "core:sys/posix"
foreign import AX "system:ApplicationServices.framework"


TypeRef :: cf.TypeRef
AXUIElementRef :: cf.TypeRef
AXValue :: cf.TypeRef

ReleaseObject :: cf.ReleaseObject
CGPoint :: cf.CGPoint
CGSize :: cf.CGSize
CGFloat :: cf.CGFloat


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


@(default_calling_convention = "c", link_prefix = "AX")
foreign AX {
	IsProcessTrusted :: proc() -> bool ---
	UIElementCreateSystemWide :: proc() -> AXUIElementRef ---
	UIElementCreateApplication :: proc(pid: posix.pid_t) -> AXUIElementRef ---
	UIElementCopyAttributeValue :: proc(element: AXUIElementRef, attribute: cf.String, value: ^cf.TypeRef) -> AXError ---
	UIElementSetAttributeValue :: proc(element: AXUIElementRef, attribute: cf.String, value: cf.TypeRef) -> AXError ---
	ValueCreate :: proc(theType: AXValueType, ptr: rawptr) -> AXValue ---
	ValueGetValue :: proc(value: AXValue, theType: AXValueType, valuePtr: rawptr) -> bool ---
}

Attribute :: cf.String
PositionAttribute := Attribute(cf.STR("AXPosition"))
SizeAttribute := (cf.STR("AXSize"))
// FocusedAttribute :: cf.StringMakeConstantString("kAXFocused")
WindowsAttribute := cf.STR("AXWindows")

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
	window_list := WindowListCopyWindowInfo(options, kCGNullWindowID)
	defer cf.ReleaseObject(window_list)

	count := ArrayGetCount(window_list)
	processed_pids := make(map[i32]bool)
	defer delete(processed_pids)

	ax_ui_elements := make([dynamic]AXUIElementRef, allocator)

	for i in 0 ..< count {
		{
			dict := ArrayGetValueAtIndex(window_list, i)

			pid := get_int_from_dict(dict, WindowOwnerPID) or_continue

			if (pid in processed_pids) do continue

			processed_pids[pid] = true


			get_window_refs_from_pid(posix.pid_t(pid), &ax_ui_elements)
		}
	}

	return ax_ui_elements, true
}

get_window_refs_from_pid :: proc(pid: posix.pid_t, window_refs: ^[dynamic]AXUIElementRef) {
	appAxUIEl := UIElementCreateApplication(pid)

	windowAxUIElements: Array
	ax_error := UIElementCopyAttributeValue(appAxUIEl, WindowsAttribute, &windowAxUIElements)
	if ax_error != AXError.kAXErrorSuccess do return

	windowsCount := ArrayGetCount(windowAxUIElements)
	for i in 0 ..< windowsCount {
		append(window_refs, ArrayGetValueAtIndex(windowAxUIElements, i))
	}
}
