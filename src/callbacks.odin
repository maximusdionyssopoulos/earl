package earl
import "base:runtime"
import "core:fmt"
import "core:time"
import CF "sys/CoreFoundation"
import CG "sys/CoreGraphics"
import SLS "sys/Skylight"

// Defines all the callbacks for the application to use
// Includes skylight callbacks and AX app & window observer callbacks


Skylight_callback :: proc "c" (
	event: SLS.Event,
	data: rawptr,
	len: uint,
	user_data: rawptr,
	_connection_id: i32,
) {
	context = runtime.default_context()
	#partial switch event {
	case .spaceWindowCreated:
		fmt.println(event)

		if len < size_of(WindowCreatedEvent) {
			return
		}
		queue := cast(^EventQueue)(user_data)
		payload := cast(^SLS.SpaceWindowPayload)(data)

		event := new(Event)
		event^ = Event(WindowCreatedEvent(payload^))

		EventQueue_enqueue(queue, event)

	case .spaceWindowDestroyed:
		fmt.println(event)

		if len < size_of(WindowDestroyedEvent) {
			return
		}

		queue := cast(^EventQueue)(user_data)
		payload := cast(^SLS.SpaceWindowPayload)(data)

		event := new(Event)
		event^ = Event(WindowDestroyedEvent(payload^))

		EventQueue_enqueue(queue, event)

	}
}
