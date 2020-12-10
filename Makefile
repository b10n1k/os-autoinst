# This is a convenience Makefile wrapping cmake calls
# All targets should be defined in CMake

.PHONY: all
all: build/CMakeCache.txt
	ninja -C build/ all

.DEFAULT: build/CMakeCache.txt
	ninja -C build/ $@

build/CMakeCache.txt:
	@mkdir -p build
	@(cd build && cmake -GNinja ..)
