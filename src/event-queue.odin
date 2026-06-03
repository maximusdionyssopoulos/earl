package earl

import "base:runtime"
import "core:sync"

// This is adapted from the odin mpsc https://github.com/odin-lang/Odin/blob/master/core/nbio/mpsc.odin
EventQueue :: struct {
	count:  int,
	head:   int,
	tail:   int,
	buffer: []^Event,
	mask:   int,
}

EventQueue_init :: proc(
	mpscq: ^EventQueue,
	cap: int,
	allocator: runtime.Allocator,
) -> runtime.Allocator_Error {
	assert(runtime.is_power_of_two_int(cap), "cap must be a power of 2")
	mpscq.buffer = make([]^Event, cap, allocator) or_return
	mpscq.mask = cap - 1
	sync.atomic_thread_fence(.Release)
	return nil
}

EventQueue_destroy :: proc(mpscq: ^EventQueue, allocator: runtime.Allocator) {
	delete(mpscq.buffer, allocator)
}

EventQueue_enqueue :: proc(mpscq: ^EventQueue, obj: ^Event) -> bool {
	count := sync.atomic_add_explicit(&mpscq.count, 1, .Acquire)
	if count >= len(mpscq.buffer) {
		sync.atomic_sub_explicit(&mpscq.count, 1, .Release)
		return false
	}

	head := sync.atomic_add_explicit(&mpscq.head, 1, .Acquire)
	assert(mpscq.buffer[head & mpscq.mask] == nil)
	rv := sync.atomic_exchange_explicit(&mpscq.buffer[head & mpscq.mask], obj, .Release)
	assert(rv == nil)
	return true
}

EventQueue_dequeue :: proc(mpscq: ^EventQueue) -> ^Event {
	ret := sync.atomic_exchange_explicit(&mpscq.buffer[mpscq.tail], nil, .Acquire)
	if ret == nil {
		return nil
	}

	mpscq.tail += 1
	if mpscq.tail >= len(mpscq.buffer) {
		mpscq.tail = 0
	}
	r := sync.atomic_sub_explicit(&mpscq.count, 1, .Release)
	assert(r > 0)
	return ret
}

EventQueue_count :: proc(mpscq: ^EventQueue) -> int {
	return sync.atomic_load_explicit(&mpscq.count, .Relaxed)
}

EventQueue_cap :: proc(mpscq: ^EventQueue) -> int {
	return len(mpscq.buffer)
}

EventQueue_peek :: proc(mpscq: ^EventQueue) -> ^Event {
	if EventQueue_count(mpscq) == 0 {
		return nil
	}
	return mpscq.buffer[mpscq.tail]
}
