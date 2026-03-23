package earl

import "base:runtime"
import hm "core:container/handle_map"
import "core:container/small_array"
import "core:log"


Handle :: hm.Handle16
Session :: struct {
	handle:  Handle,
	layers:  hm.Dynamic_Handle_Map(Layer, LayerID),
	layouts: hm.Dynamic_Handle_Map(Layout, LayoutHandle),
	screens: small_array.Small_Array(MAX_SCREENS, Screen),
}

// session_init :: proc(manager: ^SessionManager, handle: Handle) -> bool {
// 	if session, ok := hm.get(&manager.sessions, handle); ok {
//     session.panes
//
// 		return true
// 	}
// 	return false
// }


session_delete :: proc(manager: ^SessionManager, handle: Handle) -> bool {
	hm.static_remove(&manager.sessions, handle) or_return
	// this also needs to free memory

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

session_newSplit :: proc(
	session: ^Session,
	left_window: WindowHandle,
	right_window: WindowHandle,
	split_type: SplitType,
) -> (
	LayerID,
	runtime.Allocator_Error,
) {

	left_child: SplitChild
	left_child = left_window

	right_child: SplitChild
	right_child = right_window

	split := split_initWithRoot(
		{
			left_child = left_child,
			right_child = right_child,
			left_child_ratio = 0.5,
			split_variant = split_type,
		},
	)

	return hm.dynamic_add(&session.layers, split)
}

session_splitWith :: proc(
	session: ^Session,
	split_id: LayerID,
	split_window: WindowHandle,
	new_window: WindowHandle,
	as: SplitType,
	insert_left: bool,
) -> bool {

	layer, ok := hm.get(&session.layers, split_id)
	if !ok {return false}

	if split, sok := layer.variant.(^Split); sok {
		return split_insert(split, split_window, new_window, as, insert_left)
	}

	return false
}
