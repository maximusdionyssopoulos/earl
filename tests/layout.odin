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
	vector:     earl.Vector2,
}

mock_tile_window :: proc(window_ref: osx.AXUIElementRef, vector: earl.Vector2) -> bool {
	test := cast(^TileTest)context.user_ptr
	append(test.windows, TileWindowCall{window_ref, vector})

	return true
}

mock_get_max_size :: proc() -> earl.Vector2 {
	test := cast(^TileTest)context.user_ptr
	return test.vector
}

TileTest :: struct {
	vector:  earl.Vector2,
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

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
	context.user_ptr = &test


	layer := earl.Layer(earl.Window{window_ref = nil})
	earl.render_layer(&layer, &backend)
	testing.expect(t, len(calls) == 1, "Should render one window")
	call := pop_front(&calls)
	testing.expect(t, call.vector.x == 1920, "render with the full width - 1920")
	testing.expect(t, call.vector.y == 1080, "render with the full height - 1080")
}

@(test)
render_even_vertical_split :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
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

	testing.expect(t, calls[0].vector.x == 960, "render first window with the half width - 960")
	testing.expect(t, calls[0].vector.y == 1080, "render first window with the full height - 1080")

	testing.expect(t, calls[1].vector.x == 960, "render second window with the half width - 960")
	testing.expect(
		t,
		calls[1].vector.y == 1080,
		"render second window with the full height - 1080",
	)
}

@(test)
render_horizontal_split :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
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

	testing.expect(t, calls[0].vector.x == 1920, "render first window with the full width - 1920")
	testing.expect(t, calls[0].vector.y == 540, "render first window with the half height - 540")

	testing.expect(t, calls[1].vector.x == 1920, "render second window with the full width - 1920")
	testing.expect(t, calls[1].vector.y == 540, "render second window with the half height - 540")
}

@(test)
render_tree_with_horizontal_vertical_splits :: proc(t: ^testing.T) {
	calls: [dynamic]TileWindowCall
	defer delete(calls)

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
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

	testing.expect(t, calls[0].vector.x == 960, "render first window with the half width - 960")
	testing.expect(t, calls[0].vector.y == 1080, "render first window with the full height - 1080")

	testing.expect(t, calls[1].vector.x == 960, "render second window with the half width - 960")
	testing.expect(t, calls[1].vector.y == 540, "render second window with the half height - 540")

	testing.expect(t, calls[2].vector.x == 960, "render third window with the half width - 960")
	testing.expect(t, calls[2].vector.y == 540, "render third window with the half height - 540")
}

@(test)
render_tree_vertical_split_floating_point_ratio :: proc(t: ^testing.T) {}

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

	test := TileTest{earl.Vector2{1920, 1080}, &calls}
	context.user_ptr = &test
	earl.render_layer(&root, &backend)

	testing.expect(t, len(calls) == 3, "Should emit three render calls")
	// left window
	testing.expect(t, calls[0].vector.x == 1152, "Left width")
	testing.expect(t, calls[0].vector.y == 1080, "Left height")
	// right top
	testing.expect(t, calls[1].vector.x == 768, "Right-top width")
	testing.expect(t, calls[1].vector.y == 270, "Right-top height")
	// right bottom
	testing.expect(t, calls[2].vector.x == 768, "Right-bottom width")
	testing.expect(t, calls[2].vector.y == 810, "Right-bottom height")
}
