CXXFLAGS = -I/usr/include/libusb-1.0 

# things we always need built:
FINAL_OBJECT_FILES = bin/SCROD_test bin/universal_eval_test

# needed to link all:
INTERMEDIATE_OBJECT_FILES = work/usb.o

LINK_OPTIONS = -lusb-1.0
#-L$(shell pwd)/contrib -laltix -lxx_usb -lusb -Wl,-rpath,$(shell pwd)/contrib

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

bin/universal_eval_test : work/universal_eval_test.o ; g++ $^ $(LINK_OPTIONS) -o $@
bin/SCROD_test : work/SCROD_test.o $(INTERMEDIATE_OBJECT_FILES) ; g++ $^ $(LINK_OPTIONS) -o $@

clean: 
	-rm -rf work bin

