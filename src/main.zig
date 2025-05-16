const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const process = std.process;
const mem = std.mem;
const io = std.io;

const fatal = process.fatal;

const cmdInfo = @import("info.zig").cmdInfo;

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const usage =
    \\Usage: zackrf [command] [options]
    \\
    \\Commands:
    \\
    \\  info            Print information about the connected HackRF devices
    \\  help            Print this help and exit
    \\
    \\General Options:
    \\
    \\  -h, --help      Print command-specific usage
    \\
;

pub fn main() !void {
    const gpa, const is_debug = gpa: {
        if (builtin.link_libc) {
            // We would prefer to use raw libc allocator here, but cannot use
            // it if it won't support the alignment we need.
            if (@alignOf(std.c.max_align_t) < @max(@alignOf(i128), std.atomic.cache_line)) {
                break :gpa .{ std.heap.c_allocator, false };
            }
            break :gpa .{ std.heap.raw_c_allocator, false };
        }
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try process.argsAlloc(arena);

    return mainArgs(gpa, arena, args);
}

fn mainArgs(gpa: Allocator, arena: Allocator, args: []const []const u8) !void {
    if (args.len <= 1) {
        std.log.info("{s}", .{usage});
        fatal("expected command argument", .{});
    }

    const cmd = args[1];
    const cmd_args = args[2..];
    if (mem.eql(u8, cmd, "info")) {
        return cmdInfo();
    } else if (mem.eql(u8, cmd, "help") or mem.eql(u8, cmd, "-h") or mem.eql(u8, cmd, "--help")) {
        return io.getStdOut().writeAll(usage);
    }

    _ = gpa;
    _ = arena;
    _ = cmd_args;
}
