CXXFLAGS = -I/usr/include/libusb-1.0 

# things we always need built:
FINAL_OBJECT_FILES = bin/SCROD_LED_test bin/SCROD_read_temp bin/SCROD_setID bin/packet_test

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/idl_usb.o work/packet_interface.o

LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0

default :
	if [ ! -e src     ]; then mkdir     src; fi
	if [ ! -e work    ]; then mkdir    work; fi
	if [ ! -e bin     ]; then mkdir     bin; fi
	$(MAKE) intermediate
	$(MAKE) all

intermediate : $(INTERMEDIATE_OBJECT_FILES)

all : $(FINAL_OBJECT_FILES)

work/%.o : src/%.cpp
	g++ $(CXXFLAGS) -c $< -o $@

work/%.o : src/%.c
	g++ $(CXXFLAGS) -c $< -o $@

bin/SCROD_LED_test : work/SCROD_LED_test.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/SCROD_read_temp : work/SCROD_read_temp.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/SCROD_setID : work/SCROD_setID.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/packet_test : work/packet_test.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work bin

