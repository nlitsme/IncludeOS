CPP=clang++
CPPOPTS = -std=c++11 -c -Wall -Wextra -O3 -I ../src/elf  -I ../src/dummy
OBJS = vmbuild.o
OUT = vmbuild

.cpp.o:
	@ $(CPP) $(CPPOPTS) $< -o $@

all: $(OBJS)
	@ echo ">>> Building vmbuilder"
	@ $(CPP) $(OBJS) -o $(OUT)
	@ echo "  * Done \n"

clean:
	$(RM) $(OBJS) $(OUT) *~



