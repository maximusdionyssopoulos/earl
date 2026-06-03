package earl

import hm "core:container/handle_map"
import "core:fmt"
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


/**
	This is an unsolved problem in the macos space as far as I'm aware.
	This is a best guess heuristic

	First attempt at this is as follows:
	1. Get the window level, if not 0 ignore (As far as my testing has gone, this stops some tooltips and other things like that)
	but there are still some popups (i.e. the battery health in settings) that have level 0

	2. Peek ahead of the event queue as the following pattern has been observed from the Skylight
		a. SLSWindowCreatedEvent is published
		b. SLSWindowDestroyedEvent is published (when creating a native tab)

	So while this may be a potential race condition, my testing has shown it to be fine.

	3. Compare the window created's frame against all windows for the same application (including tabbed, minimised, hidden and ones the window server has held onto†)

	4. If some window matches the frame is the one that is about to be destroyed in the peeked event -> Native Tab
	Otherwise -> Single Window

	Currently, a tolerance of 20 seems to working good and not having my false positives (this needs more testing). A tolerance is needed
	because, without it some apps (like the default terminal) created tabs a different sizes

	There is one major flow of this approach however. I have noticed that when closing a native tab / switching tabs we get the same sequence of events,
		a. SLSWindowCreatedEvent is published (the tab we are going to)
		b. SLSWindowDestroyedEvent is published (the tab that we just closed)
	I think the current mitgation strategy is to check if the tab we are going to is already handled.

	Another point to consider with this. When a window is moved between displays, with seperate spaces enabled, it fires the events.
	I've noticed that the hueritstic is not accurate at all for this. I will need to investigate further.

	† My guess is the window server is some sort of arena, i've noticed that WindowIds are reused across the tab stack and window stack
	*/
Window_hueristicGetKind :: proc(window_id: CG.WindowID, queue: ^EventQueue) -> WindowKind {
	w_info := Window_queryInformation(
		window_id,
		[]SLS.WindowQueryIteratorTraits {
			SLS.WindowQueryIteratorTraits.ParentID,
			SLS.WindowQueryIteratorTraits.PID,
			SLS.WindowQueryIteratorTraits.Level,
		},
	)
	if w_info.level != 0 do return .System_Or_IgnoredWindow

	w_frame, err := Window_getFrame(window_id)
	// fmt.println(w_frame, w_info, window_id)


	event := EventQueue_peek(queue)
	if event == nil do return .SingleWindow

	#partial switch e in event {
	case WindowDestroyedEvent:
		windows := make([dynamic]WindowAttributes)
		defer delete(windows)
		Window_getWindowsForApplication(cast(i32)w_info.pid, &windows)

		matching_windows := make([dynamic]WindowAttributes)
		defer delete(matching_windows)
		Window_matchingFrameWindows(w_frame, &windows, &matching_windows, 20.0)
		// fmt.println(matching_windows[:])

		if len(matching_windows) == 0 do return .SingleWindow

		for w in matching_windows {
			if w.window_id == e.window_id {
				return .NativeTabbedWindow
			}
		}
	}

	return .SingleWindow
}


Window_matchesFrameWithinTolerance :: proc(
	frame_a: CF.Rect,
	frame_b: CF.Rect,
	tolerance: CF.Float = 1.0,
) -> bool {
	return(
		abs(frame_a.origin.x - frame_b.origin.x) <= tolerance &&
		abs(frame_a.origin.y - frame_b.origin.y) <= tolerance &&
		abs(frame_a.size.width - frame_b.size.width) <= tolerance &&
		abs(frame_a.size.height - frame_b.size.height) <= tolerance \
	)
}

Window_matchingFrameWindows :: proc(
	frame: CF.Rect,
	windows: ^[dynamic]WindowAttributes,
	matching_windows: ^[dynamic]WindowAttributes,
	tolerance: CF.Float = 1.0,
) {
	for win in windows {
		w_frame := Window_getFrame(cast(CG.WindowID)win.window_id) or_continue
		if Window_matchesFrameWithinTolerance(frame, w_frame, tolerance) {
			append(matching_windows, win)
		}
	}
}


WindowAttributes :: struct {
	pid:          i32,
	window_id:    CG.WindowID,
	owner_name:   string,
	is_on_screen: bool,
}

Window_getWindowsForApplication :: proc(
	app_pid: i32,
	windows: ^[dynamic]WindowAttributes,
) -> bool {
	options := CG.WindowListOption(CG.WindowListOptionAll)

	window_list := CG.WindowListCopyWindowInfo(options, CG.NullWindowID)
	defer CF.ReleaseObject(window_list)
	count := CF.ArrayGetCount(window_list)

	for i in 0 ..< count {
		dict := CF.ArrayGetValueAtIndex(window_list, i)

		pid := CF.Dictionary_getNumber(i32, dict, CG.WindowOwnerPID) or_continue
		wid := CF.Dictionary_getNumber(i32, dict, CG.WindowNumber) or_continue
		owner_name := CF.Dictionary_getString(dict, CG.WindowOwnerName) or_continue
		layer := CF.Dictionary_getNumber(i32, dict, CG.WindowLayer) or_continue
		is_on_screen := CF.Dictionary_getBool(dict, CG.WindowIsOnscreen) or_else false

		if layer != 0 do continue
		if pid != app_pid do continue

		append(windows, WindowAttributes{pid, cast(CG.WindowID)wid, owner_name, is_on_screen})
	}
	return true
}


Window_queryInformation :: proc(
	w_id: CG.WindowID,
	traits: []SLS.WindowQueryIteratorTraits,
) -> SLS.WindowQueryIteratorResult {

	window_ptr := new(CG.WindowID)
	window_ptr^ = w_id
	defer free(window_ptr)
	window_id := CF.NumberCreate(CF.AllocatorGetDefault(), .SInt32Type, window_ptr)
	defer CF.Release(window_id)

	windows := CF.ArrayCreate(CF.AllocatorGetDefault(), &[1]rawptr{window_id}, 1, nil)
	query := SLS.WindowQueryWindows(SLS.MainConnectionID(), windows, 1)
	defer CF.ReleaseObject(CF.TypeRef(query))

	iterator := SLS.WindowQueryResultCopyWindows(query)
	defer CF.ReleaseObject(CF.TypeRef(iterator))

	result: SLS.WindowQueryIteratorResult
	for trait in traits {
		switch trait {
		case SLS.WindowQueryIteratorTraits.ParentID:
			result.parent_id = SLS.WindowIteratorGetParentID(iterator)
			SLS.WindowIteratorAdvance(iterator)
		case SLS.WindowQueryIteratorTraits.PID:
			result.pid = SLS.WindowIteratorGetPID(iterator)
			SLS.WindowIteratorAdvance(iterator)
		case SLS.WindowQueryIteratorTraits.Attributes:
			result.attributes = SLS.WindowIteratorGetAttributes(iterator)
			SLS.WindowIteratorAdvance(iterator)
		case SLS.WindowQueryIteratorTraits.Level:
			result.level = SLS.WindowIteratorGetLevel(iterator)
			SLS.WindowIteratorAdvance(iterator)
		}
	}

	return result

}

Window_getFrame :: proc(w_id: CG.WindowID) -> (frame: CF.Rect, err: CG.Error) {
	if err := SLS.GetWindowBounds(SLS.MainConnectionID(), w_id, &frame); err != .Success {
		return frame, err
	}
	return frame, nil
}

Window_getApplicaton :: proc(
	applications: ^Applications,
	wid: CG.WindowID,
) -> (
	^Application,
	bool,
) {
	w_info := Window_queryInformation(wid, []SLS.WindowQueryIteratorTraits{.PID})
	return Application_findByPid(applications, cast(posix.pid_t)w_info.pid)
}
