package earl

import hm "core:container/handle_map"
import "osx"

WindowID :: hm.Handle16

// A window represents the AXUIElementRef - there should be one window object per AXUIElementRef
Window :: struct {
	handle:     WindowID,
	window_ref: osx.AXUIElementRef,
}

// A Slot is a window that being used to be displayed as a layer - i.e. the fullscreen window on a single screen
Slot :: struct {
	using layer: Layer,
	window_id:   WindowID,
}

WindowDrawCall :: struct {
	window: WindowID,
	rect:   Rect,
}

@(private)
window_appendDrawCall :: proc(window_id: WindowID, rect: Rect, calls: ^[dynamic]WindowDrawCall) {
	append(calls, WindowDrawCall{window_id, rect})
}
