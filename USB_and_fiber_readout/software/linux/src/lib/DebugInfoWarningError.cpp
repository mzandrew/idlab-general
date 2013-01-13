// 2013-01-13 mza (replaced c version with c++ one)

#include "DebugInfoWarningError.h"

std::ofstream debug, debug2, info, warning, error;
DebugInfoWarningError DebugInfoWarningError; // creates local object with default constructor called before main()

DebugInfoWarningError::DebugInfoWarningError() {
	has_been_initialized = false;
	verbosity = 3;
	init();
}

DebugInfoWarningError::DebugInfoWarningError(unsigned short int desired_verbosity) {
	has_been_initialized = false;
	verbosity = desired_verbosity;
	init();
}

DebugInfoWarningError::~DebugInfoWarningError() {
	close_all();
}

void DebugInfoWarningError::close_all() {
	  error.close();
	warning.close();
	   info.close();
	  debug.close();
	 debug2.close();
	has_been_initialized = false;
}

void DebugInfoWarningError::init() {
	if (has_been_initialized) { return; }
	has_been_initialized = true;
	if (verbosity >= 1) {   error.open("/dev/stderr"); } else {   error.open("/dev/null"); }
	if (verbosity >= 2) { warning.open("/dev/stderr"); } else { warning.open("/dev/null"); }
	if (verbosity >= 3) {    info.open("/dev/stdout"); } else {    info.open("/dev/null"); }
	if (verbosity >= 4) {   debug.open("/dev/stdout"); } else {   debug.open("/dev/null"); }
	if (verbosity >= 5) {  debug2.open("/dev/stdout"); } else {  debug2.open("/dev/null"); }
	if (0) {
		error   << "this is an error message"  << std::endl;
		warning << "this is a warning message" << std::endl;
		info    << "this is an info message"   << std::endl;
		debug   << "this is a debug message"   << std::endl;
		debug2  << "this is a debug2 message"  << std::endl;
	}
}

unsigned short int DebugInfoWarningError::ChangeVerbosity(unsigned short int new_verbosity) {
	close_all();
	unsigned short int old_verbosity = verbosity;
	verbosity = new_verbosity;
	init();
	return old_verbosity;
}

unsigned short int change_verbosity(unsigned short int new_verbosity) {
	DebugInfoWarningError.ChangeVerbosity(new_verbosity);
}

