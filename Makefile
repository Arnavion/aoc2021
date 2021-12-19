.PHONY: default run run-debug test test-release

default:
	zig build -Drelease-safe --color on

run:
	zig build run -Drelease-safe

run-debug:
	zig build run

test:
	zig build test --color on

test-release:
	zig build test -Drelease-safe --color on
