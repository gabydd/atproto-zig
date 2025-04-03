const std = @import("std");

pub fn encodeUri(gpa: std.mem.Allocator, collection: []const u8, rkey: []const u8) ![]const u8 {
    return std.fmt.allocPrint(gpa, "at://planpromptly.net/{s}/{s}", .{ collection, rkey });
}
