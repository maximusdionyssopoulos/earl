package earl

import hm "core:container/handle_map"

import CF "/sys/CoreFoundation"


LayerHandle :: hm.Handle16
Layer :: struct {
	handle:  LayerHandle,
	// _next:     LayerHandle,
	// _previous: LayerHandle,
	variant: union {
		^Split,
		^WindowLayer,
	},
}

Layer_new :: proc($T: typeid) -> ^T {
	l := new(T)
	l.variant = l
	return l
}

layer_tile :: proc(layer: ^Layer) {
	// idea orchestaration procedure it spawns a thread to generate a queue of windows to render with the rectangle they should be
	// it can then spawn threads to do the rendering
	//
	// because this may have to wait for each window to be properly tiled it could be better to seperate this into two threads
	// a main thread computing the layout and a background thread taking the computed nodes and 'rendering' using the ax api
	// currently this wouldn't work because theres no distinction here between what to render but with some tweaks i can see it
}

Layer_computeLayout :: proc(calls: ^[dynamic]WindowDrawCall, layer: ^Layer, rect: CF.Rect) {
	switch l in layer.variant {
	case ^WindowLayer:
		window_appendDrawCall(l.handle, rect, calls)
	case ^Split:
		split_computeRectangles(l, rect, calls)
	}
}
