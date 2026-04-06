package layer

import CF "../sys/CoreFoundation"


SplitHandle :: LayerHandle

// A Split represents a tree of windows
Split :: struct {
	using layer:   Layer,
	split_variant: union {
		^SplitInstance,
		^SplitMaster,
	},
}

SplitType :: enum {
	Horizontal,
	Vertical,
}

SplitInstance :: struct {
	parent:  SplitHandle,
	_master: SplitHandle,
}

SplitMaster :: struct {
	split_variant:    SplitType,
	left_child:       SplitHandle,
	left_child_ratio: f64,
	right_child:      SplitHandle,
}


@(private = "file")
SplitRectangle :: struct {
	node: SplitHandle,
	rect: CF.Rect,
}

@(private)
split_computeRectangles :: proc(split: ^Split, rect: CF.Rect, calls: ^[dynamic]WindowDrawCall) {
	rects: [dynamic]SplitRectangle
	defer delete(rects)

	// node :=

	// lrect, rrect := node_computeRectangles(node^, rect)
	// append(
	// 	&rects,
	// 	SplitRectangle{&node.left_child, lrect},
	// 	SplitRectangle{&node.right_child, rrect},
	// )

	// for len(rects) > 0 {
	// 	sn := pop_front(&rects)
	// 	switch c in sn.node {
	// 	case WindowHandle:
	// 		window_appendDrawCall(c, sn.rect, calls)
	// 	case ^Node:
	// 		lrect, rrect := node_computeRectangles(c^, sn.rect)

	// 		append(
	// 			&rects,
	// 			SplitRectangle{&c.left_child, lrect},
	// 			SplitRectangle{&c.right_child, rrect},
	// 		)
	// 	}
	// }
}


@(private = "file")
node_computeRectangles :: proc(
	node: ^SplitMaster,
	rect: CF.Rect,
) -> (
	lrect: CF.Rect,
	rrect: CF.Rect,
) {
	switch node.split_variant {
	case .Vertical:
		lrect = CF.Rect {
			size   = {rect.width * CF.Float(node.left_child_ratio), rect.height},
			origin = rect.origin,
		}

		rrect = CF.Rect {
			size = {width = rect.width - lrect.width, height = rect.height},
			origin = {x = rect.x + lrect.width, y = rect.y},
		}
	case .Horizontal:
		lrect = CF.Rect {
			size   = {rect.width, rect.height * CF.Float(node.left_child_ratio)},
			origin = rect.origin,
		}

		rrect = CF.Rect {
			size = {width = rect.width, height = rect.height - lrect.height},
			origin = {x = rect.x, y = rect.y + lrect.height},
		}
	}
	return
}


// split_initMaster :: proc() -> (handle: SplitHandle, ok: bool) {
// 	// split := new(Split, context.allocator)
// 	// split.variant = split
// 	// split._root = nil
// 	// return split
// }

// split_initInstance :: proc() -> (handle: SplitHandle, ok: bool) {
// 	// n_ptr := new_clone(node, allocator)
// 	//
// 	// split := split_init(allocator)
// 	// split._root = n_ptr
// 	//
// 	// return split
// }

// split_findNode :: proc(
// 	split: ^Split,
// 	containing: WindowHandle,
// ) -> (
// 	n: ^Node,
// 	is_left: bool,
// 	found: bool,
// ) {
// 	nodes: [dynamic]^Node
// 	defer delete(nodes)
//
// 	append(&nodes, split._root)
// 	for len(nodes) > 0 {
// 		node := pop_front(&nodes)
// 		switch n in node.left_child {
// 		case WindowHandle:
// 			if n == containing {
// 				return node, true, true
// 			}
// 		case ^Node:
// 			append(&nodes, n)
// 		}
//
// 		switch n in node.right_child {
// 		case WindowHandle:
// 			if n == containing {
// 				return node, false, true
// 			}
// 		case ^Node:
// 			append(&nodes, n)
// 		}
// 	}
// 	return nil, false, false
// }

// split_destroy :: proc(split: ^Split) {
// 	stack: [dynamic]^Node
// 	defer delete(stack)
//
// 	append(&stack, split._root)
//
// 	for len(stack) > 0 {
// 		n := pop_front(&stack)
//
// 		if l, lok := n.left_child.(^Node); lok {
// 			append(&stack, l)
// 		}
// 		if r, rok := n.right_child.(^Node); rok {
// 			append(&stack, r)
// 		}
//
// 		free(n)
// 	}
//
// 	free(split)
// }

// split_insert :: proc(
// 	split: ^Split,
// 	containing: WindowHandle,
// 	with: WindowHandle,
// 	as: SplitType,
// 	as_leftchild: bool,
// ) -> bool {
// 	node, is_left, found := split_findNode(split, containing)

// 	if !found {return false}

// 	_, _, alreadyHas := split_findNode(split, with)
// 	if alreadyHas {return false}

// 	new_node := new(Node)
// 	new_node.left_child = with if as_leftchild else containing
// 	new_node.right_child = containing if as_leftchild else with
// 	new_node.split_variant = as
// 	new_node.left_child_ratio = 0.5
// 	new_node.parent = node

// 	if is_left {
// 		node.left_child = new_node
// 	} else {
// 		node.right_child = new_node
// 	}

// 	return true
// }

// simply swaps the split type and updates the children so they have the correct size and offsets to render properly
// swap_split_type :: proc(split: ^Split) {}
