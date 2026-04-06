package CGraphics

foreign import CoreGraphics "system:CoreGraphics.framework"
import CF "../CoreFoundation"

WindowListOption :: distinct u32

WindowListOptionAll :: 0
WindowListOptionOnScreenOnly :: (1 << 0)
WindowListOptionOnScreenAboveWindow :: (1 << 1)
WindowListOptionOnScreenBelowWindow :: (1 << 2)
WindowListOptionIncludingWindow :: (1 << 3)
WindowListExcludeDesktopElements :: (1 << 4)

WindowID :: distinct u32
NullWindowID :: WindowID(0)

@(default_calling_convention = "c", link_prefix = "CG")
foreign CoreGraphics {
	WindowListCopyWindowInfo :: proc(option: WindowListOption, relativeToWindow: WindowID) -> CF.Array ---
}

@(default_calling_convention = "c", link_prefix = "kCG")
foreign CoreGraphics {
	WindowOwnerPID: CF.String
	WindowOwnerName: CF.String
	WindowName: CF.String
	WindowLayer: CF.String
	WindowNumber: CF.String
}

foreign import "system:ColorSync.framework"
@(link_prefix = "CG", default_calling_convention = "c")
foreign ColorSync {
	DisplayCreateUUIDFromDisplayID :: proc(displayID: DirectDisplayID) -> CF.UUID ---
	DisplayGetDisplayIDFromUUID :: proc(uuid: CF.UUID) -> DirectDisplayID ---
}
