package earl

import hm "core:container/handle_map"
import "core:fmt"
import "core:sys/darwin/CoreGraphics"
import "osx"

// A conservative guess for the max number a screens to account for
// this is purely a guess to avoid using a heap based dynamic array
// if this becomes a problem I'd think to just use a dynamic array
MAX_SCREENS :: 10

// A screen represents a visible screen for a user (i.e. a monitor)
// we store the CFUUID as a byte array - 128 bits using CFUUIDGetUUIDBytes as it gets a permanent ID - https://github.com/waydabber/BetterDisplay/discussions/3628#discussioncomment-11266263
//
// We can then back track that to get the correct size mesurements of the screen to use when displaying a window
ScreenUUID :: distinct u128

// A pane reprents what is currently being displayed and where
// i.e. what window or split is being displayed on what screen.
Screen :: struct {
	screen_uuid:  ScreenUUID,
	layer_handle: LayerID,
}


screen_getAllDisplays :: proc(screens: ^[dynamic]ScreenUUID) -> bool {
	expected_count: u32 = 0
	CoreGraphics.GetActiveDisplayList(0, nil, &expected_count)

	direct_display_ids := make([]CoreGraphics.DirectDisplayID, expected_count)
	defer delete(direct_display_ids)

	actual_count: u32 = 0
	error := CoreGraphics.GetActiveDisplayList(
		expected_count,
		raw_data(direct_display_ids),
		&actual_count,
	)

	for display_id in direct_display_ids {
		cg_screen_uuid := osx.DisplayCreateUUIDFromDisplayID(display_id)
		screen_uuid := transmute(ScreenUUID)osx.GetUUIDBytes(cg_screen_uuid)

		append(screens, screen_uuid)
	}

	return true

}
