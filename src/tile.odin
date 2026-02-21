package earl

import "core:log"
import "osx"

Rect :: osx.Rect
Size :: osx.CGSize

TileWindowProc :: proc(axUIElement: osx.AXUIElementRef, rect: Rect) -> bool

MonitorSizeProc :: proc() -> Size


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
get_max_size :: proc() -> Size {
	unimplemented("implement the ax wrapper function to get the size of the current monitor")
}

OSXTileBackend := TileBackend{tile_window, get_max_size}
