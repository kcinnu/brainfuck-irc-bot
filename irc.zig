const std = @import("std");

pub fn main() !void {
    const socket = try std.net.tcpConnectToHost(std.heap.c_allocator, "irc.libera.chat", 6667);

    try socket.writeAll("NICK alvdlfkbvsdlfk\r\n");
    try socket.writeAll("USER alvdlfkbvsdlfk 0 * alvdlfkbvsdlfk\r\n");
    try socket.writeAll("JOIN ##alvdlfkbvsdlfk\r\n");
    const rd = socket.reader();
    const wr = socket.writer();
    while (true) {
        var buf: [1024]u8 = undefined;
        var len: u32 = 0;
        while (true) {
            const ch = try rd.readByte();
            if (ch != '\r') {
                buf[len] = ch;
                len += 1;
                continue;
            }
            const ch2 = try rd.readByte();
            if (ch2 != '\n') {
                buf[len] = '\r';
                len += 1;
                buf[len] = ch2;
                len += 1;
                continue;
            }
            break;
        }
        std.debug.print("{s}\n", .{buf[0..len]});
        var iter = std.mem.tokenizeScalar(u8, buf[0..len], ' ');
        _ = iter.next().?;
        const cmd = iter.next().?;
        if (std.mem.eql(u8, cmd, "PING")) {
            const res = iter.next().?;
            try wr.print("PONG {s}\r\n", .{res});
        } else if (std.mem.eql(u8, cmd, "PRIVMSG")) {
            _ = iter.next().?;
            const msg = (iter.next().?)[1..];
            std.debug.print("msg {s}\n", .{msg});
        }
    }
}
