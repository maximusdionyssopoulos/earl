package tile

import "ax"

@(private = "file")
TileAXUIElement :: proc(
	axUIElement: ax.AXUIElementRef,
	position: ax.AXPosition,
	size: ax.AXSize,
) -> bool {
	return false
}

tile_window :: proc(axUIElement: ax.AXUIElementRef, size_x: uint, size_y: uint) -> bool {
	unimplemented(
		"need to implement the tiling logic -> convert to macos compatible and use ax api",
	)
}

get_max_size :: proc() -> (max_size_x: uint, max_size_y: uint) {
	unimplemented("implement the ax wrapper function to get the size of the current monitor")
}
