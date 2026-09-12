package earl

import "core:container/handle_map"
import NS "core:sys/darwin/Foundation"
import SLS "sys/Skylight"


/*

Defines the application daemon.

On the application it registers the callback required for skylight and AX,
starts the event queue thread.

*/

App_startDaemon :: proc() {
	// check if the app has started elsewhere -> if not hold the lock so nothing can
	//
	// init the state
	// setup the callbacks and observers
	// start the run loop
	//
	//

	app := NS.Application.sharedApplication()
	defer app->release()

	app->setActivationPolicy(.Accessory)
	app->activateIgnoringOtherApps(true)
	app->finishLaunching()

	state, _ := App_initState()

	App_setupCallbacks(state)
	Event_startConsumer(state)
	App_startListening()

	app->run()

}


main_connection := SLS.MainConnectionID()

App_setupCallbacks :: proc(state: ^SessionManager) {
	for event in SLS.Event {
		result := SLS.RegisterConnectionNotifyProc(
			main_connection,
			Skylight_callback,
			event,
			cast(rawptr)&state.events,
		)
		assert(result == 0)
	}
}

App_startListening :: proc() {}

App_initState :: proc() -> (manager: ^SessionManager, ok: bool) {
	manager = new(SessionManager)
	SessionManager_init(manager) or_return

	Display_gatherDisplays(&manager.displays)

	Application_gatherApplications(&manager.applications)

	it := handle_map.iterator_make(&manager.applications)
	for app, h in handle_map.iterate(&it) {
		assert(handle_map.is_valid(&manager.applications, h))
		Application_gatherWindows(app, &manager.windows)
	}

	active_session := handle_map.get(&manager.sessions, manager.active_session) or_return
	Session_init(active_session, &manager.windows)

	wit := handle_map.iterator_make(&manager.windows)
	for w, wh in handle_map.iterate(&wit) {
		layer_ptr := Layer_new(WindowLayer)
		layer_ptr.sys_windowHandle = w.handle

		_ = handle_map.add(&active_session.layers, layer_ptr) or_continue
	}


	return manager, true
}
