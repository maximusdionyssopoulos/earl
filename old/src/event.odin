package earl

import "core:thread"
import CG "sys/CoreGraphics"
import SLS "sys/Skylight"

/*

Defines the event types & event handling
An abstraction over the core system events.

*/

Event :: union {
	WindowCreatedEvent,
	WindowDestroyedEvent,
}
WindowCreatedEvent :: distinct SLS.SpaceWindowPayload

WindowDestroyedEvent :: distinct SLS.SpaceWindowPayload

// Creates and starts the event loop thread,
// returns the thread
Event_startConsumer :: proc(manager: ^SessionManager) -> ^thread.Thread {
	return thread.create_and_start_with_poly_data(manager, Event_handle)
}

// drain the queue, and process an event
// sits idle waiting for messages
Event_handle :: proc(manager: ^SessionManager) {
	queue := &manager.events

	for {
		if EventQueue_count(queue) == 0 {
			continue
		}
		event := EventQueue_dequeue(queue)
		if event == nil do continue
		defer free(event)

		switch e in event {
		case WindowCreatedEvent:
			Event_handleWindowCreatedEvent(e, manager)
		case WindowDestroyedEvent:

		}
	}

	// if this loop ever ends, the queue will be freed
	free(queue)
}

Event_handleWindowCreatedEvent :: proc(event: WindowCreatedEvent, manager: ^SessionManager) {
	#partial switch Window_hueristicGetKind(event.window_id, &manager.events) {
	case .NativeTabbedWindow:
	/**

	Process:
	1. check if we already have a window or tab for that cg.window_id
	if its a single window then convert it

	*/

	case .SingleWindow:
		/*
		This may need some more logic to handle cases that the hueristic is deficient in, i.e.
		moving a window from one screen to another
		*/

		window := Window_new(SingleWindow)

		if app, ok := Window_getApplicaton(&manager.applications, event.window_id); ok {
			window.application = app.handle
			window.current_space_id = event.space_id
			window.window_id = event.window_id
			if !SessionManager_addWindow(manager, window) do free(window)
		} else {
			free(window)
		}
	}
}
