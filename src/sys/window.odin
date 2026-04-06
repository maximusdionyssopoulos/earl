package sys

import hm "core:container/handle_map"

import ax "ApplicationServices"
import AX "ApplicationServices"
import CF "CoreFoundation"
import CG "CoreGraphics"
import SLS "Skylight"

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
	ref:          ax.UIElementRef,
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
	ref:       ax.UIElementRef,
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

Window_getAxUIElementRef := proc(window: ^Window) -> (ref: AX.UIElementRef, ok: bool) {
	switch w in window.variant {
	case ^SingleWindow:
		ref = w.ref
	case ^NativeTabbedWindow:
		tab := hm.get(&w.tabs, w.front_window_id) or_return
		ref = tab.ref
	}
	return
}
