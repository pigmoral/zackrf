const std = @import("std");
const hackrf = @import("hackrf");
const fatal = std.process.fatal;

pub fn cmdInfo() !void {
    try do(hackrf.hackrf_init(), @typeName(@TypeOf(hackrf.hackrf_init)));
    defer _ = hackrf.hackrf_exit();

    const list = hackrf.hackrf_device_list();
    defer hackrf.hackrf_device_list_free(list);
    if (list.*.devicecount < 1) {
        fatal("No HackRF devices found.\n", .{});
    }

    const device_count: usize = @intCast(list.*.devicecount);
    for (0..device_count) |i| {
        std.debug.print("Found HackRF {d}:\n", .{i});

        // Print serial number
        if (list.*.serial_numbers[i]) |num|
            std.debug.print("\tSerial number: {s}\n", .{num});

        // Open device
        var device: *hackrf.hackrf_device = undefined;
        try do(
            hackrf.hackrf_device_list_open(list, @intCast(i), @alignCast(@ptrCast(&device))),
            @typeName(@TypeOf(hackrf.hackrf_device_list_open)),
        );
        defer do(
            hackrf.hackrf_close(device),
            @typeName(@TypeOf(hackrf.hackrf_close)),
        ) catch {};

        // Print board ID
        var board_id: hackrf.hackrf_board_id = .BOARD_ID_UNDETECTED;
        try do(
            hackrf.hackrf_board_id_read(device, @ptrCast(&board_id)),
            @typeName(@TypeOf(hackrf.hackrf_board_id_read)),
        );
        std.debug.print(
            "\tBoard ID: {d} ({s})\n",
            .{ @intFromEnum(board_id), hackrf.hackrf_board_id_name(board_id) },
        );

        // Print board version and USB version
        var version: [255:0]u8 = undefined;
        try do(
            hackrf.hackrf_version_string_read(device, &version, version.len),
            @typeName(@TypeOf(hackrf.hackrf_version_string_read)),
        );

        var usb_version: u16 = undefined;
        try do(
            hackrf.hackrf_usb_api_version_read(device, @ptrCast(&usb_version)),
            @typeName(@TypeOf(hackrf.hackrf_usb_api_version_read)),
        );
        std.debug.print(
            "\tFirmware Version: {s} (API:{x}.{x:0>2})\n",
            .{ version, usb_version >> 8, usb_version & 0xFF },
        );

        // Print part ID number
        var part_id: hackrf.read_partid_serialno = undefined;
        try do(
            hackrf.hackrf_board_partid_serialno_read(device, @ptrCast(&part_id)),
            @typeName(@TypeOf(hackrf.hackrf_board_partid_serialno_read)),
        );
        std.debug.print(
            "\tPart ID Number: 0x{x:0>8} 0x{x:0>8}\n",
            .{ part_id.part_id[0], part_id.part_id[1] },
        );

        // Print board revision
        var board_rev: hackrf.hackrf_board_rev = .BOARD_REV_UNDETECTED;
        if (usb_version >= 0x0106 and
            board_id == .BOARD_ID_HACKRF1_OG or board_id == .BOARD_ID_HACKRF1_R9)
        {
            try do(
                hackrf.hackrf_board_rev_read(device, @ptrCast(&board_rev)),
                @typeName(@TypeOf(hackrf.hackrf_board_rev_read)),
            );
            printBoardRev(board_rev);
        }

        // Print supported platforms
        var platform: u32 = 0;
        if (usb_version >= 0x0106) {
            try do(
                hackrf.hackrf_supported_platform_read(device, @ptrCast(&platform)),
                @typeName(@TypeOf(hackrf.hackrf_supported_platform_read)),
            );
            printSupportedPlatform(platform, board_id);
        }
    }
}

fn printBoardRev(board_rev: hackrf.hackrf_board_rev) void {
    switch (board_rev) {
        .BOARD_REV_UNDETECTED => {
            std.debug.print("\tError: Hardware revision not yet detected by firmware.\n", .{});
            return;
        },
        .BOARD_REV_UNRECOGNIZED => {
            std.debug.print("\tWarning: Hardware revision not recognized by firmware.\n", .{});
            return;
        },
        else => {},
    }

    std.debug.print("\tHardware Revision: {s}\n", .{hackrf.hackrf_board_rev_name(board_rev)});

    if (@intFromEnum(board_rev) > @intFromEnum(hackrf.hackrf_board_rev.BOARD_REV_HACKRF1_OLD)) {
        if (board_rev.isGsg()) {
            std.debug.print("\tHardware appears to have been manufactured by Great Scott Gadgets.\n", .{});
        } else {
            std.debug.print("\tHardware does not appear to have been manufactured by Great Scott Gadgets.\n", .{});
        }
    }
}

fn printSupportedPlatform(platform: u32, board_id: hackrf.hackrf_board_id) void {
    std.debug.print("\tHardware supported by installed firmware:\n", .{});
    if (platform & hackrf.HACKRF_PLATFORM_JAWBREAKER != 0)
        std.debug.print("\t\tJawbreaker\n", .{});
    if (platform & hackrf.HACKRF_PLATFORM_RAD1O != 0)
        std.debug.print("\t\trad1o\n", .{});
    if (platform & hackrf.HACKRF_PLATFORM_HACKRF1_OG != 0 or
        platform & hackrf.HACKRF_PLATFORM_HACKRF1_R9 != 0)
        std.debug.print("\t\tHackRF One\n", .{});
    switch (board_id) {
        .BOARD_ID_HACKRF1_OG => {
            if (platform & hackrf.HACKRF_PLATFORM_HACKRF1_OG == 0)
                std.debug.print("\tError: Firmware does not support HackRF One revisions older than r9.\n", .{});
        },
        .BOARD_ID_HACKRF1_R9 => {
            if (platform & hackrf.HACKRF_PLATFORM_HACKRF1_R9 == 0)
                std.debug.print("\tError: Firmware does not support HackRF One r9.\n", .{});
        },
        .BOARD_ID_JAWBREAKER => {
            if (platform & hackrf.HACKRF_PLATFORM_JAWBREAKER == 0)
                std.debug.print("\tError: Firmware does not support hardware platform.\n", .{});
        },
        .BOARD_ID_RAD1O => {
            if (platform & hackrf.HACKRF_PLATFORM_RAD1O == 0)
                std.debug.print("\tError: Firmware does not support hardware platform.\n", .{});
        },
        else => {
            std.debug.print("\tWarning: Unknown board ID.\n", .{});
        },
    }
}

fn do(err: c_int, name: []const u8) !void {
    switch (@as(hackrf.hackrf_error, @enumFromInt(err))) {
        .HACKRF_SUCCESS => {},
        else => |result| {
            fatal(
                "{s} error: {s} ({d})\n",
                .{ name, @tagName(result), @intFromEnum(result) },
            );
        },
    }
}
