package tests

import earl "../src/"
import osx "../src/osx"

import "core:testing"


@(test)
render_fullscreen_layer :: proc(t: ^testing.T) {
	slot: earl.LayerVariant
	slot = &earl.Slot{}

	calls: [dynamic]earl.WindowDrawCall
	defer delete(calls)

	earl.layer_computeRectangles(&calls, &slot, earl.Rect{size = {1920, 1080}, origin = {0, 0}})

	testing.expect(t, len(calls) == 1, "Should render one window")

	call := pop(&calls)
	testing.expect(
		t,
		call.rect.size == earl.Size{1920, 1080},
		"render with the full size - 1920 x 1080",
	)
	testing.expect(
		t,
		call.rect.size == earl.Size{1920, 1080},
		"render with the full size - 1920 x 1080",
	)

	testing.expect(t, call.rect.origin == osx.CGPoint{0, 0}, "start top-left 0,0")

}

@(test)
render_even_vertical_split :: proc(t: ^testing.T) {
	calls: [dynamic]earl.WindowDrawCall
	defer delete(calls)

	child: earl.SplitChild
	child = earl.WindowID{}

	split: earl.LayerVariant
	split = &earl.Split {
		left_child_ratio = 0.5,
		split_variant = earl.SplitType.Vertical,
		left_child = &child,
		right_child = &child,
	}

	earl.layer_computeRectangles(&calls, &split, earl.Rect{size = {1920, 1080}, origin = {0, 0}})

	testing.expect(t, len(calls) == 2, "Should render two windows")

	testing.expect(
		t,
		calls[0].rect.size == earl.Size{960, 1080},
		"render first window with the half width - 960, 1080",
	)
	testing.expect(
		t,
		calls[0].rect.origin == osx.CGPoint{0, 0},
		"render first window top-left 0,0",
	)

	testing.expect(
		t,
		calls[1].rect.size == earl.Size{960, 1080},
		"render second window with the half width - 960, 1080",
	)
	testing.expect(
		t,
		calls[1].rect.origin == osx.CGPoint{960, 0},
		"render second window split vertically, 960,0",
	)
}

@(test)
render_horizontal_split :: proc(t: ^testing.T) {
	calls: [dynamic]earl.WindowDrawCall
	defer delete(calls)

	child: earl.SplitChild
	child = earl.WindowID{}

	split: earl.LayerVariant
	split = &earl.Split {
		left_child_ratio = 0.5,
		split_variant = earl.SplitType.Horizontal,
		left_child = &child,
		right_child = &child,
	}

	earl.layer_computeRectangles(&calls, &split, earl.Rect{size = {1920, 1080}, origin = {0, 0}})

	testing.expect(t, len(calls) == 2, "Should render two windows")

	testing.expect(
		t,
		calls[0].rect.size == earl.Size{1920, 540},
		"render first window with the half height - 1920, 540",
	)
	testing.expect(t, calls[0].rect.origin == osx.CGPoint{0, 0}, "starts top left - 0,0")

	testing.expect(
		t,
		calls[1].rect.size == earl.Size{1920, 540},
		"render second window with the half height - 1920, 540",
	)
	testing.expect(
		t,
		calls[1].rect.origin == {0, 540},
		"render second window with the halfway down the screen - 0, 540",
	)
}

@(test)
render_tree_with_horizontal_vertical_splits :: proc(t: ^testing.T) {
	calls: [dynamic]earl.WindowDrawCall
	defer delete(calls)

	child: earl.SplitChild
	child = earl.WindowID{}

	right_child: earl.SplitChild
	right_child = earl.Split {
		left_child_ratio = 0.5,
		split_variant    = earl.SplitType.Horizontal,
		left_child       = &child,
		right_child      = &child,
	}

	split: earl.LayerVariant
	split = &earl.Split {
		left_child_ratio = 0.5,
		split_variant = earl.SplitType.Vertical,
		left_child = &child,
		right_child = &right_child,
	}

	earl.layer_computeRectangles(&calls, &split, earl.Rect{size = {1920, 1080}, origin = {0, 0}})

	testing.expect(t, len(calls) == 3, "Should render three windows")

	testing.expect(
		t,
		calls[0].rect == earl.Rect{{0, 0}, {960, 1080}},
		"render first window top left half the width - (0,0), (960, 1080)",
	)

	testing.expect(
		t,
		calls[1].rect == earl.Rect{{960, 0}, {960, 540}},
		"render second window top-right half the width, half the height - (960,0), (960, 540)",
	)


	testing.expect(
		t,
		calls[2].rect == earl.Rect{{960, 540}, {960, 540}},
		"render third window bottom-right half the width, half the height - (960,0), (960, 540)",
	)
}

@(test)
render_tree_with_multiple_splits :: proc(t: ^testing.T) {
	child: earl.SplitChild
	child = earl.WindowID{}


	right: earl.SplitChild
	right = earl.Split {
		split_variant    = .Horizontal,
		left_child_ratio = 0.25,
		left_child       = &child,
		right_child      = &child,
	}

	root: earl.LayerVariant
	root = &earl.Split {
		split_variant = .Vertical,
		left_child = &child,
		left_child_ratio = 0.6,
		right_child = &right,
	}

	calls: [dynamic]earl.WindowDrawCall
	defer delete(calls)

	earl.layer_computeRectangles(&calls, &root, earl.Rect{size = {1920, 1080}, origin = {0, 0}})

	testing.expect(t, len(calls) == 3, "Should emit three render calls")
	// left window
	testing.expect(
		t,
		calls[0].rect == earl.Rect{{0, 0}, {1152, 1080}},
		"render first window top left half the width - (0,0), (1152, 1080)",
	)

	// right top
	testing.expect(
		t,
		calls[1].rect == earl.Rect{{1152, 0}, {768, 270}},
		"render second window top right half the width - (1152,0), (768, 270)",
	)
	// right bottom
	testing.expect(
		t,
		calls[2].rect == earl.Rect{{1152, 270}, {768, 810}},
		"render third window bottom right half the width - (1152,0), (768, 810)",
	)
}
