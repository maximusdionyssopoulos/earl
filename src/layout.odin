package earl
import "tile"
import "tile/ax"

// useful link for the subtype polymorphism i'm using here
// https://odin-lang.org/docs/overview/#advanced-idioms

Layer :: union {
	Window,
	Split,
}


Window :: struct {
	window_ref: ax.AXUIElementRef,
}


SplitType :: enum {
	Horizontal,
	Vertical,
}

Split :: struct {
	split_variant:     SplitType,
	left_child:        Layer,
	left_child_ratio:  f16,
	right_child:       Layer,
	right_child_ratio: f16,
}

Node :: struct {
	layer:  ^Layer,
	size_x: uint,
	size_y: uint,
}


@(private = "file")
render_layer :: proc(layer: ^Layer) {
	max_x, max_y = tile.get_max_size()

	// is implementation does introduce some overhead if only rendering a window - maybe try to remove this in the future
	// a nicer approach could be a recursive approach but need to benchmark performance & memory consumption there - want this to be highly performant
	nodes: [dynamic]Node
	compute_layer_size(layer, max_x, max_y, &nodes)

	for len(nodes) > 0 {
		node := pop_front(&nodes)

		switch node_layer in node.layer {
		case Window:
			tile.tile_window(node_layer.window_ref, node.size_x, node.size_y)
		case Split:
			compute_layer_size(node_layer, node.size_x, node.size_y, &nodes)
		}
	}
}

@(private = "file")
compute_layer_size :: proc(
	layer: ^Layer,
	max_size_x: uint,
	max_size_y: uint,
	nodes: ^[dynamic]Node,
) {
	switch l in layer {
	case Window:
		append(&nodes, Node{^l, max_size_x, max_size_y})
	case Split:
		lsize_x, lsize_y := compute_split_child_max_size(
			l.split_variant,
			max_size_x,
			max_size_y,
			l.left_child_ratio,
		)
		rsize_x, rsize_y := compute_split_child_max_size(
			l.split_variant,
			max_size_x,
			max_size_y,
			l.right_child_ratio,
		)
		append(&nodes, Node{^l, lsize_x, lsize_y}, Node{^l, rsize_x, rsize_y})
	}
}

@(private = "file")
compute_split_child_max_size :: proc(
	split_type: SplitType,
	max_size_x: uint,
	max_size_y: uint,
	ratio: f16,
) -> (
	size_x: uint,
	size_y: uint,
) {
	size_x = 0
	size_y = 0
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
