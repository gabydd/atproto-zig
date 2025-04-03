const std = @import("std");
const cbor = @import("../cbor.zig");
const Database = @import("../Database.zig");
const Base32 = @import("../base32.zig");
const Cid = @import("../Cid.zig");
const utils = @import("../utils.zig");
const http = @import("zzz").HTTP;

const Input = struct {
    repo: []const u8,
    collection: []const u8,
    rkey: ?[]const u8 = null,
    validate: ?bool = null,
    record: std.json.Value,
    swapCommit: ?[]const u8 = null,
};

const Output = struct {
    cid: []const u8,
    uri: []const u8,
    commit: struct {
        cid: []const u8,
        rev: []const u8,
    }, // is not required
    // validationStatus: ?enum {valid, unknown},
};

pub fn handler(ctx: *const http.Context, db: *Database) !http.Respond {
    const body = ctx.request.body orelse return error.NoBody;
    const data = try std.json.parseFromSlice(Input, db.gpa, body, .{});
    const res = try createRecord(ctx.allocator, db, data.value);

    const json = try std.json.stringifyAlloc(ctx.allocator, res, .{});
    return ctx.response.apply(.{
        .status = .OK,
        .mime = .JSON,
        .body = json,
    });
}

pub fn createRecord(arena: std.mem.Allocator, db: *Database, input: Input) !Output {
    var cbor_data: std.ArrayListUnmanaged(u8) = .empty;
    try cbor.map(&cbor_data, arena, 2);
    try cbor.string(&cbor_data, arena, "collection");
    try cbor.string(&cbor_data, arena, input.collection);

    try cbor.string(&cbor_data, arena, "record");
    try cbor.json(&cbor_data, arena, input.record);

    const f = try std.fs.createFileAbsolute("/home/gaby/temp/test.cbor", .{});
    try f.writeAll(cbor_data.items);
    f.close();
    const base32 = try Base32.encodeMultibase(arena, try Cid.encode(arena, cbor_data.items));

    std.debug.print("{s}\n", .{base32});

    const tid = db.tid.next();
    std.debug.print("{s}\n", .{&tid});

    try db.put(input.collection, &tid, input.record);

    return .{
        .cid = base32,
        .uri = try utils.encodeUri(arena, input.collection, &tid),
        .commit = .{
            .cid = try Base32.encodeMultibase(arena, try Cid.encode(arena, "testing")),
            .rev = try arena.dupe(u8, &tid),
        },
    };
}
