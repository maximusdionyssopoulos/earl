package earl

import hm "core:container/handle_map"
import "core:sys/posix"

import AX "sys/ApplicationServices"
import CF "sys/CoreFoundation"
import CG "sys/CoreGraphics"
import SLS "sys/Skylight"

WindowHandle :: hm.Handle32

Window :: struct {
	handle:           WindowHandle,
	application:      ApplicationHandle,
	current_space_id: Maybe(SLS.SpaceID),
	variant:          union {
		^SingleWindow,
		^NativeTabbedWindow,
	},
}
SingleWindow :: struct {
	using window: Window,
	// the skylight/ coregraphics id
	window_id:    CG.WindowID,
	ref:          AX.UIElementRef,
}

NativeTabbedWindow :: struct {
	using window:    Window,
	// the front window id
	front_window_id: TabHandle,
	tabs:            hm.Dynamic_Handle_Map(Tab, TabHandle),
}


TabHandle :: hm.Handle16
Tab :: struct {
	handle:    TabHandle,
	window_id: CG.WindowID,
	ref:       AX.UIElementRef,
}

WindowKind :: enum {
	SingleWindow,
	NativeTabbedWindow,
	System_Or_IgnoredWindow,
}

Window_new :: proc($T: typeid) -> ^T {
	w := new(T)
	w.variant = w
	return w
}

// this could potentially move to using the skylight move window if this is slow
// otherwise keep this since it is more stable in theory
Window_move :: proc(window: ^Window, rect: CF.Rect) -> bool {
	point := rect.origin
	ax_point_value := AX.ValueCreate(AX.ValueType.CGPoint, rawptr(&point))
	defer CF.ReleaseObject(ax_point_value)

	ax_ref := Window_getAxUIElementRef(window) or_return

	set_position_error := AX.UIElementSetAttributeValue(
		ax_ref,
		AX.PositionAttribute,
		ax_point_value,
	)

	size := rect.size
	ax_size_value := AX.ValueCreate(AX.ValueType.CGSize, rawptr(&size))
	defer CF.ReleaseObject(ax_size_value)
	set_size_error := AX.UIElementSetAttributeValue(ax_ref, AX.SizeAttribute, ax_size_value)

	return true
}

Window_getAxUIElementRef :: proc(window: ^Window) -> (ref: AX.UIElementRef, ok: bool) {
	switch w in window.variant {
	case ^SingleWindow:
		ref = w.ref
	case ^NativeTabbedWindow:
		tab := hm.get(&w.tabs, w.front_window_id) or_return
		ref = tab.ref
	}
	return
}

// Window_byCGWindowID :: proc(
// 	windows: ^hm.Dynamic_Handle_Map(Window, WindowHandle),
// 	window_id: CG.WindowID,
// ) -> (
// 	^Window,
// 	bool,
// ) {
// 	it := hm.iterator_make(windows)
// 	for window, _ in hm.iterate(&it) {
// 		switch v in window.variant {
// 		case ^SingleWindow:
// 			if v.window_id == window_id {
// 				return window, true
// 			}
// 		case ^NativeTabbedWindow:
// 			tab_it := hm.iterator_make(&v.tabs)
// 			for tab, _ in hm.iterate(&tab_it) {
// 				if tab.window_id == window_id {
// 					return window, true
// 				}
// 			}
// 		}
// 	}
// 	return nil, false
// }

//
// heuristic will probs be based on: https://github.com/karinushka/paneru/commit/5a3c72a016f3e70b555af29a0464cd477a1d7c35
// and https://github.com/acsandmann/rift/issues/36
// Window_hueristicGetType :: proc() -> WindowKind {

// }
