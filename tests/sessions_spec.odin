package tests

import earl "../src/"
import "core:container/handle_map"
import "core:log"

import "core:testing"

@(test)
session_create_basic :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	session, ok := earl.session_new(&sm)
	testing.expect(t, ok, "Should create session successfully")
	testing.expect(t, session != {}, "Should return valid session handle")
}
@(test)
session_create_up_to_limit :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	for i in 0 ..< earl.MAX_SESSIONS {
		_, ok := earl.session_new(&sm)

		testing.expectf(t, ok, "Should create session %d", i)
	}
}
@(test)
session_create_beyond_limit_fails :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	for _ in 0 ..< earl.MAX_SESSIONS {
		earl.session_new(&sm)
	}

	_, ok := earl.session_new(&sm)
	testing.expect(t, !ok, "Should fail when at capacity")
}

@(test)
session_delete_existing :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.session_new(&sm)

	ok := earl.session_delete(&sm, handle)
	testing.expect(t, ok, "Should delete existing session")
}
@(test)
session_delete_invalid_returns_false :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	ok := earl.session_delete(&sm, {})
	testing.expect(t, !ok, "Should return false for invalid session ID")
}
@(test)
session_delete_twice_returns_false :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.session_new(&sm)

	earl.session_delete(&sm, handle)
	ok := earl.session_delete(&sm, handle)
	testing.expect(t, !ok, "Should return false when deleting already-deleted session")
}

@(test)
active_session_set_valid :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.session_new(&sm)

	ok := earl.sessionManager_setActive(&sm, handle)
	testing.expect(t, ok, "Should set active session successfully")
	testing.expect(t, sm.active_session == handle, "Active session should match what was set")
}
@(test)
active_session_invalid_id_fails :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}

	ok := earl.sessionManager_setActive(&sm, {})
	testing.expect(t, !ok, "Should fail to set invalid session as active")
}

@(test)
session_newSplit_creates_new_verical_split :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	session_handle, _ := earl.session_new(&sm)

	session := handle_map.get(&sm.sessions, session_handle)
	defer handle_map.dynamic_destroy(&session.layers)
	window: earl.WindowID = {
		idx = 2,
		gen = 2,
	}


	layer_handle, err := earl.session_newSplit(session, window, window, .Vertical)
	testing.expect(t, err == .None, "Should create new layer")
	layer, ok := handle_map.get(&session.layers, layer_handle)

	split := layer.variant.(^earl.Split)
	defer earl.split_destroy(split)

	testing.expect(t, ok, "Should add that layer to the sessions layer handle map")
	root := split._root
	testing.expect(t, root.split_variant == .Vertical, "")
	testing.expect(t, root.left_child == window, "")
	testing.expect(t, root.right_child == window, "")
	testing.expect(t, root.left_child_ratio == 0.5, "")

}

@(test)
session_splitWith_updates_split_with_new_window :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	session_handle, _ := earl.session_new(&sm)

	session := handle_map.get(&sm.sessions, session_handle)
	defer handle_map.dynamic_destroy(&session.layers)
	window: earl.WindowID = {
		idx = 2,
		gen = 2,
	}
	layer_handle, _ := earl.session_newSplit(session, {}, window, .Vertical)
	l, _ := handle_map.get(&session.layers, layer_handle)
	split := l.variant.(^earl.Split)
	defer earl.split_destroy(split)


	new_window: earl.WindowID = {
		idx = 3,
		gen = 3,
	}

	did_split := earl.session_splitWith(
		session,
		layer_handle,
		window,
		new_window,
		.Vertical,
		false,
	)
	testing.expect(t, did_split, "")

	root := split._root

	testing.expect(t, root.right_child != window, "")

	n := root.right_child.(^earl.Node)
	testing.expect(t, n.right_child == new_window, "")
	testing.expect(t, n.left_child == window, "")
	testing.expect(t, n.parent == root, "")
	testing.expect(t, n.split_variant == .Vertical, "")
}

