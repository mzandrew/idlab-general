CXX= g++
CXXFLAGS= -I/usr/include/libusb-1.0 -lusb-1.0
PRJ=test_usb

SRC=${PRJ}.c
EXE=${PRJ}

${EXE}: ${SRC}
	${CXX} -o $@ ${CXXFLAGS} $?
#	sudo ./$@

test2:	usb.cpp test2.cpp
	${CXX} -o $@ ${CXXFLAGS} $?
clean:
	rm -f ${EXE}
