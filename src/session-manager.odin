package earl
import hm "core:container/handle_map"

MAX_SESSIONS :: 10

SessionManager :: struct {
	active_session: Handle,
	sessions:       hm.Static_Handle_Map(MAX_SESSIONS + 1, Session, Handle), // zero value is reserved for sentinel : https://pkg.odin-lang.org/core/container/handle_map/#static_cap
	screens:        [dynamic]ScreenUUID,
	windows:        hm.Dynamic_Handle_Map(Window, WindowHandle),
	_initialised:   bool,
}

Manager := SessionManager{}

sessionManager_setActive :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_is_valid(manager.sessions, handle) or_return

	manager.active_session = handle
	return true
}


SessionManager_Error :: enum byte {
	None = 0,
	Already_Initialised = 1,
	Window_Init_Error = 2,
	Screens_Init_Error,
}
