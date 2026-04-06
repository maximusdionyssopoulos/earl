package Skylight

// need to use  -extra-linker-flags:"-F/System/Library/PrivateFrameworks"
foreign import SkyLight "system:SkyLight.framework"
import CF "../CoreFoundation"
import CG "../CoreGraphics"

SLConnectionID :: distinct int
WindowIterator :: distinct CF.TypeRef
WindowQuery :: distinct CF.TypeRef

kCGSEvent :: enum u32 {
	windowClosed                = 804,
	spaceWindowCreated          = 1325,
	spaceWindowDestroyed        = 1326,
	frontmostApplicationChanged = 1508,
}

SLRegisterNotifyProc :: proc "c" (
	event: kCGSEvent,
	data: rawptr,
	len: uint,
	_context: rawptr,
	_connextion_id: i32,
)

@(default_calling_convention = "c", link_prefix = "SLS")
foreign SkyLight {
	MainConnectionID :: proc() -> SLConnectionID ---
	CopyManagedDisplaySpaces :: proc(cid: SLConnectionID) -> CF.Array ---
	GetActiveSpace :: proc(cid: SLConnectionID) -> u64 ---
	RegisterConnectionNotifyProc :: proc(cid: SLConnectionID, callback: SLRegisterNotifyProc, event: kCGSEvent, data: rawptr) -> i32 ---
	RemoveConnectionNotifyProc :: proc(cid: SLConnectionID, callback: SLRegisterNotifyProc, event: kCGSEvent) -> i32 ---
	WindowQueryWindows :: proc(cid: SLConnectionID, windows: CF.Array, count: i32) -> WindowQuery ---
	WindowQueryResultCopyWindows :: proc(query: WindowQuery) -> WindowIterator ---
	WindowIteratorGetCount :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorAdvance :: proc(iterator: WindowIterator) -> bool ---
	WindowIteratorGetWindowID :: proc(iterator: WindowIterator) -> CG.WindowID ---
	WindowIteratorGetPID :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorGetLevel :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorGetAttributes :: proc(iterator: WindowIterator) -> u64 ---
	WindowIteratorGetParentID :: proc(iterator: WindowIterator) -> u32 ---
}

SpaceID :: distinct u64
SpaceWindowPayload :: struct #packed {
	space_id:  SpaceID,
	window_id: CG.WindowID,
}
