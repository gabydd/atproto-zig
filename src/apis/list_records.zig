const std = @import("std");
const Database = @import("../Database.zig");
const Cid = @import("../Cid.zig");
const Base32 = @import("../base32.zig");
const utils = @import("../utils.zig");
const http = @import("zzz").HTTP;

const Input = struct {
    repo: []const u8,
    collection: []const u8,
    cursor: ?[]const u8 = null,
};

const Record = struct { uri: []const u8, cid: []const u8, value: std.json.Value };
const Output = struct {
    cursor: ?[]const u8 = null,
    records: []Record,
};

pub fn handler(ctx: *const http.Context, db: *Database) !http.Respond {
    const value = try http.Query(Input).parse(ctx.allocator, ctx);

    const res = try listRecords(ctx.allocator, db, value);

    const json = try std.json.stringifyAlloc(ctx.allocator, res, .{ .emit_null_optional_fields = false });
    return ctx.response.apply(.{
        .status = .OK,
        .mime = .JSON,
        .body = json,
    });
}

pub fn listRecords(arena: std.mem.Allocator, db: *Database, input: Input) !Output {
    var list: std.ArrayListUnmanaged(Record) = try .initCapacity(arena, db.count(input.repo, input.collection));
    var iter = db.iter(input.repo, input.collection);
    while (iter.next()) |val| {
        list.appendAssumeCapacity(.{
            .uri = try utils.encodeUri(arena, input.collection, val.key_ptr.*),
            .value = val.value_ptr.*,
            .cid = try Base32.encodeMultibase(arena, try Cid.encode(arena, "testing")),
        });
    }
    return .{
        .records = list.items,
    };
}
