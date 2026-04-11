package earl

import hm "core:container/handle_map"

SessionHandle :: hm.Handle16
Session :: struct {
	handle:  SessionHandle,
	layers:  hm.Dynamic_Handle_Map(Layer, LayerHandle),
	layouts: hm.Dynamic_Handle_Map(Layout, LayoutHandle),
	// state: []
}

// Session_gatherInitialWindowsAsLayers :: proc(manager: ^SessionManager, s_handle: SessionHandle) {
// 	session, ok := hm.get(&manager.sessions, s_handle)
// 	if !ok {
// 		panic("session not found")
// 	}

// 	window_iterator := hm.iterator_make(&manager.windows)
// 	for w, wh in hm.iterate(&window_iterator) {
// 		layer_ptr := layer.Layer_new(layer.Window)
// 		layer_ptr.sys_windowHandle = w.handle

// 		_ = hm.add(&session.layers, layer_ptr) or_continue
// 	}
// }


// session_newSplit :: proc(
// 	session: ^Session,
// 	left_window: WindowHandle,
// 	right_window: WindowHandle,
// 	split_type: SplitType,
// ) -> (
// 	LayerID,
// 	runtime.Allocator_Error,
// ) {

// 	left_child: SplitChild
// 	left_child = left_window

// 	right_child: SplitChild
// 	right_child = right_window

// 	split := split_initWithRoot(
// 		{
// 			left_child = left_child,
// 			right_child = right_child,
// 			left_child_ratio = 0.5,
// 			split_variant = split_type,
// 		},
// 	)

// 	return hm.dynamic_add(&session.layers, split)
// }

// session_splitWith :: proc(
// 	session: ^Session,
// 	split_id: LayerID,
// 	split_window: WindowHandle,
// 	new_window: WindowHandle,
// 	as: SplitType,
// 	insert_left: bool,
// ) -> bool {

// 	layer, ok := hm.get(&session.layers, split_id)
// 	if !ok {return false}

// 	if split, sok := layer.variant.(^Split); sok {
// 		return split_insert(split, split_window, new_window, as, insert_left)
// 	}

// 	return false
// }
