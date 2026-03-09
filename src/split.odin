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
