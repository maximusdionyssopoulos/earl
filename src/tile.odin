package earl

import obj_c "core:sys/darwin/Foundation"
import "osx"

Rect :: obj_c.Rect
Size :: osx.CGSize

tile_window :: proc(axUIElement: osx.AXUIElementRef, rect: Rect) -> bool {
	point := rect.origin
	ax_point_value := osx.ValueCreate(osx.AXValueType.CGPoint, rawptr(&point))
	defer osx.ReleaseObject(ax_point_value)

	set_position_error := osx.UIElementSetAttributeValue(
		axUIElement,
		osx.PositionAttribute,
		ax_point_value,
	)

	size := rect.size
	ax_size_value := osx.ValueCreate(osx.AXValueType.CGSize, rawptr(&size))
	defer osx.ReleaseObject(ax_size_value)
	set_size_error := osx.UIElementSetAttributeValue(axUIElement, osx.SizeAttribute, ax_size_value)

	return true
}

tile_getScreenSize :: proc() -> Rect {
	// for now we are ignoring multi monitor support and instead using the main screen
	main_screen := obj_c.Screen_mainScreen()
	full_frame := obj_c.Screen_frame(main_screen)

	visible_frame := obj_c.Screen_visibleFrame(main_screen)
	visible_frame.origin.y =
		full_frame.size.height - visible_frame.origin.y - visible_frame.size.height

	return visible_frame
}
