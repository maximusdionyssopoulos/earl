package earl

import hm "core:container/handle_map"
import "osx"

WindowID :: hm.Handle16

Window :: struct {
	handle:     WindowID,
	window_ref: osx.AXUIElementRef,
}

Slot :: struct {
	using layer: Layer,
	window_id:   WindowID,
}

WindowDrawCall :: struct {
	window: WindowID,
	rect:   Rect,
}

@(private)
slot_appendDrawCall :: proc(slot: ^Slot, rect: Rect, calls: ^[dynamic]WindowDrawCall) {
	append(calls, WindowDrawCall{slot.window_id, rect})
}
