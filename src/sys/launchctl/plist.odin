package launchctl

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:reflect"
import "core:strings"
/**
This file is useful for creating launchd plists using odin structs and struct field tags

It was generated from: https://www.manpagez.com/man/5/launchd.plist/
It is non exhaustive and pretty rudamentaty at the moment. The parsing is quite naive.
But it works for my case.
*/

// LaunchDKeepAlive :: struct {
// 	successful_exit:   bool `plist:"SuccessfulExit"`,
// 	network_state:     bool `plist:"NetworkState"`,
// 	path_state:        map[string]bool `plist:"PathState"`,
// 	other_job_enabled: map[string]bool `plist:"OtherJobEnabled"`,
// }

LaunchDPlist :: struct {
	// Required
	label:               string `plist:"Label"`,

	// Program execution
	program:             string `plist:"Program"`,
	program_arguments:   []string `plist:"ProgramArguments"`,

	// Lifecycle
	run_at_load:         bool `plist:"RunAtLoad"`,
	keep_alive:          bool `plist:"KeepAlive"`,

	// I/O
	standard_out_path:   string `plist:"StandardOutPath"`,
	standard_error_path: string `plist:"StandardErrorPath"`,
	process_type:        enum {
		Background,
		Standard,
		Adaptive,
		Interactive,
	} `plist:"ProcessType"`,
}

// Writes a plist struct into a string to be saved to a file
// This allocates the string that is returned
// This string must be freeded
//
to_string :: proc(plist: LaunchDPlist) -> (plistStr: string, ok: bool) {
	if (len(plist.label) == 0) {
		return "", false
	}

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	id := typeid_of(LaunchDPlist)
	names := reflect.struct_field_names(id)
	types := reflect.struct_field_types(id)
	tags := reflect.struct_field_tags(id)

	fmt.sbprintf(&sb, `<?xml version="1.0" encoding="UTF-8"?>`, newline = true)
	fmt.sbprintf(
		&sb,
		`<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">`,
		newline = true,
	)
	fmt.sbprintf(&sb, `<plist version="1.0">`, newline = true)
	fmt.sbprintf(&sb, `<dict>`, newline = true)

	for tag, i in tags {
		name, type := names[i], types[i]
		key := reflect.struct_tag_lookup(tag, "plist") or_continue

		value := reflect.struct_field_value_by_name(plist, name)
		write_node(&sb, Plist_Node{key, value})
	}

	fmt.sbprintf(&sb, `</dict>`, newline = true)
	fmt.sbprintf(&sb, `</plist>`)

	plist := strings.to_string(sb)
	plist = strings.clone(plist)

	return plist, true
}

Plist_Node :: struct {
	key:   string,
	value: any,
}
write_node :: proc(sb: ^strings.Builder, node: Plist_Node) {
	value := node.value
	key := node.key

	ti := runtime.type_info_base(type_info_of(value.id))
	a := any{value.data, ti.id}

	#partial switch info in ti.variant {
	case runtime.Type_Info_String:
		if str, valid := reflect.as_string(value); valid && len(str) > 0 {
			if len(key) > 0 {
				fmt.sbprintf(sb, "<key>%s</key>", key, newline = true)
			}
			fmt.sbprintf(sb, "<string>%s</string>", str, newline = true)
		}
	case runtime.Type_Info_Boolean:
		if b, valid := reflect.as_bool(value); valid {
			fmt.sbprintf(sb, "<key>%s</key>", key, newline = true)
			fmt.sbprintf(sb, "<true/>" if b else "<false/>", newline = true)
		}
	case runtime.Type_Info_Slice:
		slice := cast(^mem.Raw_Slice)value.data
		for i in 0 ..< slice.len {
			if i == 0 {
				fmt.sbprintf(sb, "<array>", newline = true)
			}

			sd := uintptr(slice.data) + uintptr(i * info.elem_size)
			sa := any{rawptr(sd), info.elem.id}
			write_node(sb, Plist_Node{value = sa})

			if i == slice.len - 1 {
				fmt.sbprintf(sb, "</array>", newline = true)
			}
		}
	case runtime.Type_Info_Enum:
		name := reflect.enum_string(value)
		fmt.sbprintf(sb, "<key>%s</key>", key, newline = true)
		fmt.sbprintf(sb, "<string>%s</string>", name, newline = true)
	}
}
