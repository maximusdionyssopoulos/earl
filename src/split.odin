package earl

import "osx"

// A Split represents a tree of windows
Split :: struct {
	using layer:      Layer,
	split_variant:    SplitType,
	left_child:       ^SplitChild,
	left_child_ratio: f64,
	right_child:      ^SplitChild,
}

SplitType :: enum {
	Horizontal,
	Vertical,
}

SplitChild :: union {
	WindowID,
	Split,
}

@(private = "file")
SplitNode :: struct {
	node: ^SplitChild,
	rect: Rect,
}

@(private)
split_walk :: proc(split: ^Split, rect: Rect, calls: ^[dynamic]WindowDrawCall) {
	nodes: [dynamic]SplitNode
	defer delete(nodes)

	lrect, rrect := split_computeRectangles(split^, rect)
	append(&nodes, SplitNode{split.left_child, lrect}, SplitNode{split.right_child, rrect})

	for len(nodes) > 0 {
		sn := pop_front(&nodes)
		switch c in sn.node {
		case WindowID:
			window_appendDrawCall(c, sn.rect, calls)
		case Split:
			lrect, rrect := split_computeRectangles(c, sn.rect)

			append(&nodes, SplitNode{c.left_child, lrect}, SplitNode{c.right_child, rrect})
		}
	}
}


@(private = "file")
split_computeRectangles :: proc(split: Split, rect: Rect) -> (lrect: Rect, rrect: Rect) {
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
