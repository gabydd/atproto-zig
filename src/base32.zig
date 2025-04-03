const std = @import("std");

pub fn base(byte: u5) u8 {
    const b: u8 = @intCast(byte);
    return if (b < 26) b + 97 else b - 24 + 48;
}

pub fn sortable(byte: u5) u8 {
    const b: u8 = @intCast(byte);
    return if (b < 6) b + 48 + 2 else b - 6 + 97;
}

pub fn encode(bytes: []const u8, out: []u8, toBase: fn (u5) u8) void {
    var i: usize = 0;
    var j: usize = 0;
    var bits: u8 = 0;
    var running: u5 = 0;
    const e: u8 = 8;
    while (i < bytes.len) : (i += 1) {
        const byte = bytes[i];
        const split: u3 = @intCast(5 - bits);
        const left: u3 = @intCast(e - split);
        running |= @intCast(byte >> left);
        out[j] = toBase(running);
        j += 1;
        bits = @min(e - split, 5);
        const end: u3 = @intCast(e - split - bits);
        running = @intCast(((byte << split) >> (end + split)) << @intCast(5 - bits));
        if (bits == 5) {
            out[j] = toBase(running);
            j += 1;
            bits = end;
            running = @intCast((byte << @intCast(split + bits)) >> @intCast(split + bits));
        }
    }
    if (bytes.len % 5 != 0) {
        out[j] = toBase(running);
    }
}

pub fn encodeMultibase(arena: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    var base32: []u8 = try arena.alloc(u8, ((bytes.len * 8 + 4) / 5) + 1);
    base32[0] = 'b';
    encode(bytes, base32[1..], base);
    return base32;
}
