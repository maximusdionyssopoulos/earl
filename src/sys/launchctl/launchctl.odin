package launchctl

import "core:fmt"
import "core:os"
import "core:sys/posix"

/**
A smaller wrapper over the launchtctl cli
*/
LAUNCH_CTL :: "/bin/launchctl"

Service :: struct {
	name: string,
	uid:  posix.uid_t,
}

create :: proc "contextless" (name: string) -> Service {
	uid := posix.getuid()
	return Service{name = name, uid = uid}
}

domainTarget :: proc(ser: Service) -> string {
	return fmt.aprintf("gui/%d", ser.uid)

}
serviceTarget :: proc(ser: Service) -> string {
	return fmt.aprintf("%s/%s", domainTarget(ser), ser.name)
}

plistPath :: proc(ser: Service) -> string {
	return fmt.aprintf("~/Library/LaunchAgents/%s.plist", ser.name)
}

bootstrap :: proc(ser: Service, plist_path: string) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "bootstrap", domainTarget(ser), plist_path},
	}
	state, _, _, err := os.process_exec(desc, context.temp_allocator)
}

is_bootstrapped :: proc(ser: Service) -> bool {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "print", serviceTarget(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	return state.exit_code == 0
}

enable :: proc(ser: Service) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "enable", serviceTarget(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	fmt.println(state)
}

start :: proc(ser: Service) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "kickstart", plistPath(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	fmt.println(state)
}

stop :: proc(ser: Service) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "stop", serviceTarget(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	fmt.println(state)
}

bootout :: proc(ser: Service) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "bootout", serviceTarget(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	fmt.println(state)
}

kill :: proc(ser: Service) {
	desc := os.Process_Desc {
		command = []string{LAUNCH_CTL, "kill", "SIGTERM", serviceTarget(ser)},
	}
	state, _, _, _ := os.process_exec(desc, context.temp_allocator)
	fmt.println(state)
}
