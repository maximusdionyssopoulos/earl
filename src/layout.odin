package earl

import "osx"

Layer :: union {
	Window,
	Split,
}

Window :: struct {
	window_ref: osx.AXUIElementRef,
}

SplitType :: enum {
	Horizontal,
	Vertical,
}

Split :: struct {
	split_variant:    SplitType,
	left_child:       ^Layer,
	left_child_ratio: f64,
	right_child:      ^Layer,
}

Node :: struct {
	layer: ^Layer,
	rect:  Rect,
}

@(private = "file")
render_window :: proc(
	window: ^Window,
	rect: Rect,
	nodes: ^[dynamic]Node,
	tile_backed: ^TileBackend,
) -> bool {
	return tile_backed.tile_window(window.window_ref, rect)
}

@(private = "file")
render_split :: proc(split: ^Split, rect: Rect, nodes: ^[dynamic]Node) -> bool {
	lrect, rrect := compute_split_children(split^, rect)

	append(nodes, Node{split.left_child, lrect}, Node{split.right_child, rrect})
	return true
}

@(private = "file")
render :: proc(layer: ^Layer, rect: Rect, nodes: ^[dynamic]Node, tile_backend: ^TileBackend) {
	switch &l in layer {
	case Window:
		render_window(&l, rect, nodes, tile_backend)
	case Split:
		render_split(&l, rect, nodes)
	}
}

render_layer :: proc(layer: ^Layer, tile_backend: ^TileBackend) {
	nodes: [dynamic]Node
	defer delete(nodes)

	rect := tile_backend.get_max_size()

	render(layer, rect, &nodes, tile_backend)

	for len(nodes) > 0 {
		node := pop_front(&nodes)
		// because this may have to wait for each window to be properly tiled it could be better to seperate this into two threads
		// a main thread computing the layout and a background thread taking the computed nodes and 'rendering' using the ax api
		// currently this wouldn't work because theres no distinction here between what to render but with some tweaks i can see it
		render(node.layer, node.rect, &nodes, tile_backend)
	}
}

@(private = "file")
compute_split_children :: proc(split: Split, rect: Rect) -> (lrect: Rect, rrect: Rect) {
	switch split.split_variant {
	case .Vertical:
		lrect = Rect {
			size   = Size{rect.width * osx.CGFloat(split.left_child_ratio), rect.height},
			origin = rect.origin,
		}

		rrect = Rect {
			size = {width = rect.width - lrect.width, height = rect.height},
			origin = {x = rect.x + lrect.width, y = rect.y},
		}
	case .Horizontal:
		lrect = Rect {
			size   = Size{rect.width, rect.height * osx.CGFloat(split.left_child_ratio)},
			origin = rect.origin,
		}

		rrect = Rect {
			size = {width = rect.width, height = rect.height - lrect.height},
			origin = {x = rect.x, y = rect.y + lrect.height},
		}
	}
	return
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
