package earl

import hm "core:container/handle_map"


LayoutHandle :: hm.Handle16

Layout :: struct {
	handle: LayoutHandle,
	layers: [dynamic; MAX_SCREENS] Screen,
	name:   string,
}

Screen :: struct {
	layer: LayerHandle,
	display: DisplayHandle
}
