package earl

import hm "core:container/handle_map"

MAX_SESSIONS :: 10

Handle :: hm.Handle16

SessionManager :: struct {
	active_session: Handle,
	// zero value is reserved for sentinel : https://pkg.odin-lang.org/core/container/handle_map/#static_cap
	sessions:       hm.Static_Handle_Map(MAX_SESSIONS + 1, Session, Handle),
}


Session :: struct {
	handle:          Handle,
	layers:          [dynamic]Layer,
	last_used_layer: ^Layer,
}

set_active_session :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_is_valid(manager.sessions, handle) or_return

	manager.active_session = handle
	return true
}

delete_session :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_remove(&manager.sessions, handle) or_return

	// this needs to deal with every space under every session - initial idea is to combine the active sesson
	// if the active session is deleted then... if no sessions create an empty one, else set the first session active
	// perhaps ^ shouldn't be in this method but rather outside
	return true
}


create_session :: proc(manager: ^SessionManager) -> (Handle, bool) {

	session := Session{}

	session_handle, ok := hm.add(&manager.sessions, session)

	if !ok {
		return {}, false
	}

	return session_handle, true
}
