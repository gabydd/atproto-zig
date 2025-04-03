const std = @import("std");
const Base32 = @import("base32.zig");

last_time: u64,
clock_id: u64,

const TID = @This();
pub fn init() TID {
    var rand = std.Random.DefaultPrng.init(@abs(std.time.milliTimestamp()));
    return .{
        .last_time = 0,
        .clock_id = rand.random().intRangeAtMost(u64, 0, 0x1f),
    };
}
pub fn next(tid: *TID) [13]u8 {
    var buf: [13]u8 = undefined;
    var time = @abs(std.time.microTimestamp());
    if (time == tid.last_time) {
        time += 1;
    }
    var num = time << 10;
    num |= tid.clock_id;
    tid.last_time = time;
    const bytes: [8]u8 = @bitCast(std.mem.nativeToBig(u64, num));
    Base32.encode(&bytes, &buf, Base32.sortable);
    return buf;
}
