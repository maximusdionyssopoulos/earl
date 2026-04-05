package sys

import hm "core:container/handle_map"

import ax "ApplicationServices"
import cg "CoreGraphics"
import sls "Skylight"

WindowHandle :: hm.Handle32

Window :: struct {
	handle:           WindowHandle,
	application:      ApplicationHandle,
	current_space_id: Maybe(sls.SpaceID),
	variant:          union {
		^SingleWindow,
		^NativeTabbedWindow,
	},
}

SingleWindow :: struct {
	using window: Window,
	// the skylight/ coregraphics id
	window_id:    cg.WindowID,
	ref:          ax.UIElementRef,
}

NativeTabbedWindow :: struct {
	using window:    Window,
	// the front window id
	front_window_id: cg.WindowID,
	tabs:            hm.Dynamic_Handle_Map(Tab, TabHandle),
}


TabHandle :: hm.Handle16
Tab :: struct {
	handle:    TabHandle,
	window_id: cg.WindowID,
	ref:       ax.UIElementRef,
}

Window_new :: proc($T: typeid) -> ^T {
	w := new(T)
	w.variant = w
	return w
}
