package earl

import "base:runtime"
import "osx"

// A Split represents a tree of windows
Split :: struct {
	using layer: Layer,
	_root:       ^Node,
	_allocator:  runtime.Allocator,
}

SplitChild :: union {
	WindowID,
	^Node,
}

SplitType :: enum {
	Horizontal,
	Vertical,
}

Node :: struct {
	split_variant:    SplitType,
	left_child:       SplitChild,
	left_child_ratio: f64,
	right_child:      SplitChild,
	parent:           ^Node,
}


@(private = "file")
SplitRectangle :: struct {
	node: ^SplitChild,
	rect: Rect,
}

@(private)
split_computeRectangles :: proc(split: ^Split, rect: Rect, calls: ^[dynamic]WindowDrawCall) {
	rects: [dynamic]SplitRectangle
	defer delete(rects)

	node := split._root

	lrect, rrect := node_computeRectangles(node^, rect)
	append(
		&rects,
		SplitRectangle{&node.left_child, lrect},
		SplitRectangle{&node.right_child, rrect},
	)

	for len(rects) > 0 {
		sn := pop_front(&rects)
		switch c in sn.node {
		case WindowID:
			window_appendDrawCall(c, sn.rect, calls)
		case ^Node:
			lrect, rrect := node_computeRectangles(c^, sn.rect)

			append(
				&rects,
				SplitRectangle{&c.left_child, lrect},
				SplitRectangle{&c.right_child, rrect},
			)
		}
	}
}


@(private = "file")
node_computeRectangles :: proc(node: Node, rect: Rect) -> (lrect: Rect, rrect: Rect) {
	switch node.split_variant {
	case .Vertical:
		lrect = Rect {
			size   = Size{rect.width * osx.CGFloat(node.left_child_ratio), rect.height},
			origin = rect.origin,
		}

		rrect = Rect {
			size = {width = rect.width - lrect.width, height = rect.height},
			origin = {x = rect.x + lrect.width, y = rect.y},
		}
	case .Horizontal:
		lrect = Rect {
			size   = Size{rect.width, rect.height * osx.CGFloat(node.left_child_ratio)},
			origin = rect.origin,
		}

		rrect = Rect {
			size = {width = rect.width, height = rect.height - lrect.height},
			origin = {x = rect.x, y = rect.y + lrect.height},
		}
	}
	return
}


split_init :: proc(allocator := context.allocator) -> ^Split {
	split := new(Split, context.allocator)
	split.variant = split
	split._root = nil
	split._allocator = allocator
	return split
}

split_initWithRoot :: proc(node: Node, allocator := context.allocator) -> ^Split {
	n_ptr := new_clone(node, allocator)

	split := split_init(allocator)
	split._root = n_ptr

	return split
}

split_findNode :: proc(
	split: ^Split,
	containing: WindowID,
) -> (
	n: ^Node,
	is_left: bool,
	found: bool,
) {
	nodes: [dynamic]^Node
	defer delete(nodes)

	append(&nodes, split._root)
	for len(nodes) > 0 {
		node := pop_front(&nodes)
		switch n in node.left_child {
		case WindowID:
			if n == containing {
				return node, true, true
			}
		case ^Node:
			append(&nodes, n)
		}

		switch n in node.right_child {
		case WindowID:
			if n == containing {
				return node, false, true
			}
		case ^Node:
			append(&nodes, n)
		}
	}
	return nil, false, false
}

split_destroy :: proc(split: ^Split) {
	stack: [dynamic]^Node
	defer delete(stack)

	append(&stack, split._root)

	for len(stack) > 0 {
		n := pop_front(&stack)

		if l, lok := n.left_child.(^Node); lok {
			append(&stack, l)
		}
		if r, rok := n.right_child.(^Node); rok {
			append(&stack, r)
		}

		free(n, split._allocator)
	}

	free(split, split._allocator)
}

split_insert :: proc(
	split: ^Split,
	containing: WindowID,
	with: WindowID,
	as: SplitType,
	as_leftchild: bool,
) -> bool {
	node, is_left, found := split_findNode(split, containing)

	if !found {return false}

	_, _, alreadyHas := split_findNode(split, with)
	if alreadyHas {return false}

	new_node := new(Node, split._allocator)
	new_node.left_child = with if as_leftchild else containing
	new_node.right_child = containing if as_leftchild else with
	new_node.split_variant = as
	new_node.left_child_ratio = 0.5
	new_node.parent = node

	if is_left {
		node.left_child = new_node
	} else {
		node.right_child = new_node
	}

	return true
}
