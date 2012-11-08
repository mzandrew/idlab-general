#include "packet_interface.h"

main() {
	packet a;
	a.CreateCommandPacket(137,0xA201);
	a.AddPingToPacket();
	a.AddWriteToPacket(16,1);
	a.PrintPacket();
}
