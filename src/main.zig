const std = @import("std");
const zzz = @import("zzz");
const tardy = zzz.tardy;
const http = zzz.HTTP;
const Router = http.Router;
const Route = http.Route;
const Middleware = http.Middleware;
const Context = http.Context;
const Respond = http.Respond;
const Server = http.Server;
const Next = http.Next;
const Query = http.Query;
const Tardy = tardy.Tardy(.auto);
const Socket = tardy.Socket;
const Runtime = tardy.Runtime;

const apis = @import("apis.zig");
const Database = @import("Database.zig");

pub fn main() !void {
    const host: []const u8 = "0.0.0.0";
    const port: u16 = 9876;

    var gpa: std.heap.DebugAllocator(.{ .thread_safe = true }) = .{};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var db: Database = .{ .tid = .init(), .gpa = allocator, .collections = .{} };

    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    var router = try Router.init(allocator, &.{
        Middleware.init({}, corsMiddleware).layer(),
        Route.init("/xrpc/com.atproto.repo.createRecord").post(&db, apis.CreateRecord.handler).layer(),
        Route.init("/xrpc/com.atproto.repo.getRecord").get(&db, apis.GetRecord.handler).layer(),
        Route.init("/xrpc/com.atproto.repo.createRecord").options({}, notFoundHandler).layer(),
        Route.init("/xrpc/com.atproto.repo.getRecord").options({}, notFoundHandler).layer(),
    }, .{});
    defer router.deinit(allocator);

    // create socket for tardy
    var socket = try Socket.init(.{ .tcp = .{ .host = host, .port = port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(4096);

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
    };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(.{
                    .stack_size = 1024 * 1024 * 4,
                    .socket_buffer_bytes = 1024 * 2,
                });
                try server.serve(rt, p.router, .{ .normal = p.socket });
            }
        }.entry,
    );
}

fn notFoundHandler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .@"Not Found",
        .body = "404 | Not Found",
        .mime = .TEXT,
    });
}

fn corsMiddleware(next: *Next, _: void) !Respond {
    const request = next.context.request;
    const mode = request.headers.get("sec-fetch-mode") orelse return next.run();
    if (!std.mem.eql(u8, mode, "cors")) return next.run();

    try next.context.response.headers.put("Access-Control-Allow-Origin", "*");
    try next.context.response.headers.put("Access-Control-Allow-Methods", "OPTIONS, GET, HEAD, POST");
    try next.context.response.headers.put("Access-Control-Allow-Headers", "atproto-accept-labelers,content-type");
    if (request.method != .OPTIONS) return next.run();
    return next.context.response.apply(.{
        .status = .@"No Content",
        .mime = .TEXT,
        .body = "",
    });
}
