#include <fstream>
using namespace std; // helpful for getting at std::endl with just endl

class DebugInfoWarningError {
	private:
		unsigned short int verbosity;
		bool has_been_initialized;
		void init();
		void close_all();
	public:
		DebugInfoWarningError();
		DebugInfoWarningError(unsigned short int desired_verbosity);
		~DebugInfoWarningError();
		unsigned short int ChangeVerbosity(unsigned short int new_verbosity);
};

extern std::ofstream debug, debug2, info, warning, error;

unsigned short int change_verbosity(unsigned short int new_verbosity);

