package earl

import "core:os"
import "sys/launchctl"

/**
Service:
	Start:
		- start a launchd agent
	Install:
		- install the launchd agent
	Uninstall:
		- uninstall the launchd agent
	Restart:
		- restart the launchd agent
	Stop:
		- stop the launchd agent
*/

AppService := launchctl.create("com.github.maxdionyss.earl")
LOG_FILE := "earl.log"
ERR_FILE := "earl.err"


Service_start :: proc() {
	if !Service_installed() {
		Service_install()
	}

	if !launchctl.is_bootstrapped(AppService) {

		launchctl.bootstrap(AppService)
		launchctl.enable(AppService)
	}

	launchctl.start(AppService)
}

Service_installed :: proc() -> bool {
	return os.exists(launchctl.plistPath(AppService))
}

Service_install :: proc() -> bool {
	if Service_installed() {
		return true
	}

	path, exc_err := os.get_executable_path(context.allocator)
	if exc_err != nil {
		return false
	}
	defer delete(path)

	plist, ok := launchctl.to_string(
		launchctl.LaunchDPlist {
			label = AppService.name,
			run_at_load = true,
			keep_alive = false,
			process_type = .Interactive,
			program = path,
			program_arguments = []string{"daemon"},
		},
	)

	if !ok do return false

	f, err := os.create(launchctl.plistPath(AppService))
	if err != nil do return false
	defer os.close(f)

	os.write_string(f, plist)

	return true
}

Service_uninstall :: proc() {}

Service_restart :: proc() {
	Service_stop()
	Service_start()
}

Service_stop :: proc() {
	if launchctl.is_bootstrapped(AppService) {
		launchctl.bootout(AppService)
	} else {
		launchctl.kill(AppService)
	}
}

/*
This creates the file if it doesn't already exist,
allocates the file name on the cotnexxt allocator
*/
// Service_createFile :: proc(file: string) -> (string, bool) {
// 	// dir, err := os.temp_directory(context.allocator)
// 	// if err != nil {
// 	// 	return "", false
// 	// }

// 	// file_path := strings.concatenate([]string{dir, "/", file})

// 	f, err := os.create_temp_file("", file)


// 	// 	f.
// 	// 	if err != nil {
// 	// 		return "", false
// 	// 	}
// 	// 	defer if err == nil {os.close(f)}
// 	// }

// 	// return file_path, true

// }
