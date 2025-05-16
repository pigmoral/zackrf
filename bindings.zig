pub const hackrf_error = enum(c_int) {
    /// no error happened
    HACKRF_SUCCESS = 0,
    /// TRUE value, returned by some functions that return boolean value. Only a few functions can return this variant, and this fact should be explicitly noted at those functions.
    HACKRF_TRUE = 1,
    /// The function was called with invalid parameters.
    HACKRF_ERROR_INVALID_PARAM = -2,
    /// USB device not found, returned at opening.
    HACKRF_ERROR_NOT_FOUND = -5,
    /// Resource is busy, possibly the device is already opened.
    HACKRF_ERROR_BUSY = -6,
    /// Memory allocation (on host side) failed
    HACKRF_ERROR_NO_MEM = -11,
    /// LibUSB error, use @ref hackrf_error_name to get a human-readable error string (using `libusb_strerror`)
    HACKRF_ERROR_LIBUSB = -1000,
    /// Error setting up transfer thread (pthread-related error)
    HACKRF_ERROR_THREAD = -1001,
    /// Streaming thread could not start due to an error
    HACKRF_ERROR_STREAMING_THREAD_ERR = -1002,
    /// Streaming thread stopped due to an error
    HACKRF_ERROR_STREAMING_STOPPED = -1003,
    /// Streaming thread exited (normally)
    HACKRF_ERROR_STREAMING_EXIT_CALLED = -1004,
    /// The installed firmware does not support this function
    HACKRF_ERROR_USB_API_VERSION = -1005,
    /// Can not exit library as one or more HackRFs still in use
    HACKRF_ERROR_NOT_LAST_DEVICE = -2000,
    /// Unspecified error
    HACKRF_ERROR_OTHER = -9999,
};

pub const hackrf_usb_board_id = enum(c_uint) {
    /// Jawbreaker (beta platform) USB product id
    USB_BOARD_ID_JAWBREAKER = 0x604B,
    /// HackRF One USB product id
    USB_BOARD_ID_HACKRF_ONE = 0x6089,
    /// RAD1O (custom version) USB product id
    USB_BOARD_ID_RAD1O = 0xCC15,
    /// Invalid / unknown USB product id
    USB_BOARD_ID_INVALID = 0xFFFF,
};

pub const hackrf_board_id = enum(c_uint) {
    /// Jellybean (pre-production revision, not supported)
    BOARD_ID_JELLYBEAN = 0,
    /// Jawbreaker (beta platform, 10-6000MHz, no bias-tee)
    BOARD_ID_JAWBREAKER = 1,
    /// HackRF One (prior to rev 9, same limits: 1-6000MHz, 20MSPS, bias-tee)
    BOARD_ID_HACKRF1_OG = 2,
    /// RAD1O (Chaos Computer Club special edition with LCD & other features. 50M-4000MHz, 20MSPS, no bias-tee)
    BOARD_ID_RAD1O = 3,
    /// HackRF One (rev. 9 & later. 1-6000MHz, 20MSPS, bias-tee)
    BOARD_ID_HACKRF1_R9 = 4,
    /// Unknown board (failed detection)
    BOARD_ID_UNRECOGNIZED = 0xFE,
    /// Unknown board (detection not yet attempted, should be default value)
    BOARD_ID_UNDETECTED = 0xFF,
};

pub const hackrf_board_rev = enum(c_uint) {
    /// Older than rev6
    BOARD_REV_HACKRF1_OLD = 0,
    /// board revision 6, generic
    BOARD_REV_HACKRF1_R6 = 1,
    /// board revision 7, generic
    BOARD_REV_HACKRF1_R7 = 2,
    /// board revision 8, generic
    BOARD_REV_HACKRF1_R8 = 3,
    /// board revision 9, generic
    BOARD_REV_HACKRF1_R9 = 4,
    /// board revision 10, generic
    BOARD_REV_HACKRF1_R10 = 5,

    /// board revision 6, made by GSG
    BOARD_REV_GSG_HACKRF1_R6 = 0x81,
    /// board revision 7, made by GSG
    BOARD_REV_GSG_HACKRF1_R7 = 0x82,
    /// board revision 8, made by GSG
    BOARD_REV_GSG_HACKRF1_R8 = 0x83,
    /// board revision 9, made by GSG
    BOARD_REV_GSG_HACKRF1_R9 = 0x84,
    /// board revision 10, made by GSG
    BOARD_REV_GSG_HACKRF1_R10 = 0x85,

    /// unknown board revision (detection failed)
    BOARD_REV_UNRECOGNIZED = 0xFE,
    /// unknown board revision (detection not yet attempted)
    BOARD_REV_UNDETECTED = 0xFF,

    pub fn isGsg(self: hackrf_board_rev) bool {
        return (@intFromEnum(self) & 0x80) != 0;
    }
};

/// JAWBREAKER platform bit in result of @ref hackrf_supported_platform_read
/// @ingroup device
pub const HACKRF_PLATFORM_JAWBREAKER = (1 << 0);
/// HACKRF ONE (pre r9) platform bit in result of @ref hackrf_supported_platform_read
/// @ingroup device
pub const HACKRF_PLATFORM_HACKRF1_OG = (1 << 1);
/// RAD1O platform bit in result of @ref hackrf_supported_platform_read
/// @ingroup device
pub const HACKRF_PLATFORM_RAD1O = (1 << 2);
/// HACKRF ONE (r9 or later) platform bit in result of @ref hackrf_supported_platform_read
/// @ingroup device
pub const HACKRF_PLATFORM_HACKRF1_R9 = (1 << 3);

const hackrf_device_list_t = extern struct {
    serial_numbers: [*c][*c]u8,
    usb_board_ids: [*c]hackrf_usb_board_id,
    usb_device_index: [*c]c_int,
    devicecount: c_int,
    usb_devices: ?*anyopaque,
    usb_devicecount: c_int,
};

pub const read_partid_serialno = extern struct {
    /// MCU part ID register value
    part_id: [2]u32,
    /// MCU device unique ID (serial number)
    serial_no: [4]u32,
};

pub const hackrf_device = opaque {};

pub extern fn hackrf_init() c_int;
pub extern fn hackrf_exit() c_int;
pub extern fn hackrf_device_list() [*c]hackrf_device_list_t;
pub extern fn hackrf_device_list_open([*c]hackrf_device_list_t, c_int, [*c]?*hackrf_device) c_int;
pub extern fn hackrf_device_list_free([*c]hackrf_device_list_t) void;
pub extern fn hackrf_open([*c]?*hackrf_device) c_int;
pub extern fn hackrf_open_by_serial([*c]const u8, [*c]?*hackrf_device) c_int;
pub extern fn hackrf_close(?*hackrf_device) c_int;
pub extern fn hackrf_board_id_read(?*hackrf_device, [*c]u8) c_int;
pub extern fn hackrf_board_id_name(hackrf_board_id) [*c]const u8;
pub extern fn hackrf_version_string_read(?*hackrf_device, [*c]u8, u8) c_int;
pub extern fn hackrf_usb_api_version_read(?*hackrf_device, [*c]u16) c_int;
pub extern fn hackrf_board_partid_serialno_read(?*hackrf_device, [*c]read_partid_serialno) c_int;
pub extern fn hackrf_board_rev_read(?*hackrf_device, [*c]u8) c_int;
pub extern fn hackrf_board_rev_name(hackrf_board_rev) [*c]const u8;
pub extern fn hackrf_supported_platform_read(?*hackrf_device, [*c]u32) c_int;
