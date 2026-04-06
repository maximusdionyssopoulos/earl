package sys

import AX "ApplicationServices"
import CF "CoreFoundation"
import CG "CoreGraphics"
import hm "core:container/handle_map"
import "core:fmt"
import "core:sys/posix"

import NS "core:sys/darwin/Foundation"

ApplicationHandle :: hm.Handle16

Application :: struct {
	handle:  ApplicationHandle,
	pid:     posix.pid_t,
	windows: hm.Dynamic_Handle_Map(Window, WindowHandle),
}

// ProcessSerialNumber :: struct {
// 	high: u32,
// 	low:  u32,
// }


// maybe investigate using carbon or ns running applications instead here
//
Application_gatherApplicationsAndWindows :: proc(
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
			Application_gatherWindows(&app)
		}
	}

	return true
}

Application_gatherWindows :: proc(app: ^Application) {

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
		if ax_err != AX.Error.ErrorSuccess {
			panic("Error gathering the inital windows")
		}
		window.window_id = id
		window.application = app.handle

		handle, err := hm.add(&app.windows, window)
		if err != .None {
			panic("Error gathering the inital windows")
		}
		window.handle = handle
	}
}
