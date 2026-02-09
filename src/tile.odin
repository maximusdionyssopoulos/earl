package earl

import "osx"

Vector2 :: [2]f64

TileWindowProc :: proc(axUIElement: osx.AXUIElementRef, vector: Vector2) -> bool

MonitorSizeProc :: proc() -> Vector2


TileBackend :: struct {
	tile_window:  TileWindowProc,
	get_max_size: MonitorSizeProc,
}

@(private = "file")
tile_window :: proc(axUIElement: osx.AXUIElementRef, vector: Vector2) -> bool {
	unimplemented(
		"need to implement the tiling logic -> convert to macos compatible and use ax api",
	)
}

@(private = "file")
get_max_size :: proc() -> Vector2 {
	unimplemented("implement the ax wrapper function to get the size of the current monitor")
}

OSXTileBackend := TileBackend{tile_window, get_max_size}
