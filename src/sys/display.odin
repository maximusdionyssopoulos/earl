package sys

import CF "CoreFoundation"
import SLS "Skylight"
import "core:container/handle_map"
import "core:encoding/uuid"
import "core:fmt"

// A conservative guess for the max number a screens to account for
// this is purely a guess to avoid using a heap based dynamic array
// if this becomes a problem I'd think to just use a dynamic array
MAX_SCREENS :: 10

DisplayUUID :: distinct uuid.Identifier


// A display is the display information available
//
// We store the only space id. A display can have multiple spaces but we ignore that.
//
// should cache some more stuff about the monitor like the screen size, area, menubar, notch
//
DisplayHandle :: handle_map.Handle16
Display :: struct {
	handle:           DisplayHandle,
	display_uuid:     DisplayUUID,
	managed_space_id: SLS.SpaceID,
	space_uuid:       uuid.Identifier,
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
		display_uuid_str := CF.Dictionary_getString(dict, CF.STR("Display Identifier")) or_continue
		display_uuid, err := uuid.read(display_uuid_str)
		if err != .None {
			panic("Error converting read uuids when gathering displays")
		}

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
				managed_space_id = SLS.SpaceID(managed_space_id),
				space_uuid = space_uuid,
			},
		)
	}
}
