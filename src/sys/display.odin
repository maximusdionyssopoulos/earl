package sys

import CF "CoreFoundation"
import CG "CoreGraphics"
import SLS "Skylight"

import "core:container/handle_map"
import "core:encoding/uuid"
import NS "core:sys/darwin/Foundation"

// A conservative guess for the max number a screens to account for
// this is purely a guess to avoid using a heap based dynamic array
// if this becomes a problem I'd think to just use a dynamic array
MAX_SCREENS :: 10

DisplayUUID :: distinct uuid.Identifier


DisplayHandle :: handle_map.Handle16

// A display is the display information available
//
// We only store one space id for the display despite a display being able to have more than one space.
// This is a tradeoff for simplicity but as a result means some workflows may break the app.
Display :: struct {
	handle:            DisplayHandle,
	display_uuid:      DisplayUUID,
	direct_display_id: CG.DirectDisplayID,
	managed_space_id:  SLS.SpaceID,
	space_uuid:        uuid.Identifier,
	frame:             CF.Rect,
	visible_frame:     CF.Rect,
	screen_size:       CF.Rect,
}

Display_gatherDisplays :: proc(
	displays: ^handle_map.Static_Handle_Map(MAX_SCREENS, Display, DisplayHandle),
) {
	/*
	Shape of the dictionary inside the array
	(
        {
        "Current Space" =         {
            ManagedSpaceID = 3;
            id64 = 3;
            type = 0;
            uuid = "22EB273B-C4D0-4BB9-8EDE-74C896BC3354";
        };
        "Display Identifier" = "54A6CAF2-E408-4BE1-9376-052F3727EAB9";
        Spaces = // ignored    },
    }
)
	*/

	array := SLS.CopyManagedDisplaySpaces(SLS.MainConnectionID())
	count := CF.ArrayGetCount(array)

	for i in 0 ..< count {
		dict := CF.ArrayGetValueAtIndex(array, i)
		display_uuid_cf_str := cast(CF.String)CF.DictionaryGetValue(
			dict,
			CF.STR("Display Identifier"),
		)
		display_uuid_str := CF.StringCopyToOdinString(display_uuid_cf_str)

		display_uuid, err := uuid.read(display_uuid_str)
		if err != .None {
			panic("Error converting read uuids when gathering displays")
		}

		direct_display_id := CG.DisplayGetDisplayIDFromUUID(
			CF.UUIDCreateFromString(CF.AllocatorGetDefault(), display_uuid_cf_str),
		)


		space_dict := cast(CF.Dictionary)CF.DictionaryGetValue(dict, CF.STR("Current Space"))
		space_uuid_str := CF.Dictionary_getString(space_dict, CF.STR("uuid")) or_continue
		space_uuid, s_err := uuid.read(space_uuid_str)
		if s_err != .None {
			panic("Error converting read uuids when gathering displays")
		}

		managed_space_id := CF.Dictionary_getNumber(
			int,
			space_dict,
			CF.STR("ManagedSpaceID"),
		) or_continue


		h, ok := handle_map.add(
			displays,
			Display {
				display_uuid = DisplayUUID(display_uuid),
				direct_display_id = direct_display_id,
				managed_space_id = SLS.SpaceID(managed_space_id),
				space_uuid = space_uuid,
			},
		)
	}
}

Display_cacheScreenInformation :: proc(
	displays: ^handle_map.Static_Handle_Map(MAX_SCREENS, Display, DisplayHandle),
) {
	screens := NS.Screen_screens()

	for i in 0 ..< screens->count() {
		screen := screens->objectAs(i, ^NS.Screen)
		dict := screen->deviceDescription()
		str := NS.String_alloc()
		str = NS.String_initWithOdinString(str, "NSScreenNumber")

		number := cast(^NS.Number)dict->objectForKey(str)
		display := Display_findWithDirectDisplayId(displays, number->u32Value()) or_continue
		display.frame = screen->frame()
		display.visible_frame = screen->visibleFrame()

		screen_size := screen->visibleFrame()
		screen_size.origin.y =
			screen->frame().size.height - screen_size.origin.y - screen_size.size.height
		display.screen_size = screen_size
	}
}

Display_findWithDirectDisplayId :: proc(
	displays: ^handle_map.Static_Handle_Map(MAX_SCREENS, Display, DisplayHandle),
	direct_display_id: CG.DirectDisplayID,
) -> (
	display: ^Display,
	ok: bool,
) {
	it := handle_map.iterator_make(displays)
	for d, _ in handle_map.iterate(&it) {
		if d.direct_display_id == direct_display_id {
			return d, true
		}
	}
	return
}
