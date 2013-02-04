COMPILE_FLAGS = -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB
#COMPILE_FLAGS = -Isrc/lib -I/usr/include/libusb-1.0 -DUSE_USB -DFAKE_IT
#COMPILE_FLAGS = -Icontrib -DUSE_FIBER
LINK_OPTIONS = -L/usr/lib/i386-linux-gnu -lusb-1.0

# things we always need built:
FINAL_OBJECT_FILES = bin/setPreampSetupDACs bin/multiChannel64SampleReadout

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/DebugInfoWarningError.o work/generic.o work/io_interface.o work/idl_usb.o work/packet_interface.o

default :
	if [ ! -e src     ]; then mkdir     src; fi
	if [ ! -e work    ]; then mkdir    work; fi
	if [ ! -e bin     ]; then mkdir     bin; fi
	$(MAKE) intermediate all

intermediate : $(INTERMEDIATE_OBJECT_FILES)

all : $(FINAL_OBJECT_FILES) $(NON_ESSENTIAL_HELPER_PROGRAMS)

work/%.o : src/%.cpp $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/test/%.cpp $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/lib/%.cpp src/lib/%.h ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

work/%.o : src/%.c $(INTERMEDIATE_OBJECT_FILES) ;
	g++ $(COMPILE_FLAGS) -c $< -o $@

bin/setPreampSetupDACs     : work/setPreampSetupDACs.o     $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

bin/multiChannel64SampleReadout     : work/multiChannel64SampleReadout.o     $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work/* bin/*

