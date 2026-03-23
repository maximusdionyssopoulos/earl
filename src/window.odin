package earl

import hm "core:container/handle_map"
import "core:fmt"
import "core:sys/posix"
import "osx"

WindowHandle :: distinct hm.Handle16

Window :: struct {
	handle:           WindowHandle,
	application_pid:  posix.pid_t,
	cg_window_id:     osx.WindowID,
	application_name: string,
}

// A Slot is a window that being used to be displayed as a layer - i.e. the fullscreen window on a single screen
Slot :: struct {
	using layer: Layer,
	window_id:   WindowHandle,
}

WindowDrawCall :: struct {
	window: WindowHandle,
	rect:   Rect,
}

@(private)
window_appendDrawCall :: proc(
	window_id: WindowHandle,
	rect: Rect,
	calls: ^[dynamic]WindowDrawCall,
) {
	append(calls, WindowDrawCall{window_id, rect})
}

window_getAllWindows :: proc(
	handle_map: ^hm.Dynamic_Handle_Map(Window, WindowHandle),
	handles: ^[dynamic]WindowHandle,
) -> bool {
	options := osx.WindowListOption(
		osx.kCGWindowListOptionOnScreenOnly | osx.kCGWindowListExcludeDesktopElements,
	)

	window_list := osx.WindowListCopyWindowInfo(options, osx.kCGNullWindowID)
	defer osx.ReleaseObject(window_list)
	count := osx.ArrayGetCount(window_list)
	for i in 0 ..< count {
		dict := osx.ArrayGetValueAtIndex(window_list, i)

		pid := osx.get_int_from_dict(dict, osx.WindowOwnerPID) or_continue
		id := osx.get_int_from_dict(dict, osx.WindowNumber) or_continue
		owner_name, _ := osx.get_string_from_dict(dict, osx.WindowOwnerName)
		layer, _ := osx.get_int_from_dict(dict, osx.WindowLayer)

		if layer != 0 {continue}


		handle, err := hm.add(
			handle_map,
			Window {
				application_pid = posix.pid_t(pid),
				cg_window_id = osx.WindowID(id),
				application_name = owner_name,
			},
		)

		if err != .None {
			return false
		}

		append(handles, handle)
	}

	return true
}
