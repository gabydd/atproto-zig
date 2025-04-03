const std = @import("std");

const Tag = packed struct(u8) {
    additional_information: u5,
    type: u3,
};

pub fn varint(cbor: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, value: u64, tag_type: u3) !void {
    if (value <= 0x17) {
        const tag: Tag = .{ .type = tag_type, .additional_information = @intCast(value) };
        try cbor.append(arena, @bitCast(tag));
    } else {
        const little = std.mem.nativeToLittle(u64, value);
        const bytes: [8]u8 = @bitCast(@byteSwap(little));
        const size = (64 - @clz(little) + 7) / 8;
        const tag: Tag = .{ .type = tag_type, .additional_information = @intCast(0x17 + size) };
        try cbor.append(arena, @bitCast(tag));
        try cbor.appendSlice(arena, bytes[bytes.len - size ..]);
    }
}

pub fn map(cbor: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, length: u32) !void {
    try varint(cbor, arena, length, 0x5);
}

pub fn string(cbor: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, value: []const u8) !void {
    try varint(cbor, arena, value.len, 0x3);
    try cbor.appendSlice(arena, value);
}

pub fn json(cbor: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, value: std.json.Value) !void {
    switch (value) {
        .object => |obj| {
            try map(cbor, arena, @intCast(obj.count()));
            const keys = try arena.dupe([]const u8, obj.keys());
            std.mem.sortUnstable([]const u8, keys, {}, struct {
                fn cmp(_: void, lhs: []const u8, rhs: []const u8) bool {
                    return std.mem.order(u8, lhs, rhs) == .lt;
                }
            }.cmp);
            for (keys) |key| {
                try json(cbor, arena, obj.get(key).?);
            }
        },
        .string => |val| {
            try string(cbor, arena, val);
        },
        .integer => |val| {
            if (val >= 0) {
                try varint(cbor, arena, @bitCast(val), 0x0);
            } else {
                try varint(cbor, arena, @abs(val + 1), 0x1);
            }
        },
        else => {
            std.debug.print("unhandled cbor type\n", .{});
        }
    }
}
