package earl

import "base:runtime"
import hm "core:container/handle_map"
import "core:container/small_array"

MAX_SESSIONS :: 10

Handle :: hm.Handle16

SessionManager :: struct {
	active_session: Handle,
	sessions:       hm.Static_Handle_Map(MAX_SESSIONS + 1, Session, Handle), // zero value is reserved for sentinel : https://pkg.odin-lang.org/core/container/handle_map/#static_cap
	screens:        hm.Dynamic_Handle_Map(Screen, ScreenHandle),
	windows:        hm.Dynamic_Handle_Map(Window, WindowID),
}

Manager := SessionManager{}

Session :: struct {
	handle:  Handle,
	layers:  hm.Dynamic_Handle_Map(Layer, LayerID),
	layouts: hm.Dynamic_Handle_Map(Layout, LayoutHandle),
	panes:   small_array.Small_Array(MAX_SCREENS, Pane),
}

sessionManager_setActive :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_is_valid(manager.sessions, handle) or_return

	manager.active_session = handle
	return true
}

session_delete :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_remove(&manager.sessions, handle) or_return

	// this needs to deal with every space under every session - initial idea is to combine the active sesson
	// if the active session is deleted then... if no sessions create an empty one, else set the first session active
	// perhaps ^ shouldn't be in this method but rather outside
	return true
}


session_new :: proc(manager: ^SessionManager) -> (Handle, bool) {
	session := Session{}

	session_handle, ok := hm.add(&manager.sessions, session)

	if !ok {
		return {}, false
	}

	return session_handle, true
}
