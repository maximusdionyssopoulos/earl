package earl

import hm "core:container/handle_map"
import "core:sys/posix"
import AX "sys/ApplicationServices"
import CF "sys/CoreFoundation"
import CG "sys/CoreGraphics"

import NS "core:sys/darwin/Foundation"

ApplicationHandle :: hm.Handle16

// I'm thinking of refactoring the application and window data structures
// basically instead of apps owning windows which models how it works from a domain pov
// each window will have a handle to a app
// an app doesn't know its windows -> don't think this operation will happen very often so the O(N) lookup is fine
//
// and the windows are stored like [cgwindowid]Window as a map
// this allows for easier lookup since a majority of callbacks and actions give the cgwindowid i think
//
// the problem is that it doesn't quite work for tabs so i need to think about this more
// native tabs destroy their window when you switch tab
// so the heuristic was an attempt to stop destroying and recreating and instead modeling the world
// in such a way where we know about this and can easily see all the tabs and which one is front
// but the map doesn't allow us to model this easily
Application :: struct {
	handle: ApplicationHandle,
	pid:    posix.pid_t,
}

// ProcessSerialNumber :: struct {
// 	high: u32,
// 	low:  u32,
// }


// maybe investigate using carbon or ns running applications instead here
//
Application_gatherApplications :: proc(
	applications: ^hm.Dynamic_Handle_Map(Application, ApplicationHandle),
) -> bool {
	options := CG.WindowListOption(
		CG.WindowListOptionOnScreenOnly | CG.WindowListExcludeDesktopElements,
	)
	window_list := CG.WindowListCopyWindowInfo(options, CG.NullWindowID)
	defer CF.ReleaseObject(window_list)

	count := CF.ArrayGetCount(window_list)
	processed_pids := make(map[posix.pid_t]bool)
	defer delete(processed_pids)

	for i in 0 ..< count {
		{
			dict := CF.ArrayGetValueAtIndex(window_list, i)
			pid := cast(posix.pid_t)CF.Dictionary_getNumber(
				i32,
				dict,
				CG.WindowOwnerPID,
			) or_continue
			layer := CF.Dictionary_getNumber(i32, dict, CG.WindowLayer) or_continue
			if layer != 0 do continue


			if (pid in processed_pids) do continue
			processed_pids[pid] = true

			// maybe_running_app := NS.RunningApplication_runningApplicationWithProcessIdentifier(pid)
			// if maybe_running_app == nil do continue
			// running_app := maybe_running_app.(^NS.RunningApplication)
			// fmt.println(NS.String_odinString(running_app->localizedName()))


			app := Application {
				pid = pid,
			}
			handle, err := hm.add(applications, app)
			if err != .None {
				panic("Error gathering the inital applications")
			}

			app.handle = handle
		}
	}

	return true
}

Application_gatherWindows :: proc(
	app: ^Application,
	windows: ^hm.Dynamic_Handle_Map(Window, WindowHandle),
) {

	appAxUIEl := AX.UIElementCreateApplication(app.pid)

	windowAxUIElements: CF.Array
	ax_error := AX.UIElementCopyAttributeValue(appAxUIEl, AX.WindowsAttribute, &windowAxUIElements)
	if ax_error != AX.Error.ErrorSuccess do return

	windowsCount := CF.ArrayGetCount(windowAxUIElements)

	for i in 0 ..< windowsCount {
		// this should use a heuristic to check for native tabs vs windows
		// for now this hasn't been implemented so this is fine
		// heuristic will probs be based on: https://github.com/karinushka/paneru/commit/5a3c72a016f3e70b555af29a0464cd477a1d7c35
		// and https://github.com/acsandmann/rift/issues/36
		window := Window_new(SingleWindow)
		window.ref = CF.ArrayGetValueAtIndex(windowAxUIElements, i)

		id: CG.WindowID
		ax_err := AX.UIElementGetWindowID(window.ref, &id)
		if ax_err != AX.Error.ErrorSuccess do continue

		window.window_id = id
		window.application = app.handle

		handle := hm.add(windows, window) or_continue
		window.handle = handle
	}
}
