package ax

import cfe "cf-extensions"
import cf "core:sys/darwin/CoreFoundation"

GetCurrentAXUIElements :: proc(
	allocator := context.allocator,
) -> (
	arr: [dynamic]AXUIElementRef,
	ok: bool,
) #optional_ok {
	if !IsProcessTrusted() do return

	options := WindowListOption(
		kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
	)
	window_list := CGWindowListCopyWindowInfo(options, kCGNullWindowID)
	defer cf.ReleaseObject(window_list)

	count := cfe.ArrayGetCount(window_list)
	processed_pids := make(map[i32]bool)
	defer delete(processed_pids)

	ax_ui_elements := make([dynamic]AXUIElementRef, allocator)

	for i in 0 ..< count {
		{
			dict := cfe.ArrayGetValueAtIndex(window_list, i)
			// defer cf.ReleaseObject(dict)

			pid := cfe.get_int_from_dict(dict, kCGWindowOwnerPID) or_continue

			if (pid in processed_pids) do continue

			processed_pids[pid] = true

			append(&ax_ui_elements, UIElementCreateApplication(pid))
		}
	}

	return ax_ui_elements, true
}
