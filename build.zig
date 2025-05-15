const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libhackrf = b.addStaticLibrary(.{
        .name = "libhackrf",
        .target = target,
        .optimize = optimize,
    });
    libhackrf.linkLibC();
    libhackrf.addIncludePath(b.path("src/libhackrf"));
    libhackrf.addCSourceFile(.{
        .file = b.path("src/libhackrf/hackrf.c"),
        .flags = &.{"-std=gnu11"},
    });

    const bindings = b.addModule("hackrf", .{
        .root_source_file = b.path("bindings.zig"),
        .target = target,
        .optimize = optimize,
    });
    bindings.linkLibrary(libhackrf);

    const exe = b.addExecutable(.{
        .name = "zackrf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "hackrf",
                    .module = bindings,
                },
            },
        }),
    });
    exe.linkSystemLibrary("usb-1.0");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
