.PHONY: default run run-debug test

default:
	zig build -Drelease-safe --color on

run:
	zig build run -Drelease-safe

run-debug:
	zig build run

test:
	zig build test --color on
