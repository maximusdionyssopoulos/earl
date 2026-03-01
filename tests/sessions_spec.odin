package tests

import earl "../src/"

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
