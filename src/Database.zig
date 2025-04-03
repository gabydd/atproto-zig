const std = @import("std");
const TID = @import("TID.zig");

tid: TID,
gpa: std.mem.Allocator,
collections: std.StringArrayHashMapUnmanaged(std.json.Value),

const Database = @This();

pub fn get(db: *Database, collection: []const u8, rkey: []const u8) std.json.Value {
    _ = collection;
    return db.collections.get(rkey) orelse .null;
}

pub fn put(db: *Database, collection: []const u8, rkey: []const u8, value: std.json.Value) !void {
    _ = collection;
    try db.collections.put(db.gpa, try db.gpa.dupe(u8, rkey), value);
}
