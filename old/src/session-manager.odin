package earl
import hm "core:container/handle_map"

MAX_SESSIONS :: 10


Applications :: hm.Dynamic_Handle_Map(Application, ApplicationHandle)
Windows :: hm.Dynamic_Handle_Map(Window, WindowHandle)

SessionManager :: struct {
	active_session: SessionHandle,
	sessions:       hm.Static_Handle_Map(MAX_SESSIONS + 1, Session, SessionHandle), // zero value is reserved for sentinel : https://pkg.odin-lang.org/core/container/handle_map/#static_cap
	displays:       hm.Static_Handle_Map(MAX_SCREENS, Display, DisplayHandle),
	applications:   Applications,
	windows:        Windows,
	events:         EventQueue,
}

SessionManager_init :: proc(manager: ^SessionManager) -> bool {
	// I think giving the event queue a capacity should be ok, not really sure.
	EventQueue_init(&manager.events, 256, context.allocator)
	hm.dynamic_init(&manager.applications, context.allocator)
	hm.dynamic_init(&manager.windows, context.allocator)

	active_session_handle := SessionManager_newSession(manager) or_return
	SessionManager_setActiveSession(manager, active_session_handle)

	return true
}

SessionManager_setActiveSession :: proc(manager: ^SessionManager, handle: SessionHandle) -> bool {
	hm.static_is_valid(manager.sessions, handle) or_return

	manager.active_session = handle
	return true
}

SessionManager_newSession :: proc(manager: ^SessionManager) -> (SessionHandle, bool) {
	session := Session{}

	session_handle, ok := hm.add(&manager.sessions, session)

	if !ok {
		return {}, false
	}

	return session_handle, true
}

SessionManager_deleteSession :: proc(manager: ^SessionManager, handle: SessionHandle) -> bool {
	hm.remove(&manager.sessions, handle) or_return

	// we need to do something will all the layers and layouts the session
	// possible just free them
	// or maybe add them to thne new active session
	//
	// if the active session is deleted then... if no sessions create an empty one, else set the first session active
	// perhaps ^ shouldn't be in this method but rather outside

	return true
}

SessionManager_addWindow :: proc(manager: ^SessionManager, window: ^Window) -> bool {
	if h, err := hm.add(&manager.windows, window^); err == nil {
		window.handle = h
		return true
	}
	return false
}
