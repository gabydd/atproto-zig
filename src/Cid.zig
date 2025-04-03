const std = @import("std");
const Base32 = @import("base32.zig");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub fn encode(arena: std.mem.Allocator, cbor: []const u8) ![]const u8 {
    var cid: std.ArrayListUnmanaged(u8) = .empty;
    try cid.append(arena, 1); // cid version
    try cid.append(arena, 0x71); // dag-cbor
    try cid.append(arena, 0x12); // sha-256
    try cid.append(arena, 32); // sha-256 length

    var hash: Sha256 = .init(.{});
    var hash_buf: [Sha256.digest_length]u8 = undefined;
    hash.update(cbor);
    hash.final(&hash_buf);
    try cid.appendSlice(arena, &hash_buf);
    return cid.toOwnedSlice(arena);
}
