package ColorSync
foreign import "system:ColorSync.framework"
import CF "../CoreFoundation"
import CG "../CoreGraphics"

@(link_prefix = "CG", default_calling_convention = "c")
foreign ColorSync {
	DisplayCreateUUIDFromDisplayID :: proc(displayID: CG.DirectDisplayID) -> CF.UUID ---
}
