const std = @import("std");
const Database = @import("../Database.zig");
const utils = @import("../utils.zig");
const http = @import("zzz").HTTP;

const Input = struct {
    repo: []const u8,
    collection: []const u8,
    rkey: []const u8,
    cid: ?[]const u8 = null,
};

const Output = struct {
    uri: []const u8,
    cid: ?[]const u8 = null,
    value: std.json.Value,
};

pub fn handler(ctx: *const http.Context, db: *Database) !http.Respond {
    const value = try http.Query(Input).parse(ctx.allocator, ctx);

    const res = try getRecord(ctx.allocator, db, value);

    const json = try std.json.stringifyAlloc(ctx.allocator, res, .{ .emit_null_optional_fields = false });
    return ctx.response.apply(.{
        .status = .OK,
        .mime = .JSON,
        .body = json,
    });
}

pub fn getRecord(arena: std.mem.Allocator, db: *Database, input: Input) !Output {
    const value = db.get(input.collection, input.repo, input.rkey);
    return .{
        .uri = try utils.encodeUri(arena, input.collection, input.rkey),
        .value = value,
    };
}
