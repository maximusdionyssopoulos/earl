package tests

import earl "../src/"

import "core:testing"

@(test)
session_create_basic :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	session, ok := earl.create_session(&sm)
	testing.expect(t, ok, "Should create session successfully")
	testing.expect(t, session != {}, "Should return valid session handle")
}
@(test)
session_create_up_to_limit :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	for i in 0 ..< earl.MAX_SESSIONS {
		_, ok := earl.create_session(&sm)

		testing.expectf(t, ok, "Should create session %d", i)
	}
}
@(test)
session_create_beyond_limit_fails :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	for _ in 0 ..< earl.MAX_SESSIONS {
		earl.create_session(&sm)
	}

	_, ok := earl.create_session(&sm)
	testing.expect(t, !ok, "Should fail when at capacity")
}

@(test)
session_delete_existing :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.create_session(&sm)

	ok := earl.delete_session(&sm, handle)
	testing.expect(t, ok, "Should delete existing session")
}
@(test)
session_delete_invalid_returns_false :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	ok := earl.delete_session(&sm, {})
	testing.expect(t, !ok, "Should return false for invalid session ID")
}
@(test)
session_delete_twice_returns_false :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.create_session(&sm)

	earl.delete_session(&sm, handle)
	ok := earl.delete_session(&sm, handle)
	testing.expect(t, !ok, "Should return false when deleting already-deleted session")
}

@(test)
active_session_set_valid :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}
	handle, _ := earl.create_session(&sm)

	ok := earl.set_active_session(&sm, handle)
	testing.expect(t, ok, "Should set active session successfully")
	testing.expect(t, sm.active_session == handle, "Active session should match what was set")
}
@(test)
active_session_invalid_id_fails :: proc(t: ^testing.T) {
	sm := earl.SessionManager{}

	ok := earl.set_active_session(&sm, {})
	testing.expect(t, !ok, "Should fail to set invalid session as active")
}
