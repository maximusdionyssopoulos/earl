package earl

import hm "core:container/handle_map"

LayerID :: hm.Handle16
Layer :: struct {
	handle: LayerID,
}

LayerVariant :: union {
	^Slot,
	^Split,
}

layer_tile :: proc(layer: ^Layer) {
	// idea orchestaration procedure it spawns a thread to generate a queue of windows to render with the rectangle they should be
	// it can then spawn threads to do the rendering
	//
	// because this may have to wait for each window to be properly tiled it could be better to seperate this into two threads
	// a main thread computing the layout and a background thread taking the computed nodes and 'rendering' using the ax api
	// currently this wouldn't work because theres no distinction here between what to render but with some tweaks i can see it
}

layer_computeRectangles :: proc(
	calls: ^[dynamic]WindowDrawCall,
	layer: ^LayerVariant,
	rect: Rect,
) {
	switch l in layer {
	case ^Slot:
		window_appendDrawCall(l.window_id, rect, calls)
	case ^Split:
		split_walk(l, rect, calls)
	}
}


// traverse through the space tree in a depth first search, yielding up control
// i.e. if the layout is |p1|p2| (two panes in a vertial split) then first go p1, then yield control,
// next time this is called it would be p2, called again p1 etc.
// you cannot stop on a split only on a window
// maybe it returns the pane it has focused
// cycle_focus :: proc(space: ^Space) {}


// this needs to copy a window into space by creating a new struct with the same window_ref
// but different size and offset
//
// also need to consider does this join with a certain split type? how does it work with an already complex tree?
// initial thoughts is to have this accept the split type and then window to join to
// this would effectively replace the window in the children of the parent with a new split where the replaced window is a child with the copied window
//
// the user of this can be then decide how to determine the leaf window to join with
// copy_window_to_space :: proc(
// 	copied_window: ^Window,
// 	split_type: Split_Type,
// 	window_to_join: ^Window,
// ) {}


// simply swaps the split type and updates the children so they have the correct size and offsets to render properly
// swap_split_type :: proc(split: ^Split) {}
