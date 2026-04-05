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

@(default_calling_convention = "c")
foreign SkyLight {
	SLSMainConnectionID :: proc() -> SLConnectionID ---
	SLSCopyManagedDisplaySpaces :: proc(cid: SLConnectionID) -> CF.Array ---
	SLSGetActiveSpace :: proc(cid: SLConnectionID) -> u64 ---
	SLSRegisterConnectionNotifyProc :: proc(cid: SLConnectionID, callback: SLRegisterNotifyProc, event: kCGSEvent, data: rawptr) -> i32 ---
	SLSRemoveConnectionNotifyProc :: proc(cid: SLConnectionID, callback: SLRegisterNotifyProc, event: kCGSEvent) -> i32 ---
	SLSWindowQueryWindows :: proc(cid: SLConnectionID, windows: CF.Array, count: i32) -> WindowQuery ---
	SLSWindowQueryResultCopyWindows :: proc(query: WindowQuery) -> WindowIterator ---
	SLSWindowIteratorGetCount :: proc(iterator: WindowIterator) -> uint ---
	SLSWindowIteratorAdvance :: proc(iterator: WindowIterator) -> bool ---
	SLSWindowIteratorGetWindowID :: proc(iterator: WindowIterator) -> CG.WindowID ---
	SLSWindowIteratorGetPID :: proc(iterator: WindowIterator) -> uint ---
	SLSWindowIteratorGetLevel :: proc(iterator: WindowIterator) -> uint ---
	SLSWindowIteratorGetAttributes :: proc(iterator: WindowIterator) -> u64 ---
	SLSWindowIteratorGetParentID :: proc(iterator: WindowIterator) -> u32 ---
}

SpaceID :: distinct u64
SpaceWindowPayload :: struct #packed {
	space_id:  SpaceID,
	window_id: CG.WindowID,
}
