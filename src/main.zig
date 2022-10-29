const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    const prog = args.next().?;
    const paramSeconds = args.next() orelse {
        std.log.err("usage: {s} seconds", .{prog});

        return error.InvalidArgs;
    };

    const stdout = std.io.getStdOut();
    const writer = stdout.writer();

    const seconds = try std.fmt.parseInt(u64, paramSeconds, 10);

    var i: u64 = 0;
    while (i <= seconds) : (i += 1) {
        try writer.print("[\x1b[2K[\u{001b}[42m\u{001b}[1m", .{});

        for (progressBar(i, seconds)) |bar| {
            std.debug.print("{c}", .{bar});
            // try writer.print("{c}", .{bar}); // FIXME: 文字化ける
        }

        // FIXME: 以下もNG
        // var s = progressBar(i, seconds);
        // try writer.print("{s}", .{s});

        try writer.print("\u{001b}[0m] \u{001b}[32m{}/{}\u{001b}[0m\r", .{seconds - i, seconds});

        std.time.sleep(1000000000);
    }

    try writer.print("\n", .{});
}

fn progressBar(currentTime: u64, totalTime: u64) []const u8 {
    const maxWidth = 50;
    const ratio = @intToFloat(f64, currentTime) / @intToFloat(f64, totalTime);
    const current = @floatToInt(u64, maxWidth * ratio);

    var strings = [_]u8{' '} ** maxWidth;

    var i: u64 = 0;
    while (i < maxWidth) : (i += 1)  {
        if (i < current) {
            strings[i] = '=';
            continue;
        }

        if (i == current) {
            strings[i] = '>';
            continue;
        }

        break;
    }

    return strings[0..maxWidth];
}
