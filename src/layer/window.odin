package layer

import CF "../sys/CoreFoundation"
import "../sys"


WindowHandle :: LayerHandle

Window :: struct {
	using layer:      Layer,
	sys_windowHandle: sys.WindowHandle,
}

WindowDrawCall :: struct {
	window: WindowHandle,
	rect:   CF.Rect,
}

@(private)
window_appendDrawCall :: proc(
	window_id: WindowHandle,
	rect: CF.Rect,
	calls: ^[dynamic]WindowDrawCall,
) {
	append(calls, WindowDrawCall{window_id, rect})
}
