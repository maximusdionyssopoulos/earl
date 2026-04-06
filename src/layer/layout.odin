package layer

import hm "core:container/handle_map"
import "../sys"

LayoutHandle :: hm.Handle16

Layout :: struct {
	handle: LayoutHandle,
	layers: [dynamic; sys.MAX_SCREENS] Screen,
	name:   string,
}

Screen :: struct {
	layer: LayerHandle,
	display: sys.DisplayHandle
}
