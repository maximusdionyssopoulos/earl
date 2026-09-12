package gaffer

import "core:encoding/uuid"
import "darwin"

DisplayUUID :: distinct uuid.Identifier


// A display is the display information available
//
// We only store one space id for the display despite a display being able to have more than one space.
// This is a tradeoff for simplicity but as a result means some workflows may break the app.
Display :: struct {
	display_uuid:      DisplayUUID,
	direct_display_id: darwin.DirectDisplayID,
	managed_space_id:  darwin.SpaceID,
	space_uuid:        uuid.Identifier,
	frame:             darwin.Rect,
	visible_frame:     darwin.Rect,
	screen_size:       darwin.Rect,
	layout:            LAYOUT_ID,
}

