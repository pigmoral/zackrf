const std = @import("std");
const hackrf = @import("hackrf");

pub fn main() !void {
    const result = hackrf.hackrf_init();
    defer _ = hackrf.hackrf_exit();

    std.debug.print("HackRF initialized: {}\n", .{result});
}
