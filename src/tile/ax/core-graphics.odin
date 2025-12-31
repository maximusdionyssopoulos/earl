package ax

import cfe "cf-extensions"
import cf "core:sys/darwin/CoreFoundation"

foreign import CoreFoundations "system:CoreGraphics.framework"

WindowListOption :: distinct u32

kCGWindowListOptionAll :: 0
kCGWindowListOptionOnScreenOnly :: (1 << 0)
kCGWindowListOptionOnScreenAboveWindow :: (1 << 1)
kCGWindowListOptionOnScreenBelowWindow :: (1 << 2)
kCGWindowListOptionIncludingWindow :: (1 << 3)
kCGWindowListExcludeDesktopElements :: (1 << 4)

WindowID :: distinct u32
kCGNullWindowID :: WindowID(0)

@(default_calling_convention = "c")
foreign CoreFoundations {
	CGWindowListCopyWindowInfo :: proc(option: WindowListOption, relativeToWindow: WindowID) -> cfe.Array ---
}

@(default_calling_convention = "c")
foreign CoreFoundations {
	kCGWindowOwnerPID: cf.String
	kCGWindowOwnerName: cf.String
	kCGWindowName: cf.String
	kCGWindowLayer: cf.String
	kCGWindowNumber: cf.String
}
