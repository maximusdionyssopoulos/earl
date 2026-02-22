package tests

import earl "../src"
import osx "../src/osx/"

import "base:intrinsics"
import "core:log"
import "core:sys/posix"
import "core:testing"

read_attribute :: proc(
	ref: osx.AXUIElementRef,
	attr: osx.Attribute,
	valueType: osx.AXValueType,
	$T: typeid,
) -> (
	T,
	bool,
) {
	ax_value: osx.AXValue
	ax_error := osx.UIElementCopyAttributeValue(ref, attr, &ax_value)
	if (ax_error != osx.AXError.kAXErrorSuccess) {
		return T{}, false
	}
	defer osx.ReleaseObject(ax_value)
	value: T
	ok := osx.ValueGetValue(ax_value, valueType, rawptr(&value))
	if !ok {
		return T{}, false
	}
	return value, true
}


spawn_terminal :: proc() -> (pid: posix.pid_t, ok: bool) {
	argv := [?]cstring{"/Applications/Ghostty.app/Contents/MacOS/ghostty", nil}

	result := posix.posix_spawn(&pid, argv[0], nil, nil, raw_data(&argv), nil)

	if result != .NONE {
		return 0, false
	}

	return pid, true
}

spawn_terminal_window :: proc() -> (osx.AXUIElementRef, posix.pid_t, bool) {
	pid, ok := spawn_terminal()

	if !ok {
		return nil, 0, false
	}

	window_refs: [dynamic]osx.AXUIElementRef
	defer delete(window_refs)


	for {
		osx.get_window_refs_from_pid(pid, &window_refs)
		length := len(window_refs)

		if length != 0 {
			break
		}
	}

	ax_ref, ref_ok := pop_safe(&window_refs)
	if !ref_ok {
		return nil, 0, false
	}

	return ax_ref, pid, true
}

@(test)
tile_window_moves_window :: proc(t: ^testing.T) {
	axel_ref, pid, ok := spawn_terminal_window()
	if !ok {
		panic("Error spawning terminal and getting window ref")
	}

	rect := earl.OSXTileBackend.get_max_size()

	earl.OSXTileBackend.tile_window(axel_ref, rect)

	position, pos_ok := read_attribute(
		axel_ref,
		osx.PositionAttribute,
		osx.AXValueType.CGPoint,
		osx.CGPoint,
	)
	testing.expect(t, position == rect.origin, "should tile window from top-left")

	size, size_ok := read_attribute(
		axel_ref,
		osx.SizeAttribute,
		osx.AXValueType.CGSize,
		osx.CGSize,
	)


	testing.expect(t, size == rect.size, "should tile window full screen")

	posix.kill(pid, posix.Signal.SIGTERM)
}

@(test)
tile_window_with_permission :: proc(t: ^testing.T) {
}

@(test)
tile_window_without_permission :: proc(t: ^testing.T) {
}
