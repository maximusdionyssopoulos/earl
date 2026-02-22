package earl

import "core:log"
import obj_c "core:sys/darwin/Foundation"
import "osx"

Rect :: obj_c.Rect
Size :: osx.CGSize

TileWindowProc :: proc(axUIElement: osx.AXUIElementRef, rect: Rect) -> bool

MonitorSizeProc :: proc() -> Rect


TileBackend :: struct {
	tile_window:  TileWindowProc,
	get_max_size: MonitorSizeProc,
}

@(private = "file")
tile_window :: proc(axUIElement: osx.AXUIElementRef, rect: Rect) -> bool {
	// point := osx.CGPoint {
	// 	x = osx.CGFloat(vector.x),
	// 	y = osx.CGFloat(vector.y),
	// }
	// ax_point_value := osx.ValueCreate(osx.AXValueType.CGPoint, rawptr(&point))
	// defer osx.ReleaseObject(ax_point_value)
	//
	// error := osx.UIElementSetAttributeValue(axUIElement, osx.PositionAttribute, ax_point_value)
	// log.info(error)
	// return true
	return false
}

@(private = "file")
get_max_size :: proc() -> Rect {
	// for now we are ignoring multi monitor support and instead using the main screen
	main_screen := obj_c.Screen_mainScreen()
	full_frame := obj_c.Screen_frame(main_screen)
	visible_frame := obj_c.Screen_visibleFrame(main_screen)
	visible_frame.origin.y =
		full_frame.size.height - visible_frame.origin.y - visible_frame.size.height
	return visible_frame
}


OSXTileBackend := TileBackend{tile_window, get_max_size}
