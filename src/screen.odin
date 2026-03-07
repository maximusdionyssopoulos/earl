package earl

import hm "core:container/handle_map"

ScreenHandle :: hm.Handle16
// A screen represents a visible screen for a user (i.e. a monitor)
// we store the CFUUID as a byte array - 128 bits using CFUUIDGetUUIDBytes as it gets a permanent ID - https://github.com/waydabber/BetterDisplay/discussions/3628#discussioncomment-11266263
//
// We can then back track that to get the correct size mesurements of the screen to use when displaying a window
Screen :: struct {
	handle: ScreenHandle,
	uuid:   [15]byte,
}

// A pane reprents what is currently being displayed and where
// i.e. what window or split is being displayed on what screen.
Pane :: struct {
	screen_handle: ScreenHandle,
	layer_handle:  LayerID,
}

// A conservative guess for the max number a screens to account for
// this is purely a guess to avoid using a heap based dynamic array
// if this becomes a problem I'd think to just use a dynamic array
MAX_SCREENS :: 10
