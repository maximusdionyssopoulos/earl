package CoreGraphics

foreign import CoreGraphics "system:CoreGraphics.framework"
import CF "../CoreFoundation"

WindowListOption :: distinct u32

kCGWindowListOptionAll :: 0
kCGWindowListOptionOnScreenOnly :: (1 << 0)
kCGWindowListOptionOnScreenAboveWindow :: (1 << 1)
kCGWindowListOptionOnScreenBelowWindow :: (1 << 2)
kCGWindowListOptionIncludingWindow :: (1 << 3)
kCGWindowListExcludeDesktopElements :: (1 << 4)

WindowID :: distinct u32
kCGNullWindowID :: WindowID(0)

@(default_calling_convention = "c", link_prefix = "CG")
foreign CoreGraphics {
	WindowListCopyWindowInfo :: proc(option: WindowListOption, relativeToWindow: WindowID) -> Array ---
}

@(default_calling_convention = "c", link_prefix = "kCG")
foreign CoreGraphics {
	WindowOwnerPID: CF.String
	WindowOwnerName: CF.String
	WindowName: CF.String
	WindowLayer: CF.String
	WindowNumber: CF.String
}
