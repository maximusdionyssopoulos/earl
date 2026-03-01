package earl

import "osx"

SplitType :: enum {
	Horizontal,
	Vertical,
}

Split :: struct {
	using layer:      Layer,
	split_variant:    SplitType,
	left_child:       ^Layer,
	left_child_ratio: f64,
	right_child:      ^Layer,
}

@(private = "file")
SplitNode :: struct {
	layer: ^Layer,
	rect:  Rect,
}

@(private)
split_walk :: proc(split: ^Split, rect: Rect, calls: ^[dynamic]WindowDrawCall) {
	nodes: [dynamic]SplitNode
	defer delete(nodes)

	append(&nodes, SplitNode{split, rect})

	for len(nodes) > 0 {
		sn := pop_front(&nodes)
		switch sl in sn.layer.variant {
		case ^Slot:
			slot_appendDrawCall(sl, sn.rect, calls)
		case ^Split:
			lrect, rrect := split_computeRectangles(sl^, sn.rect)

			append(&nodes, SplitNode{sl.left_child, lrect}, SplitNode{sl.right_child, rrect})
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
