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
	layer:  ^Layer,
	vector: Vector2,
}

@(private = "file")
render_window :: proc(
	window: ^Window,
	vector: Vector2,
	nodes: ^[dynamic]Node,
	tile_backed: ^TileBackend,
) -> bool {
	return tile_backed.tile_window(window.window_ref, vector)
}

@(private = "file")
render_split :: proc(split: ^Split, vector: Vector2, nodes: ^[dynamic]Node) -> bool {
	lvector := compute_split_child_max_size(split.split_variant, vector, split.left_child_ratio)
	rvector := compute_split_child_max_size(
		split.split_variant,
		vector,
		1 - split.left_child_ratio,
	)

	append(nodes, Node{split.left_child, lvector}, Node{split.right_child, rvector})
	return true
}

@(private = "file")
render :: proc(layer: ^Layer, vector: Vector2, nodes: ^[dynamic]Node, tile_backend: ^TileBackend) {
	switch &l in layer {
	case Window:
		render_window(&l, vector, nodes, tile_backend)
	case Split:
		render_split(&l, vector, nodes)
	}
}

render_layer :: proc(layer: ^Layer, tile_backend: ^TileBackend) {
	nodes: [dynamic]Node
	defer delete(nodes)

	vector := tile_backend.get_max_size()

	render(layer, vector, &nodes, tile_backend)

	for len(nodes) > 0 {
		node := pop_front(&nodes)
		render(node.layer, node.vector, &nodes, tile_backend)
	}
}

@(private = "file")
compute_split_child_max_size :: proc(
	split_type: SplitType,
	vector: Vector2,
	ratio: f64,
) -> (
	size: Vector2,
) {
	switch split_type {
	case .Vertical:
		size = {vector.x * ratio, vector.y}
	case .Horizontal:
		size = {vector.x, vector.y * ratio}
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
