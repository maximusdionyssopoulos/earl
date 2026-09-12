package darwin

// need to use  -extra-linker-flags:"-F/System/Library/PrivateFrameworks"
foreign import SkyLight "system:SkyLight.framework"

SLConnectionID :: distinct int
WindowIterator :: distinct TypeRef
WindowQuery :: distinct TypeRef

Event :: enum u32 {
	spaceWindowCreated   = 1325,
	spaceWindowDestroyed = 1326,
}

RegisterNotifyProc :: proc "c" (
	event: Event,
	data: rawptr,
	len: uint,
	_context: rawptr,
	_connextion_id: i32,
)

@(default_calling_convention = "c", link_prefix = "SLS")
foreign SkyLight {
	MainConnectionID :: proc() -> SLConnectionID ---
	CopyManagedDisplaySpaces :: proc(cid: SLConnectionID) -> Array ---
	GetActiveSpace :: proc(cid: SLConnectionID) -> u64 ---
	RegisterConnectionNotifyProc :: proc(cid: SLConnectionID, callback: RegisterNotifyProc, event: Event, data: rawptr) -> i32 ---
	RemoveConnectionNotifyProc :: proc(cid: SLConnectionID, callback: RegisterNotifyProc, event: Event) -> i32 ---
	WindowQueryWindows :: proc(cid: SLConnectionID, windows: Array, count: i32) -> WindowQuery ---
	WindowQueryResultCopyWindows :: proc(query: WindowQuery) -> WindowIterator ---
	WindowIteratorGetCount :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorAdvance :: proc(iterator: WindowIterator) -> bool ---
	WindowIteratorGetWindowID :: proc(iterator: WindowIterator) -> WindowID ---
	WindowIteratorGetPID :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorGetLevel :: proc(iterator: WindowIterator) -> uint ---
	WindowIteratorGetAttributes :: proc(iterator: WindowIterator) -> u64 ---
	WindowIteratorGetParentID :: proc(iterator: WindowIterator) -> u32 ---
	GetWindowBounds :: proc(cid: SLConnectionID, window_id: WindowID, frame: ^Rect) -> CGError ---
	CopyWindowsWithOptionsAndTags :: proc(cid: SLConnectionID, owner: uint, spaces: Array, options: uint, set_tags: ^u64, clear_tags: ^u64) -> Array ---
}

SpaceID :: distinct u64
SpaceWindowPayload :: struct #packed {
	space_id:  SpaceID,
	window_id: WindowID,
}

WindowQueryIteratorResult :: struct {
	parent_id:  u32,
	pid:        uint,
	level:      uint,
	attributes: u64,
}
WindowQueryIteratorTraits :: enum {
	ParentID,
	PID,
	Level,
	Attributes,
}

