#include "DebugInfoWarningError.h"

int main() {
/*
	cout << "hi, " << endl;
	//DebugInfoWarningError DIWE;     // using default verbosity (3/info)
	DebugInfoWarningError DIWE(4); // sets desired verbosity
	DIWE.ChangeVerbosity(3);
	cout << "earth!" << endl;
*/
	info << "this is an informational message" << endl;
	change_verbosity(1);
	info << "but you don't see this one" << endl;
}

