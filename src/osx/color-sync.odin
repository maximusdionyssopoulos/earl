package osx

@(require) foreign import "system:ColorSync.framework"

import CG "core:sys/darwin/CoreGraphics"

@(link_prefix = "CG", default_calling_convention = "c")
foreign ColorSync {
	DisplayCreateUUIDFromDisplayID :: proc(displayID: CG.DirectDisplayID) -> UUID ---
}
