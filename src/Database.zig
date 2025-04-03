const std = @import("std");
const TID = @import("TID.zig");

const CollectionsMap = std.StringArrayHashMapUnmanaged(std.json.Value);
tid: TID,
gpa: std.mem.Allocator,
collections: CollectionsMap,

const Database = @This();

pub fn get(db: *Database, collection: []const u8, repo: []const u8, rkey: []const u8) std.json.Value {
    _ = collection;
    _ = repo;
    return db.collections.get(rkey) orelse .null;
}

pub fn count(db: *Database, collection: []const u8, repo: []const u8) usize {
    _ = collection;
    _ = repo;
    return db.collections.count();
}

pub fn iter(db: *Database, collection: []const u8, repo: []const u8) CollectionsMap.Iterator {
    _ = collection;
    _ = repo;
    return db.collections.iterator();
}

pub fn put(db: *Database, collection: []const u8, repo: []const u8, rkey: []const u8, value: std.json.Value) !void {
    _ = collection;
    _ = repo;
    try db.collections.put(db.gpa, try db.gpa.dupe(u8, rkey), value);
}
