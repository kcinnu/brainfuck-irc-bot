const std = @import("std");

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    const args = try std.process.argsAlloc(alloc);
    if (args.len < 3) {
        std.debug.print(
            "you need to specify a nickname and a channel to join (and an irc server if you want to actually use the bot over irc)",
            .{},
        );
        return;
    }

    const file = try std.fs.cwd().openFile("ircbot.bf", .{});
    defer file.close();
    const source = try file.readToEndAlloc(alloc, 1000000000);

    var bytecode = try alloc.alloc(packed struct {
        addr: u29 = 0,
        op: enum(u3) { incr, decr, left, rght, obrk, cbrk, inpt, outp },
    }, source.len);
    var blen: u32 = 0;

    var stack = std.BoundedArray(u32, 256){};

    for (source) |ch| {
        bytecode[blen] = switch (ch) {
            '+' => .{ .op = .incr },
            '-' => .{ .op = .decr },
            '<' => .{ .op = .left },
            '>' => .{ .op = .rght },
            ',' => .{ .op = .inpt },
            '.' => .{ .op = .outp },
            '[' => {
                try stack.append(blen);
                blen += 1;
                continue;
            },
            ']' => {
                const trg = stack.popOrNull() orelse return error.Asdf;
                bytecode[trg] = .{ .op = .obrk, .addr = @intCast(blen) };
                bytecode[blen] = .{ .op = .cbrk, .addr = @intCast(trg) };
                blen += 1;
                continue;
            },
            else => {
                continue;
            },
        };
        blen += 1;
    }

    // std.debug.print("{any}\n", .{bytecode[0..blen]});

    var mem: [1 << 20]u8 = undefined;
    var ptr: usize = 0;
    var ip: u32 = 0;

    @memset(&mem, 0);

    {
        const nick = args[1];
        const channel = args[2];
        ptr += 1;
        @memcpy(mem[ptr .. ptr + nick.len], nick);
        ptr += nick.len + 1;
        @memcpy(mem[ptr .. ptr + channel.len], channel);
        ptr += channel.len;
    }

    var rd: std.io.AnyReader = undefined;
    var wr: std.io.AnyWriter = undefined;

    const local = args.len <= 3;

    if (local) {
        rd = std.io.getStdIn().reader().any();
        wr = std.io.getStdOut().writer().any();
    } else {
        const socket = try std.net.tcpConnectToHost(std.heap.c_allocator, args[3], 6667);

        rd = socket.reader().any();
        wr = socket.writer().any();
    }

    while (ip < blen) {
        // std.debug.print("{d}\n", .{ip});
        switch (bytecode[ip].op) {
            .incr => mem[ptr] +%= 1,
            .decr => mem[ptr] -%= 1,
            .rght => ptr += 1,
            .left => ptr -= 1,
            .inpt => {
                mem[ptr] = try rd.readByte();
                if (!local) std.debug.print("{c}", .{mem[ptr]});
            },
            .outp => {
                try wr.writeByte(mem[ptr]);
                if (!local) std.debug.print("\x1B[41m{c}\x1B[0m", .{mem[ptr]});
            },
            // .outp => try wr.print("{d}\n", .{mem[ptr]}),
            .obrk => if (mem[ptr] == 0) {
                ip = bytecode[ip].addr;
            },
            .cbrk => if (mem[ptr] != 0) {
                ip = bytecode[ip].addr;
            },
        }
        ip += 1;
    }
}
