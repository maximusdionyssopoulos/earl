package earl

import "base:runtime"
import "core:container/handle_map"
import "core:fmt"
import obj_c "core:sys/darwin/Foundation"
import "core:thread"


main :: proc() {
	app := obj_c.Application_sharedApplication()

	app->setActivationPolicy(.Prohibited)

	// launch_initState(&Manager)

	// t := thread.create(launch_runAppRunLoop)
	// t.data = app
	//  t
	t := thread.create_and_start_with_poly_data(app, launch_runAppRunLoop)
	fmt.println("thread", t)

	for {
		running := app->isRunning()
		fmt.println("running", running)
		if running {break}
	}

	app->terminate(app)


	// app->run()


}

launch_runAppRunLoop :: proc(app: ^obj_c.Application) {
	app->run()
}

launch_initState :: proc(manager: ^SessionManager) -> SessionManager_Error {
	if !manager._initialised {
		return .Already_Initialised
	}

	manager._initialised = true

	if active_session_handle, ok := session_new(manager); ok {
		manager.active_session = active_session_handle
	}

	// init screens
	screens := make([dynamic]ScreenUUID)
	if ok := screen_getAllDisplays(&screens); !ok {
		return .Screens_Init_Error

	}

	// init windows
	window_handles: [dynamic]WindowHandle
	defer delete(window_handles)

	if did_init_windows := window_getAllWindows(&manager.windows, &window_handles);
	   !did_init_windows {
		return .Window_Init_Error
	}

	// init the active session
	session, ok := handle_map.get(&manager.sessions, manager.active_session)
	if !ok {return .Window_Init_Error}

	// copy windows as slots
	for window_handle in window_handles {
		slot := new(Slot)
		slot.variant = slot
		slot.window_id = window_handle

		if _, err := handle_map.add(&session.layers, slot); err != .None {
			return .Window_Init_Error
		}
	}

	return .None
}
