package ApplicationServices

import "core:sys/posix"
foreign import AX "system:ApplicationServices.framework"

import CF "../CoreFoundation"
import CG "../CoreGraphics"

UIElementRef :: CF.TypeRef
ObserverRef :: distinct CF.TypeRef
Value :: CF.TypeRef

Error :: enum i32 {
	ErrorSuccess                           = 0,
	ErrorAttributeUnsupported              = -25205,
	ErrorIllegalArgument                   = -25201,
	ErrorInvalidUIElement                  = -25202,
	ErrorCannotComplete                    = -25204,
	ErrorNotImplemented                    = -25208,
	ErrorNoValue                           = -25212,
	ErrorAPIDisabled                       = -25211,
	ErrorActionUnsupported                 = -25206,
	ErrorFailure                           = -25200,
	ErrorInvalidUIElementObserver          = -25203,
	ErrorNotEnoughPrecision                = -25214,
	ErrorNotificationAlreadyRegistered     = -25209,
	ErrorNotificationNotRegistered         = -25210,
	ErrorNotificationUnsupported           = -25207,
	ErrorParameterizedAttributeUnsupported = -25213,
}

ValueType :: enum u32 {
	Error   = 5,
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
	UIElementCreateSystemWide :: proc() -> UIElementRef ---
	UIElementCreateApplication :: proc(pid: posix.pid_t) -> UIElementRef ---
	UIElementCopyAttributeValue :: proc(element: UIElementRef, attribute: CF.String, value: ^CF.TypeRef) -> Error ---
	UIElementSetAttributeValue :: proc(element: UIElementRef, attribute: CF.String, value: CF.TypeRef) -> Error ---
	ValueCreate :: proc(theType: ValueType, ptr: rawptr) -> Value ---
	ValueGetValue :: proc(value: Value, theType: ValueType, valuePtr: rawptr) -> bool ---

	@(link_name = "_AXUIElementGetWindow")
	UIElementGetWindowID :: proc(element: UIElementRef, windowId: ^CG.WindowID) -> Error ---
}
