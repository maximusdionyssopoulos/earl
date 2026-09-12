package earl

import CF "sys/CoreFoundation"


WindowLayerHandle :: LayerHandle

WindowLayer :: struct {
	using layer:      Layer,
	sys_windowHandle: WindowHandle,
}

WindowDrawCall :: struct {
	window: WindowLayerHandle,
	rect:   CF.Rect,
}

@(private)
window_appendDrawCall :: proc(
	window_id: WindowLayerHandle,
	rect: CF.Rect,
	calls: ^[dynamic]WindowDrawCall,
) {
	append(calls, WindowDrawCall{window_id, rect})
}
