package tests

import earl "../src/"
import osx "../src/osx"

import "core:log"
import "core:testing"


/**
 * This is a pretty hacky way to do things but for testing purposes it works nicely - i might change it in the future i guess.
 * Essentially since the 'backend' is provided to the rendering functions giving it the procedures to ractually render
 * we create a backend for testing purposes.
 *
 * Each test then must inject a TileTest struct into the context which is implicitly passed to all functions called within the test, like:
 * ```
  calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
	context.user_ptr = &test
 * ```
 * The because the mocked testing backend appends & reads from this we can assert that the correct computations happened with the
 * render logic.
 */
TileWindowCall :: struct {
	window_ref: rawptr,
	rectangle:  earl.Rect,
}

mock_tile_window :: proc(window_ref: osx.AXUIElementRef, rect: earl.Rect) -> bool {
	test := cast(^TileTest)context.user_ptr
	append(test.windows, TileWindowCall{window_ref, rect})

	return true
}

mock_get_max_size :: proc() -> earl.Size {
	test := cast(^TileTest)context.user_ptr
	return test.size
}

TileTest :: struct {
	size:    earl.Size,
	windows: ^[dynamic]TileWindowCall,
}

backend := earl.TileBackend {
	tile_window  = mock_tile_window,
	get_max_size = mock_get_max_size,
}

@(test)
render_fullscreen_layer :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Size{1920, 1080}, &calls}
	context.user_ptr = &test


	layer := earl.Layer(earl.Window{window_ref = nil})
	earl.render_layer(&layer, &backend)
	testing.expect(t, len(calls) == 1, "Should render one window")
	call := pop_front(&calls)
	testing.expect(
		t,
		call.rectangle.size == earl.Size{1920, 1080},
		"render with the full size - 1920 x 1080",
	)

	testing.expect(t, call.rectangle.origin == osx.CGPoint{0, 0}, "start top-left 0,0")

}

@(test)
render_even_vertical_split :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Size{1920, 1080}, &calls}
	context.user_ptr = &test

	child := earl.Layer(earl.Window{window_ref = nil})
	split := earl.Split {
		left_child_ratio = 0.5,
		split_variant    = earl.SplitType.Vertical,
		left_child       = &child,
		right_child      = &child,
	}


	layer := earl.Layer(split)
	earl.render_layer(&layer, &backend)

	testing.expect(t, len(calls) == 2, "Should render two windows")

	testing.expect(
		t,
		calls[0].rectangle.size == earl.Size{960, 1080},
		"render first window with the half width - 960, 1080",
	)
	testing.expect(
		t,
		calls[0].rectangle.origin == osx.CGPoint{0, 0},
		"render first window top-left 0,0",
	)

	testing.expect(
		t,
		calls[1].rectangle.size == earl.Size{960, 1080},
		"render second window with the half width - 960, 1080",
	)
	testing.expect(
		t,
		calls[1].rectangle.origin == osx.CGPoint{960, 0},
		"render second window split vertically, 960,0",
	)
}

@(test)
render_horizontal_split :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)


	test := TileTest{earl.Size{1920, 1080}, &calls}
	context.user_ptr = &test

	child := earl.Layer(earl.Window{window_ref = nil})
	split := earl.Split {
		left_child_ratio = 0.5,
		split_variant    = earl.SplitType.Horizontal,
		left_child       = &child,
		right_child      = &child,
	}


	layer := earl.Layer(split)
	earl.render_layer(&layer, &backend)

	testing.expect(t, len(calls) == 2, "Should render two windows")

	testing.expect(
		t,
		calls[0].rectangle.size == earl.Size{1920, 540},
		"render first window with the half height - 1920, 540",
	)
	testing.expect(t, calls[0].rectangle.origin == osx.CGPoint{0, 0}, "starts top left - 0,0")

	testing.expect(
		t,
		calls[1].rectangle.size == earl.Size{1920, 540},
		"render second window with the half height - 1920, 540",
	)
	testing.expect(
		t,
		calls[1].rectangle.origin == {0, 540},
		"render second window with the halfway down the screen - 0, 540",
	)
}

@(test)
render_tree_with_horizontal_vertical_splits :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Size{1920, 1080}, &calls}
	context.user_ptr = &test

	window_child := earl.Layer(earl.Window{window_ref = nil})
	right_child := earl.Layer(
		earl.Split {
			left_child_ratio = 0.5,
			split_variant = earl.SplitType.Horizontal,
			left_child = &window_child,
			right_child = &window_child,
		},
	)
	split := earl.Split {
		left_child_ratio = 0.5,
		split_variant    = earl.SplitType.Vertical,
		left_child       = &window_child,
		right_child      = &right_child,
	}
	layer := earl.Layer(split)

	earl.render_layer(&layer, &backend)

	testing.expect(t, len(calls) == 3, "Should render three windows")

	testing.expect(
		t,
		calls[0].rectangle == earl.Rect{{0, 0}, {960, 1080}},
		"render first window top left half the width - (0,0), (960, 1080)",
	)

	testing.expect(
		t,
		calls[1].rectangle == earl.Rect{{960, 0}, {960, 540}},
		"render second window top-right half the width, half the height - (960,0), (960, 540)",
	)


	testing.expect(
		t,
		calls[2].rectangle == earl.Rect{{960, 540}, {960, 540}},
		"render third window bottom-right half the width, half the height - (960,0), (960, 540)",
	)
}

@(test)
render_tree_with_multiple_splits :: proc(t: ^testing.T) {
	left := earl.Layer(earl.Window{window_ref = nil})
	right_top := earl.Layer(earl.Window{window_ref = nil})
	right_bottom := earl.Layer(earl.Window{window_ref = nil})

	right := earl.Layer(
		earl.Split {
			split_variant = .Horizontal,
			left_child = &right_top,
			left_child_ratio = 0.25,
			right_child = &right_bottom,
		},
	)

	root := earl.Layer(
		earl.Split {
			split_variant = .Vertical,
			left_child = &left,
			left_child_ratio = 0.6,
			right_child = &right,
		},
	)

	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Size{1920, 1080}, &calls}
	context.user_ptr = &test
	earl.render_layer(&root, &backend)

	testing.expect(t, len(calls) == 3, "Should emit three render calls")
	// left window
	testing.expect(
		t,
		calls[0].rectangle == earl.Rect{{0, 0}, {1152, 1080}},
		"render first window top left half the width - (0,0), (1152, 1080)",
	)

	// right top
	testing.expect(
		t,
		calls[1].rectangle == earl.Rect{{1152, 0}, {768, 270}},
		"render second window top right half the width - (1152,0), (768, 270)",
	)
	// right bottom
	testing.expect(
		t,
		calls[2].rectangle == earl.Rect{{1152, 270}, {768, 810}},
		"render third window bottom right half the width - (1152,0), (768, 810)",
	)
}

//
// @(test)
// render_tree_vertical_split_floating_point_ratio :: proc(t: ^testing.T) {}
//
