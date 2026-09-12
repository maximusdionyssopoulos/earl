package gaffer

MAX_SCREENS :: 200
MAX_LAYOUTS :: 1024

DISPLAY_ID :: distinct u8
WINDOW_ID :: distinct u16
LAYOUT_ID :: distinct u16
LAYER_ID :: distinct u16

import "darwin"

WindowKind :: enum {
	SingleWindow,
	NativeTabbedWindow,
	System_Or_IgnoredWindow,
}

Window :: struct {
	name:             string,
	darwin_window_id: darwin.WindowID,
	ax_ref:           darwin.UIElementRef,
	kind:             WindowKind,
	is_front:         bool,
}

SplitType :: enum {
	Horizontal,
	Vertical,
}
Split :: struct {
	ratio:       f64,
	left_child:  LAYOUT_ID,
	right_child: LAYOUT_ID,
	type:        SplitType,
}

Layer :: union {
	Split,
	Window,
}

Arrangement :: struct {
	display_id: DISPLAY_ID,
	layer_id:   LAYER_ID,
}
Layout :: struct {
	name:     string,
	displays: []Arrangement,
}

State :: struct {
	displays: []Display,
	layer:    []Layer,
	layouts:  []Layout,
	active:   LAYOUT_ID,
}

