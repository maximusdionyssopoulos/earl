package earl

import hm "core:container/handle_map"
import "core:container/small_array"

LayoutHandle :: hm.Handle16


Layout :: struct {
	handle: LayoutHandle,
	layers: small_array.Small_Array(MAX_SCREENS, Pane), // each layerID
	name:   string,
}
