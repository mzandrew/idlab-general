COMPILE_FLAGS = -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB `root-config --cflags `
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0 `root-config --glibs` 

# things we always need built:
FINAL_OBJECT_FILES = bin/target6Control_readReg bin/target6Control_writeReg bin/target6Control_writeDacReg

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/generic.o work/io_interface.o work/idl_usb.o work/packet_interface.o work/target6ControlClass.o

default :
	if [ ! -e src     ]; then mkdir     src; fi
	if [ ! -e work    ]; then mkdir    work; fi
	if [ ! -e bin     ]; then mkdir     bin; fi
	$(MAKE) intermediate all

intermediate : $(INTERMEDIATE_OBJECT_FILES)

all : $(FINAL_OBJECT_FILES)

work/%.o : src/%.cpp $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/lib/%.cpp src/lib/%.h ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/target6Control_readReg  : work/target6Control_readReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_writeReg  : work/target6Control_writeReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/target6Control_writeDacReg  : work/target6Control_writeDacReg.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work/* bin/*



